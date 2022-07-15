// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '../../Interface/IClaimValidator.sol';
import '../../Interface/IIdentity.sol';

import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IIdentityRegistryStorage.sol';

import '../../Role/agent/AgentRole.sol';

contract IdentityRegistry is IIdentityRegistry, AgentRole {

    //  @dev Address of the IdentityRegistryStorage Contract
    IIdentityRegistryStorage private identityRegistryStorage_;

    //  @dev Address of the ComplianceClaimsRequired Contract
    IComplianceClaimsRequired private complianceClaimsRequired_;

    //  @dev Address of the TrustedVerifierssRegistry Contract
    IClaimVerifiersRegistry private claimVerifiersRegistry_;

    //  @dev the constructor initiates the Identity Registry smart contract
    constructor(
        address _claimVerifiersRegistry,
        address _complianceClaimsRequired,
        address _identityRegistryStorage
    ) {
        complianceClaimsRequired_ = IComplianceClaimsRequired(_complianceClaimsRequired);
        claimVerifiersRegistry_ = IClaimVerifiersRegistry(_claimVerifiersRegistry);
        identityRegistryStorage_ = IIdentityRegistryStorage(_identityRegistryStorage);
        emit ComplianceClaimsRequiredSet(_complianceClaimsRequired);
        emit ClaimVerifiersRegistrySet(_claimVerifiersRegistry);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    function identity(
        address _account
    )
        public
        view
        override
        returns (IIdentity)
    {
        return identityRegistryStorage_.storedIdentity(_account);
    }

    function holderCountry(
        address _account
    )
        external
        view
        override
        returns (uint16)
    {
        return identityRegistryStorage_.storedHolderCountry(_account);
    }

    function claimVerifiersRegistry()
        external
        view
        override
        returns (IClaimVerifiersRegistry)
    {
        return claimVerifiersRegistry_;
    }

    function complianceClaimsRequired()
        external
        view
        override
        returns (IComplianceClaimsRequired)
    {
        return complianceClaimsRequired_;
    }

    function identityRegistryStorage()
        external
        view
        override
        returns (IIdentityRegistryStorage)
    {
        return identityRegistryStorage_;
    }

    function registerIdentity(
        address _account,
        IIdentity _identity,
        uint16 _country
    )
        public
        override
        onlyAgent
    {
        identityRegistryStorage_.addIdentityToStorage(_account, _identity, _country);
        emit IdentityRegistered(_account, _identity);
    }

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

    function updateIdentity(
        address _account,
        IIdentity _identity
    )
        external
        override
        onlyAgent
    {
        IIdentity oldIdentity = identity(_account);
        identityRegistryStorage_.modifyStoredIdentity(_account, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    function updateCountry(
        address _account, 
        uint16 _country
    )
        external
        override
        onlyAgent
    {
        identityRegistryStorage_.modifyStoredHolderCountry(_account, _country);
        emit CountryUpdated(_account, _country);
    }

    function deleteIdentity(
        address _account
    )
        external
        override
        onlyAgent
    {
        identityRegistryStorage_.removeIdentityFromStorage(_account);
        emit IdentityRemoved(_account, identity(_account));
    }

    function isVerified(address _account) external view override returns (bool) {
        if (address(identity(_account)) == address(0)) {
            return false;
        }
        uint256[] memory requiredClaimTopics = complianceClaimsRequired_.getClaimTopics();
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

                try IClaimValidator(issuer).isClaimValid(identity(_account), requiredClaimTopics[claimTopic], sig,
                data) returns(bool _validity){
                    if (
                        _validity
                        && claimVerifiersRegistry_.hasClaimTopic(issuer, requiredClaimTopics[claimTopic])
                        && claimVerifiersRegistry_.isVerifier(issuer)
                    ) {
                        j = claimIds.length;
                    }
                    if (!claimVerifiersRegistry_.isVerifier(issuer) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!claimVerifiersRegistry_.hasClaimTopic(issuer, requiredClaimTopics[claimTopic]) && j == (claimIds.length - 1)) {
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

    function setIdentityRegistryStorage(address _identityRegistryStorage) external override onlyOwner {
        identityRegistryStorage_ = IIdentityRegistryStorage(_identityRegistryStorage);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    function setComplianceClaimsRequired(address _complianceClaimsRequired) external override onlyOwner {
        complianceClaimsRequired_ = IComplianceClaimsRequired(_complianceClaimsRequired);
        emit ComplianceClaimsRequiredSet(_complianceClaimsRequired);
    }

    function setClaimVerifiersRegistry(address _claimVerifiersRegistry) external override onlyOwner {
        claimVerifiersRegistry_ = IClaimVerifiersRegistry(_claimVerifiersRegistry);
        emit ClaimVerifiersRegistrySet(_claimVerifiersRegistry);
    }

    function contains(address _account) external view override returns (bool) {
        if (address(identity(_account)) == address(0)) {
            return false;
        }
        return true;
    }

    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    function addAgentOnIdentityRegistryContract(address _agent) external override {
        addAgent(_agent);
    }

    function removeAgentOnIdentityRegistryContract(address _agent) external override {
        removeAgent(_agent);
    }
}
