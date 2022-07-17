/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.6;

import '.../Interfaces/IERC20.sol';

// Okay, so this doesn't recieve money from further down chain, it recieves messages and send's them back.
// So this would be used as an extension to ERC-725x and ERC-725y as part of the account sending money BACK to the relay!
// So this is not the relay!!
// And instead of complex key management, it just has one key which is the registry
// The registry holds the gas for transactions, and sends them to the account, the registry is the relay, and this is the refunder and execute
// Actually, all it needs to be is a capable proxy contract, that has an owner.
// Mainly just needs to be able to do all different opcode and stuff, the control logic is in registry.

contract Identity {
    
    // ?? Needed
    event ExecutedSigned(bytes32 signHash, uint nonce, bool success);


    uint256 lastTxNonce;
    uint256 lastTxTimestamp;
  
    // TODO Check Gnosis safe for
    // See requiredTxGas
    // See handlePayment
    // See execTransaction

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
        // TODO onlyOwner 
    {

        uint256 startGas = gasleft();
        // do sanity checks
        require(from == address(this)); // ??

        require(nonce == lastTxNonce + 1 || nonce >= now);
        require(supportedOpType[operationType]);
        require(startGas >= gasLimit);


        if (operationType == 0) {
            executeCall(to, value, data);
        } // @TODO add other types of call

        if (nonce == lastTxNonce + 1) {
            lastTxNonce++;
        } else {
            lastTxTimestamp = nonce;
        }

        uint256 refundAmount = (startGas - gasleft()) * gasPrice;

        if (gasToken == address(0)) { // gas refund is in ETH
            require(address(this).balance > refundAmount);
            msg.sender.transfer(refundAmount); // ... Returns funds to sender i.e. Identity reg
        } else { // gas refund is in ERC20
            require(ERC20Interface(gasToken).balanceOf(address(this)) > refundAmount);
            require(ERC20Interface(gasToken).transfer(msg.sender, refundAmount)); // ... Returns funds to sender i.e. Identity reg
        }
    }

    function lastNonce() public view returns (uint nonce) {
        return lastTxNonce;
    }

    function lastTimestamp() public view returns (uint nonce) {
        return lastTxTimestamp;
    }

}
