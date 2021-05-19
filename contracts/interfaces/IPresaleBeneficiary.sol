// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IPresaleBeneficiary {
  /**
   * @dev Executed when the auction is created.
   * @param auctionId Index of auctions array
   * @param token The address of token registered for auction
   */
  function notifyCreate(uint256 auctionId, address token) external;

  /**
   * @notice Keep user data as you like.
   * @dev Executed whenever a participant invokes an engage.
   * @param auctionId Index of auctions array
   * @param user The address of the user invoked the engage
   * @param amount The amount the user participated in the auction (ETH/BNB)
   */
  function notifyEngage(
    uint256 auctionId,
    address user,
    uint256 amount
  ) external;

  /**
   * @notice Token and funds raised will be transferred before the call.
   * @dev Executed when the auction is archived.
   * @param auctionId Index of auctions array
   * @param token The address of token registered for auction
   * @param amount The amount raised in auction (ETH/BNB)
   */
  function notifyArchive(
    uint256 auctionId,
    address token,
    uint256 amount
  ) external;

  /**
   * @notice You are responsible for distributing rewards to users.
   * @dev Executed whenever a participant invokes a claim.
   * @param auctionId Index of auctions array
   * @param user The address of the user invoked the claim
   * @param amount The amount the user participated in the auction (ETH/BNB)
   */
  function notifyClaim(
    uint256 auctionId,
    address user,
    uint256 amount
  ) external;
}
