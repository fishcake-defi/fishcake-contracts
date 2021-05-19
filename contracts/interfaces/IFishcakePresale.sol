// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IFishcakePresale {
  // Swap for simple auction and Callback for delegate contract
  enum AuctionOpts { Swap, Callback }

  struct AuctionInfo {
    string name; // auction name
    uint256 deadline; // auction deadline
    uint256 swapRatio; // swap ratio [1-100000000]
    uint256 allocation; // allocation per wallet
    uint256 tokenSupply; // amount of the pre-sale token
    uint256 tokenRemain; // remain of the pre-sale token
    uint256 capacity; // total value of pre-sale token in ETH or BNB (calculated by RocketBunny)
    uint256 engaged; // total raised fund value ()
    address token; // address of the pre-sale token
    address payable beneficiary; // auction host (use contract address for AuctionOpts.Callback)
    bool archived; // flag to determine archived
    AuctionOpts option; // options [Swap, Callback]
  }

  struct UserInfo {
    uint256 engaged;
    bool claim;
  }

  function getAuction(uint256 id) external view returns (AuctionInfo memory);

  /**
   * @dev User's amount and boolean flag for claim
   * @param id Auction ID
   * @param user User's address
   * @return True for already claimed
   */
  function getUserInfo(uint256 id, address user)
    external
    view
    returns (UserInfo memory);

  /**
   * @dev Calculate the amount of tokens for the funds raised.
   * @param id Auction ID
   * @param amount Raised amount (ETH/BNB)
   * @return The amount of tokens swapped
   */
  function swapTokenAmount(uint256 id, uint256 amount)
    external
    view
    returns (uint256);
}
