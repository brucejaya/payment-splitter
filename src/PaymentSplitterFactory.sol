// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/proxy/Clones.sol";

import "./PaymentSplitterCloneable.sol";

contract PaymentSplitterFactory is Ownable {
        
    ////////////////
    // STATES
    ////////////////

    uint256 public _tax = 1;

    // @notice Splitters created by target
    mapping(address => address[]) private _createdSplitters;

    // @notice Splitters where target is a payee
    mapping(address => address[]) private _registeredSplitters; 

    address[] public splitters;
        
    ////////////////
    // EVENTS
    ////////////////

    event PaymentSplitterCreated(address newSplitter);
    
    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor () {
        // Cloneable implementation
        PaymentSplitterCloneable implementation = new PaymentSplitterCloneable();
        
        // Payees
        address[] memory payees = new address[](1);
        payees[0] = address(this);

        // Shares
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1;

        // Init splitter
        implementation.initialize(payees, shares);

        // Push to all splitters 
        splitters.push(address(implementation));

        // Push to created splitters
        _createdSplitters[address(this)].push(address(implementation));

        // Push to registered splitters ??
        _registeredSplitters[address(this)].push(address(implementation));
    }

    //////////////////////////////////////////////
    // SPLITTER FUNTIONS
    //////////////////////////////////////////////

    // @notice Spawn a new PaymentSplitter passing in `payees` and `shares` to its initializer, and records the splitter in memory.
    function newSplitter(
        address[] memory payees, 
        uint256[] memory shares
    )
        external
        payable
    {
        // Require message value is equal to tax
        require(msg.value == _tax, "PaymentSplitterManagerClones: msg.value must be equal to tax");

        // Create new splitter
        address _newSplitter = Clones.clone(splitterImplementation());

        // Initialize new splitter
        PaymentSplitterCloneable(payable(_newSplitter)).initialize{value: msg.value}(payees, shares);

        // Push to all splitters 
        splitters.push(_newSplitter);

        // Push to created splitters
        _createdSplitters[msg.sender].push(_newSplitter);

        // Push to registered splitters
        for(uint i = 0; i < payees.length; i++) {
            _registeredSplitters[payees[i]].push(_newSplitter);
        }

        // Emit event
        emit PaymentSplitterCreated(_newSplitter);
    }

    // @notice Release funds associated with the address `receiver` from the splitter at `splitter`.
    function release(
        address payable receiver,
        address splitter
    )
        external
    {
        PaymentSplitterCloneable splitter = PaymentSplitterCloneable(payable(splitter));
        splitter.release(receiver);
    }

    // @notice Release all funds associated with the address `receiver`.
    function releaseAll(
        address payable receiver
    )
        external
    {
        // Iterate through registered splitters and release funds
        for(uint i = 0; i < _registeredSplitters[receiver].length; i++) {
            PaymentSplitterCloneable splitter = PaymentSplitterCloneable(payable(_registeredSplitters[receiver][i]));
            splitter.release(receiver);
        }
    }

    // @notice Release in range funds associated with the address `receiver`.
    function releaseInRange(
        address payable receiver,
        uint start,
        uint end
    )
        external
    {
        // Iterate through registered splitters and release funds
        for(uint i = start; i < end; i++) {
            PaymentSplitterCloneable splitter = PaymentSplitterCloneable(payable(_registeredSplitters[receiver][i]));
            splitter.release(receiver);
        }
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////
    
    // @notice Getter for the address of the PaymentSplitterCloneable implementation contract.
    function splitterImplementation()
        public
        view
        returns (address)
    {
        return splitters[0];
    }

    // @notice Getter for the number of PaymentSplitters registered where `target` has shares.
    function registeredCountOf(
        address target
    )
        external
        view
        returns (uint)
    {
        return _registeredSplitters[target].length;
    }

    // @notice Getter for the addresses of the PaymentSplitters registered where `target` has shares.
    function registeredSplittersOf(
        address target
    )
        external
        view
        returns (address[] memory)
    {
        return _registeredSplitters[target];
    }

    // @notice Getter for the address of the PaymentSplitters created by `target`.
    function createdSplittersOf(
        address target
    )
        external
        view
        returns (address[] memory)
    {
        return _createdSplitters[target];
    }

    // @notice Getter helper for the amount of shares held by an account.
    function sharesOfAccount(
        address splitter,
        address account
    )
        public
        view
        returns (uint256)
    {
        return PaymentSplitterCloneable(payable(splitter)).shares(account);
    }

    // @notice Getter helper for the shares distribution of the splitter at `splitter`.
    function shares(
        address splitter
    )
        public
        view
        returns (uint256[] memory)
    {
        PaymentSplitterCloneable psc = PaymentSplitterCloneable(payable(splitter));
        uint numPayees = psc.payeesCount();
        uint256[] memory shares = new uint256[](numPayees);
        for (uint i = 0; i < numPayees; i++) {
            shares[i] = psc.shares(psc.payee(i));
        }
        return shares;
    }

    // @notice Getter helper for the amount of shares held by an account.
    function totalShares(
        address splitter
    )
        public
        view
        returns (uint256)
    {
        return PaymentSplitterCloneable(payable(splitter)).totalShares();
    }

    // @notice Getter helper for the payee number `index` of the splitter `splitter`.
    function payee(
        address splitter,
        uint256 index
    )
        public
        view
        returns (address)
    {
        return PaymentSplitterCloneable(payable(splitter)).payee(index);
    }

    // @notice Getter helper for the payees of the splitter at `splitter`.
    function payees(
        address splitter
    )
        public
        view
        returns (address[] memory)
    {
        PaymentSplitterCloneable psc = PaymentSplitterCloneable(payable(splitter));
        uint numPayees = psc.payeesCount();
        address[] memory payees = new address[](numPayees);
        for (uint i = 0; i < numPayees; i++) {
            payees[i] = psc.payee(i);
        }
        return payees;
    }

    // @notice Getter helper for the current releaseable funds associated with a specific payee at at `splitter`.
    function balanceOf(
        address splitter,
        address account
    )
        public
        view
        returns (uint256)
    {
        return PaymentSplitterCloneable(payable(splitter)).balanceOf(account);
    }

    // @notice Getter helper for the current releaseable funds associated with each payee in the  splitter at `splitter`.
    function balances(
        address splitter
    )
        public
        view
        returns (uint256[] memory)
    {
        PaymentSplitterCloneable psc = PaymentSplitterCloneable(payable(splitter));
        uint numPayees = psc.payeesCount();
        uint256[] memory balances_ = new uint256[](numPayees);
        for (uint i = 0; i < numPayees; i++) {
            address p = psc.payee(i); 
            balances_[i] = psc.balanceOf(p);
        }
        return balances_;
    }

    //////////////////////////////////////////////
    // OWNER FUNTIONS
    //////////////////////////////////////////////

    // @notice Set the price of creating a clone
    function setTax(
        uint tax
    )
        external
        onlyOwner
    {
        _tax = tax;
    }

    // @notice Withdraw ether from the contract
    function withdraw(
        uint _amount
    )
        external
        onlyOwner
    {
        require(address(this).balance >= _amount);
        payable(msg.sender).transfer(_amount);
    }

    // @notice Withdraw all ether from the contract
    function withdrawAll()
        external
        onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }

}