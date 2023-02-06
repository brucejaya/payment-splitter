// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import 'openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import '../../Interface/IEquity.sol';

contract Scrip is ERC20, ERC20, ERC1155Holder {

    ////////////////
    // CONTRACT
    ////////////////
    
    // @notice
    IEquity public _equity;

    ////////////////
    // STATE
    ////////////////

    // @notice
    uint256 public _id;

    // @notice
	string public _uri;

    ////////////////
    // CONSTRUCTOR
    ////////////////

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

    //////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////
    
    // @notice
    function wrapTokens(
        address account,
        uint256 amount
    ) public {

        // Handle deposit of ERC1155 tokens
        _equity.safeTransferFrom(account, address(this), _id, amount, "" );

        _mint(account, amount);
    }

    // @notice
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

    // @notice
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
