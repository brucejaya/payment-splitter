// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IClaimsRequired {

    event ClaimVerifiersRegistrySet(address indexed trustedVerifiersRegistry);
    event ClaimTopicAdded(uint256 indexed claimTopic, uint256 indexed id);
    event ClaimTopicRemoved(uint256 indexed claimTopic, uint256 indexed id);
    event ClaimRegistrySet(address claimRegistry_);

    function addClaimTopic(uint256 claimTopic, uint256 id) external;
    function removeClaimTopic(uint256 claimTopic, uint256 id) external;
    function getClaimTopics(uint256 id) external view returns (uint256[] memory);
    function transferOwnershipOnComplianceClaimsRequiredContract(address newOwner) external;
    function isVerified(address account, uint256 id) external view returns (bool);

    
    
}