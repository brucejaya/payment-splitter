// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './IClaimValidator.sol';

interface IClaimVerifiersRegistry {
    /**
     *  this event is emitted when a trusted issuer is added in the registry.
     *  the event is emitted by the addTrustedVerifier function
     *  `trustedVerifier` is the address of the trusted issuer's ClaimVerifier contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event TrustedVerifierAdded(IClaimValidator indexed trustedVerifier, uint256[] claimTopics);

    /**
     *  this event is emitted when a trusted issuer is removed from the registry.
     *  the event is emitted by the removeTrustedVerifier function
     *  `trustedVerifier` is the address of the trusted issuer's ClaimVerifier contract
     */
    event TrustedVerifierRemoved(IClaimValidator indexed trustedVerifier);

    /**
     *  this event is emitted when the set of claim topics is changed for a given trusted issuer.
     *  the event is emitted by the updateVerifierClaimTopics function
     *  `trustedVerifier` is the address of the trusted issuer's ClaimVerifier contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event ClaimTopicsUpdated(IClaimValidator indexed trustedVerifier, uint256[] claimTopics);

    /**
     *  @dev registers a ClaimVerifier contract as trusted claim issuer.
     *  Requires that a ClaimVerifier contract doesn't already exist
     *  Requires that the claimTopics set is not empty
     *  @param _trustedVerifier The ClaimVerifier contract address of the trusted claim issuer.
     *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Verifiers Registry contract
     *  emits a `TrustedVerifierAdded` event
     */
    function addTrustedVerifier(IClaimValidator _trustedVerifier, uint256[] calldata _claimTopics) external;

    /**
     *  @dev Removes the ClaimVerifier contract of a trusted claim issuer.
     *  Requires that the claim issuer contract to be registered first
     *  @param _trustedVerifier the claim issuer to remove.
     *  This function can only be called by the owner of the Trusted Verifiers Registry contract
     *  emits a `TrustedVerifierRemoved` event
     */
    function removeTrustedVerifier(IClaimValidator _trustedVerifier) external;

    /**
     *  @dev Updates the set of claim topics that a trusted issuer is allowed to emit.
     *  Requires that this ClaimVerifier contract already exists in the registry
     *  Requires that the provided claimTopics set is not empty
     *  @param _trustedVerifier the claim issuer to update.
     *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Verifiers Registry contract
     *  emits a `ClaimTopicsUpdated` event
     */
    function updateVerifierClaimTopics(IClaimValidator _trustedVerifier, uint256[] calldata _claimTopics) external;

    /**
     *  @dev Function for getting all the trusted claim issuers stored.
     *  @return array of all claim issuers registered.
     */
    function getTrustedVerifiers() external view returns (IClaimValidator[] memory);

    /**
     *  @dev Checks if the ClaimVerifier contract is trusted
     *  @param _issuer the address of the ClaimVerifier contract
     *  @return true if the issuer is trusted, false otherwise.
     */
    function isVerifier(address _issuer) external view returns (bool);

    /**
     *  @dev Function for getting all the claim topic of trusted claim issuer
     *  Requires the provided ClaimVerifier contract to be registered in the trusted issuers registry.
     *  @param _trustedVerifier the trusted issuer concerned.
     *  @return The set of claim topics that the trusted issuer is allowed to emit
     */
    function getTrustedVerifierClaimTopics(IClaimValidator _trustedVerifier) external view returns (uint256[] memory);

    /**
     *  @dev Function for checking if the trusted claim issuer is allowed
     *  to emit a certain claim topic
     *  @param _issuer the address of the trusted issuer's ClaimVerifier contract
     *  @param _claimTopic the Claim Topic that has to be checked to know if the `issuer` is allowed to emit it
     *  @return true if the issuer is trusted for this claim topic.
     */
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view returns (bool);

    /**
     *  @dev Transfers the Ownership of TrustedVerifiersRegistry to a new Owner.
     *  @param _newOwner The new owner of this contract.
     *  This function can only be called by the owner of the Trusted Verifiers Registry contract
     *  emits an `OwnershipTransferred` event
     */
    function transferOwnershipOnVerifiersRegistryContract(address _newOwner) external;
}
