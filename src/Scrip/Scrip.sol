// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import 'openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import '../../Interface/IEquity.sol';

contract Scrip is ERC20, ERC20, ERC1155Holder {
    
    // Contracts
    IEquity public _equity;

    // States
    uint256 public _id;
	string public _uri;

    // Constructor
    constructor(
        IEquity equity,
        uint256 id,
        string memory name,
        string memory symbol,
        string memory uri
    )
        ERC20(name, symbol)
    {
        _equity = equity;
        _id = id;
        _uri = uri;
    }

    // Functions
    function wrapTokens(
        address account,
        uint256 amount
    ) public {

        // Handle deposit of ERC1155 tokens
        _equity.safeTransferFrom(account, address(this), _id, amount, "" );

        _mint(account, amount);
    }

    function unWrapTokens(
        address account, 
        uint256 amount
    )
        public
    {
        // Require _equity can transfer
        
        // 
        if (msg.sender != account) {
            uint _allowance =  allowance(account, msg.sender);
            require(_allowance > amount, "ERC20: burn amount exceeds allowance");
            uint256 decreasedAllowance =  _allowance - amount; 
            _approve(account, msg.sender, decreasedAllowance);
        }

        // Burn the scrip
        _burn(account, amount);

        // Return _equity
        _equity.safeTransferFrom(address(this), account, _id, amount, "" );
    }

    function uri()
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _uri;
    }
}
