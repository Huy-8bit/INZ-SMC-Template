// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IMysteryBox {
    function initialize(
        string memory       _uri,
        IERC20              _payToken,
        string memory       _name,
        string memory       _symbol,
        uint256             _startTimeToBuy,
        uint256             _endTimeToBuy,
        bool                _isAutoIncreaseId,
        uint256             _totalSupply,
        uint256             _price
    ) external;

    function openBox(address to, uint256 amount) external;
}

