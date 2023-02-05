// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IClaims.sol';

contract Claims is IClaims {

  	////////////////
    // STATE
    ////////////////

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
		address subject;
        bytes signature;
        bytes data;
        string uri;
    }
    
    mapping (address => mapping(bytes32 => Claim)) internal _claims;
    mapping (address => mapping(uint256 => bytes32[])) internal _claimsByTopic; 
    mapping (bytes => bool) public _revokedClaims;

    ////////////////////////////////////////////////////////////////
    //                           CLAIMS
    ////////////////////////////////////////////////////////////////

    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
		address subject,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
        public
        override
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(issuer, topic));

        if (_claims[subject][claimId].issuer != issuer) {
            _claimsByTopic[topic].push(claimId);
            _claims[subject][claimId].topic = topic;
            _claims[subject][claimId].scheme = scheme;
            _claims[subject][claimId].issuer = issuer;
            _claims[subject][claimId].subject = subject;
            _claims[subject][claimId].signature = signature;
            _claims[subject][claimId].data = data;
            _claims[subject][claimId].uri = uri;

            emit ClaimAdded(
                claimId,
                topic,
                scheme,
                issuer,
                subject,
                signature,
                data,
                uri
            );
        } else {
            _claims[subject][claimId].topic = topic;
            _claims[subject][claimId].scheme = scheme;
            _claims[subject][claimId].issuer = issuer;
            _claims[subject][claimId].subject = subject;
            _claims[subject][claimId].signature = signature;
            _claims[subject][claimId].data = data;
            _claims[subject][claimId].uri = uri;

            emit ClaimChanged(
                claimId,
                topic,
                scheme,
                issuer,
                subject,
                signature,
                data,
                uri
            );
        }

        return claimId;
    }

    function removeClaim(
        bytes32 claimId,
		address subject
    )
        public
        override
        returns (bool success)
    {
        if (_claims[subject][claimId].topic == 0) {
            revert("NonExisting: There is no claim with this ID");
        }

        uint claimIndex = 0;
        while (_claimsByTopic[_claims[subject][claimId].topic][claimIndex] != claimId) {
            claimIndex++;
        }

        _claimsByTopic[_claims[subject][claimId].topic][claimIndex] = _claimsByTopic[_claims[subject][claimId].topic][_claimsByTopic[_claims[subject][claimId].topic].length - 1];
        _claimsByTopic[_claims[subject][claimId].topic].pop();

        emit ClaimRemoved(
            claimId,
            _claims[subject][claimId].topic,
            _claims[subject][claimId].scheme,
            _claims[subject][claimId].issuer,
            _claims[subject][claimId].subject,
            _claims[subject][claimId].signature,
            _claims[subject][claimId].data,
            _claims[subject][claimId].uri
        );

        delete _claims[subject][claimId];

        return true;
    }

    function getClaim(
        bytes32 claimId,
		address subject
    )
        public
        override
        view
        returns (
            uint256 topic_,
            uint256 scheme_,
            address issuer_,
			address subject_,
            bytes memory signature_,
            bytes memory data_,
            string memory uri_
        )
    {
        return (
            _claims[subject][claimId].topic,
            _claims[subject][claimId].scheme,
            _claims[subject][claimId].issuer,
            _claims[subject][claimId].subject,
            _claims[subject][claimId].signature,
            _claims[subject][claimId].data,
            _claims[subject][claimId].uri
        );
    }

    function getClaimIdsByTopic(
        uint256 topic,
		address subject

    )
        public
        override
        view
        returns(bytes32[] memory claimIds)
    {
        return _claimsByTopic[subject][topic];
    }

    // @notice Revoke a claim previously issued, the claim is no longer considered as valid after revocation.
    function revokeClaim(
        bytes32 claimId,
        address subject
    )
        public
        override
        returns(bool)
    {
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory  sig;
        bytes  memory data;

        ( foundClaimTopic, scheme, issuer, sig, data, ) = getClaim(claimId, subject);

        _revokedClaims[sig] = true;
        return true;
    }
    
    ////////////////////////////////////////////////////////////////
    //                       CLAIM FUNCTIONS
    ////////////////////////////////////////////////////////////////

    // @notice Checks if a claim is valid.
    function isClaimValid(
        address subject,
        uint256 claimTopic,
        bytes memory sig,
        bytes memory data
    )
        public
        override
        view
        returns (bool claimValid)
    {
        bytes32 dataHash = keccak256(abi.encode(subject, claimTopic, data));
        
        // Use abi.encodePacked to concatenate the message prefix and the message to sign.
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

        // Recover address of data signer
        address recovered = getRecoveredAddress(sig, prefixedHash);

        // Take hash of recovered address
        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        // Does the trusted identifier have they key which signed the user's claim?
        if (isClaimRevoked(sig) == false) {
            return true;
        }

        return false;
    }

    // @notice Returns revocation status of a claim.
    function isClaimRevoked(
        bytes memory _sig
    )
        public
        override
        view
        returns (bool)
    {
        if (_revokedClaims[_sig]) {
            return true;
        }

        return false;
    }


    // @notice Get address from signature
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