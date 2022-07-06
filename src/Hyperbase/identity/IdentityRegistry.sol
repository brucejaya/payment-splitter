// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '../../Interface/IClaimVerifier.sol';
import '../../Interface/IIdentity.sol';

import '../../Interface/IClaimTopicsRegistry.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IIdentityRegistryStorage.sol';

import '../../Role/agent/AgentRole.sol';

contract IdentityRegistry is IIdentityRegistry, AgentRole {

    /// @dev Address of the IdentityRegistryStorage Contract
    IIdentityRegistryStorage private identityRegistryStorage;

    /// @dev Address of the ClaimTopicsRegistry Contract
    IClaimTopicsRegistry private claimTopicsRegistry;

    /// @dev Address of the TrustedIssuersRegistry Contract
    IClaimVerifiersRegistry private claimVerifiersRegistry;

    /**
     *  @dev the constructor initiates the Identity Registry smart contract
     *  @param _claimVerifiersRegistry the trusted issuers registry linked to the Identity Registry
     *  @param _claimTopicsRegistry the claim topics registry linked to the Identity Registry
     *  @param _identityRegistryStorage the identity registry storage linked to the Identity Registry
     *  emits a `ClaimTopicsRegistrySet` event
     *  emits a `TrustedIssuersRegistrySet` event
     *  emits an `IdentityStorageSet` event
     */
    constructor(
        address _claimVerifiersRegistry,
        address _claimTopicsRegistry,
        address _identityRegistryStorage
    ) {
        claimTopicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        claimVerifiersRegistry = IClaimVerifiersRegistry(_claimVerifiersRegistry);
        identityRegistryStorage = IIdentityRegistryStorage(_identityRegistryStorage);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
        emit TrustedIssuersRegistrySet(_claimVerifiersRegistry);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    /**
     *  @dev See {IIdentityRegistry-identity}.
     */
    function identity(
        address _account
    )
        public
        view
        override
        returns (IIdentity)
    {
        return identityRegistryStorage.storedIdentity(_account);
    }

    /**
     *  @dev See {IIdentityRegistry-holderCountry}.
     */
    function holderCountry(
        address _account
    )
        external
        view
        override
        returns (uint16)
    {
        return identityRegistryStorage.storedHolderCountry(_account);
    }

    /**
     *  @dev See {IIdentityRegistry-issuersRegistry}.
     */
    function issuersRegistry()
        external
        view
        override
        returns (IClaimVerifiersRegistry)
    {
        return claimVerifiersRegistry;
    }

    /**
     *  @dev See {IIdentityRegistry-topicsRegistry}.
     */
    function topicsRegistry()
        external
        view
        override
        returns (IClaimTopicsRegistry)
    {
        return claimTopicsRegistry;
    }

    /**
     *  @dev See {IIdentityRegistry-identityStorage}.
     */
    function identityStorage()
        external
        view
        override
        returns (IIdentityRegistryStorage)
    {
        return identityRegistryStorage;
    }

    /**
     *  @dev See {IIdentityRegistry-registerIdentity}.
     */
    function registerIdentity(
        address _account,
        IIdentity _identity,
        uint16 _country
    )
        public
        override
        onlyAgent
    {
        identityRegistryStorage.addIdentityToStorage(_account, _identity, _country);
        emit IdentityRegistered(_account, _identity);
    }

    /**
     *  @dev See {IIdentityRegistry-batchRegisterIdentity}.
     */
    function batchRegisterIdentity(
        address[] calldata _accounts,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    )
        external
        override
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            registerIdentity(_accounts[i], _identities[i], _countries[i]);
        }
    }

    /**
     *  @dev See {IIdentityRegistry-updateIdentity}.
     */
    function updateIdentity(
        address _account,
        IIdentity _identity
    )
        external
        override
        onlyAgent
    {
        IIdentity oldIdentity = identity(_account);
        identityRegistryStorage.modifyStoredIdentity(_account, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistry-updateCountry}.
     */
    function updateCountry(
        address _account, 
        uint16 _country
    )
        external
        override
        onlyAgent
    {
        identityRegistryStorage.modifyStoredHolderCountry(_account, _country);
        emit CountryUpdated(_account, _country);
    }

    /**
     *  @dev See {IIdentityRegistry-deleteIdentity}.
     */
    function deleteIdentity(
        address _account
    )
        external
        override
        onlyAgent
    {
        identityRegistryStorage.removeIdentityFromStorage(_account);
        emit IdentityRemoved(_account, identity(_account));
    }

    /**
     *  @dev See {IIdentityRegistry-isVerified}.
     */
    function isVerified(address _account) external view override returns (bool) {
        if (address(identity(_account)) == address(0)) {
            return false;
        }
        uint256[] memory requiredClaimTopics = claimTopicsRegistry.getClaimTopics();
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
            bytes32[] memory claimIds = identity(_account).getClaimIdsByTopic(requiredClaimTopics[claimTopic]);
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = identity(_account).getClaim(claimIds[j]);

                try IClaimVerifier(issuer).isClaimValid(identity(_account), requiredClaimTopics[claimTopic], sig,
                data) returns(bool _validity){
                    if (
                        _validity
                        && claimVerifiersRegistry.hasClaimTopic(issuer, requiredClaimTopics[claimTopic])
                        && claimVerifiersRegistry.isVerifier(issuer)
                    ) {
                        j = claimIds.length;
                    }
                    if (!claimVerifiersRegistry.isVerifier(issuer) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!claimVerifiersRegistry.hasClaimTopic(issuer, requiredClaimTopics[claimTopic]) && j == (claimIds.length - 1)) {
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
     *  @dev See {IIdentityRegistry-setIdentityRegistryStorage}.
     */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external override onlyOwner {
        identityRegistryStorage = IIdentityRegistryStorage(_identityRegistryStorage);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    /**
     *  @dev See {IIdentityRegistry-setClaimTopicsRegistry}.
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external override onlyOwner {
        claimTopicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
    }

    /**
     *  @dev See {IIdentityRegistry-setTrustedIssuersRegistry}.
     */
    function setTrustedIssuersRegistry(address _claimVerifiersRegistry) external override onlyOwner {
        claimVerifiersRegistry = IClaimVerifiersRegistry(_claimVerifiersRegistry);
        emit TrustedIssuersRegistrySet(_claimVerifiersRegistry);
    }

    /**
     *  @dev See {IIdentityRegistry-contains}.
     */
    function contains(address _account) external view override returns (bool) {
        if (address(identity(_account)) == address(0)) {
            return false;
        }
        return true;
    }

    /**
     *  @dev See {IIdentityRegistry-transferOwnershipOnIdentityRegistryContract}.
     */
    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IIdentityRegistry-addAgentOnIdentityRegistryContract}.
     */
    function addAgentOnIdentityRegistryContract(address _agent) external override {
        addAgent(_agent);
    }

    /**
     *  @dev See {IIdentityRegistry-removeAgentOnIdentityRegistryContract}.
     */
    function removeAgentOnIdentityRegistryContract(address _agent) external override {
        removeAgent(_agent);
    }
}
