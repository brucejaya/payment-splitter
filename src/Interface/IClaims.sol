// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IClaims {

    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, address indexed subject, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, address indexed subject, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, address indexed subject, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, address indexed subject, bytes signature, bytes data, string uri);

    function getClaim(bytes32 _claimId, address _subject) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);
    function getClaimIdsByTopic(uint256 _topic, address _subject) external view returns(bytes32[] memory claimIds);
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, address subject, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);
    function removeClaim(bytes32 _claimId, address _subject) external returns (bool success);
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(address subject, uint256 claimTopic, bytes memory sig, bytes memory data ) public override view returns (bool claimValid);
}