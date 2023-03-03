// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/proxy/Clones.sol";

import "./PaymentSplitterCloneable.sol";

contract PaymentSplitterFactory is Ownable {
        
    ////////////////
    // STATES
    ////////////////

    uint256 public _tax = 1 ether;

    PaymentSplitterCloneable[] private _splitters;

    // @notice Mapping from address to splitter index
    mapping(address => uint256) private _splittersByAddress;

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
        PaymentSplitterCloneable splitter = new PaymentSplitterCloneable();

        address[] memory payees_ = new address[](1);
        payees_[0] = address(this);

        uint256[] memory shares_ = new uint256[](1);
        shares_[0] = 1;
        
        splitter.initialize(payees_, shares_);
        
        _splitters.push(splitter);

        _splittersByAddress[address(splitter)] = _splitters.length - 1;
        
        _createdSplittersOf[address(this)].push(address(splitter));

        _registeredSplittersOf[address(this)].push(address(splitter));
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
        require(payees.length == shares.length, "PaymentSplitterFactory: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitterFactory: no payees");
        require(msg.value >= _tax, "PaymentSplitterFactory: msg.value must be equal to tax");

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
        // Create splitter
        PaymentSplitterCloneable splitter = new PaymentSplitterCloneable();

        // Initialize splitter
        splitter.initialize(payees, shares);

        // Record splitter
        _splitters.push(splitter);

        // Record splitter in mapping
        _splittersByAddress[address(splitter)] = _splitters.length - 1;
        
        // Record splitter as created by sender
        _createdSplittersOf[msg.sender].push(address(splitter));

        // Record splitter as registered to all payees
        for(uint i = 0; i < payees.length; i++) {
            _registeredSplittersOf[payees[i]].push(address(splitter));
        }

        return address(splitter);
    }

    // @notice Release all eth in splitter to all recievers.
    function releaseAll(
        address splitter
    )
        external
    {
        address[] memory payees = _splitters[_splittersByAddress[splitter]].getPayees();

        // Sanity checks
        require(payees.length > 0, "PaymentSplitterFactory: no payees");
        
        // For all the payees of the splitter
        for(uint i = 0; i < payees.length; i++) {
            
            // Release their funds
            _splitters[_splittersByAddress[splitter]].release(payees[i]);
            
        }
    }

    // @notice Release all tokens in splitter to all recievers
    function releaseAllTokens(
        address token,
        address splitter
    )
        external
    {
        address[] memory payees = _splitters[_splittersByAddress[splitter]].getPayees();

        // Sanity checks
        require(payees.length > 0, "PaymentSplitterFactory: no payees");
        
        // For all the payees of the splitter
        for(uint i = 0; i < payees.length; i++) {
            
            // Release their eth
            _splitters[_splittersByAddress[splitter]].releaseTokens(token, payees[i]);
            
        }
    }

    // @notice Release eth associated with the address `receiver` from the splitter at `splitter`.
    function release(
        address receiver,
        address splitter
    )
        external
    {
        _splitters[_splittersByAddress[splitter]].release(receiver);
    }

    // @notice Release tokens associated with the address `receiver` from the splitter at `splitter`.
    function releaseTokens(
        address token,
        address receiver,
        address splitter
    )
        external
    {
        _splitters[_splittersByAddress[splitter]].releaseTokens(token, receiver);
    }

    // @notice Release funds from all splitters of receiver
    function releaseAllSplitters(
        address receiver
    )
        external
    {
        // Iterate through registered splitters of receiver and release eth
        for(uint i = 0; i < _registeredSplittersOf[receiver].length; i++) {
            _splitters[_splittersByAddress[_registeredSplittersOf[receiver][i]]].release(receiver);
        }
    }

    // @notice Release tokens from all splitters of receiver 
    function releaseAllSplittersTokens(
        address token,
        address receiver
    )
        external
    {
        // Iterate through registered splitters of receiver and release eth
        for(uint i = 0; i < _registeredSplittersOf[receiver].length; i++) {
            _splitters[_splittersByAddress[_registeredSplittersOf[receiver][i]]].releaseTokens(token, receiver);
        }
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////
    
    // @notice Getter function for payees of splitter
    function getPayees(
        address splitter
    )
        external
        returns (address[] memory)
    {
        address[] memory payees = _splitters[_splittersByAddress[splitter]].getPayees();

        return payees;
    }
    
    // @notice Getter helper for the shares distribution of the splitter at `splitter`.
    function getShares(
        address splitter
    )
        public
        view
        returns (uint256[] memory)
    {
        PaymentSplitterCloneable splitterInstance = _splitters[_splittersByAddress[splitter]];
        uint256[] memory shares = new uint256[](splitterInstance.payeesLength());
        for (uint i = 0; i < splitterInstance.payeesLength(); i++) {
            shares[i] = splitterInstance.shares(splitterInstance.payeeIndex(i));
        }
        return shares;
    }
    
    // @notice Getter function for current tax price.
    function getTax()
        external
        view
        returns (uint256)
    {
        return _tax;
    }
    
    // @notice Getter for the address of the PaymentSplitterCloneable implementation contract.
    function getSplitterImplementation()
        public
        view
        returns (address)
    {
        return _createdSplittersOf[address(this)][0];
    }

    // @notice Getter for the number of PaymentSplitters registered where `target` has shares.
    function getRegisteredCountOf(
        address target
    )
        external
        view
        returns (uint256)
    {
        return _registeredSplittersOf[target].length;
    }

    // @notice Getter for the addresses of the PaymentSplitters registered where `target` has shares.
    function getRegisteredSplittersOf(
        address target
    )
        external
        view
        returns (address[] memory)
    {
        return _registeredSplittersOf[target];
    }

    // @notice Getter for the address of the PaymentSplitters created by `target`.
    function getCreatedSplittersOf(
        address target
    )
        external
        view
        returns (address[] memory)
    {
        return _createdSplittersOf[target];
    }

    // @notice Getter helper for the amount of shares held by an account.
    function getSharesOfAccount(
        address splitter,
        address account
    )
        public
        view
        returns (uint256)
    {
        return _splitters[_splittersByAddress[splitter]].shares(account);
    }

    // @notice Getter helper for the amount of shares held by an account.
    function getTotalShares(
        address splitter
    )
        public
        view
        returns (uint256)
    {
        return _splitters[_splittersByAddress[splitter]].totalShares();
    }

    // @notice Getter helper for the payee number `index` of the splitter `splitter`.
    function getPayeeIndex(
        address splitter,
        uint256 index
    )
        public
        view
        returns (address)
    {
        return _splitters[_splittersByAddress[splitter]].payeeIndex(index);
    }

    // @notice Getter helper for the current releaseable eth associated with a specific payee at at `splitter`.
    function getBalanceOf(
        address splitter,
        address account
    )
        public
        view
        returns (uint256)
    {
        return _splitters[_splittersByAddress[splitter]].balanceOf(account);
    }

    // @notice Getter helper for the current releaseable tokens associated with a specific payee at at `splitter`.
    function getBalanceOfTokens(
        address splitter,
        address token,
        address account
    )
        public
        view
        returns (uint256)
    {
        return _splitters[_splittersByAddress[splitter]].balanceOfTokens(token, account);
    }

    // @notice Getter helper for the current releaseable eth associated with each payee in the  splitter at `splitter`.
    function getBalances(
        address splitter
    )
        public
        view
        returns (uint256[] memory)
    {
        PaymentSplitterCloneable splitterInstance = _splitters[_splittersByAddress[splitter]];
        uint256[] memory balances = new uint256[](splitterInstance.payeesLength());
        for (uint i = 0; i < splitterInstance.payeesLength(); i++) {
            balances[i] = splitterInstance.balanceOf(splitterInstance.payeeIndex(i));
        }
        return balances;
    }

    // @notice Getter helper for the current releaseable tokens associated with each payee in the  splitter at `splitter`.
    function getBalancesTokens(
        address splitter,
        address token
    )
        public
        view
        returns (uint256[] memory)
    {
        PaymentSplitterCloneable splitterInstance = _splitters[_splittersByAddress[splitter]];
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