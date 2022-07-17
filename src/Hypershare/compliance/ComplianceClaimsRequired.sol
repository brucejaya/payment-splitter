// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/IComplianceClaimsRequired.sol';

contract ComplianceClaimsRequired is IComplianceClaimsRequired, Ownable {
    
    // @dev Mapping from token id to required Claim Topics
    mapping(uint256 => uint256[]) private claimTopics;

    // @dev Gets claim topics by token id
    function getClaimTopics(
        uint256 id
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        return claimTopics[id];
    }
    
    // @dev Add a claim topic to be required of holders
    function addClaimTopic(
        uint256 claimTopic,
        uint256 id
    )
        external
        override
        onlyOwner
    {
        uint256 length = claimTopics[id].length;
        for (uint256 i = 0; i < length; i++) {
            require(claimTopics[id][i] != claimTopic, 'claimTopic already exists');
        }
        claimTopics[id].push(claimTopic);
        emit ClaimTopicAdded(claimTopic);
    }

    // @dev Remove claim topic required of holders
    function removeClaimTopic(
        uint256 claimTopic,
        uint256 id
    )
        external
        override
        onlyOwner
    {
        uint256 length = claimTopics[id].length;
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[id][i] == claimTopic) {
                claimTopics[id][i] = claimTopics[id][length - 1];
                claimTopics[id].pop();
                emit ClaimTopicRemoved(claimTopic);
                break;
            }
        }
    }

    // @dev Iterates through the claims comparing them to the identity to ensure the reciever has all of the appropriate claims
    function isVerified(
        address _account,
        uint256 id
    )
        external
        view
        override
        returns (bool)
    {
        if (address(identity(_account)) == address(0)) {
            return false;
        }
        if (claimTopics[id].length == 0) {
            return true;
        }
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopic;
        for (claimTopic = 0; claimTopic < claimTopics[id].length; claimTopic++) {
            bytes32[] memory claimIds = identity(_account).getClaimIdsByTopic(claimTopics[id][claimTopic]);
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = identity(_account).getClaim(claimIds[j]);

                try IClaimValidator(issuer).isClaimValid(
                    identity(_account),
                    claimTopics[id][claimTopic],
                    sig,
                    data
                )
                    returns(bool _validity)
                {
                    if (
                        _validity
                        && claimVerifiersRegistry_.hasClaimTopic(issuer, claimTopics[id][claimTopic])
                        && claimVerifiersRegistry_.isVerifier(issuer)
                    ) {
                        j = claimIds.length;
                    }
                    if (!claimVerifiersRegistry_.isVerifier(issuer) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!claimVerifiersRegistry_.hasClaimTopic(issuer, claimTopics[id][claimTopic]) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!_validity && j == (claimIds.length - 1)) {
                        return false;
                    }
                }
                catch {
                    if (j == (claimIds.length - 1)) {
                        return false;
                    }
                }
            }
        }
        return true;
    }



    function transferOwnershipOnComplianceClaimsRequiredContract(
        address _newOwner
    )
        external
        override
        onlyOwner
    {
        transferOwnership(_newOwner);
    }
}