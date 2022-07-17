// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import './IIdentity.sol';
interface IIdentityRegistry {

    event ComplianceClaimsRequiredSet(address indexed claimTopicsRegistry);

    event IdentityStorageSet(address indexed identityStorage);

    event ClaimVerifiersRegistrySet(address indexed trustedVerifiersRegistry);

    event IdentityRegistered(address indexed holderAddress, IIdentity indexed identity);

    event IdentityRemoved(address indexed holderAddress, IIdentity indexed identity);

    event IdentityUpdated(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    event CountryUpdated(address indexed holderAddress, uint16 indexed country);

    function registerIdentity(address _account, IIdentity _identity, uint16 _country) external;

    function deleteIdentity(address _account) external;

    function setIdentityRegistryStorage(address _identityRegistryStorage) external;

    function setComplianceClaimsRequired(address _complianceClaimsRequired) external;

    function setClaimVerifiersRegistry(address _trustedVerifiersRegistry) external;

    function updateCountry(address _account, uint16 _country) external;

    function updateIdentity(address _account, IIdentity _identity) external;

    function batchRegisterIdentity(address[] calldata _accounts, IIdentity[] calldata _identities, uint16[] calldata _countries ) external;

    function contains(address _account) external view returns (bool);

    function isVerified(address _account) external view returns (bool);

    function identity(address _account) external view returns (IIdentity);

    function identityCountry(address _account) external view returns (uint16);

    function identityRegistryStorage() external view returns (IIdentityRegistryStorage);

    function claimVerifiersRegistry() external view returns (IClaimVerifiersRegistry);

    function complianceClaimsRequired() external view returns (IComplianceClaimsRequired);

    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external;

    function addAgentOnIdentityRegistryContract(address _agent) external;

    function removeAgentOnIdentityRegistryContract(address _agent) external;
    
}
