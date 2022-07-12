// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './IIdentity.sol';

interface IIdentityRegistryStorage {

    // TODO code comments
    event IdentityStored(address _account, IIdentity _identity);
    event IdentityModified(IIdentity _oldIdentity, IIdentity _identity);
    event CountryModified(address _account, uint16 _country);
    event IdentityUnstored(address _account, IIdentity _identity);
    event IdentityRegistryBound(address _identityRegistry);
    event IdentityRegistryUnbound(address _identityRegistry);


    /**
     *  this event is emitted when the HolderRegistry has been set for the token
     *  the event is emitted by the token constructor and by the setHolderRegistry function
     *  `_holderRegistry` is the address of the Identity Registry of the token
     */
    event IdentityRegistryAdded(address indexed _holderRegistry);

    /**
     *  this event is emitted when the Compliance has been set for the token
     *  the event is emitted by the token constructor and by the setCompliance function
     *  `_compliance` is the address of the Compliance contract of the token
     */
    event ComplianceAdded(address indexed _compliance);

    /**
     *  this event is emitted when an holder successfully recovers his tokens
     *  the event is emitted by the recoveryAddress function
     *  `_lostWallet` is the address of the wallet that the holder lost access to
     *  `_newWallet` is the address of the wallet that the holder provided for the recovery
     *  `_holderIdentity` is the address of the Identity of the holder who asked for a recovery
     */
    event RecoverySuccess(address _lostWallet, address _newWallet, address _holderIdentity);

    /**
     *  this event is emitted when the wallet of an holder is frozen or unfrozen
     *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
     *  `_account` is the wallet of the holder that is concerned by the freezing status
     *  `_isFrozen` is the freezing status of the wallet
     *  if `_isFrozen` equals `true` the wallet is frozen after emission of the event
     *  if `_isFrozen` equals `false` the wallet is unfrozen after emission of the event
     *  `_owner` is the address of the agent who called the function to freeze the wallet
     */
    event AddressFrozen(address indexed _account, bool indexed _isFrozen, address indexed _owner);

    /**
     *  this event is emitted when a certain amount of tokens is frozen on a wallet
     *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
     *  `_account` is the wallet of the holder that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are frozen
     */
    event TokensFrozen(address indexed _account, uint256 _amount);

    /**
     *  this event is emitted when a certain amount of tokens is unfrozen on a wallet
     *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
     *  `_account` is the wallet of the holder that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are unfrozen
     */
    event TokensUnfrozen(address indexed _account, uint256 _amount);

    /**
     *  this event is emitted when the token is paused
     *  the event is emitted by the pause function
     *  `_account` is the address of the wallet that called the pause function
     */
    event Paused(address _account, uint256 _id);

    /**
     *  this event is emitted when the token is unpaused
     *  the event is emitted by the unpause function
     *  `_account` is the address of the wallet that called the unpause function
     */
    event Unpaused(address _account, uint256 _id);

    // TODO comments
    function storedIdentity(address _account) external view override returns (IIdentity);

    // TODO comments 
    function storedHolderCountry(address _account) external view override returns (uint16);

    /**
     *  @dev adds an identity contract corresponding to a user address in the storage.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _account The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the holder
     *  emits `IdentityStored` event
     */
    function addIdentityToStorage(address _account, IIdentity _identity, uint16 _country) external;

    /**
     *  @dev Removes an user from the storage.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _account The address of the user to be removed
     *  emits `IdentityUnstored` event
     */
    function removeIdentityFromStorage(address _account) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _account The address of the user
     *  @param _country The new country of the user
     *  emits `CountryModified` event
     */
    function modifyStoredHolderCountry(address _account, uint16 _country) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _account The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityModified` event
     */
    function modifyStoredIdentity(address _account, IIdentity _identity) external;

    /**
     *  @notice Transfers the Ownership of the Identity Registry Storage to a new Owner.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _newOwner The new owner of this contract.
     */
    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external;

    /**
     *  @notice Adds an identity registry as agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function adds the identity registry to the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to add.
     */
    function bindIdentityRegistry(address _identityRegistry) external;

    /**
     *  @notice Removes an identity registry from being agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function removes the identity registry from the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to remove.
     */
    function unbindIdentityRegistry(address _identityRegistry) external;
}
