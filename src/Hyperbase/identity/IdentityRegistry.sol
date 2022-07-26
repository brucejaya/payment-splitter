// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/utils/Context.sol';

import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IIdentity.sol';

// TODO replace owner role with ownable or operatorApprovals?

contract IdentityRegistry is Context, IIdentityRegistry {

    ////////////////
    // STATES
    ////////////////

    // @dev mapping between a user address and the corresponding identity
    mapping(address => Identity) private identities;

   // @dev struct containing the identity contract and the country of the user
    struct Identity {
        IIdentity identityContract;
        uint16 identityCountry;
    }

    ////////////////
    // CONSTRUCTOR
    ////////////////
    
    // constructor(
    // ) {
    // }

    ////////////////////////////////////////////////////////////////
    //                       READ FUNCTIONS
    ////////////////////////////////////////////////////////////////

    // @dev returns the associated address of an identity account
    function identity(
        address _account
    )
        public
        view
        override
        returns (IIdentity)
    {
        return identities[_account].identityContract; 
    }

    function identityCountry(
        address _account
    )
        external
        view
        override
        returns (uint16)
    {
        return identities[_account].identityCountry; 
    }

    function contains(
        address _account
    )
        external
        view
        override
        returns (bool)
    {
        if (address(identity(_account)) == address(0)) {
            return false;
        }
        return true;
    }

    ////////////////////////////////////////////////////////////////
                            IDENTITY CONTROLS
    ////////////////////////////////////////////////////////////////

    function registerIdentity(
        address _account,
        IIdentity _identity,
        uint16 _country
    )
        public
        override
    {
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        require(address(identities[_account].identityContract) == address(0), 'identity contract already exists, please use update');
        identities[_account].identityContract = _identity;
        identities[_account].identityCountry = _country;
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

    // @dev updates the country associated with an identity account
    function updateIdentity(
        address _account,
        IIdentity _identity
    )
        external
        override
    {
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
        require(address(identities[_account].identityContract) != address(0), 'this user has no identity registered');
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        IIdentity oldIdentity = identities[_account].identityContract;
        identities[_account].identityContract = _identity;

        emit IdentityUpdated(oldIdentity, _identity);
    }

    // @dev updates the country associated with an identity account
    function updateCountry(
        address _account, 
        uint16 _country
    )
        external
        override
    {
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
        
        require(address(identities[_account].identityContract) != address(0), 'this user has no identity registered');
        identities[_account].identityCountry = _country;
        emit CountryUpdated(_account, _country);
    }
    
    // @dev removes an identity from the registry
    function deleteIdentity(
        address _account
    )
        external
        override
    {
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
        require(address(identities[_account].identityContract) != address(0), 'you haven\'t registered an identity yet');
        delete identities[_account];
        emit IdentityRemoved(_account, identity(_account));
    }

    ////////////////////////////////////////////////////////////////
                                FACTORY 
    ////////////////////////////////////////////////////////////////


    // TODO, factory



}
