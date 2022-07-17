// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import '../../Interface/IClaimValidator.sol';

import '../identity/Identity.sol';

contract ClaimValidator is IClaimValidator, Identity {
    
    mapping (bytes => bool) public revokedClaims;

    constructor(address initialManagementKey) Identity(initialManagementKey, false) {}

    // @dev Revoke a claim previously issued, the claim is no longer considered as valid after revocation.
    function revokeClaim(
        bytes32 claimId,
        address identity
    )
        public
        override
        delegatedOnly
        returns(bool)
    {
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory  sig;
        bytes  memory data;

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key");
        }

        ( foundClaimTopic, scheme, issuer, sig, data, ) = Identity(identity).getClaim(claimId);

        revokedClaims[sig] = true;
        return true;
    }

    // @dev Returns revocation status of a claim.
    function isClaimRevoked(
        bytes memory _sig
    )
        public
        override
        view
        returns (bool)
    {
        if (revokedClaims[_sig]) {
            return true;
        }

        return false;
    }

    //   @dev Checks if a claim is valid.
    function isClaimValid(
        IIdentity identity,
        uint256 claimTopic,
        bytes memory sig,
        bytes memory data
    )
        public
        override
        view
        returns (bool claimValid)
    {
        bytes32 dataHash = keccak256(abi.encode(identity, claimTopic, data));
        
        // Use abi.encodePacked to concatenate the message prefix and the message to sign.
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

        // Recover address of data signer
        address recovered = getRecoveredAddress(sig, prefixedHash);

        // Take hash of recovered address
        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        // Does the trusted identifier have they key which signed the user's claim?
        if (keyHasPurpose(hashedAddr, 3) && (isClaimRevoked(sig) == false)) {
            return true;
        }

        return false;
    }

    function getRecoveredAddress(
        bytes memory sig,
        bytes32 dataHash
    )
        public
        override
        pure
        returns (address addr)
    {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the signature length
        if (sig.length != 65) {
            return address(0);
        }

        // Divide the signature in r, s and v variables
        assembly {
            ra := mload(add(sig, 32))
            sa := mload(add(sig, 64))
            va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27) {
            va += 27;
        }

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }
}
