// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/ICompliance.sol';
import '../../Interface/IIdentity.sol';
import '../../Interface/IClaimVerifier.sol';
import './OwnerRoles.sol';

contract OwnerManager is OwnerRoles {

    /// @dev the tokenRegistry that is managed by this OwnerManager Contract
    ITokenRegistry public tokenRegistry;

    /// @dev Event emitted for each executed interaction with the compliance contract.
    ///
    /// For gas efficiency, only the interaction calldata selector (first 4
    /// bytes) is included in the event. For interactions without calldata or
    /// whose calldata is shorter than 4 bytes, the selector will be `0`.
    event ComplianceInteraction(address indexed target, bytes4 selector);

    /**
     *  @dev the constructor initiates the OwnerManager contract
     *  and sets msg.sender as owner of the contract
     *  @param _tokenRegistry the tokenRegistry managed by this OwnerManager contract
     */
    constructor(
        address _tokenRegistry
    ) {
        tokenRegistry = ITokenRegistry(_tokenRegistry);
    }

    /**
     *  @dev calls the `setIdentityRegistry` function on the tokenRegistry contract
     *  OwnerManager has to be set as owner on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-setIdentityRegistry}.
     *  Requires that `_identity` is set as RegistryAddressSetter on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `setCompliance` function on the tokenRegistry contract
     *  OwnerManager has to be set as owner on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-setCompliance}.
     *  Requires that `_identity` is set as ComplianceSetter on the OwnerManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls any onlyOwner function available on the compliance contract
     *  OwnerManager has to be set as owner on the compliance smart contract to process this function
     *  Requires that `_identity` is set as ComplianceManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callComplianceFunction(
        bytes calldata callData, 
        IIdentity _identity
    )
        external
    {
        require(
            isComplianceManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Compliance Manager');
        address target = address(tokenRegistry.compliance());

        // NOTE: Use assembly to call the interaction instead of a low level
        // call for two reasons:
        // - We don't want to copy the return data, since we discard it for
        // interactions.
        // - Solidity will under certain conditions generate code to copy input
        // calldata twice to memory (the second being a "memcopy loop").
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

    /// @dev Extracts the Solidity ABI selector for the specified interaction.
    /// @param callData Interaction data.
    /// @return result The 4 byte function selector of the call encoded in
    /// this interaction.
    function selector(
        bytes calldata callData
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (callData.length >= 4) {
        // NOTE: Read the first word of the interaction's calldata. The
        // value does not need to be shifted since `bytesN` values are left
        // aligned, and the value does not need to be masked since masking
        // occurs when the value is accessed and not stored:
        // <https://docs.soliditylang.org/en/v0.7.6/abi-spec.html#encoding-of-indexed-event-parameters>
        // <https://docs.soliditylang.org/en/v0.7.6/assembly.html#access-to-external-variables-functions-and-libraries>
        // solhint-disable-next-line no-inline-assembly
            assembly {
                result := calldataload(callData.offset)
                }
            }
        }

    /**
     *  @dev calls the `setName` function on the tokenRegistry contract
     *  OwnerManager has to be set as owner on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-setName}.
     *  Requires that `_identity` is set as TokenInfoManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetTokenName(
        string calldata _name, 
        IIdentity _identity
    ) 
        external 
    {
        require(
            isTokenInfoManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Token Information Manager'
        );
        tokenRegistry.setName(_name);
    }

    /**
     *  @dev calls the `setSymbol` function on the tokenRegistry contract
     *  OwnerManager has to be set as owner on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-setSymbol}.
     *  Requires that `_identity` is set as TokenInfoManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetTokenSymbol(
        string calldata _symbol, 
        IIdentity _identity
    )
        external
    {
        require(
            isTokenInfoManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Token Information Manager'
        );
        tokenRegistry.setSymbol(_symbol);
    }

    /**
     *  @dev calls the `setOnchainID` function on the tokenRegistry contract
     *  OwnerManager has to be set as owner on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-setOnchainID}.
     *  Requires that `_tokenRegistryOnchainID` is set as TokenInfoManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetTokenOnchainID(
        address _tokenRegistryOnchainID,
        IIdentity _identity
    )
        external
    {
        require(
            isTokenInfoManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Token Information Manager'
        );
        tokenRegistry.setOnchainID(_tokenRegistryOnchainID);
    }

    /**
     *  @dev calls the `setComplianceClaimsRequired` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-setComplianceClaimsRequired}.
     *  Requires that `_identity` is set as RegistryAddressSetter on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `setTrustedIssuersRegistry` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-setTrustedIssuersRegistry}.
     *  Requires that `_identity` is set as RegistryAddressSetter on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetTrustedIssuersRegistry(
        address _trustedIssuersRegistry,
        IIdentity _identity
    )
        external
    {
        require(
            isRegistryAddressSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        tokenRegistry.identityRegistry().setTrustedIssuersRegistry(_trustedIssuersRegistry);
    }

    /**
     *  @dev calls the `addTrustedIssuer` function on the Trusted Issuers Registry contract
     *  OwnerManager has to be set as owner on the Trusted Issuers Registry smart contract to process this function
     *  See {IClaimVerifiersRegistry-addTrustedIssuer}.
     *  Requires that `_identity` is set as IssuersRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callAddTrustedIssuer(
        IClaimVerifier _trustedIssuer,
        uint256[] calldata _claimTopics,
        IIdentity _identity
    )
        external
    {
        require(
            isIssuersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT IssuersRegistryManager'
        );
        tokenRegistry.identityRegistry().issuersRegistry().addTrustedIssuer(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev calls the `removeTrustedIssuer` function on the Trusted Issuers Registry contract
     *  OwnerManager has to be set as owner on the Trusted Issuers Registry smart contract to process this function
     *  See {IClaimVerifiersRegistry-removeTrustedIssuer}.
     *  Requires that `_identity` is set as IssuersRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callRemoveTrustedIssuer(
        IClaimVerifier _trustedIssuer, 
        IIdentity _identity
    )
        external
    {
        require(
            isIssuersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT IssuersRegistryManager'
        );
        tokenRegistry.identityRegistry().issuersRegistry().removeTrustedIssuer(_trustedIssuer);
    }

    /**
     *  @dev calls the `updateIssuerClaimTopics` function on the Trusted Issuers Registry contract
     *  OwnerManager has to be set as owner on the Trusted Issuers Registry smart contract to process this function
     *  See {IClaimVerifiersRegistry-updateIssuerClaimTopics}.
     *  Requires that `_identity` is set as IssuersRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callUpdateIssuerClaimTopics(
        IClaimVerifier _trustedIssuer,
        uint256[] calldata _claimTopics,
        IIdentity _identity
    )
        external
    {
        require(
            isIssuersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT IssuersRegistryManager'
        );
        tokenRegistry.identityRegistry().issuersRegistry().updateIssuerClaimTopics(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev calls the `addClaimTopic` function on the Claim Topics Registry contract
     *  OwnerManager has to be set as owner on the Claim Topics Registry smart contract to process this function
     *  See {IComplianceClaimsRequired-addClaimTopic}.
     *  Requires that `_identity` is set as ClaimRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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
        tokenRegistry.identityRegistry().topicsRegistry().addClaimTopic(_claimTopic);
    }

    /**
     *  @dev calls the `removeClaimTopic` function on the Claim Topics Registry contract
     *  OwnerManager has to be set as owner on the Claim Topics Registry smart contract to process this function
     *  See {IComplianceClaimsRequired-removeClaimTopic}.
     *  Requires that `_identity` is set as ClaimRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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
        tokenRegistry.identityRegistry().topicsRegistry().removeClaimTopic(_claimTopic);
    }

    /**
     *  @dev calls the `transferOwnershipOnTokenContract` function on the tokenRegistry contract
     *  OwnerManager has to be set as owner on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-transferOwnershipOnTokenContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnTokenContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.transferOwnershipOnTokenContract(_newOwner);
    }

    /**
     *  @dev calls the `transferOwnershipOnIdentityRegistryContract` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-transferOwnershipOnIdentityRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnIdentityRegistryContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().transferOwnershipOnIdentityRegistryContract(_newOwner);
    }

    /**
     *  @dev calls the `transferOwnershipOnComplianceContract` function on the Compliance contract
     *  OwnerManager has to be set as owner on the Compliance smart contract to process this function
     *  See {ICompliance-transferOwnershipOnComplianceContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnComplianceContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.compliance().transferOwnershipOnComplianceContract(_newOwner);
    }

    /**
     *  @dev calls the `transferOwnershipOnComplianceClaimsRequiredContract` function on the Claim Topics Registry contract
     *  OwnerManager has to be set as owner on the Claim Topics registry smart contract to process this function
     *  See {IComplianceClaimsRequired-transferOwnershipOnComplianceClaimsRequiredContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnComplianceClaimsRequiredContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().topicsRegistry().transferOwnershipOnComplianceClaimsRequiredContract(_newOwner);
    }

    /**
     *  @dev calls the `transferOwnershipOnIssuersRegistryContract` function on the Trusted Issuers Registry contract
     *  OwnerManager has to be set as owner on the Trusted Issuers registry smart contract to process this function
     *  See {IClaimVerifiersRegistry-transferOwnershipOnIssuersRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnIssuersRegistryContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().issuersRegistry().transferOwnershipOnIssuersRegistryContract(_newOwner);
    }

    /**
     *  @dev calls the `addAgentOnTokenContract` function on the tokenRegistry contract
     *  OwnerManager has to be set as owner on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-addAgentOnTokenContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callAddAgentOnTokenContract(
        address _agent
    ) 
        external 
        onlyAdmin 
    {
        tokenRegistry.addAgentOnTokenContract(_agent);
    }

    /**
     *  @dev calls the `removeAgentOnTokenContract` function on the tokenRegistry contract
     *  OwnerManager has to be set as owner on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-removeAgentOnTokenContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callRemoveAgentOnTokenContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.removeAgentOnTokenContract(_agent);
    }

    /**
     *  @dev calls the `addAgentOnIdentityRegistryContract` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-addAgentOnIdentityRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callAddAgentOnIdentityRegistryContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().addAgentOnIdentityRegistryContract(_agent);
    }

    /**
     *  @dev calls the `removeAgentOnIdentityRegistryContract` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-removeAgentOnIdentityRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callRemoveAgentOnIdentityRegistryContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().removeAgentOnIdentityRegistryContract(_agent);
    }
}