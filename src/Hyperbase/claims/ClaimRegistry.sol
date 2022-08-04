// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

contract ClaimRegistry {

    mapping(address => mapping(address => mapping(bytes32 => bytes32))) public registry;

    event ClaimSet(address indexed subject, address indexed issuer, bytes32 indexed key, bytes32 value, uint updatedAt);

    event ClaimRemoved(address indexed issuer, address indexed subject, bytes32 indexed key, uint removedAt);

    function setClaim(
		address subject, 
		bytes32 key, 
		bytes32 value
	)
		public 
	{
        registry[msg.sender][subject][key] = value;
        emit ClaimSet(msg.sender, subject, key, value, now);
    }

    function setSelfClaim(
		bytes32 key,
		bytes32 value
	)
		public
	{
        setClaim(msg.sender, key, value);
    }

    function getClaim(
		address issuer, 
		address subject, 
		bytes32 key
	)
		public 
		view returns(bytes32) 
	{
        return registry[issuer][subject][key];
    }

    function removeClaim(
		address issuer,
		address subject, 
		bytes32 key
	)
		public
	{
        require(msg.sender == issuer);
        delete registry[issuer][subject][key];
        emit ClaimRemoved(msg.sender, subject, key, now);
    }

}