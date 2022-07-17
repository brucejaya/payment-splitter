// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IComplianceLimitHolder.sol';
import '../../Interface/IIdentity.sol';
import '../../Interface/IClaimValidator.sol';

import './OwnerRoles.sol';

contract OwnerManager is OwnerRoles {

    /// @dev the tokenRegistry that is managed by this OwnerManager Contract
    ITokenRegistry public tokenRegistry;

    event ComplianceInteraction(address indexed target, bytes4 selector);

    constructor(
        address _tokenRegistry
    ) {
        tokenRegistry = ITokenRegistry(_tokenRegistry);
    }

    function callSetIdentityRegistry(
        address _identityRegistry, 
        IIdentity _identity
    )
        external
    {
        require(
            isRegistryAddressSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        tokenRegistry.setIdentityRegistry(_identityRegistry);
    }

    function callSetCompliance(
        address _compliance,
        IIdentity _identity
    )
       external
    {
        require(
            isComplianceSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Compliance Setter'
        );
        tokenRegistry.setCompliance(_compliance);
    }

    function callComplianceFunction(
        bytes calldata callData, 
        IIdentity _identity
    )
        external
    {
        require(
            isComplianceManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Compliance Manager');
            address target = address(tokenRegistry.compliance()
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            calldatacopy(freeMemoryPointer, callData.offset, callData.length)
            if iszero(
                call(
                    gas(),
                    target,
                    0,
                    freeMemoryPointer,
                    callData.length,
                    0,
                    0
                    ))
                {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

        emit ComplianceInteraction(target, selector(callData));

        }

    // @dev Extracts the Solidity ABI selector for the specified interaction.
    function selector(
        bytes calldata callData
    )
        internal
        pure
        returns (bytes4 result) 
    {
        if (callData.length >= 4) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                result := calldataload(callData.offset)
            }
        }
    }


    function callSetTokenIdentity(
        address _tokenRegistryIdentity,
        IIdentity _identity
    )
        external
    {
        require(
            isTokenInfoManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Token Information Manager'
        );
        tokenRegistry.setIdentity(_tokenRegistryIdentity);
    }

    function callSetComplianceClaimsRequired(
        address _ComplianceClaimsRequired,
        IIdentity _identity
    )
        external
    {
        require(
            isRegistryAddressSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        tokenRegistry.identityRegistry().setComplianceClaimsRequired(_ComplianceClaimsRequired);
    }

    function callSetTrustedVerifierssRegistry(
        address _trustedVerifiersRegistry,
        IIdentity _identity
    )
        external
    {
        require(
            isRegistryAddressSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        tokenRegistry.identityRegistry().setClaimVerifiersRegistry(_trustedVerifiersRegistry);
    }

    function callAddTrustedVerifiers(
        IClaimValidator _trustedVerifier,
        uint256[] calldata _claimTopics,
        IIdentity _identity
    )
        external
    {
        require(
            isVerifiersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT VerifiersRegistryManager'
        );
        tokenRegistry.identityRegistry().claimVerifiersRegistry().addTrustedVerifier(_trustedVerifier, _claimTopics);
    }

    function callRemoveTrustedVerifiers(
        IClaimValidator _trustedVerifier, 
        IIdentity _identity
    )
        external
    {
        require(
            isVerifiersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT VerifiersRegistryManager'
        );
        tokenRegistry.identityRegistry().claimVerifiersRegistry().removeTrustedVerifier(_trustedVerifier);
    }

    function callUpdateVerifierClaimTopics(
        IClaimValidator _trustedVerifier,
        uint256[] calldata _claimTopics,
        IIdentity _identity
    )
        external
    {
        require(
            isVerifiersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT VerifiersRegistryManager'
        );
        tokenRegistry.identityRegistry().claimVerifiersRegistry().updateVerifierClaimTopics(_trustedVerifier, _claimTopics);
    }

    function callAddClaimTopic(
        uint256 _claimTopic, 
        IIdentity _identity
    )
        external
    {
        require(
            isClaimRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT ClaimRegistryManager'
        );
        tokenRegistry.identityRegistry().complianceClaimsRequired().addClaimTopic(_claimTopic);
    }

    function callRemoveClaimTopic(
        uint256 _claimTopic, 
        IIdentity _identity
    )
        external
    {
        require(
            isClaimRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT ClaimRegistryManager'
        );
        tokenRegistry.identityRegistry().complianceClaimsRequired().removeClaimTopic(_claimTopic);
    }

    function callTransferOwnershipOnTokenContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.transferOwnershipOnTokenContract(_newOwner);
    }

    function callTransferOwnershipOnIdentityRegistryContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().transferOwnershipOnIdentityRegistryContract(_newOwner);
    }

    function callTransferOwnershipOnComplianceContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.compliance().transferOwnershipOnComplianceContract(_newOwner);
    }

    function callTransferOwnershipOnComplianceClaimsRequiredContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().complianceClaimsRequired().transferOwnershipOnComplianceClaimsRequiredContract(_newOwner);
    }

    function callTransferOwnershipOnVerifiersRegistryContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().claimVerifiersRegistry().transferOwnershipOnVerifiersRegistryContract(_newOwner);
    }

    function callAddAgentOnTokenContract(
        address _agent
    ) 
        external 
        onlyAdmin 
    {
        tokenRegistry.addAgentOnTokenContract(_agent);
    }

    function callRemoveAgentOnTokenContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.removeAgentOnTokenContract(_agent);
    }

    function callAddAgentOnIdentityRegistryContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().addAgentOnIdentityRegistryContract(_agent);
    }

    function callRemoveAgentOnIdentityRegistryContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().removeAgentOnIdentityRegistryContract(_agent);
    }

    
    /*//////////////////////////////////////////////////////////////
                            TOKEN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function callForcedTransfer(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data,
        IIdentity _identity
    )
        external
    {
        require(
            isTransferManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Transfer Manager'
        );
        tokenRegistry.forcedTransfer(_from, _to, _id, _amount, _data);
    }

    function callBatchForcedTransfer(
        address[] memory _fromList,
        address[] memory _toList,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes[] memory _data,
        IIdentity _identity
    )
        external
    {
        require(
            isTransferManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Transfer Manager'
        );
        tokenRegistry.batchForcedTransfer(_fromList, _toList, _ids, _amounts, _data);
    }

    function callPause(
        IIdentity _identity,
        uint256 _id
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.pause(_id);
    }

    function callUnpause(
        IIdentity _identity,
        uint256 _id
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.unpause(_id);
    }

    function callMint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.mint(_to, _id, _amount, _data);
    }

    function callMintBatch(
        address[] memory _accounts,
        uint256 _id,
        uint256[] memory _amounts,
        bytes memory _data,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.mintBatch(_accounts, _id, _amounts, _data);
    }

    function callBurn(
        address _account,
        uint256 _id,
        uint256 _amount,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.burn(_account, _id, _amount);
        
    }

    function callBurnBatch(
        address[] memory _accounts,
        uint256 _id,
        uint256[] memory _amounts,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.burnBatch(_accounts, _id, _amounts);
    }

    function callSetAddressFrozen(
        address _account,
        uint256 _id,
        bool _freeze,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.setAddressFrozen(_account, _id, _freeze);
    }

    function callBatchSetAddressFrozen(
        address[] calldata _accounts,
        uint256[] calldata _ids,
        bool[] calldata _freeze,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.batchSetAddressFrozen(_accounts, _ids, _freeze);
    }

    function callFreezePartialTokens(
        address _account,
        uint256 _id,
        uint256 _amount,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.freezePartialTokens(_account, _id, _amount);
    }

    function callBatchFreezePartialTokens(
        address[] calldata _accounts,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.batchFreezePartialTokens(_accounts, _ids, _amounts);
    }

    function callUnfreezePartialTokens(
        address _account,
        uint256 _ids,
        uint256 _amount,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.unfreezePartialTokens(_account, _ids, _amount);
    }

    function callBatchUnfreezePartialTokens(
        address[] calldata _accounts,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.batchUnfreezePartialTokens(_accounts, _ids, _amounts);
    }

    function callRecoveryAddress(
        address _lostWallet,
        address _newWallet,
        uint256 _id,
        address _account,
        bytes memory _data,
        IIdentity _managerIdentity
    )
        external
    {
        require(
            isRecoveryAgent(address(_managerIdentity)) && _managerIdentity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Recovery Agent'
        );
        tokenRegistry.recoveryAddress(_lostWallet, _newWallet, _id, _account, _data);
    }

    function callRegisterIdentity(
        address _account,
        IIdentity _identity,
        uint16 _country,
        IIdentity _managerIdentity
    )
        external
    {
        require(
            isWhiteListManager(address(_managerIdentity)) && _managerIdentity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        tokenRegistry.identityRegistry().registerIdentity(_account, _identity, _country);
    }

    function callUpdateIdentity(
        address _account,
        IIdentity _identity
    ) external {
        require(
            isWhiteListManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        tokenRegistry.identityRegistry().updateIdentity(_account, _identity);
    }

    function callUpdateCountry(
        address _account,
        uint16 _country,
        IIdentity _identity
    ) external {
        require(
            isWhiteListManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        tokenRegistry.identityRegistry().updateCountry(_account, _country);
    }

    function callDeleteIdentity(
        address _account,
        IIdentity _identity
    ) external {
        require(
            isWhiteListManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        tokenRegistry.identityRegistry().deleteIdentity(_account);
    }

}