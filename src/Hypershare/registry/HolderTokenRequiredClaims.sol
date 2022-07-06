// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/IHolderTokenRequiredClaims.sol';

contract HolderTokenRequiredClaims is IHolderTokenRequiredClaims, Ownable {
    
    /// @dev All required Claim Topics
    uint256[] private claimTopics;

    /**
     *  @dev See {IHolderTokenRequiredClaims-addClaimTopic}.
     */
    function addClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            require(claimTopics[i] != _claimTopic, 'claimTopic already exists');
        }
        claimTopics.push(_claimTopic);
        emit ClaimTopicAdded(_claimTopic);
    }

    /**
     *  @dev See {IHolderTokenRequiredClaims-removeClaimTopic}.
     */
    function removeClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[i] == _claimTopic) {
                claimTopics[i] = claimTopics[length - 1];
                claimTopics.pop();
                emit ClaimTopicRemoved(_claimTopic);
                break;
            }
        }
    }

    /**
     *  @dev See {IHolderTokenRequiredClaims-getClaimTopics}.
     */
    function getClaimTopics() external view override returns (uint256[] memory) {
        return claimTopics;
    }

    /**
     *  @dev See {IHolderTokenRequiredClaims-transferOwnershipOnHolderTokenRequiredClaimsContract}.
     */
    function transferOwnershipOnHolderTokenRequiredClaimsContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }
}
