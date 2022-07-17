// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import '../Keys.sol';
import '.../Interfaces/IERC20.sol';

contract KeyRelay is Keys {

    event ExecutedSigned(bytes32 signHash, uint nonce, bool success);

    uint256 lastTxNonce;
    uint256 lastTxTimestamp;

    mapping(uint256 => uint256) SigRequirementByKeyType;
    mapping(uint256 => bool) supportedOpType;

    // Queries the Keys for signature requirements for the type of operation
    constructor (uint256[] _requirementsByKeyType) Account() public {

        for (uint16 i = 0; i < _requirementsByKeyType.length; i++) {
            SigRequirementByKeyType[i + 1] = _requirementsByKeyType[i];
        }

        supportedOpType[0] = true; // only supported normal call type
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

    ) public {

        uint256 startGas = gasleft();
        // do sanity checks
        require(from == address(this));
        require(nonce == lastTxNonce + 1 || nonce >= now);
        require(supportedOpType[operationType]);
        require(startGas >= gasLimit);

        // extract callPrefix on the
        // get the msgHash
        bytes32 msgHash = getMessageHash(to, value, data, nonce, gasPrice, gasLimit, gasToken, operationType, extraHash);
        uint256 requiredKeyType = ACTION_KEY;
        if (to == address(this)) {
            requiredKeyType = MANAGEMENT_KEY; // calling Self should be only be with MANAGEMENT_KEY
        }
        require(haveEnoughValidSignatures(requiredKeyType, msgHash, messageSignatures));

        if (operationType == 0) {
            executeCall(to, value, data);
        } 
        // @TODO add other types of call

        if (nonce == lastTxNonce + 1) {
            lastTxNonce++;
        }
        else {
            lastTxTimestamp = nonce;
        }

        uint256 refundAmount = (startGas - gasleft()) * gasPrice;

        if (gasToken == address(0)) { // gas refund is in ETH
            require(address(this).balance > refundAmount);
            msg.sender.transfer(refundAmount);
        }
        else { // gas refund is in ERC20
            require(ERC20Interface(gasToken).balanceOf(address(this)) > refundAmount);
            require(ERC20Interface(gasToken).transfer(msg.sender, refundAmount));
        }
    } 

    function lastNonce() public view returns (uint nonce) {
        return lastTxNonce;
    }

    function lastTimestamp() public view returns (uint nonce) {
        return lastTxTimestamp;
    }

    function requiredSignatures(uint _type) public view returns (uint) {
        return SigRequirementByKeyType[_type];
    }

    // B: https://medium.com/metamask/eip712-is-coming-what-to-expect-and-how-to-use-it-bb92fd1a7a26 
    // B: RE ERC-191:
    //      The version-specific data depends (as the name suggests) on the version we use. Currently, EIP-191 has three versions:
    //          0x00: Data with “intended validator.” In the case of a contract, this can be the address of the contract.
    //          0x01: Structured data, as defined in EIP-712. This will be explained further on.
    //          0x45: Regular signed messages, like the current behaviour of personal_sign.

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
    public view returns (bytes32 messageHash) {
        bytes4 callPrefix;

        assembly {
            callPrefix := mload(add(data, 32))
        }

        return keccak256(
            abi.encodePacked(
                byte(0x19),
                byte(0x00),
                address(this), // from
                to,
                value,
                keccak256(data), // data hash
                nonce,
                gasPrice,
                gasLimit,
                gasToken,
                operationType,
                callPrefix,
                extraHash
            )
        );
        
    }

    ///////////////////////
    // Private Functions
    ///////////////////////

    function haveEnoughValidSignatures(
        uint256 _type,
        bytes32 _msgHash,
        bytes _messageSignatures
    ) internal view returns (bool hasEnough) {

        // B: More than one signed transaction with the same parameter can be executed by this function at the same time, by passing all signatures in the messageSignatures field. That field will split the signature in multiple 72 character individual signatures and evaluate each one. This is used for cases in which one action might require the approval of multiple parties, in a single transaction.
        // B: Why is this 65 then?

        uint256 numSignatures = _messageSignatures.length / 65;
        uint256 validSignatureCount = 0;

        for (uint pos = 0; pos < numSignatures; pos++) {
            uint8 v;
            bytes32 r;
            bytes32 s;
            
            assembly {
                r := mload(add(_messageSignatures, add(32, mul(65,pos))))
                s := mload(add(_messageSignatures, add(64, mul(65,pos))))
                // Here we are loading the last 32 bytes, including 31 bytes
                // of 's'. There is no 'mload8' to do this.
                //
                // 'byte' is not working due to the Solidity parser, so lets
                // use the second best option, 'add'
                v := mload(add(_messageSignatures, add(65, mul(65,pos))))
            }
            if (keys[bytes32(ecrecover(_msgHash, v, r, s))].purposeExists[_type]) {
                validSignatureCount++;
            }
        }

        if (validSignatureCount >= SigRequirementByKeyType[_type]) {
            return true;
        }

        return false;
    }
}
