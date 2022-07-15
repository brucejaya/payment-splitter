// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '../Interface/IImplementationAuthority.sol';
import './access/Ownable.sol';

contract ImplementationAuthority is IImplementationAuthority, Ownable {

    event UpdatedImplementation(address newAddress);

    address implementation;

    constructor(address _implementation) {
        implementation = _implementation;
        emit UpdatedImplementation(_implementation);
    }

    function getImplementation() external override view returns(address) {
        return implementation;
    }

    function updateImplementation(address _newImplementation) public onlyOwner {
        implementation = _newImplementation;
        emit UpdatedImplementation(_newImplementation);
    }
}