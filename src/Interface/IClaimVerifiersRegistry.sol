// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './IClaimValidator.sol';

interface IClaimVerifiersRegistry {

    event TrustedVerifierAdded(IClaimValidator indexed trustedVerifier, uint256[] claimTopics);

    event TrustedVerifierRemoved(IClaimValidator indexed trustedVerifier);

    event ClaimTopicsUpdated(IClaimValidator indexed trustedVerifier, uint256[] claimTopics);

    function addTrustedVerifier(IClaimValidator _trustedVerifier, uint256[] calldata _claimTopics) external;

    function removeTrustedVerifier(IClaimValidator _trustedVerifier) external;

    function updateVerifierClaimTopics(IClaimValidator _trustedVerifier, uint256[] calldata _claimTopics) external;

    function getTrustedVerifiers() external view returns (IClaimValidator[] memory);

    function isVerifier(address _issuer) external view returns (bool);

    function getTrustedVerifierClaimTopics(IClaimValidator _trustedVerifier) external view returns (uint256[] memory);

    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view returns (bool);

    function transferOwnershipOnVerifiersRegistryContract(address _newOwner) external;
    
}
