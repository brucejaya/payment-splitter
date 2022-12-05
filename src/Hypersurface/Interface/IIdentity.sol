// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./IERC734.sol";
interface IIdentity is IERC734 {
	
    event Approval(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 operationType, uint256 required);
    event ExecutedGasRelayed(bytes32 signHash, bool success);

}