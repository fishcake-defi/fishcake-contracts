// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IFishcakeMinter.sol";

contract FishcakeMinter is IFishcakeMinter, OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* -------------------------------- CONSTANTS ------------------------------- */
  address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

  uint256 public constant FEE_MAX = 10000;

  /* ----------------------------- STATE VARIABLES ---------------------------- */

  mapping(address => bool) private _minters;

  uint256 public PERFORMANCE_FEE;
  uint256 public override WITHDRAWAL_FEE;
  uint256 public override WITHDRAWAL_FEE_FREE_PERIOD;

  uint256 public override fishcakePerBNBProfit;

  /* -------------------------------- MODIFIERS ------------------------------- */

  modifier onlyMinter {
    require(
      isMinter(msg.sender) == true,
      "FishcakeMinter: caller is not the minter"
    );

    _;
  }

  receive() external payable {}

  /* ------------------------------- INITIALIZER ------------------------------ */
  function initialize() external initializer {
    WITHDRAWAL_FEE_FREE_PERIOD = 3 days;
    WITHDRAWAL_FEE = 50;

    PERFORMANCE_FEE = 3000;

    fishcakePerBNBProfit = 100e18;
  }

  /* ---------------------------------- VIEWS --------------------------------- */
  function isMinter(address account) public view override returns (bool) {
    return _minters[account];
  }

  /* -------------------------- RESTRICTED FUNCTIONS -------------------------- */
  function setMinter(address minter, bool canMint) external override onlyOwner {
    if (canMint) {
      _minters[minter] = canMint;
    } else {
      delete _minters[minter];
    }
  }

  /* ---------------------------- PRIVATE FUNCTIONS --------------------------- */
}
