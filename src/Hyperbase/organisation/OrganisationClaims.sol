// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IERC735.sol';

contract OrganisationClaims is ERC735 {
	
    ////////////////
    // CLAIMS
    ////////////////

    mapping(bytes32 => Claim) internal claims;
    mapping(uint256 => bytes32[]) internal claimsByTopic; 

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }
	
    /*//////////////////////////////////////////////////////////////
                                 CLAIMS
    //////////////////////////////////////////////////////////////*/

    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
        public
        override
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(issuer, topic));

        if (msg.sender != address(this)) {
            // TODO require(operatorHasRole(msg.sender, CLAIM_SIGNER), "Permissions: Sender does not have claim signer key");
        }

        if (claims[claimId].issuer != issuer) {
            claimsByTopic[topic].push(claimId);
            claims[claimId].topic = topic;
            claims[claimId].scheme = scheme;
            claims[claimId].issuer = issuer;
            claims[claimId].signature = signature;
            claims[claimId].data = data;
            claims[claimId].uri = uri;

            emit ClaimAdded(
                claimId,
                topic,
                scheme,
                issuer,
                signature,
                data,
                uri
            );
        } else {
            claims[claimId].topic = topic;
            claims[claimId].scheme = scheme;
            claims[claimId].issuer = issuer;
            claims[claimId].signature = signature;
            claims[claimId].data = data;
            claims[claimId].uri = uri;

            emit ClaimChanged(
                claimId,
                topic,
                scheme,
                issuer,
                signature,
                data,
                uri
            );
        }

        return claimId;
    }

    function removeClaim(
        bytes32 claimId
    )
        public
        override
        returns (bool success)
    {
        if (msg.sender != address(this)) {
            // TODO require(operatorHasRole(msg.sender, CLAIM_SIGNER), "Permissions: Sender does not have CLAIM key");
        }

        if (claims[claimId].topic == 0) {
            revert("NonExisting: There is no claim with this ID");
        }

        uint claimIndex = 0;
        while (claimsByTopic[claims[claimId].topic][claimIndex] != claimId) {
            claimIndex++;
        }

        claimsByTopic[claims[claimId].topic][claimIndex] = claimsByTopic[claims[claimId].topic][claimsByTopic[claims[claimId].topic].length - 1];
        claimsByTopic[claims[claimId].topic].pop();

        emit ClaimRemoved(
            claimId,
            claims[claimId].topic,
            claims[claimId].scheme,
            claims[claimId].issuer,
            claims[claimId].signature,
            claims[claimId].data,
            claims[claimId].uri
        );

        delete claims[claimId];

        return true;
    }

    function getClaim(
        bytes32 claimId
    )
        public
        override
        view
        returns (
            uint256 topic,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        )
    {
        return (
            claims[claimId].topic,
            claims[claimId].scheme,
            claims[claimId].issuer,
            claims[claimId].signature,
            claims[claimId].data,
            claims[claimId].uri
        );
    }

    function getClaimIdsByTopic(
        uint256 topic
    )
        public
        override
        view
        returns(bytes32[] memory claimIds)
    {
        return claimsByTopic[topic];
    }

}