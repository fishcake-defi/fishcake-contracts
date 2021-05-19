// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./../interfaces/IFishcakePresale.sol";
import "./../interfaces/IPresaleBeneficiary.sol";

contract FishcakePresale is IFishcakePresale, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ========== STATE VARIABLES ========== */

  uint8 public constant ALLOWED_MAX_DECIMALS = 18;

  uint256 public constant swapBase = 10000;
  uint256 public constant swapMax = 100000000;
  uint256 public constant swapMin = 1;

  uint256 public constant ALLOWED_MAX_SERVICE_FEE = 10000;
  uint256 public serviceFee = 0;

  address public governance;
  address payable public treasury;

  uint256 public auctionCount;
  AuctionInfo[] public auctions;
  mapping(uint256 => mapping(address => UserInfo)) public users;

  /* ========== EVENTS ========== */

  event Create(uint256 indexed id, address indexed token);
  event Archive(uint256 indexed id, address indexed token, uint256 amount);
  event Engage(uint256 indexed id, address indexed participant, uint256 amount);
  event Claim(uint256 indexed id, address indexed participant, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier onlyGovernance {
    require(msg.sender == governance, "onlyGovernance");
    _;
  }

  /* ========== CONSTRUCTOR ========== */

  constructor(address _governance, address payable _treasury) public {
    governance = _governance;
    treasury = _treasury;
  }

  /* ========== RESTRICTED ========== */

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "!governance");
    governance = _governance;
  }

  function setTreasury(address payable _treasury) public onlyGovernance {
    require(_treasury != address(0), "!treasury");
    treasury = _treasury;
  }

  function setServiceFee(uint256 _serviceFee) public onlyGovernance {
    serviceFee = _serviceFee;
  }

  /* ========== VIEWS ========== */

  function swapTokenAmount(uint256 id, uint256 amount)
    public
    view
    override
    returns (uint256)
  {
    AuctionInfo memory auction = auctions[id];
    uint256 decimals = ERC20(auction.token).decimals();
    uint256 decimalCompensation = 10**(ALLOWED_MAX_DECIMALS - decimals);
    return amount.mul(auction.swapRatio).div(swapBase).div(decimalCompensation);
  }

  function getAuctions(uint256 page, uint256 resultPerPage)
    external
    view
    returns (AuctionInfo[] memory, uint256)
  {
    uint256 index = page.mul(resultPerPage);
    uint256 limit = page.add(1).mul(resultPerPage);
    uint256 next = page.add(1);

    if (limit > auctionCount) {
      limit = auctionCount;
      next = 0;
    }

    if (auctionCount == 0 || index > auctionCount - 1) {
      return (new AuctionInfo[](0), 0);
    }

    uint256 cursor = 0;
    AuctionInfo[] memory segment = new AuctionInfo[](limit.sub(index));
    for (index; index < limit; index++) {
      if (index < auctionCount) {
        segment[cursor] = auctions[index];
      }
      cursor++;
    }

    return (segment, next);
  }

  function getAuction(uint256 id)
    external
    view
    override
    returns (AuctionInfo memory)
  {
    return auctions[id];
  }

  function getUserInfo(uint256 id, address user)
    external
    view
    override
    returns (UserInfo memory)
  {
    return users[id][user];
  }

  /* ========== FOR BENEFICIARIES ========== */

  function create(AuctionInfo memory request) external payable {
    require(request.deadline > now, "!deadline");
    require(request.allocation > 0, "!allocation");
    require(request.beneficiary != address(0), "!beneficiary");
    require(
      request.swapRatio >= swapMin && request.swapRatio <= swapMax,
      "!swapRatio"
    );

    require(request.token != address(0), "!token");
    require(request.tokenSupply > 0, "!tokenSupply");

    uint256 decimals = ERC20(request.token).decimals();
    require(decimals <= ALLOWED_MAX_DECIMALS, "!decimals");

    uint256 decimalCompensation = 10**(ALLOWED_MAX_DECIMALS - decimals);
    uint256 capacity =
      request.tokenSupply.mul(decimalCompensation).mul(swapBase).div(
        request.swapRatio
      );

    uint256 fee = capacity.mul(serviceFee).div(ALLOWED_MAX_SERVICE_FEE);
    require(msg.value >= fee, "!fee");
    if (msg.value > 0) {
      treasury.transfer(msg.value);
    }

    IERC20 token = IERC20(request.token);
    require(token.balanceOf(msg.sender) >= request.tokenSupply, "!tokenSupply");

    uint256 preBalance = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), request.tokenSupply);
    uint256 balanceDiff = token.balanceOf(address(this)).sub(preBalance);
    require(balanceDiff == request.tokenSupply, "!tokenSupply");

    request.tokenRemain = request.tokenSupply;
    request.capacity = capacity;
    request.engaged = 0;
    auctions.push(request);
    auctionCount++;

    if (request.option == AuctionOpts.Callback) {
      IPresaleBeneficiary(request.beneficiary).notifyCreate(
        auctionCount,
        request.token
      );
    }

    emit Create(auctionCount, request.token);
  }

  function archive(uint256 id) external nonReentrant {
    AuctionInfo memory auction = auctions[id];

    require(!auction.archived, "!archived");
    require(now >= auction.deadline, "!deadline");

    if (auction.option == AuctionOpts.Callback) {
      IERC20(auction.token).safeTransfer(
        auction.beneficiary,
        auction.tokenSupply
      );
    } else {
      IERC20(auction.token).safeTransfer(
        auction.beneficiary,
        auction.tokenRemain
      );
    }

    uint256 totalEngaged = auction.engaged;
    auction.archived = true;
    auctions[id] = auction;

    if (totalEngaged > 0) {
      auction.beneficiary.transfer(totalEngaged);
    }

    if (auction.option == AuctionOpts.Callback) {
      IPresaleBeneficiary(auction.beneficiary).notifyArchive(
        id,
        auction.token,
        auction.engaged
      );
    }

    emit Archive(id, auction.token, totalEngaged);
  }

  /* ========== FOR USERS ========== */

  function engage(uint256 id) external payable {
    AuctionInfo memory auction = auctions[id];

    require(!auction.archived, "!archived");
    require(now < auction.deadline, "!deadline");

    uint256 available = auction.capacity.sub(auction.engaged);
    require(available >= 0 && msg.value <= available, "!remain");

    UserInfo memory user = users[id][msg.sender];
    require(user.engaged.add(msg.value) <= auction.allocation, "!allocation");

    user.engaged = user.engaged.add(msg.value);
    users[id][msg.sender] = user;

    uint256 tokenAmount = swapTokenAmount(id, msg.value);
    auction.tokenRemain = auction.tokenRemain.sub(tokenAmount);
    auction.engaged = auction.engaged.add(msg.value);
    auctions[id] = auction;

    if (auction.option == AuctionOpts.Callback) {
      IPresaleBeneficiary(auction.beneficiary).notifyEngage(
        id,
        msg.sender,
        msg.value
      );
    }

    emit Engage(id, msg.sender, msg.value);
  }

  function claim(uint256 id) external nonReentrant {
    AuctionInfo memory auction = auctions[id];

    require(auction.archived, "!archived");
    require(now >= auction.deadline, "!deadline");

    UserInfo memory user = users[id][msg.sender];
    require(user.engaged > 0 && !user.claim, "!engaged");

    user.claim = true;
    users[id][msg.sender] = user;

    if (auction.option == AuctionOpts.Callback) {
      IPresaleBeneficiary(auction.beneficiary).notifyClaim(
        id,
        msg.sender,
        user.engaged
      );
    } else {
      uint256 tokenAmount = swapTokenAmount(id, user.engaged);
      require(tokenAmount >= 0, "!tokenAmount");

      IERC20(auction.token).safeTransfer(msg.sender, tokenAmount);
    }

    emit Claim(id, msg.sender, user.engaged);
  }
}
