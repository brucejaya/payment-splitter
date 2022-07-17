pragma solidity ^0.8.6;

interface IERC1271 {
	function isValidSignature(bytes32 _messageHash, bytes memory _signature) external view returns (bytes4 magicValue);
}