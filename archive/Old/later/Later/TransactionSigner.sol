/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.6;


import './C.sol';


// Signature management and execution


// Won't msg.sender fail with signed transactions?

contract TransactionSigner is TransactionRelay {


    mapping(bytes32 => mapping(uint256 => uint256)) public SigRequirementByKeyType;

    // ********************************* Execution stuff ******************************** //
    
    
    // Multi sign stuff
    
    
}