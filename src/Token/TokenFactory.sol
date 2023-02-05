// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;


// This deploys the tokens and records their location

import "./Token.sol";

contract TokenFactory {

    // Contracts

    Token private token;

    // States

    address[] public tokens;

    // Events

    event Created(address indexed token, address indexed _creator);

    // Functions
    
    function createToken(
        // Args
    )
        public
    {
        token = new Token();
        Tokens.push(address(token));
        emit Created(address(token), _creator);
    }

    function getTokenCount()
        public
        view
        returns (uint256 TokenCount)
    {
        return Tokens.length;
    }

    // 
}