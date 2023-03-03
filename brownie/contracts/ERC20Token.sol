// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract ERC20Token is ERC20 {

    // @notice Constructor
    constructor() ERC20("Test Token", "TT") { }

    // @notice Public function wrapper for internal mint function
    function mint(
        address account,
        uint256 amount
    )
        public
    {
        _mint(account, amount);
    }

}