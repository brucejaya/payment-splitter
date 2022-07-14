// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/IClaimValidator.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';

contract ClaimVerifiersRegistry is IClaimVerifiersRegistry, Ownable {
    
    /// @dev Array containing all verifiers identity contract address.
    IClaimValidator[] private verifiers;

    /// @dev Mapping between a trusted Verifier index and its corresponding claimsRequired.
    mapping(address => uint256[]) private claimVerifierTopics;

    /**
     *  @dev See {IClaimVerifiersRegistry-addTrustedVerifier}.
     */
    function addTrustedVerifier(
        IClaimValidator _verifier,
        uint256[] calldata _claimsRequired
    )
        external
        override
        onlyOwner
    {
        require(claimVerifierTopics[address(_verifier)].length == 0, 'trusted Verifier already exists');
        require(_claimsRequired.length > 0, 'trusted claim topics cannot be empty');
        verifiers.push(_verifier);
        claimVerifierTopics[address(_verifier)] = _claimsRequired;
        emit TrustedVerifierAdded(_verifier, _claimsRequired);
    }

    /**
     *  @dev See {IClaimVerifiersRegistry-removeTrustedVerifier}.
     */
    function removeTrustedVerifier(
        IClaimValidator _verifier
    )
        external
        override
        onlyOwner
    {
        require(claimVerifierTopics[address(_verifier)].length != 0, 'trusted Verifier doesn\'t exist');
        uint256 length = verifiers.length;
        for (uint256 i = 0; i < length; i++) {
            if (verifiers[i] == _verifier) {
                verifiers[i] = verifiers[length - 1];
                verifiers.pop();
                break;
            }
        }
        delete claimVerifierTopics[address(_verifier)];
        emit TrustedVerifierRemoved(_verifier);
    }

    /**
     *  @dev See {IClaimVerifiersRegistry-updateVerifierClaimTopics}.
     */
    function updateVerifierClaimTopics(
        IClaimValidator _verifier,
        uint256[] calldata _claimsRequired
    )
        external
        override
        onlyOwner
    {
        require(claimVerifierTopics[address(_verifier)].length != 0, 'trusted Verifier doesn\'t exist');
        require(_claimsRequired.length > 0, 'claim topics cannot be empty');
        claimVerifierTopics[address(_verifier)] = _claimsRequired;
        emit ClaimTopicsUpdated(_verifier, _claimsRequired);
    }

    /**
     *  @dev See {IClaimVerifiersRegistry-getverifiers}.
     */
    function getverifiers()
        external
        view
        override
        returns (IClaimValidator[] memory)
    {
        return verifiers;
    }

    /**
     *  @dev See {IClaimVerifiersRegistry-isVerifier}.
     */
    function isVerifier(
        address _Verifier
    )
        external
        view
        override
        returns (bool)
    {
        uint256 length = verifiers.length;
        for (uint256 i = 0; i < length; i++) {
            if (address(verifiers[i]) == _Verifier) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @dev See {IClaimVerifiersRegistry-getclaimVerifierTopics}.
     */
    function getclaimVerifierTopics(
        IClaimValidator _verifier
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        require(claimVerifierTopics[address(_verifier)].length != 0, 'trusted Verifier doesn\'t exist');
        return claimVerifierTopics[address(_verifier)];
    }

    /**
     *  @dev See {IClaimVerifiersRegistry-hasClaimTopic}.
     */
    function hasClaimTopic(
        address _Verifier,
        uint256 _claimTopic
    )
        external
        view
        override
        returns (bool)
    {
        uint256 length = claimVerifierTopics[_Verifier].length;
        uint256[] memory claimsRequired = claimVerifierTopics[_Verifier];
        for (uint256 i = 0; i < length; i++) {
            if (claimsRequired[i] == _claimTopic) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @dev See {IClaimVerifiersRegistry-transferOwnershipOnVerifiersRegistryContract}.
     */
    function transferOwnershipOnVerifiersRegistryContract(
        address _newOwner
    )
        external
        override
        onlyOwner
    {
        transferOwnership(_newOwner);
    }
}
