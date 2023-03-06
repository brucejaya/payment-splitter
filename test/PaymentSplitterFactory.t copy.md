// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./utils/Utils.sol";

import "../src/PaymentSplitterFactory.sol";
import "../src/ERC20Token.sol";


// #TOOD Go through and make amount dynamic

contract PaymentSplitterFactoryTest is Test {
    
    ERC20Token public _token;

    PaymentSplitterFactory public _factory;
    
    Utils public _utils;
    
    uint256 _amount = 1000;
    uint256 _noPayees = 4;
    
    address[] public _payees;
    uint256[] public _shares;

    uint256 _tax;

    function setUp() public {

        // Get utils
        _utils = new Utils();

        // Set up contracts
        _factory = new PaymentSplitterFactory(); 

        // Get factory tax
        _tax = _factory.getTax();

        // Create token instance
        _token = new ERC20Token();

        // Create testing payees
        _payees = _utils.createUsers(_noPayees);

        // Generate a random number of shares for each user
        _shares = _utils.createShares(_payees);
    }

    // @notice Test send funds dirtly to payee account and get balance of splitter
    function testGetBalance() public {

        // Get user starting balance
        uint256 startingBalance = address(_payees[0]).balance;

        // Assert balance equals 100 ether
        assertTrue(startingBalance == 100 ether, "User does not have 100 ether");

        // Send _amount eth to payee
        payable(_payees[0]).transfer(_amount);

        // Check user balance
        assertTrue((startingBalance + _amount) == address(_payees[0]).balance, "Payee does has not recieved _amount eth");

    }

    // @notice Test create new splitter
    function testNewSplitter() internal returns (address) {
        
        // Transfer eth and create new payment splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares);

        assertTrue(splitter != address(0), "Splitter was not returned");
    }

    
    // @notice Transfer eth to splitter and test release all
    function testReleaseAll() public {
        
        // Get starting balances of all users
        uint256[] memory startingBalances = new uint256[](_noPayees);
        for (uint256 i = 0; i < _noPayees; i++) {
            startingBalances[i] = address(_payees[i]).balance;
        }
        
        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Send _amount eth to splitter
        payable(splitter).transfer(_amount);
        
        // Check that splitter received eth
        assertTrue(address(splitter).balance == _amount, "Splitter did not receive eth");
        
        // Release all eth in factory
        _factory.releaseAll(splitter);

        // Check splitter has 0 eth
        assertTrue(address(splitter).balance == 0, "Splitter does not have 0 eth");

        // Iterate through payees and assert eth balance is equal to their share
        for (uint256 i = 0; i < _noPayees; i++) {

            // Calculate payees share of profits based on their shares and total tax
            uint256 share = (_amount * _shares[i]) / 100;
            
            // Assert payee has recieved their share
            assertTrue((startingBalances[i] + share) == address(_payees[i]).balance, "Payee did not recieve their share of profits");
        }
    }

    // @notice Transfer tokens to splitter and test release all
    function testReleaseAllTokens() public {
        
        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Mint _amount tokens to _admin
        _token.mint(address(this), _amount);

        // Transfer tokens from this address to the splitter
        _token.transfer(splitter, _amount);

        // Check that splitter received tokens
        assertTrue(_token.balanceOf(splitter) == _amount, "Splitter did not receive tokens");
        
        // Release all tokens in factory
        _factory.releaseAllTokens(address(_token), splitter);
        
        // Check splitter has 0 tokens
        assertTrue(_token.balanceOf(splitter) == 0, "Splitter does not have 0 tokens");

        // Iterate through payees and assert token balance is equal to their share
        for (uint256 i = 0; i < _noPayees; i++) {
            
            // Calculate payees share of profits based on their shares and total tax
            uint256 share = (_amount * _shares[i]) / 100;
            
            // Assert payee has recieved their share
            assertTrue(_token.balanceOf(_payees[i]) == share, "Payee did not recieve their share of profits");
        }
    }

    // @notice Transfer eth to splitter and test release only to single payee
    function testRelease() public {
        
        // Get starting balance for _payees[0]
        uint256 startingBalance = address(_payees[0]).balance;
        
        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Send _amount eth to splitter
        payable(splitter).transfer(_amount);
        
        // Check that splitter received eth
        assertTrue(address(splitter).balance == _amount, "Splitter did not receive eth");
        
        // Release all eth in factory
        _factory.release(_payees[0], splitter);

        // Calculate payees share of profits based on their shares and total tax
        uint256 share = (_amount * _shares[0]) / 100;
        
        // Check splitter has released funds
        assertTrue(address(splitter).balance == (_amount - share), "Splitter has not distributed user share eth");

        // Assert payee has recieved their share
        assertTrue((startingBalance + share) == address(_payees[0]).balance, "Payee did not recieve their share of profits");

    }

    // @notice Transfer tokens to splitter and test release only to single payee
    function testReleaseTokens() public {
        
        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Mint _amount tokens to _admin
        _token.mint(address(this), _amount);

        // Transfer tokens from this address to the splitter
        _token.transfer(splitter, _amount);

        // Check that splitter received tokens
        assertTrue(_token.balanceOf(splitter) == _amount, "Splitter did not receive tokens");
        
        // Release all tokens in factory
        _factory.releaseTokens(address(_token), _payees[0], splitter);
        
        // Check splitter has released tokens
        assertTrue(_token.balanceOf(splitter) == (_amount - (_amount / _noPayees)), "Splitter has not distributed (_amount / _noPayees) tokens");

        // Check payee one has received tokens
        assertTrue(_token.balanceOf(_payees[0]) == (_amount / _noPayees), "Payee does has not recieved (_amount / _noPayees) tokens");
    }
        
    // @notice Release funds across all splitters associated with the address of payee
    function testReleaseAllSplitters() public {

        // Get starting balance for _payees[0]
        uint256 startingBalance = address(_payees[0]).balance;

        // Create splitter array
        uint256 noSplitters = 6;
        address[] memory splitters = new address[](noSplitters);

        // Create splitters in range 
        for (uint256 i = 0; i < noSplitters; i++) {

            // Create new splitter
            splitters[i] = _factory.newSplitter{value: _tax}(_payees, _shares); 
            
            // Transfer splitter amount to splitter
            payable(splitters[i]).transfer(_amount);
            
        }
        
        // Release all eth in factory
        _factory.releaseAllSplitters(_payees[0]);

        // Iterate through splitters and check they have released funds
        for (uint256 i = 0; i < noSplitters; i++) {
            assertTrue(address(splitters[i]).balance == (_amount - (_amount / _noPayees)), "Splitter has not distributed (_amount / _noPayees) tokens");
        }

        // Check that _payees[0] has received appropriate amount of funds
        assertTrue((startingBalance + ((_amount / _noPayees) * noSplitters)) == address(_payees[0]).balance, "Payee does has not recieved ((_amount / _noPayees) * noSplitters) eth");

    }

    // @notice Release tokens across all splitters associated with the address of payee
    function testReleaseAllSplittersTokens() public {

        // Create splitter array
        uint256 noSplitters = 6;
        address[] memory splitters = new address[](noSplitters);

        // Create splitters in range 
        for (uint256 i = 0; i < noSplitters; i++) {

            // Create new splitter
            address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

            // Mint _amount tokens to _admin
            _token.mint(address(this), _amount);

            // Transfer tokens from this address to the splitter
            _token.transfer(splitter, _amount);

            // Add splitter to array
            splitters[i] = splitter;
        }
        
        // Release all tokens in factory
        _factory.releaseAllSplittersTokens(address(_token), _payees[0]);

        // Iterate through splitters and check they have released funds
        for (uint256 i = 0; i < noSplitters; i++) {
            
            assertTrue(_token.balanceOf(splitters[i]) == (_amount - (_amount / _noPayees)), "Splitter has not distributed (_amount / _noPayees) tokens");

        }

        // Check that user has tokens equal to their share of tokens 
        assertTrue(_token.balanceOf(_payees[0]) == ((_amount / _noPayees) * noSplitters), "Incorrect user balance");
    }

    //////////////////////////////////////////////
    // GETTER FUNCTIONS
    //////////////////////////////////////////////

    function testGetPayees() public {
        
        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Get payees from splitter
        address[] memory returnedPayees = _factory.getPayees(splitter);

        // Check returned payees is equal to _payees
        for (uint256 i = 0; i < _noPayees; i++) {
            assertTrue(_payees[i] == returnedPayees[i], "Returned payees not equal to _payees");
        }
    }

    function testGetShares() public {
        
        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Get shares from splitter
        uint256[] memory returnedShares = _factory.getShares(splitter);

        // Check returned shares is equal to _shares
        for (uint256 i = 0; i < _noPayees; i++) {
            assertTrue(_shares[i] == returnedShares[i], "Returned shares not equal to _shares");
        }
    }

    function testGetRegisteredCountOf() public {
        
        // #TODO generate this dyanmically
        uint256 noSplitters = 3;
        
        // Deploy a number of splitters from this address
        for (uint256 i = 0; i < noSplitters; i++) {

            // Create new splitter
            _factory.newSplitter{value: _tax}(_payees, _shares); 
        }

        // Get registered count of splitter
        uint256 registeredCountOf = _factory.getRegisteredCountOf(_payees[0]);

        // Check registered count is greater than zero
        assertTrue(registeredCountOf > 0, "Registered count of splitter is not greater than zero");

        // Check registered count of splitter is equal to noSplitters
        assertTrue(registeredCountOf == noSplitters, "Registered count of splitter is not equal to noSplitters");
        
    }

    function testGetRegisteredSplittersOf() public {

        // #TODO generate this dynamically
        uint256 noSplitters = 3;

        // Create empty address array of size noSplitters
        address[] memory splitters = new address[](noSplitters);
        
        // Deploy a number of splitters from this address
        for (uint256 i = 0; i < noSplitters; i++) {

            // Create new splitter and add splitter to array
            splitters[i] = _factory.newSplitter{value: _tax}(_payees, _shares); 
        }

        // Get registered splitters of splitter
        address[] memory registeredSplittersOf = _factory.getRegisteredSplittersOf(_payees[0]);

        // Check arrays are of equal size
        assertTrue(registeredSplittersOf.length == splitters.length, "Registered splitters of splitter is not equal to splitters");

        // Check registered splitters of splitter is equal to splitters
        for (uint256 i = 0; i < noSplitters; i++) {
            assertTrue(registeredSplittersOf[i] == splitters[i], "Registered splitters of splitter is not equal to splitters");
        }
    }

    function testGetCreatedSplittersOf() public {

        // #TODO generate this dynamically
        uint256 noSplitters = 3;

        // Create empty address array of size noSplitters
        address[] memory splitters = new address[](noSplitters);
        
        // Deploy a number of splitters from this address
        for (uint256 i = 0; i < noSplitters; i++) {

            // Create new splitter and add splitter to array
            splitters[i] = _factory.newSplitter{value: _tax}(_payees, _shares); 
        }

        // Get created splitters of splitter
        address[] memory createdSplittersOf = _factory.getCreatedSplittersOf(address(this));

        // Check arrays are of equal size
        assertTrue(createdSplittersOf.length == splitters.length, "Created splitters of splitter is not equal to splitters");

        // Check created splitters of splitter is equal to splitters
        for (uint256 i = 0; i < noSplitters; i++) {
            assertTrue(createdSplittersOf[i] == splitters[i], "Created splitters of splitter is not equal to splitters");
        }
    }

    function testGetSharesOfAccount() public {

        // #TODO make this dynamic: (uint256(4)) ?
        uint256 noShares = 3;

        // Add to shares array 
        _shares[0] = noShares;

        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Get shares of account
        uint256 sharesOfAccount = _factory.getSharesOfAccount(splitter, _payees[0]);

        // Check shares of account is equal to noShares
        assertTrue(sharesOfAccount == noShares, "Shares of account is not equal to noShares");
    }

    function testGetTotalShares() public {

        // #TODO make this dynamic: (uint256(4)) ?
        // Iterate through shares adding to total
        uint256 totalShares;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }

        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Check total shares is equal to noShares
        assertTrue(totalShares == _factory.getTotalShares(splitter), "Total shares is not equal to noShares");
    }

    function testGetPayeeIndex() public {

        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Iterate through payees
        for (uint256 i = 0; i < _noPayees; i++) {

            // Get payee index
            address payee = _factory.getPayeeIndex(splitter, i);

            // Check payee index is equal to i
            assertTrue(payee == _payees[i], "Payee index is not the same as payee");
        }
    }

    function testGetBalanceOf() public {

        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Send funds to splitter
        payable(splitter).transfer(_amount);

        // Get balance of splitter
        uint256 balanceOf = _factory.getBalanceOf(splitter, _payees[0]);

        // Check balance of user is starting balance + share of funds
        assertTrue((_amount / _payees.length) == balanceOf, "Balance of splitter is not equal to zero");
    }

    function testGetBalanceOfTokens() public {

        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Mint _amount tokens to _admin
        _token.mint(address(this), _amount);

        // Send tokens to splitter
        _token.transfer(splitter, _amount);

        // Get balance of user
        uint256 balanceOf = _factory.getBalanceOfTokens(splitter, address(_token), _payees[0]);

        // Check balance of user is equal to their shares
        assertTrue(balanceOf == (_amount / _payees.length), "Balance of splitter is not equal to zero");
    }
    
    function testGetBalances() public {

        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Send funds to splitter
        payable(splitter).transfer(_amount);

        // Get balance of splitter
        uint256[] memory balances = _factory.getBalances(splitter);

        // Iterate through balances checking for appropriate amount
        for (uint256 i = 0; i < balances.length; i++) {
            assertTrue(balances[i] == (_amount / _payees.length), "Balance of payee is not equal to share");
        }
    }

    function testGetBalancesTokens() public {

        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Mint _amount tokens to _admin
        _token.mint(address(this), _amount);

        // Send tokens to splitter
        _token.transfer(splitter, _amount);
        
        // Get balance of splitter
        uint256[] memory balances = _factory.getBalancesTokens(splitter, address(_token));
        
        // Iterate through balances checking for appropriate amount
        for (uint256 i = 0; i < balances.length; i++) {
            assertTrue(balances[i] == (_amount / _payees.length), "Balance of payee is not equal to share");            
        }
    }

    function testSetTax() public {

        // Create new splitter
        address splitter = _factory.newSplitter{value: _tax}(_payees, _shares); 

        // Set tax
        _factory.setTax(10 ether);

        // Get tax
        uint256 tax = _factory.getTax();

        // Check tax is equal to 10
        assertTrue(tax == 10 ether, "Tax is not equal to 10");
    }

    function withdraw() public {

        // Get starting balance for _payees[0]
        uint256 startingBalance = address(_payees[0]).balance;

        // For range create splitters
        uint256 noSplitters = 4;
        for (uint256 i = 0; i < noSplitters; i++) {

            // Create new splitter
            _factory.newSplitter{value: _tax}(_payees, _shares); 

        }

        // Withdraw funds from splitter
        _factory.withdraw(_payees[0]);

        // Check the balance of _payees[0] is equal to _tax * noSplitters
        assertTrue(address(_payees[0]).balance == (_tax * noSplitters), "Balance of splitter is not equal to zero");
    }

}