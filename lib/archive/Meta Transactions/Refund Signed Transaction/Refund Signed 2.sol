/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.6;

import '.../Interfaces/IERC20.sol';

contract Identity {
    
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
