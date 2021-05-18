// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFishcakeMinter {
  //Views
  function WITHDRAWAL_FEE() external view returns (uint256);

  function WITHDRAWAL_FEE_FREE_PERIOD() external view returns (uint256);

  function setMinter(address minter, bool canMint) external;

  function fishcakePerBNBProfit() external view returns (uint256);

  function isMinter(address account) external view returns (bool);
}
