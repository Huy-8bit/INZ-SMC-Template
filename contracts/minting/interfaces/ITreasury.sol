// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITreasury {
    /**
     *  @notice Function allow update balance to InZTreasury contract
     */
    function updateBalanceCollection(
        address _collectionAddress,
        address _payToken,
        uint256 _amount
    ) external;

    /**
     *  @notice Function allow send Token from Treasury to Gateway
     */
    function withdrawFromGateway(
        uint256 _amount,
        address _collectionAddress,
        address _payToken
    ) external;

}

