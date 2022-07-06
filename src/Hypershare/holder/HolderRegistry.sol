// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '../../Interface/IClaimVerifier.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IHolderClaimsRequired.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IHolderRegistry.sol';
import '../../Interface/IHolderRegistryStorage.sol';

import '../roles/agent/AgentRole.sol';

contract HolderRegistry is IHolderRegistry, AgentRole {

    // @dev Address of the HolderClaimsRequired Contract
    IHolderClaimsRequired private tokenClaimsRequired;

    // @dev Address of the ClaimVerifiersRegistry Contract
    IClaimVerifiersRegistry private tokenClaimsVerifiers;

    // @dev Address of the HolderRegistryStorage Contract
    IHolderRegistryStorage private tokenHolderStorage;

    /**
     *  @dev the constructor initiates the Identity Registry smart contract
     *  @param _claimVerifiersRegistry the trusted issuers registry linked to the Identity Registry
     *  @param _holderClaimsRequired the claim topics registry linked to the Identity Registry
     *  @param _holderStorage the holder registry storage linked to the Identity Registry
     *  emits a `HolderClaimsRequiredSet` event
     *  emits a `ClaimVerifiersRegistrySet` event
     *  emits an `HolderStorageSet` event
     */
    constructor(
        address _claimVerifiersRegistry,
        address _holderClaimsRequired,
        address _holderStorage
    ) {
        tokenClaimsRequired = IHolderClaimsRequired(_holderClaimsRequired);
        tokenClaimsVerifiers = IClaimVerifiersRegistry(_claimVerifiersRegistry);
        tokenHolderStorage = IHolderRegistryStorage(_holderStorage);
        emit HolderClaimsRequiredSet(_holderClaimsRequired);
        emit ClaimVerifiersRegistrySet(_claimVerifiersRegistry);
        emit HolderStorageSet(_holderStorage);
    }

    /**
     *  @dev See {IHolderRegistry-holder}.
     */
    function holder(
        address _account
    ) public view override returns (IIdentityRegistry) {
        return tokenHolderStorage.storedIdentity(_account);
    }

    /**
     *  @dev See {IHolderRegistry-investorCountry}.
     */
    function investorCountry(
        address _account
    ) external view override returns (uint16) {
        return tokenHolderStorage.storedInvestorCountry(_account);
    }

    /**
     *  @dev See {IHolderRegistry-issuersRegistry}.
     */
    function issuersRegistry() external view override returns (IClaimVerifiersRegistry) {
        return tokenClaimsVerifiers;
    }

    /**
     *  @dev See {IHolderRegistry-topicsRegistry}.
     */
    function topicsRegistry() external view override returns (IHolderClaimsRequired) {
        return tokenClaimsRequired;
    }

    /**
     *  @dev See {IHolderRegistry-holderStorage}.
     */
    function holderStorage() external view override returns (IHolderRegistryStorage) {
        return tokenHolderStorage;
    }

    /**
     *  @dev See {IHolderRegistry-registerIdentity}.
     */
    function registerIdentity(
        address _account,
        IIdentityRegistry _holder,
        uint16 _country
    ) public override onlyOperator {
        tokenHolderStorage.addIdentityToStorage(_account, _holder, _country);
        emit IdentityRegistered(_account, _holder);
    }

    /**
     *  @dev See {IHolderRegistry-batchRegisterIdentity}.
     */
    function batchRegisterIdentity(
        address[] calldata _accountes,
        IIdentityRegistry[] calldata _identities,
        uint16[] calldata _countries
    ) external override {
        for (uint256 i = 0; i < _accountes.length; i++) {
            registerIdentity(_accountes[i], _identities[i], _countries[i]);
        }
    }

    /**
     *  @dev See {IHolderRegistry-updateIdentity}.
     */
    function updateIdentity(
        address _account,
        IIdentityRegistry _holder
    ) external override onlyOperator {
        IIdentityRegistry oldIdentity = holder(_account);
        tokenHolderStorage.modifyStoredIdentity(_account, _holder);
        emit IdentityUpdated(oldIdentity, _holder);
    }

    /**
     *  @dev See {IHolderRegistry-updateCountry}.
     */
    function updateCountry(
        address _account,
        uint16 _country
    ) external override onlyOperator {
        tokenHolderStorage.modifyStoredInvestorCountry(_account, _country);
        emit CountryUpdated(_account, _country);
    }

    /**
     *  @dev See {IHolderRegistry-deleteIdentity}.
     */
    function deleteIdentity(
        address _account
    ) external override onlyOperator {
        tokenHolderStorage.removeIdentityFromStorage(_account);
        emit IdentityRemoved(_account, holder(_account));
    }

    /**
     *  @dev See {IHolderRegistry-isVerified}.
     */
    function isVerified(
        address _account
    ) external view override returns (bool) {
        if (address(holder(_account)) == address(0)) {
            return false;
        }
        uint256[] memory requiredClaimTopics = tokenClaimsRequired.getClaimTopics();
        if (requiredClaimTopics.length == 0) {
            return true;
        }
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopic;
        for (claimTopic = 0; claimTopic < requiredClaimTopics.length; claimTopic++) {
            bytes32[] memory claimIds = holder(_account).getClaimIdsByTopic(requiredClaimTopics[claimTopic]);
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = holder(_account).getClaim(claimIds[j]);

                try IClaimIssuer(issuer).isClaimValid(holder(_account), requiredClaimTopics[claimTopic], sig,
                data) returns(bool _validity){
                    if (
                        _validity
                        && tokenClaimsVerifiers.hasClaimTopic(issuer, requiredClaimTopics[claimTopic])
                        && tokenClaimsVerifiers.isTrustedIssuer(issuer)
                    ) {
                        j = claimIds.length;
                    }
                    if (!tokenClaimsVerifiers.isTrustedIssuer(issuer) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!tokenClaimsVerifiers.hasClaimTopic(issuer, requiredClaimTopics[claimTopic]) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!_validity && j == (claimIds.length - 1)) {
                        return false;
                    }
                }
                catch {
                    if (j == (claimIds.length - 1)) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    /**
     *  @dev See {IHolderRegistry-setHolderRegistryStorage}.
     */
    function setHolderRegistryStorage(
        address _holderRegistryStorage
    ) external override onlyOwner {
        tokenHolderStorage = IHolderRegistryStorage(_holderRegistryStorage);
        emit HolderStorageSet(_holderRegistryStorage);
    }

    /**
     *  @dev See {IHolderRegistry-setHolderClaimsRequired}.
     */
    function setHolderClaimsRequired(
        address _holderClaimsRequired
    ) external override onlyOwner {
        tokenClaimsRequired = IHolderClaimsRequired(_holderClaimsRequired);
        emit HolderClaimsRequiredSet(_holderClaimsRequired);
    }

    /**
     *  @dev See {IHolderRegistry-setClaimVerifiersRegistry}.
     */
    function setClaimVerifiersRegistry(
        address _claimVerifiersRegistry
    ) external override onlyOwner {
        tokenClaimsVerifiers = IClaimVerifiersRegistry(_claimVerifiersRegistry);
        emit ClaimVerifiersRegistrySet(_claimVerifiersRegistry);
    }

    /**
     *  @dev See {IHolderRegistry-contains}.
     */
    function contains(
        address _account
    ) external view override returns (bool) {
        if (address(holder(_account)) == address(0)) {
            return false;
        }
        return true;
    }

    /**
     *  @dev See {IHolderRegistry-transferOwnershipOnHolderRegistryContract}.
     */
    function transferOwnershipOnHolderRegistryContract(
        address _newOwner
    ) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IHolderRegistry-addAgentOnHolderRegistryContract}.
     */
    function addAgentOnHolderRegistryContract(
        address _agent
    ) external override {
        addAgent(_agent);
    }

    /**
     *  @dev See {IHolderRegistry-removeAgentOnHolderRegistryContract}.
     */
    function removeAgentOnHolderRegistryContract(
        address _agent
    ) external override {
        removeAgent(_agent);
    }
}
