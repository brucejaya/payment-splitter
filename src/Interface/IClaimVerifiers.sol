// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import './IIdentity.sol';
interface IClaimVerifiers {

    event TrustedVerifierAdded(IIdentity indexed trustedVerifier, uint256[] claimTopics);
    event TrustedVerifierRemoved(IIdentity indexed trustedVerifier);
    event ClaimTopicsUpdated(IIdentity indexed trustedVerifier, uint256[] claimTopics);

    function addTrustedVerifier(IIdentity _trustedVerifier, uint256[] calldata _claimTopics) external;
    function removeTrustedVerifier(IIdentity _trustedVerifier) external;
    function updateVerifierClaimTopics(IIdentity _trustedVerifier, uint256[] calldata _claimTopics) external;
    function isVerifier(address _issuer) external view returns (bool);
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view returns (bool);
    function transferOwnershipOnVerifiersRegistryContract(address _newOwner) external;
    
}
