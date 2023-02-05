// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IAccounts.sol';

// TODO replace owner role with ownable or operatorApprovals?

contract Accounts is IAccounts {

    ////////////////
    // STATES
    ////////////////

   // @dev struct containing the identity contract and the country of the user
    struct Account {
        // address name; #TODO
        uint16 country;
    }

    // @dev mapping between a hased user address and the corresponding identity account
    mapping(address => Account) public accounts;

    ////////////////////////////////////////////////////////////////
    //                       IDENTITY CONTROLS
    ////////////////////////////////////////////////////////////////

    function registerAccount(
        address _account,
        IAccounts _identity,
        uint16 _country
    )
        public
        override
    {
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        require(address(accounts[_account].identityContract) == address(0), 'identity contract already exists, please use update');
        accounts[_account].identityContract = _identity;
        accounts[_account].country = _country;
        emit AccountsRegistered(_account, _identity);
    }

    function batchRegisterAccount(
        address[] calldata _accounts,
        IAccounts[] calldata _accounts,
        uint16[] calldata _countries
    )
        external
        override
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            registerAccount(_accounts[i], _accounts[i], _countries[i]);
        }
    }

    // @dev updates the country associated with an identity account
    function updateAccount(
        address _account,
        IAccounts _identity
    )
        external
        override
    {
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
        require(address(accounts[_account].identityContract) != address(0), 'this user has no identity registered');
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        IAccounts oldAccounts = accounts[_account].identityContract;
        accounts[_account].identityContract = _identity;

        emit AccountsUpdated(oldAccounts, _identity);
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
        
        require(address(accounts[_account].identityContract) != address(0), 'this user has no identity registered');
        accounts[_account].country = _country;
        emit CountryUpdated(_account, _country);
    }
    
    // @dev removes an identity from the registry
    function deleteAccount(
        address _account
    )
        external
        override
    {
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
        require(address(accounts[_account].identityContract) != address(0), 'you haven\'t registered an identity yet');
        delete accounts[_account];
        emit AccountsRemoved(_account, identity(_account));
    }

    

}
