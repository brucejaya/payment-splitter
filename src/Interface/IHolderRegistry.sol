// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './ITrustedIssuersRegistry.sol';
import './IComplianceClaimsRequired.sol';
import './IIdentityRegistryStorage.sol';
import './IClaimVerifier.sol';
import './IIdentity.sol';

interface IIdentityRegistry {
    /**
     *  this event is emitted when the ComplianceClaimsRequired has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `ComplianceClaimsRequired` is the address of the Claim Topics Registry contract
     */
    event ComplianceClaimsRequiredSet(address indexed ComplianceClaimsRequired);

    /**
     *  this event is emitted when the IdentityRegistryStorage has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `identityStorage` is the address of the Holder Registry Storage contract
     */
    event IdentityStorageSet(address indexed identityStorage);

    /**
     *  this event is emitted when the ComplianceClaimsRequired has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `trustedIssuersRegistry` is the address of the Trusted Issuers Registry contract
     */
    event TrustedIssuersRegistrySet(address indexed trustedIssuersRegistry);

    /**
     *  this event is emitted when an Holder is registered into the Holder Registry.
     *  the event is emitted by the 'registerIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Holder smart contract (onchainID)
     */
    event IdentityRegistered(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Holder is removed from the Holder Registry.
     *  the event is emitted by the 'deleteIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Holder smart contract (onchainID)
     */
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Holder has been updated
     *  the event is emitted by the 'updateIdentity' function
     *  `oldIdentity` is the old Holder contract's address to update
     *  `newIdentity` is the new Holder contract's
     */
    event IdentityUpdated(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /**
     *  this event is emitted when an Holder's country has been updated
     *  the event is emitted by the 'updateCountry' function
     *  `investorAddress` is the address on which the country has been updated
     *  `country` is the numeric code (ISO 3166-1) of the new country
     */
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);

    /**
     *  @dev Register an identity contract corresponding to a user address.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _account The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the investor
     *  emits `IdentityRegistered` event
     */
    function registerIdentity(
        address _account,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev Removes an user from the identity registry.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _account The address of the user to be removed
     *  emits `IdentityRemoved` event
     */
    function deleteIdentity(address _account) external;

    /**
     *  @dev Replace the actual identityRegistryStorage contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _identityRegistryStorage The address of the new Holder Registry Storage
     *  emits `IdentityStorageSet` event
     */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external;

    /**
     *  @dev Replace the actual ComplianceClaimsRequired contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _ComplianceClaimsRequired The address of the new claim Topics Registry
     *  emits `ComplianceClaimsRequiredSet` event
     */
    function setComplianceClaimsRequired(address _ComplianceClaimsRequired) external;

    /**
     *  @dev Replace the actual trustedIssuersRegistry contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _trustedIssuersRegistry The address of the new Trusted Issuers Registry
     *  emits `TrustedIssuersRegistrySet` event
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _account The address of the user
     *  @param _country The new country of the user
     *  emits `CountryUpdated` event
     */
    function updateCountry(address _account, uint16 _country) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _account The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityUpdated` event
     */
    function updateIdentity(address _account, IIdentity _identity) external;

    /**
     *  @dev function allowing to register identities in batch
     *  This function can only be called by a wallet set as agent of the smart contract
     *  Requires that none of the users has an identity contract already registered.
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_accountes.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _accountes The addresses of the users
     *  @param _identities The addresses of the corresponding identity contracts
     *  @param _countries The countries of the corresponding investors
     *  emits _accountes.length `IdentityRegistered` events
     */
    function batchRegisterIdentity(
        address[] calldata _accountes,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external;

    /**
     *  @dev This functions checks whether a wallet has its Holder registered or not
     *  in the Holder Registry.
     *  @param _account The address of the user to be checked.
     *  @return 'True' if the address is contained in the Holder Registry, 'false' if not.
     */
    function contains(address _account) external view returns (bool);

    /**
     *  @dev This functions checks whether an identity contract
     *  corresponding to the provided user address has the required claims or not based
     *  on the data fetched from trusted issuers registry and from the claim topics registry
     *  @param _account The address of the user to be verified.
     *  @return 'True' if the address is verified, 'false' if not.
     */
    function isVerified(address _account) external view returns (bool);

    /**
     *  @dev Returns the onchainID of an investor.
     *  @param _account The wallet of the investor
     */
    function identity(address _account) external view returns (IIdentity);

    /**
     *  @dev Returns the country code of an investor.
     *  @param _account The wallet of the investor
     */
    function investorCountry(address _account) external view returns (uint16);

    /**
     *  @dev Returns the IdentityRegistryStorage linked to the current IdentityRegistry.
     */
    function identityStorage() external view returns (IIdentityRegistryStorage);

    /**
     *  @dev Returns the TrustedIssuersRegistry linked to the current IdentityRegistry.
     */
    function issuersRegistry() external view returns (ITrustedIssuersRegistry);

    /**
     *  @dev Returns the ComplianceClaimsRequired linked to the current IdentityRegistry.
     */
    function topicsRegistry() external view returns (IComplianceClaimsRequired);

    /**
     *  @notice Transfers the Ownership of the Holder Registry to a new Owner.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _newOwner The new owner of this contract.
     */
    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external;

    /**
     *  @notice Adds an address as _agent of the Holder Registry Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _agent The _agent's address to add.
     */
    function addAgentOnIdentityRegistryContract(address _agent) external;

    /**
     *  @notice Removes an address from being _agent of the Holder Registry Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _agent The _agent's address to remove.
     */
    function removeAgentOnIdentityRegistryContract(address _agent) external;
}
