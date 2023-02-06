// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IAccounts.sol';

// TODO replace owner role with ownable or operatorApprovals?

contract Accounts is IAccounts {

  	////////////////
    // STATE
    ////////////////

    // @notice Enumerated list of countries
	enum Country {
		Afghanistan,
		Albania,
		Algeria,
		Andorra,
		Angola,
		Antigua_and_Deps,
		Argentina,
		Armenia,
		Australia,
		Austria,
		Azerbaijan,
		Bahamas,
		Bahrain,
		Bangladesh,
		Barbados,
		Belarus,
		Belgium,
		Belize,
		Benin,
		Bhutan,
		Bolivia,
		Bosnia_Herzegovina,
		Botswana,
		Brazil,
		Brunei,
		Bulgaria,
		Burkina,
		Burundi,
		Cambodia,
		Cameroon,
		Canada,
		Cape_Verde,
		Central_African_Rep,
		Chad,
		Chile,
		China,
		Colombia,
		Comoros,
		Congo,
		Congo_Democratic_Rep,
		Costa_Rica,
		Croatia,
		Cuba,
		Cyprus,
		Czech_Republic,
		Denmark,
		Djibouti,
		Dominica,
		Dominican_Republic,
		East_Timor,
		Ecuador,
		Egypt,
		El_Salvador,
		Equatorial_Guinea,
		Eritrea,
		Estonia,
		Ethiopia,
		Fiji,
		Finland,
		France,
		Gabon,
		Gambia,
		Georgia,
		Germany,
		Ghana,
		Greece,
		Grenada,
		Guatemala,
		Guinea,
		Guinea_Bissau,
		Guyana,
		Haiti,
		Honduras,
		Hungary,
		Iceland,
		India,
		Indonesia,
		Iran,
		Iraq,
		Ireland,
		Israel,
		Italy,
		Ivory_Coast,
		Jamaica,
		Japan,
		Jordan,
		Kazakhstan,
		Kenya,
		Kiribati,
		Korea_North,
		Korea_South,
		Kosovo,
		Kuwait,
		Kyrgyzstan,
		Laos,
		Latvia,
		Lebanon,
		Lesotho,
		Liberia,
		Libya,
		Liechtenstein,
		Lithuania,
		Luxembourg,
		Macedonia,
		Madagascar,
		Malawi,
		Malaysia,
		Maldives,
		Mali,
		Malta,
		Marshall_Islands,
		Mauritania,
		Mauritius,
		Mexico,
		Micronesia,
		Moldova,
		Monaco,
		Mongolia,
		Montenegro,
		Morocco,
		Mozambique,
		Myanmar,
		Namibia,
		Nauru,
		Nepal,
		Netherlands,
		New_Zealand,
		Nicaragua,
		Niger,
		Nigeria,
		Norway,
		Oman,
		Pakistan,
		Palau,
		Panama,
		Papua_New_Guinea,
		Paraguay,
		Peru,
		Philippines,
		Poland,
		Portugal,
		Qatar,
		Romania,
		Russian_Federation,
		Rwanda,
		St_Kitts_and_Nevis,
		St_Lucia,
		Saint_Vincent_and_the_Grenadines,
		Samoa,
		San_Marino,
		Sao_Tome_and_Principe,
		Saudi_Arabia,
		Senegal,
		Serbia,
		Seychelles,
		Sierra_Leone,
		Singapore,
		Slovakia,
		Slovenia,
		Solomon_Islands,
		Somalia,
		South_Africa,
		South_Sudan,
		Spain,
		Sri_Lanka,
		Sudan,
		Suriname,
		Swaziland,
		Sweden,
		Switzerland,
		Syria,
		Taiwan,
		Tajikistan,
		Tanzania,
		Thailand,
		Togo,
		Tonga,
		Trinidad_and_Tobago,
		Tunisia,
		Turkey,
		Turkmenistan,
		Tuvalu,
		Uganda,
		Ukraine,
		United_Arab_Emirates,
		United_Kingdom,
		United_States,
		Uruguay,
		Uzbekistan,
		Vanuatu,
		Vatican_City,
		Venezuela,
		Vietnam,
		Yemen,
		Zambia,
		Zimbabwe
	}

    // @notice Account fields
    struct Account {
		bool exists;
        Country country;
    }

    // @notice Accounts
    mapping(address => Account) public _accounts;

    //////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////

    // @notice
    function registerAccount(
        address account,
        uint16 country
    )
        public
        override
    {
        // Sanity checks
		require(!_accounts[account].exists, "Account already exists");
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
        require(_account != address(0), "Owner cannot be zero address");
        
        // Update
		_accounts[account].exists = true;
        _accounts[account].identityContract = identity;
        _accounts[account].country = country;

        // Event
        emit AccountsRegistered(account, identity);
    }

    // @notice
    function batchRegisterAccount(
        address[] calldata accounts,
        uint16[] calldata countries
    )
        external
        override
    {
        // Sanity checks
        require(accounts.length == countries.length, "Length of countries and accounts must match");
        
        // Iterate through accounts and create accounts
        for (uint256 i = 0; i < accounts.length; i++) {
            registerAccount(account[i], accounts[i], countries[i]);
        }
    }

    // @notice updates the country associated with an identity account
    function updateAccount(
        address account
    )
        external
        override
    {
        // Sanity checks
        require(account == _msgSender(), "Only the owner of an identity can make changes to it");
        require(account != address(0), "Owner cannot be zero address");
        
        // Update
        _accounts[account].identityContract = identity;

        // Event
        emit AccountsUpdated(account, identity);
    }

    // @notice updates the country associated with an identity account
    function updateCountry(
        address account, 
        uint16 country
    )
        external
        override
    {
        // Sanity checks
        require(account == _msgSender(), "Only the owner of an identity can make changes to it");
        require(account != address(0), "Owner cannot be zero address");
        
        // Update 
        _accounts[account].country = country;

        // Event
        emit CountryUpdated(account, country);
    }
    
    // @notice removes an identity from the registry
    function deleteAccount(
        address account
    )
        external
        override

		// #TODO requirements

    {
        // Sanity checks
        require(account == _msgSender(), "Only the owner of an identity can make changes to it");

        // Delete
        delete _accounts[account];

        // Event
        emit AccountsRemoved(account, identity(account));
    }

}