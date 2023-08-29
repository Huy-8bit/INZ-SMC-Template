// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    constructor() ERC20("USD TETHER", "USDT") {
        _mint(msg.sender, 500000000000 * 10 ** 18);
    }
}
