// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../src/PaymentSplitterFactory.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "./utils/Utils.sol";

contract PaymentSplitterFactoryTest is Test {
    
    ERC20 public _token;

    PaymentSplitterFactory public _factory;
    
    Utils public _utils;

    address[] public _users;
    
    address payable internal admin;

    address payable internal alice;
    address payable internal bob;
    
    function setUp() public {
        // Set up contracts
        _factory = new PaymentSplitterFactory(); 
        _token = new ERC20("Test", "TT");
        _utils = new Utils();
        
        // Create testing users
        _users = _utils.createUsers(2);

        admin = payable(_users[0]);
        alice = payable(_users[1]);
        bob =   payable(_users[2]);
    }


    function testPaymentSplitterFactory() public {
        
        // Create address array of payees
        address[] memory payees = new address[](2);
        payees[0] = address(alice);
        payees[1] = address(bob);
        
        // Create uint256 array of shares with 1 share each
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 1;
        
        // Create new splitter
        address splitter = _factory.newSplitter(payees, shares);

        // Send ETH to payment splitter
        uint256 amount = 1000;
        payable(splitter).transfer(amount);

        // Release funds
        _factory.release(alice, splitter);
        _factory.release(bob, splitter);

        // Check balances
        assertEq(alice.balance, amount / 2);
        assertEq(bob.balance, amount / 2);

        // Send tokens to payment splitter
        _token.mint(splitter, amount);

        // Release tokens
        _factory.releaseToken(alice, splitter, address(_token));
        _factory.releaseToken(bob, splitter, address(_token));

        // Check _token balances
        assertEq(_token.balanceOf(alice), amount / 2);
        assertEq(_token.balanceOf(bob), amount / 2);
    }
    
}