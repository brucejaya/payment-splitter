// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract IdentityExecuter {

    uint256 internal executionNonce;
    mapping(uint256 => Execution) internal executions;
    
    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

	// TODO see ERC-191 for more details on this
	function getMessageHash(
        address to,
        uint256 value,
        bytes data,
        uint nonce,
        uint gasPrice,
        uint gasLimit,
        address gasToken,
        uint8 operationType,
        bytes extraHash
    )
        public
        view
        returns (bytes32 messageHash)
    {
        // bytes4 callPrefix;
        // assembly {
            // callPrefix := mload(add(data, 32))
        // }

        return keccak256(
            abi.encodePacked(
                // byte(0x19),      // ERC-191 - the initial 0x19 byte
                // byte(0x0),       // ERC-191 - the version byte
                address(this),      // this
                to,
                value,
                keccak256(data),   // data hash
                nonce,
                gasPrice,
                gasLimit,
                gasToken,
                operationType,
                // callPrefix,
                extraHash
                
            )
        );
    }

    
    /**
     * @notice Approves an execution or claim addition.
     * This SHOULD require n of m approvals of keys purpose 1, if the to of the execution is the identity contract itself, to successfully approve an execution.
     * And COULD require n of m approvals of keys purpose 2, if the to of the execution is another contract, to successfully approve an execution.
     */
    function approve(
        uint256 id,
        bool approve
    )
        public
        delegatedOnly
        override
        returns (bool success)
    {
        require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), "Sender does not have action key");

        emit Approved(id, approve);

        if (approve == true) {
            executions[id].approved = true;

            (success,) = executions[id].to.call{value:(executions[id].value)}(abi.encode(executions[id].data, 0));

            if (success) {
                executions[id].executed = true;

                emit Executed(
                    id,
                    executions[id].to,
                    executions[id].value,
                    executions[id].data
                );

                return true;
            } else {
                emit ExecutionFailed(
                    id,
                    executions[id].to,
                    executions[id].value,
                    executions[id].data
                );

                return false;
            }
        } else {
            executions[id].approved = false;
        }
        return true;
    }

    /**
     * @notice Passes an execution instruction to the keymanager.
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for addKey, removeKey and replaceKey and removeClaim.
     *
     * @return executionId SHOULD be sent to the approve function, to approve or reject this execution.
     */
    function execute(
        address to, 
        uint256 value, 
        bytes memory data
    )
        public
        delegatedOnly
        override
        payable
        returns (uint256 executionId)
    {
        uint256 executionId = _execute(to, value, data);
        return executionId;
    }


    function executeSigned(
        address to,
        address from,
        uint256 value,
        bytes data,
        uint nonce,
        uint gasPrice,
        uint gasLimit,
        address gasToken,
        uint8 operationType,
        bytes extraHash,
        bytes messageSignatures
    )
        public
    {

        uint256 startGas = gasleft();

        require(supportedOpType[operationType]);
        require(startGas >= gasLimit);

        bytes32 msgHash = getMessageHash(to, value, data, nonce, gasPrice, gasLimit, gasToken, operationType, extraHash);
        
        uint256 requiredKeyType = ACTION_KEY;
        if (to == address(this)) {
            // calling Self should be only be with MANAGEMENT_KEY
            requiredKeyType = MANAGEMENT_KEY;
        }
        require(haveEnoughValidSignatures(requiredKeyType, msgHash, messageSignatures));

        uint256 executionId = _execute(to, value, data);

        uint256 refundAmount = (startGas - gasleft()) * gasPrice;

        if (gasToken == address(0)) { // gas refund is in ETH
            require(address(this).balance > refundAmount);
            msg.sender.transfer(refundAmount);
        } else { // gas refund is in ERC20
            require(ERC20Interface(gasToken).balanceOf(address(this)) > refundAmount);
            require(ERC20Interface(gasToken).transfer(msg.sender, refundAmount));
        }
    }


    function _execute(
        address _to, 
        uint256 _value, 
        bytes memory _data
    )
        internal
        returns (uint256 executionId)
    {
        
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(abi.encode(msg.sender)), 2)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }

}