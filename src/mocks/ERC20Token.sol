// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract TokenERC20 is ERC20 {

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