/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.6;


// Signature management and execution


// Won't msg.sender fail with signed transactions?

contract C is B {


    
    // ********************************* Execution stuff ******************************** //
    

    uint256 executionNonce;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }
    
    mapping (uint256 => Execution) executions; // !! SHOULD THIS BE GLOBAL

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    function _approve(bytes32 identity, address from, uint256 id, bool approve) // KeyRouter
        internal
        returns(bool success)
    {
        Key storage senderKey = keys[identity][addressToBytes32(from)];
        require (!transactions[id].rejected); // if tx has been rejected, revert
        require (!transactions[id].executed);




        //TODO permission logic
        require (senderKey.purposeExists[1] || senderKey.purposeExists[2]);
        if (approve == true) {

            

            // KEY RELAY
            if (transactions[id].to == address(this)) {
                require (senderKey.purposeExists[1]);
            }
            // TODO execution logic passes to hardcoded executeCall function at the bottom
            executeCall(transactions[id].to, transactions[id].value, transactions[id].data);
            transactions[id].executed = true;
            emit Executed(id, transactions[id].to, transactions[id].value, transactions[id].data);
            return true;
            // KEY RELAY

            // KEY HOLDER
            executions[id].approved = true;
            // TODO execution logic 
            success = executions[id].to.call.value(executions[id].value)(executions[id].data, 0);
            if (success) {
                executions[id].executed = true;
                emit Executed(
                    id,
                    executions[id].to,
                    executions[id].value,
                    executions[id].data
                );
                return;
            } else {
                emit ExecutionFailed(
                    id,
                    executions[id].to,
                    executions[id].value,
                    executions[id].data
                );
                return;
            }
            // KEY HOLDER
        }
        else {
            executions[id].approved = false;
            return false;
        }

    }
    

    function _execute(bytes32 identity, address from, address to, uint256 value, bytes data) // KeyRouter
        internal
        returns(uint256 executionId)
    {
        require(!executions[executionNonce].executed, "Already executed");

        transactions[executionNonce].to = to;
        transactions[executionNonce].value = value;
        transactions[executionNonce].data = data;

        emit ExecutionRequested(executionNonce, to, value, data);


        // TODO permission logic
        // check the managementKey Level and call approve with true if true
        Key storage senderKey = keys[identity][addressToBytes32(from)];
        if (senderKey.purposeExists[1] || senderKey.purposeExists[2]) {

            // TODO passes execution to approve function
            approve(executionNonce, true);
        }
        //

        executionNonce++;
        return executionNonce-1;
    }



    function execute(bytes32 _identity, address _to, uint256 _value, bytes _data) // KeyRouter
		public
		returns(address)
	{
        return _execute(_identity, msg.sender, _to, _value, _data);
    }


    function executeSigned(bytes32 _identity, uint8 _sigV, bytes32 _sigR, bytes32 _sigS, bytes32 _hash, address _to, uint256 _value, bytes _data) // KeyRouter
		public
		returns(address)
	{
        return _execute(_identity, ecrecover(_hash, _sigV, _sigR, _sigS), _to, _value, _data);
    }


    function approve(bytes32 _identity, uint256 _id, bool _approve) // KeyRouter
        public
        returns(bool success)
    {
        return _approve(_identity, msg.sender, _id, _approve);

    }

    function approveSigned(bytes32 _identity, uint8 _sigV, bytes32 _sigR, bytes32 _sigS, bytes32 _hash, uint256 _id, bool _approve) // KeyRouter
		public
		returns(address)
	{
        return _approve(_identity, ecrecover(_hash, _sigV, _sigR, _sigS), _id, _approve);
    }


    // ********************************* KeyRouter execution logic ******************************** //

    // B: This has not been done... (23:30)
    function executeCall(address destination, uint256 value, bytes callData)
    internal
    {
        bool result;
        uint256 dataLength = callData.length;

        assembly {
            let x := mload(0x40)        // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(callData, 32)  // First 32 bytes are the padded length of data, so exclude that
            result := call(
            sub(gas(), 34710),            // 34710 is the value that solidity is currently emitting
                                        // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                        // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
            destination,
            value,
            d,
            dataLength,                 // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                           // Output is ignored, therefore the output size is zero
            )
        }

        if (!result) {
            revert();
        }
    }


}