//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "openzeppelin-contracts/contracts/utils/Context.sol";
import "openzeppelin-contracts/contracts/finance/PaymentSplitter.sol";

contract PaymentSplitterCloneable is PaymentSplitter, Context {
    
    constructor() parent(address[], uint256[]) {}

    function initialize(
		address[] memory payees,
		uint256[] memory shares_
	) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

}