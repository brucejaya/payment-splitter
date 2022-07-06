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
        address _userAddress
    ) external view override returns (IIdentity) {
        return identities[_userAddress].holderContract;
    }

    /**
     *  @dev See {IHolderRegistryStorage-storedInvestorCountry}.
     */
    function storedInvestorCountry(
        address _userAddress
    ) external view override returns (uint16) {
        return identities[_userAddress].investorCountry;
    }

    /**
     *  @dev See {IHolderRegistryStorage-addHolderToStorage}.
     */
    function addHolderToStorage(
        address _userAddress,
        bytes32 _identity,
        uint16 _country
    ) external override onlyOperator {
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        require(address(identities[_userAddress].holderContract) == address(0), 'holder contract already exists, please use update');
        identities[_userAddress].holderContract = _identity;
        identities[_userAddress].investorCountry = _country;
        emit HolderStored(_userAddress, _identity);
    }

    /**
     *  @dev See {IHolderRegistryStorage-modifyStoredHolder}.
     */
    function modifyStoredHolder(
        address _userAddress,
        bytes32 _identity
    ) external override onlyOperator {
        require(address(identities[_userAddress].holderContract) != address(0), 'this user has no holder registered');
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        IIdentity oldHolder = identities[_userAddress].holderContract;
        identities[_userAddress].holderContract = _identity;
        emit HolderModified(oldHolder, _identity);
    }

    /**
     *  @dev See {IHolderRegistryStorage-modifyStoredInvestorCountry}.
     */
    function modifyStoredInvestorCountry(
        address _userAddress,
        uint16 _country
    ) external override onlyOperator {
        require(address(identities[_userAddress].holderContract) != address(0), 'this user has no holder registered');
        identities[_userAddress].investorCountry = _country;
        emit CountryModified(_userAddress, _country);
    }

    /**
     *  @dev See {IHolderRegistryStorage-removeHolderFromStorage}.
     */
    function removeHolderFromStorage(
        address _userAddress
    ) external override onlyOperator {
        require(address(identities[_userAddress].holderContract) != address(0), 'you haven\'t registered an holder yet');
        delete identities[_userAddress];
        emit HolderUnstored(_userAddress, identities[_userAddress].holderContract);
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
