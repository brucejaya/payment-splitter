// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IIdentity.sol';

contract ComplianceClaimsRequired is IComplianceClaimsRequired, Ownable {
    
    ////////////////
    // STATE
    ////////////////
    
    // @notice Mapping from token id to required Claim Topics
    mapping(uint256 => uint256[]) private claimTopics;

    // @notice Claim verifiers contract
    IClaimVerifiersRegistry public _claimVerifiersRegistry;

    constructor(
        address claimVerifiersRegistry_
    ) {
        _claimVerifiersRegistry = IClaimVerifiersRegistry(claimVerifiersRegistry_);
        emit ClaimVerifiersRegistrySet(claimVerifiersRegistry_);
    }

    function claimVerifiersRegistry()
        external
        view
        returns (IClaimVerifiersRegistry)
    {
        return _claimVerifiersRegistry;
    }

    function setClaimVerifiersRegistry(
        address claimVerifiersRegistry_
    )
        external
        onlyOwner
    {
        _claimVerifiersRegistry = IClaimVerifiersRegistry(claimVerifiersRegistry_);
        emit ClaimVerifiersRegistrySet(claimVerifiersRegistry_);
    }

    // @notice Gets claim topics by token id
    function getClaimTopics(
        uint256 id
    )
        external
        view
        returns (uint256[] memory)
    {
        return claimTopics[id];
    }
    
    // @notice Add a claim topic to be required of holders
    function addClaimTopic(
        uint256 claimTopic,
        uint256 id
    )
        external
        onlyOwner
    {
        uint256 length = claimTopics[id].length;
        for (uint256 i = 0; i < length; i++) {
            require(claimTopics[id][i] != claimTopic, 'claimTopic already exists');
        }
        claimTopics[id].push(claimTopic);
        emit ClaimTopicAdded(claimTopic, id);
    }

    // @notice Remove claim topic required of holders
    function removeClaimTopic(
        uint256 claimTopic,
        uint256 id
    )
        external
        onlyOwner
    {
        uint256 length = claimTopics[id].length;
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[id][i] == claimTopic) {
                claimTopics[id][i] = claimTopics[id][length - 1];
                claimTopics[id].pop();
                emit ClaimTopicRemoved(claimTopic, id);
                break;
            }
        }
    }

    // @notice Iterates through the claims comparing them to the identity to ensure the reciever has all of the appropriate claims
    function isVerified(
        address account,
        uint256 id
    )
        external
        view
        returns (bool)
    {
        if (address(IIdentity(account)) == address(0)) {
            return false;
        }
        if (claimTopics[id].length == 0) {
            return true;
        }
        // TODO if (has claim from issuer is whitelisted return true)
        // else >>
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopic;
        for (claimTopic = 0; claimTopic < claimTopics[id].length; claimTopic++) {
            bytes32[] memory claimIds = IIdentity(account).getClaimIdsByTopic(claimTopics[id][claimTopic]);
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = IIdentity(account).getClaim(claimIds[j]);

                try IClaimValidator(issuer).isClaimValid(
                    IIdentity(account),
                    claimTopics[id][claimTopic],
                    sig,
                    data
                )
                    returns(bool _validity)
                {
                    if (
                        _validity
                        && _claimVerifiersRegistry.hasClaimTopic(issuer, claimTopics[id][claimTopic])
                        && _claimVerifiersRegistry.isVerifier(issuer)
                    ) {
                        j = claimIds.length;
                    }
                    if (!_claimVerifiersRegistry.isVerifier(issuer) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!_claimVerifiersRegistry.hasClaimTopic(issuer, claimTopics[id][claimTopic]) && j == (claimIds.length - 1)) {
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

}