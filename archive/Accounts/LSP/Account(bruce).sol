
/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.6;

// Y manages key management

contract Y is X {

	// *** CONSTANTS *** //

	// >> ERC725X OPERATIONS TYPES
	uint256 constant OPERATION_CALL = 0;
	uint256 constant OPERATION_CREATE = 1;
	uint256 constant OPERATION_CREATE2 = 2;
	uint256 constant OPERATION_STATICCALL = 3;
	uint256 constant OPERATION_DELEGATECALL = 4;

	// *** SC based accounts? *** //


    struct Key {
        bytes32 key;		// TOOD., Why is this 32bytes ?
        bytes value; 	// e.g., MANAGEMENT_KEY = 1, ACTION_KEY = 2, etc.
    }

	mapping( internal store;)	 // mapping of mapping indentities to keys 
	
	mapping(bytes32 => mapping(bytes32 => bytes)) public delegates;



    /* Public functions */
    /**
     * @inheritdoc IERC725Y
     */
    function getData(bytes32 key) public view virtual override returns (bytes memory value) {
        value = _getData(key);
    }

    /**
     * @inheritdoc IERC725Y
     */
    function setData(bytes32 key, bytes memory value) public virtual override onlyOwner {
        _setData(key, value);
    }

}