// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract FishcakePresale is Ownable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ----------------------------- STATE VARIABLES ---------------------------- */

  uint8 public constant ALLOWED_MAX_DECIMALS = 18;

  uint256 public auctionCount;
}
