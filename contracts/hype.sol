// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.4.0/token/ERC20/ERC20.sol";

contract HYPE is ERC20 {
    constructor() ERC20("HYPE", "HYPE") {
        _mint(msg.sender, 7000000000 * 10 ** decimals());
    }
}