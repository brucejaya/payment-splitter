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
    
    address internal alice;
    address internal bob;
    
    function setUp() public {
        // Set up contracts
        _factory = new PaymentSplitterFactory(); 
        _token = new ERC20("Test", "TT");
        _utils = new Utils();
        
        // Create testing users
        _users = _utils.createUsers(2);
        alice = _users[0];
        bob = _users[1];
    }

    function testPaymentSplitterFactory() public {
        
        uint256[] memory shares = [1,1];
        address[] memory payees = [address(alice), address(bob)];
        
        address splitter = _factory.newSplitter(shares, payees);

        // Send ETH to payment splitter
        uint256 amount = 1000;
        alice.send(splitter, amount);

        // Release funds
        _factory.release(address(alice), splitter);
        _factory.release(address(bob), splitter);

        // Check balances
        assertEq(alice.balance(), amount / 2);
        assertEq(bob.balance(), amount / 2);

        // Send tokens to payment splitter
        _token.transfer(splitter, amount);

        // Release tokens
        _factory.releaseToken(address(alice), splitter, address(_token));
        _factory.releaseToken(address(bob), splitter, address(_token));

        // Check _token balances
        assertEq(_token.balanceOf(address(alice)), amount / 2);
        assertEq(_token.balanceOf(address(bob)), amount / 2);
    }
    
}