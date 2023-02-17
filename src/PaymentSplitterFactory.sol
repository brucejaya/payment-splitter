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

    // @notice Mapping from address to splitter interface
    mapping(address => PaymentSplitterCloneable) private _splitters;

    // @notice Mapping from target address to index of splitters created by the target
    mapping(address => address[]) private _createdSplittersOf;

    // @notice Mapping from target address to index of splitters where target is a payee
    mapping(address => address[]) private _registeredSplittersOf; 

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
        
        implementation.initialize(payees_, shares_);
        
        _splitters[address(implementation)] = implementation;
        
        _createdSplitters[address(this)].push(address(implementation));

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
        returns (address)
    {
        // Sanity checks
        require(payees.length == shares.length, "PaymentSplitterManagerClones: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitterManagerClones: no payees");
        require(msg.value == _tax, "PaymentSplitterManagerClones: msg.value must be equal to tax");

        // Create splitter
        address splitter = _createSplitter(payees, shares);

        // Emit event
        emit PaymentSplitterCreated(splitter);
        
        return address(splitter);
    }

    // @notice Internal function to create splitter
    function _createSplitter(
        address[] memory payees, 
        uint256[] memory shares
    )
        internal
        returns (address)
    {
        address _newSplitterAddress = Clones.clone(splitterImplementation());

        PaymentSplitterCloneable(payable(_newSplitterAddress)).initialize(payees, shares);
        
        _splitters[_newSplitterAddress] = PaymentSplitterCloneable(payable(_newSplitterAddress));
        
        _createdSplittersOf[msg.sender].push(_newSplitterAddress);
        
        for(uint i = 0; i < payees.length; i++) {
            _registeredSplittersOf[payees[i]].push(_newSplitterAddress);
        }
        
        return address(_newSplitterAddress);
    }

    // @notice Release all funds in splitter to all recievers.
    function releaseAll(
        address splitter
    )
        external
    {
        // For all the payees of the splitter
        for(uint i = 0; i < _splitters[splitter].payeesLength(); i++) {
            
            // Release their funds
            _splitters[splitter].release(payable(_splitters[splitter].payees()[i]));
        }
    }

    // @notice Release all tokens in splitter to all recievers
    function releaseAllTokens(
        address token,
        address splitter
    )
        external
    {
        // For all the payees of the splitter
        for(uint i = 0; i < _splitters[splitter].payeesLength(); i++) {
            
            // Release their funds
            _splitters[splitter].releaseTokens(token, payable(_splitters[splitter].payees()[i]));
        }
    }

    // @notice Release funds associated with the address `receiver` from the splitter at `splitter`.
    function release(
        address payable receiver,
        address splitter
    )
        external
    {
        _splitters[splitter].release(receiver);
    }

    // @notice Release tokens associated with the address `receiver` from the splitter at `splitter`.
    function releaseTokens(
        address token,
        address receiver,
        address splitter
    )
        external
    {
        _splitters[splitter].releaseTokens(token, receiver);
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
            _splitters[_registeredSplittersOf[receiver][i]].release(receiver);
        }
    }

    // @notice Release in range tokens associated with the address `receiver`.
    function releaseInRangeTokens(
        address token,
        address receiver,
        uint start,
        uint end
    )
        external
    {
        // Iterate through registered splitters and release funds
        for(uint i = start; i < end; i++) {
            _splitters[_registeredSplittersOf[receiver][i]].releaseTokens(token, receiver);
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
        return _createdSplittersOf[address(this)][0];
    }

    // @notice Getter for the number of PaymentSplitters registered where `target` has shares.
    function registeredCountOf(
        address target
    )
        external
        view
        returns (uint)
    {
        return _registeredSplittersOf[target].length;
    }

    // @notice Getter for the addresses of the PaymentSplitters registered where `target` has shares.
    function registeredSplittersOf(
        address target
    )
        external
        view
        returns (address[] memory)
    {
        return _registeredSplittersOf[target];
    }

    // @notice Getter for the address of the PaymentSplitters created by `target`.
    function createdSplittersOf(
        address target
    )
        external
        view
        returns (address[] memory)
    {
        return _createdSplittersOf[target];
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
        return _splitters[splitter].shares(account);
    }

    // @notice Getter helper for the shares distribution of the splitter at `splitter`.
    function shares(
        address splitter
    )
        public
        view
        returns (uint256[] memory)
    {
        PaymentSplitterCloneable splitterInstance = _splitters[splitter];
        uint256[] memory shares = new uint256[](splitterInstance.payeesLength());
        for (uint i = 0; i < splitterInstance.payeesLength(); i++) {
            shares[i] = splitterInstance.shares(splitterInstance.payeeIndex(i));
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
        return _splitters[splitter].totalShares();
    }

    // @notice Getter helper for the payee number `index` of the splitter `splitter`.
    function payeeIndex(
        address splitter,
        uint256 index
    )
        public
        view
        returns (address)
    {
        return _splitters[splitter].payeeIndex(index);
    }

    // @notice Getter helper for the payees of the splitter at `splitter`.
    function payees(
        address splitter
    )
        public
        view
        returns (address[] memory)
    {
        return _splitters[splitter].payees();
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
        return _splitters[splitter].balanceOf(account);
    }

    // @notice Getter helper for the current releaseable tokens associated with a specific payee at at `splitter`.
    function balanceOfTokens(
        address splitter,
        address token,
        address account
    )
        public
        view
        returns (uint256)
    {
        return _splitters[splitter].balanceOfTokens(token, account);
    }

    // @notice Getter helper for the current releaseable funds associated with each payee in the  splitter at `splitter`.
    function balances(
        address splitter
    )
        public
        view
        returns (uint256[] memory)
    {
        PaymentSplitterCloneable splitterInstance = _splitters[splitter];
        uint256[] memory balances = new uint256[](splitterInstance.payeesLength());
        for (uint i = 0; i < splitterInstance.payeesLength(); i++) {
            balances[i] = splitterInstance.balanceOf(splitterInstance.payeeIndex(i));
        }
        return balances;
    }

    // @notice Getter helper for the current releaseable tokens associated with each payee in the  splitter at `splitter`.
    function balancesTokens(
        address splitter,
        address token
    )
        public
        view
        returns (uint256[] memory)
    {
        PaymentSplitterCloneable splitterInstance = _splitters[splitter];
        uint256[] memory balances = new uint256[](splitterInstance.payeesLength());
        for (uint i = 0; i < splitterInstance.payeesLength(); i++) {
            balances[i] = splitterInstance.balanceOfTokens(token, splitterInstance.payeeIndex(i));
        }
        return balances;
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