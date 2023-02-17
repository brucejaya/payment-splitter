// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/interfaces/IERC20.sol';

interface IERC20Token is IERC20 {

    // @notice Public function wrapper for internal mint function
    function mint(address account, uint256 amount) external;

}