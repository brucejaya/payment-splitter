// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IOrganisationManaged {
    
    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addOperator was successfully called.
     */
    event OperatorAdded(bytes32 indexed keypurposekeyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeOperator was successfully called.
     */
    event OperatorRemoved(bytes32 indexed keypurposekeyType);

    /**
     * @dev Emitted when the list of required keys to perform an action was updated.
     *
     * Specification: MUST be triggered when changeOperatorsRequired was successfully called.
     */
    event OperatorsRequiredChanged(uint256 purpose, uint256 number);


}
