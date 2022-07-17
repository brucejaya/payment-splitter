pragma solidity ^0.8.6;

/**
 * @title EnsRegistry
 * @dev Extract of the interface for ENS Registry
 */
interface IENSRegistry {
	function setOwner(bytes32 node, address owner) public;
	function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
	function setResolver(bytes32 node, address resolver) public;
	function owner(bytes32 node) public view returns (address);
	function resolver(bytes32 node) public view returns (address);
}


/**
 * @title EnsResolver
 * @dev Extract of the interface for ENS Resolver
 */
interface IENSResolver {
	function setAddr(bytes32 node, address addr) public;
	function addr(bytes32 node) public view returns (address);
}
