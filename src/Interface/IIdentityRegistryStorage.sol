// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import './IIdentity.sol';

interface IIdentityRegistryStorage {

    // TODO code comments
    event IdentityStored(address _account, IIdentity _identity);
    
    event IdentityModified(IIdentity _oldIdentity, IIdentity _identity);
    
    event CountryModified(address _account, uint16 _country);
    
    event IdentityUnstored(address _account, IIdentity _identity);
    
    event IdentityRegistryBound(address _identityRegistry);

    event IdentityRegistryUnbound(address _identityRegistry);

    event IdentityRegistryAdded(address indexed _holderRegistry);

    event ComplianceAdded(address indexed _compliance);

    event RecoverySuccess(address _lostWallet, address _newWallet, address _holderIdentity);

    event AddressFrozen(address indexed _account, bool indexed _isFrozen, address indexed _owner);

    event TokensFrozen(address indexed _account, uint256 _amount);

    event TokensUnfrozen(address indexed _account, uint256 _amount);

    event Paused(address _account, uint256 _id);

    event Unpaused(address _account, uint256 _id);

    function storedIdentity(address _account) external view override returns (IIdentity);

    function storedHolderCountry(address _account) external view override returns (uint16);

    function addIdentityToStorage(address _account, IIdentity _identity, uint16 _country) external;

    function removeIdentityFromStorage(address _account) external;

    function modifyStoredHolderCountry(address _account, uint16 _country) external;

    function modifyStoredIdentity(address _account, IIdentity _identity) external;

    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external;

    function bindIdentityRegistry(address _identityRegistry) external;

    function unbindIdentityRegistry(address _identityRegistry) external;

}