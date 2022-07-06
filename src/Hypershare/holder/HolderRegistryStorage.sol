// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '../../Interface/IIdentity.sol';
import '../../Interface/IHolderRegistryStorage.sol';

import '../roles/agent/AgentRole.sol';

contract HolderRegistryStorage is IHolderRegistryStorage, AgentRole {

    // @dev struct containing the holder contract and the country of the user
    struct Holder {
        bytes32 holderHolder;
        uint16 investorCountry;
    }

    // @dev mapping between a user address and the corresponding holder
    mapping(address => Holder) private identities;

    // @dev array of Holder Registries linked to this storage
    address[] private holderRegistries;

    /**
     *  @dev See {IHolderRegistryStorage-linkedHolderRegistries}.
     */
    function linkedHolderRegistries() external view override returns (address[] memory) {
        return holderRegistries;
    }

    /**
     *  @dev See {IHolderRegistryStorage-storedHolder}.
     */
    function storedHolder(
        address _account
    ) external view override returns (IIdentity) {
        return identities[_account].holderContract;
    }

    /**
     *  @dev See {IHolderRegistryStorage-storedInvestorCountry}.
     */
    function storedInvestorCountry(
        address _account
    ) external view override returns (uint16) {
        return identities[_account].investorCountry;
    }

    /**
     *  @dev See {IHolderRegistryStorage-addHolderToStorage}.
     */
    function addHolderToStorage(
        address _account,
        bytes32 _identity,
        uint16 _country
    ) external override onlyOperator {
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        require(address(identities[_account].holderContract) == address(0), 'holder contract already exists, please use update');
        identities[_account].holderContract = _identity;
        identities[_account].investorCountry = _country;
        emit HolderStored(_account, _identity);
    }

    /**
     *  @dev See {IHolderRegistryStorage-modifyStoredHolder}.
     */
    function modifyStoredHolder(
        address _account,
        bytes32 _identity
    ) external override onlyOperator {
        require(address(identities[_account].holderContract) != address(0), 'this user has no holder registered');
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        IIdentity oldHolder = identities[_account].holderContract;
        identities[_account].holderContract = _identity;
        emit HolderModified(oldHolder, _identity);
    }

    /**
     *  @dev See {IHolderRegistryStorage-modifyStoredInvestorCountry}.
     */
    function modifyStoredInvestorCountry(
        address _account,
        uint16 _country
    ) external override onlyOperator {
        require(address(identities[_account].holderContract) != address(0), 'this user has no holder registered');
        identities[_account].investorCountry = _country;
        emit CountryModified(_account, _country);
    }

    /**
     *  @dev See {IHolderRegistryStorage-removeHolderFromStorage}.
     */
    function removeHolderFromStorage(
        address _account
    ) external override onlyOperator {
        require(address(identities[_account].holderContract) != address(0), 'you haven\'t registered an holder yet');
        delete identities[_account];
        emit HolderUnstored(_account, identities[_account].holderContract);
    }

    /**
     *  @dev See {IHolderRegistryStorage-transferOwnershipOnHolderRegistryStorage}.
     */
    function transferOwnershipOnHolderRegistryStorage(
        address _newOwner
    ) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IHolderRegistryStorage-bindHolderRegistry}.
     */
    function bindHolderRegistry(
        address _holderRegistry
    ) external override {
        addAgent(_holderRegistry);
        holderRegistries.push(_holderRegistry);
        emit HolderRegistryBound(_holderRegistry);
    }

    /**
     *  @dev See {IHolderRegistryStorage-unbindHolderRegistry}.
     */
    function unbindHolderRegistry(
        address _holderRegistry
    ) external override {
        require(holderRegistries.length > 0, 'holder registry is not stored');
        uint256 length = holderRegistries.length;
        for (uint256 i = 0; i < length; i++) {
            if (holderRegistries[i] == _holderRegistry) {
                holderRegistries[i] = holderRegistries[length - 1];
                holderRegistries.pop();
                break;
            }
        }
        removeAgent(_holderRegistry);
        emit HolderRegistryUnbound(_holderRegistry);
    }
}
