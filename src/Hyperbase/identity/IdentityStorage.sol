// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract IdentityStorage {

    ////////////////
    // KEYS
    ////////////////
    uint256 constant MANAGEMENT_KEY = 1;
    uint256 constant ACTION_KEY = 2;
    uint256 constant CLAIM_SIGNER_KEY = 3;
    uint256 constant ENCRYPTION_KEY = 4;
    
    mapping(bytes32 => Key) internal keys;
    mapping(uint256 => bytes32[]) internal keysByPurpose;

    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }


    ////////////////
    // EXEUCTIONS
    ////////////////
    uint256 internal executionNonce;
    mapping(uint256 => Execution) internal executions;
    
    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

}