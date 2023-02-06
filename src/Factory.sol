// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./Equity.sol";

contract Factory {

    ////////////////
    // CONTRACT
    ////////////////

    // @notice
    Token private token;

    ////////////////
    // STATES
    ////////////////

    // @notice
    address[] public tokens;

    ////////////////
    // EVENT
    ////////////////

    // @notice
    event Created(address indexed token, address indexed _creator);

    //////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////
    
    // @notice 
    function createToken(
        // Args
    )
        public
    {
        token = new Token();
        Tokens.push(address(token));
        emit Created(address(token), _creator);
    }

    // @notice 
    function getTokenCount()
        public
        view
        returns (uint256 TokenCount)
    {
        return Tokens.length;
    }

    // 
}