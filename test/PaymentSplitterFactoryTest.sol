// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../src/PaymentSplitterFactory.sol";

import "../src/mocks/IERC20Token.sol";
import "../src/mocks/ERC20Token.sol";

import "./utils/Utils.sol";

contract PaymentSplitterFactoryTest is Test {
    
    ERC20Token public _token;

    PaymentSplitterFactory public _factory;
    
    Utils public _utils;
    address[] public _users;
    address payable internal admin;
    address payable internal alice;
    address payable internal bob;

    uint256 _amount = 1000;

    function setUp() public {

        // Get utils
        _utils = new Utils();

        // Set up contracts
        _factory = new PaymentSplitterFactory(); 

        // Create token instance
        _token = new ERC20Token();

        // Create testing users
        _users = _utils.createUsers(3);

        admin = payable(_users[0]);
        alice = payable(_users[1]);
        bob =   payable(_users[2]);
    }

    // @notice Internal function to create new splitters
    function _createNewSplitter() internal returns (address) {

        // Create address array of payees
        address[] memory payees = new address[](2);
        payees[0] = address(alice);
        payees[1] = address(bob);

        // Create uint256 array of shares with 1 share each
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 1;

        // Transfer eth and create new payment splitter
        address splitter = _factory.newSplitter{value: _factory.getTax()}(payees, shares);

        return splitter;
    }

    // @notice Test create payment splitter
    function testNewSplitter() public {

        // Create new splitter
        address splitter = _createNewSplitter(); 
        
        // Check payment splitter is not 0x0 address
        assertTrue(splitter != address(0), "Payment splitter address is 0x0");
    }

    // @notice Transfer eth to splitter and test release all
    function testReleaseAll() public {
        
        // Create new splitter
        address splitter = _createNewSplitter(); 

        // Send _amount eth to splitter
        payable(splitter).transfer(_amount);
        
        // Check that splitter received eth
        assertTrue(address(splitter).balance == _amount, "Splitter did not receive eth");
        
        // Release all eth in factory
        _factory.releaseAll(splitter);

        // Check alice has (_amount / 2) eth
        assertTrue(address(alice).balance == (_amount / 2), "Alice does not have (_amount / 2) eth");

        // // Check bob has (_amount / 2) eth
        // assertTrue(address(bob).balance == (_amount / 2), "Bob does not have (_amount / 2) eth");

        // // Check splitter has 0 eth
        // assertTrue(address(splitter).balance == 0, "Splitter does not have 0 eth");

    }

    // @notice Transfer tokens to splitter and test release all
    // function testReleaseAllTokens() public {
        
    //     // Create new splitter
    //     address splitter = _createNewSplitter(); 

    //     // Mint _amount tokens to admin
    //     _token.mint(admin, _amount);
        
    //     // Approve _amount tokens to splitter
    //     _token.approve(splitter, _amount);
        
    //     // Deposit _amount tokens to splitter
    //     _token.transferFrom(admin, splitter, _amount);
        
    //     // Release all tokens in factory
    //     _factory.releaseAll(splitter);

    //     // Check alice has (_amount / 2) tokens
    //     assertTrue(_token.balanceOf(alice) == (_amount / 2), "Alice does not have (_amount / 2) tokens");
        
    //     // Check bob has (_amount / 2) tokens
    //     assertTrue(_token.balanceOf(bob) == (_amount / 2), "Bob does not have (_amount / 2) tokens");
        
    //     // Check splitter has 0 tokens
    //     assertTrue(_token.balanceOf(splitter) == 0, "Splitter does not have 0 tokens");
    // }
    
}