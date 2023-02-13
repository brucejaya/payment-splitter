// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./IPaymentSplitter.sol";

interface IPaymentSplitterCloneable is IPaymentSplitter {

    function initialize(address[] memory payees, uint256[] memory shares_) external payable;
    function payeesCount() external view returns (uint256);
    function balanceOf(address payee) external view returns (uint256);
    
}