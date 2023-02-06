// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import 'openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import '../../Interface/IEquity.sol';

contract Scrip is ERC20, ERC20, ERC1155Holder { // context {

    ////////////////
    // CONTRACT
    ////////////////
    
    // @notice Equity contract for wrapped token
    IEquity public _equity;

    ////////////////
    // STATE
    ////////////////

    // @notice Equity token id in the equity contract
    uint256 public _id;

    // @notice Metatdata uri for legal contract 
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
    
    // @notice Deposit tokens and mint scrip
    function wrapTokens(
        address account,
        uint256 amount
    )
        public
    {
        // Handle deposit of ERC1155 tokens
        _equity.safeTransferFrom(account, address(this), _id, amount, "" );
        
        // Mint scrip
        _mint(account, amount);
    }

    // @notice Withdraw tokens and burn scrip
    function unWrapTokens(
        address account, 
        uint256 amount
    )
        public
    {
        // Require _equity can transfer
        require(_equity.preValidateTransfer(address(this), account, _id, amount, ""), "Token transfer invalid");
        
        // Handle unwrap if done by third party
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

}