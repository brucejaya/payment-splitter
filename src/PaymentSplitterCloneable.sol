// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./PaymentSplitter.sol";

contract PaymentSplitterCloneable is PaymentSplitter {

    constructor() {}

    // @notice Initialise for cloneable 
    function initialize(
		address[] memory payees,
		uint256[] memory shares_
	)
        public
        payable
    {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    // @notice Return number of payees
    function payeesLength() public view returns (uint256) {
        return _payees.length;
    }

    // @notice Return releasable balance of payee
    function balanceOf(
        address payee
    )
        public
        view
        returns (uint256)
    {
        require(_shares[payee] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(payee, totalReceived, released(payee));
        return payment;
    }

    // @notice Return release token balance of payee
    function balanceOfTokens(
        address token,
        address payee
    )
        public
        view
        returns (uint256)
    {
        require(_shares[payee] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = IERC20(token).balanceOf(address(this)) + totalTokensReleased(token);
        uint256 payment = _pendingPayment(payee, totalReceived, releasedTokens(token, payee));
        return payment;
    }

    // @notice Return payees

    function payees()
        public
        view
        returns (address[] memory)
    {
        return _payees;   
    }
    
}