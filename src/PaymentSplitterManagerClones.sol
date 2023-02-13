//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "./PaymentSplitterCloneable.sol";

contract PaymentSplitterManagerClones is Ownable {
        
    ////////////////
    // STATES
    ////////////////

    uint256 public tax = 1;

    mapping(address => address[]) private _paymentTokens;
    mapping(address => address[]) private _createdSplitters;
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
        PaymentSplitterCloneable implementation = new PaymentSplitterCloneable();
        address[] memory payees_ = new address[](1);
        payees_[0] = address(this);
        uint256[] memory shares_ = new uint256[](1);
        shares_[0] = 1;
        address paymentToken_ = 0x0000000000000000000000000000000000000000;
        implementation.initialize(payees_, shares_, paymentToken_);
        splitters.push(address(implementation));
        _createdSplitters[address(this)].push(address(implementation));
        _registeredSplitters[address(this)].push(address(implementation));
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

    // @notice Getter for the number of PaymentSplitters registered where `_target` has shares.
    function registeredCountOf(
        address _target
    )
        external
        view
        returns (uint)
    {
        return _registeredSplitters[_target].length;
    }

    // @notice Getter for the addresses of the PaymentSplitters registered where `_target` has shares.
    function registeredSplittersOf(
        address _target
    )
        external
        view
        returns (address[] memory)
    {
        return _registeredSplitters[_target];
    }

    // @notice Getter for the address of the PaymentSplitters created by `_target`.
    function createdSplittersOf(
        address _target
    )
        external
        view
        returns (address[] memory)
    {
        return _createdSplitters[_target];
    }

    // @notice Set the price of clones.
    function setTax(
        uint _tax
    )
        external
        onlyOwner
    {
        tax = _tax;
    }

    //////////////////////////////////////////////
    // SPLITTER FUNTIONS
    //////////////////////////////////////////////

    // @notice Spawn a new PaymentSplitter passing in `payees_` and `shares_` to its initializer, and records the splitter in memory.
    function newSplitter(
        address[] memory payees_, 
        uint256[] memory shares_,
        address paymentToken_
    )
        external
        payable
    {
        require(msg.value * 1e18 >= tax);
        address _newSplitter = Clones.clone(splitterImplementation());
        PaymentSplitterCloneable(payable(_newSplitter)).initialize(payees_, shares_, paymentToken_);
        splitters.push(_newSplitter);
        _createdSplitters[msg.sender].push(_newSplitter);
        _paymentTokens[_newSplitter].push(paymentToken_);
        for(uint i = 0; i < payees_.length; i++) {
            _registeredSplitters[payees_[i]].push(_newSplitter);
        }
    }

    // @notice Release funds associated with the address `_receiver`. `_ids` is an array of indexes into `_registeredSplitters`.
    function shakeIndex(
        address payable _receiver, 
        uint [] memory _ids
    )
        external
    {
        for(uint i = 0; i < _ids.length; i++) {
            PaymentSplitterCloneable(payable(_registeredSplitters[_receiver][_ids[i]])).release(_receiver);
        }
    }

    // @notice Release funds associated with the address `_receiver`. `_start` and `_end` are bounds on indexes in `_registeredSplitters`.
    function shakeRange(
        address payable _receiver,
        uint _start,
        uint _end
    )
        external
    {
        for(uint i = _start; i < _end; i++) {
            PaymentSplitterCloneable(payable(_registeredSplitters[_receiver][i])).release(_receiver);
        }
    }

    // @notice Release all funds associated with the address `_receiver`.
    function shakeAll(
        address payable _receiver
    )
        external
    {
        for(uint i = 0; i < _registeredSplitters[_receiver].length; i++){
            PaymentSplitterCloneable(payable(_registeredSplitters[_receiver][i])).release(_receiver);
        }
    }

    // @notice Admin function to collect tax.
    function release(
        address payable _receiver,
        uint _amount
    )
        external
        onlyOwner
    {
        Address.sendValue(_receiver, _amount);
    }

    // @notice Admin function to collect all tax.
    function withdrawAll(
        address payable withdrawTo
    )
        external
        onlyOwner
    {
        withdrawTo.transfer(address(this).balance);
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

        uint numPayees = psc.numPayees();
        uint256[] memory shares_ = new uint256[](numPayees);
        for (uint i = 0; i < numPayees; i++) {
            address p = psc.payee(i); 
            shares_[i] = psc.shares(p);
        }
        return shares_;
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
        uint numPayees = psc.numPayees();
        address[] memory payees_ = new address[](numPayees);
        for (uint i = 0; i < numPayees; i++) {
            payees_[i] = psc.payee(i);
        }
        return payees_;
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
        uint numPayees = psc.numPayees();
        uint256[] memory balances_ = new uint256[](numPayees);
        for (uint i = 0; i < numPayees; i++) {
            address p = psc.payee(i); 
            balances_[i] = psc.balanceOf(p);
        }
        return balances_;
    }

}