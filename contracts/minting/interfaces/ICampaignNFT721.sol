// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ICampaignNFT721 {
    function initialize(
        string memory _symbol,
        string memory _name,
        address _adminAddress,
        address _factoryAddress
    ) external;
}


