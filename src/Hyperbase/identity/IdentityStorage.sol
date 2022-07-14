// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract IdentityStorage {

    /// Keys
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

    /// Claims
    mapping(bytes32 => Claim) internal claims;
    mapping(uint256 => bytes32[]) internal claimsByTopic; 

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /// Multi-signature
    mapping(uint256 => uint256) sigRequirementByKeyType;
    mapping(uint256 => bool) supportedOpType;
    // TODO reference gnosis

    /// Executions
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