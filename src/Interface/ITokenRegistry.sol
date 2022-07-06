// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';

import './IIdentityRegistry.sol';
import './IComplianceTokenRegistry.sol';

interface ITokenRegistry is IERC1155 {

    /**
     *  this event is emitted when the token information is updated.
     *  the event is emitted by the token constructor and by the setTokenInformation function
     *  `_newName` is the name of the token
     *  `_newSymbol` is the symbol of the token
     *  `_newDecimals` is the decimals of the token
     *  `_newVersion` is the version of the token, current version is 3.0
     *  `_newIdentity` is the address of the Identity of the token
     */
    event UpdatedTokenInformation(string _newName, string _newSymbol, uint8 _newDecimals, string _newVersion, address _newIdentity);

    /**
     *  this event is emitted when the HolderRegistry has been set for the token
     *  the event is emitted by the token constructor and by the setHolderRegistry function
     *  `_holderRegistry` is the address of the Identity Registry of the token
     */
    event HolderRegistryAdded(address indexed _holderRegistry);

    /**
     *  this event is emitted when the Compliance has been set for the token
     *  the event is emitted by the token constructor and by the setCompliance function
     *  `_compliance` is the address of the Compliance contract of the token
     */
    event ComplianceAdded(address indexed _compliance);

    /**
     *  this event is emitted when an investor successfully recovers his tokens
     *  the event is emitted by the recoveryAddress function
     *  `_lostWallet` is the address of the wallet that the investor lost access to
     *  `_newWallet` is the address of the wallet that the investor provided for the recovery
     *  `_investorIdentity` is the address of the Identity of the investor who asked for a recovery
     */
    event RecoverySuccess(address _lostWallet, address _newWallet, address _investorIdentity);

    /**
     *  this event is emitted when the wallet of an investor is frozen or unfrozen
     *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_isFrozen` is the freezing status of the wallet
     *  if `_isFrozen` equals `true` the wallet is frozen after emission of the event
     *  if `_isFrozen` equals `false` the wallet is unfrozen after emission of the event
     *  `_owner` is the address of the agent who called the function to freeze the wallet
     */
    event AddressFrozen(address indexed _userAddress, bool indexed _isFrozen, address indexed _owner);

    /**
     *  this event is emitted when a certain amount of tokens is frozen on a wallet
     *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are frozen
     */
    event TokensFrozen(address indexed _userAddress, uint256 _amount);

    /**
     *  this event is emitted when a certain amount of tokens is unfrozen on a wallet
     *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are unfrozen
     */
    event TokensUnfrozen(address indexed _userAddress, uint256 _amount);

    /**
     *  this event is emitted when the token is paused
     *  the event is emitted by the pause function
     *  `_userAddress` is the address of the wallet that called the pause function
     */
    event Paused(address _userAddress);

    /**
     *  this event is emitted when the token is unpaused
     *  the event is emitted by the unpause function
     *  `_userAddress` is the address of the wallet that called the unpause function
     */
    event Unpaused(address _userAddress);

    /**
     *  @dev TODO
     */
    function totalSupply(uint256 id) external view override returns (uint256);
    
    /**
     *  @dev See {ITokenRegistry-Identity}.
     */
    function Identity() external view override returns (address);
    /**
     *  @dev See {ITokenRegistry-version}.
     */
    function version() external view override returns (string memory);
    
    /**
     *  @dev See {ITokenRegistry-holderRegistry}.
     */
    function holderRegistry() external view override returns (IIdentityRegistry);
    /**
     *  @dev See {ITokenRegistry-compliance}.
     */
    function compliance() external view override returns (IComplianceTokenRegistry);
    /**
     *  @dev See {ITokenRegistry-paused}.
     */
    function paused() external view override returns (bool);
    
    /**
     *  @dev See {ITokenRegistry-Wrapper}.
     */
    function Wrapper(
        uint256 id
    ) external view override returns (address);

    /**
     *  @dev See {ITokenRegistry-isFrozen}.
     */
    function isFrozen(
        address account,
        uint256 id
    ) external view override returns (bool);

    /**
     *  @dev See {ITokenRegistry-getFrozenTokens}.
     */
    function getFrozenTokens(
        address account,
        uint256 id     
    ) external view override returns (uint256);
    
    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function setURI(
        string memory uri
    ) internal virtual;
    /**
     *  @dev See {ITokenRegistry-setIdentity}.
     */
    function setIdentity(address Identity) external override;

    /**
     *  @dev See {ITokenRegistry-pause}.
     */
    function pause() external override;
    /**
     *  @dev See {ITokenRegistry-unpause}.
     */
    function unpause() external override;
    
    /**
     *  @dev See {ITokenRegistry-setHolderRegistry}.
     */
    function setHolderRegistry(address holderRegistryAddress) external override;

    /**
     *  @dev See {ITokenRegistry-setCompliance}.
     */
    function setCompliance(address complianceAddress) external override;
    
    /**
     *  @dev See {ITokenRegistry-transferOwnershipOnTokenContract}.
     */
    function transferOwnershipOnTokenContract(address newOwner) external override;

    /**
     *  @dev See {ITokenRegistry-addAgentOnTokenContract}.
     */
    function addAgentOnTokenContract(address agent) external override;

    /**
     *  @dev See {ITokenRegistry-removeAgentOnTokenContract}.
     */
    function removeAgentOnTokenContract(address agent) external override;

    /**
     *  @dev See {ITokenRegistry-forcedTransferFrom}.
     */
    function forcedTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual;

    /**
     *  @dev See {ITokenRegistry-batchForcedTransfer}.
     */
    function batchForcedTransfer(
        address[] memory fromList,
        address[] memory toList,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes[] memory dataList
    ) external override;


    /**
     *  @dev See {ITokenRegistry-mint}.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override;

    /**
     *  @dev See {ITokenRegistry-batchMint}.
     */
    function batchMint(
        address[] memory fromList,
        address[] memory toList,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes[] memory dataList
    ) public override;


    /**
     *  @dev See {ITokenRegistry-setAddressFrozen}.
     */
    function setAddressFrozen(
        address account,
        uint256 id,
        bool freeze
    ) public override;

    
    /**
     *  @dev See {ITokenRegistry-batchSetAddressFrozen}.
     */
    function batchSetAddressFrozen(
        address[] memory accounts,
        uint256[] memory ids,
        bool[] memory freeze
    ) external override;

    /**
     *  @dev See {ITokenRegistry-freezePartialTokens}.
     */
    function freezePartialTokens(
        address account,
        uint256 id,
        uint256 amount
    ) public override;
    /**
     *  @dev See {ITokenRegistry-batchFreezePartialTokens}.
     */
    function batchFreezePartialTokens(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external override;

    /**
     *  @dev See {ITokenRegistry-unfreezePartialTokens}.
     */
    function unfreezePartialTokens(
        address account,
        uint256 id,
        uint256 amount
    ) public override;

    /**
     *  @dev See {ITokenRegistry-batchUnfreezePartialTokens}.
     */
    function batchUnfreezePartialTokens(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external override;
    
    // -------------------------------------------------------------------------------------------------------------done
    // -------------------------------------------------------------------------------------------------------------done
    // -------------------------------------------------------------------------------------------------------------done
    // -------------------------------------------------------------------------------------------------------------done



    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual;
    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual;


    /**
     *  @dev See {ITokenRegistry-recoveryAddress}.
     */
    function recoveryAddress(
        address lostWallet,
        address newWallet,
        uint256 id,
        address investorIdentity,
        bytes memory data
    ) external override returns (bool);


    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address account,
        address operator,
        bool approved
    ) internal virtual;

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual;

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual;

    function doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private;

    function doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private;

    function asSingletonArray(uint256 element) private pure returns (uint256[] memory);
}
