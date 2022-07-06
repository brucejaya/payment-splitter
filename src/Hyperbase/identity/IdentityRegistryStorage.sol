// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '../../Role/agent/AgentRole.sol';

import '../../Interface/IIdentityRegistryStorage.sol';
import '../../Interface/IIdentity.sol';

contract IdentityRegistryStorage is IIdentityRegistryStorage, AgentRole {
    /// @dev struct containing the identity contract and the country of the user
    struct Identity {
        IIdentity identityContract;
        uint16 holderCountry;
    }

    /// @dev mapping between a user address and the corresponding identity
    mapping(address => Identity) private identities;

    /// @dev array of Identity Registries linked to this storage
    address[] private identityRegistries;

    /**
     *  @dev See {IIdentityRegistryStorage-linkedIdentityRegistries}.
     */
    function linkedIdentityRegistries() external view override returns (address[] memory) {
        return identityRegistries;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedIdentity}.
     */
    function storedIdentity(address _account) external view override returns (IIdentity) {
        return identities[_account].identityContract;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedHolderCountry}.
     */
    function storedHolderCountry(address _account) external view override returns (uint16) {
        return identities[_account].holderCountry;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-addIdentityToStorage}.
     */
    function addIdentityToStorage(
        address _account,
        IIdentity _identity,
        uint16 _country
    ) external override onlyAgent {
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        require(address(identities[_account].identityContract) == address(0), 'identity contract already exists, please use update');
        identities[_account].identityContract = _identity;
        identities[_account].holderCountry = _country;
        emit IdentityStored(_account, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredIdentity}.
     */
    function modifyStoredIdentity(address _account, IIdentity _identity) external override onlyAgent {
        require(address(identities[_account].identityContract) != address(0), 'this user has no identity registered');
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        IIdentity oldIdentity = identities[_account].identityContract;
        identities[_account].identityContract = _identity;
        emit IdentityModified(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredHolderCountry}.
     */
    function modifyStoredHolderCountry(address _account, uint16 _country) external override onlyAgent {
        require(address(identities[_account].identityContract) != address(0), 'this user has no identity registered');
        identities[_account].holderCountry = _country;
        emit CountryModified(_account, _country);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-removeIdentityFromStorage}.
     */
    function removeIdentityFromStorage(address _account) external override onlyAgent {
        require(address(identities[_account].identityContract) != address(0), 'you haven\'t registered an identity yet');
        delete identities[_account];
        emit IdentityUnstored(_account, identities[_account].identityContract);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-transferOwnershipOnIdentityRegistryStorage}.
     */
    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-bindIdentityRegistry}.
     */
    function bindIdentityRegistry(address _identityRegistry) external override {
        addAgent(_identityRegistry);
        identityRegistries.push(_identityRegistry);
        emit IdentityRegistryBound(_identityRegistry);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-unbindIdentityRegistry}.
     */
    function unbindIdentityRegistry(address _identityRegistry) external override {
        require(identityRegistries.length > 0, 'identity registry is not stored');
        uint256 length = identityRegistries.length;
        for (uint256 i = 0; i < length; i++) {
            if (identityRegistries[i] == _identityRegistry) {
                identityRegistries[i] = identityRegistries[length - 1];
                identityRegistries.pop();
                break;
            }
        }
        removeAgent(_identityRegistry);
        emit IdentityRegistryUnbound(_identityRegistry);
    }
}
