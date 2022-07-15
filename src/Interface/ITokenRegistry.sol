// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';

import './IIdentityRegistry.sol';
import './ICompliance.sol';

interface ITokenRegistry is IERC1155 {

    /**
     *  this event is emitted when the token information is updated.
     *  the event is emitted by the token constructor and by the setTokenInformation function
     *  `newName` is the name of the token
     *  `newSymbol` is the symbol of the token
     *  `newDecimals` is the decimals of the token
     *  `newVersion` is the version of the token, current version is 3.0
     *  `newIdentity` is the address of the Identity of the token
     */
    event UpdatedTokenInformation(string newName, string newSymbol, uint8 newDecimals, string newVersion, address newIdentity);

    /**
     *  this event is emitted when the IdentityRegistry has been set for the token
     *  the event is emitted by the token constructor and by the setIdentityRegistry function
     *  `identityRegistry` is the address of the Identity Registry of the token
     */
    event IdentityRegistryAdded(address indexed identityRegistry);

    /**
     *  this event is emitted when the Compliance has been set for the token
     *  the event is emitted by the token constructor and by the setCompliance function
     *  `compliance` is the address of the Compliance contract of the token
     */
    event ComplianceAdded(address indexed compliance);

    /**
     *  this event is emitted when an holder successfully recovers his tokens
     *  the event is emitted by the recoveryAddress function
     *  `lostWallet` is the address of the wallet that the holder lost access to
     *  `newWallet` is the address of the wallet that the holder provided for the recovery
     *  `holderIdentity` is the address of the Identity of the holder who asked for a recovery
     */
    event RecoverySuccess(address lostWallet, address newWallet, address holderIdentity);

    /**
     *  this event is emitted when the wallet of an holder is frozen or unfrozen
     *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
     *  `account` is the wallet of the holder that is concerned by the freezing status
     *  `isFrozen` is the freezing status of the wallet
     *  if `isFrozen` equals `true` the wallet is frozen after emission of the event
     *  if `isFrozen` equals `false` the wallet is unfrozen after emission of the event
     *  `owner` is the address of the agent who called the function to freeze the wallet
     */
    event AddressFrozen(address indexed account, bool indexed isFrozen, address indexed owner);

    /**
     *  this event is emitted when a certain amount of tokens is frozen on a wallet
     *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
     *  `account` is the wallet of the holder that is concerned by the freezing status
     *  `amount` is the amount of tokens that are frozen
     */
    event TokensFrozen(address indexed account, uint256 amount);

    /**
     *  this event is emitted when a certain amount of tokens is unfrozen on a wallet
     *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
     *  `account` is the wallet of the holder that is concerned by the freezing status
     *  `amount` is the amount of tokens that are unfrozen
     */
    event TokensUnfrozen(address indexed account, uint256 amount);

    /**
     *  this event is emitted when the token is paused
     *  the event is emitted by the pause function
     *  `account` is the address of the wallet that called the pause function
     *  `id` The token id
     */
    event Paused(address account, uint256 id);

    /**
     *  this event is emitted when the token is unpaused
     *  the event is emitted by the unpause function
     *  `account` is the address of the wallet that called the unpause function
     *  `id` The token id
     */
    event Unpaused(address account, uint256 id);

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply(uint256 id) external view override returns (uint256);
    
    /**
     * @dev Returns the address of the Hyperbase identity of the token.
     * The Hyperbase of the token gives all the information available
     * about the token and is managed by the token issuer or his agent.
     */
    function Identity() external view override returns (address);

    /**
     *  @dev Returns the Identity Registry linked to the token
     */
    function identityRegistry() external view override returns (IIdentityRegistry);

    /**
     *  @dev Returns the Identity Registry linked to the token
     */
    function compliance() external view override returns (ICompliance);
  
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(uint256 id) external view override returns (bool);
    
    /**
     *  @dev Returns the freezing status of a wallet
     *  if isFrozen returns `true` the wallet is frozen
     *  if isFrozen returns `false` the wallet is not frozen
     *  isFrozen returning `true` doesn't mean that the balance is free, tokens could be blocked by
     *  a partial freeze or the whole token could be blocked by pause
     *  @param account the address of the wallet on which isFrozen is called
     *  @param id the id of the token
     */
    function isFrozen(address account, uint256 id) external view override returns (bool);

    /**
     *  @dev Returns the amount of tokens that are partially frozen on a wallet
     *  the amount of frozen tokens is always <= to the total balance of the wallet
     *  @param account the address of the wallet on which getFrozenTokens is called
     *  @param id the id of the token
     */
    function getFrozenTokens(address account, uint256 id) external view override returns (uint256);
    
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
    function setURI(string memory uri) external;

    /**
     *  TODO
     *  @dev See {ITokenRegistry-setIdentity}.
     */
    function setIdentity(address Identity) external override;

    /**
     *  @dev pauses the token contract, when contract is paused investors cannot transfer tokens anymore
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `Paused` event
     */
    function pause(uint256 id) external;

    /**
     *  @dev unpauses the token contract, when contract is unpaused investors can transfer tokens
     *  if their wallet is not blocked & if the amount to transfer is <= to the amount of free tokens
     *  This function can only be called by a wallet set as agent of the token
     *  emits an `Unpaused` event
     */
    function unpause(uint256 id) external;

    /**
     *  @dev sets the Identity Registry for the token
     *  @param identityRegistry the address of the Identity Registry to set
     *  Only the owner of the token smart contract can call this function
     *  emits an `IdentityRegistryAdded` event
     */
    function setIdentityRegistry(address identityRegistry) external override;

    /**
     *  @dev sets the compliance contract of the token
     *  @param complianceAddress the address of the compliance contract to set
     *  Only the owner of the token smart contract can call this function
     *  emits a `ComplianceAdded` event
     */
    function setCompliance(address complianceAddress) external override;
    
    /**
     *  @dev transfers the ownership of the token smart contract
     *  @param newOwner the address of the new token smart contract owner
     *  This function can only be called by the owner of the token
     *  emits an `OwnershipTransferred` event
     */
    function transferOwnershipOnTokenContract(address newOwner) external;
    
    /**
     *  @dev adds an agent to the token smart contract
     *  @param agent the address of the new agent of the token smart contract
     *  This function can only be called by the owner of the token
     *  emits an `AgentAdded` event
     */
    function addAgentOnTokenContract(address agent) external;

    /**
     *  @dev remove an agent from the token smart contract
     *  @param agent the address of the agent to remove
     *  This function can only be called by the owner of the token
     *  emits an `AgentRemoved` event
     */
    function removeAgentOnTokenContract(address agent) external;

    /**
     *  @dev force a transfer of tokens between 2 whitelisted wallets
     *  In case the `from` address has not enough free tokens (unfrozen tokens)
     *  but has a total balance higher or equal to the `amount`
     *  the amount of frozen tokens is reduced in order to have enough free tokens
     *  to proceed the transfer, in such a case, the remaining balance on the `from`
     *  account is 100% composed of frozen tokens post-transfer.
     *  Require that the `to` address is a verified address,
     *  @param from The address of the sender
     *  @param to The address of the receiver
     *  @param amount The number of tokens to transfer
     *  @return `true` if successful and revert if unsuccessful
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event if `amount` is higher than the free balance of `_from`
     *  emits a `Transfer` event
     */
    function forcedTransfer(address from, address to, uint256 id, uint256 amount, bytes memory data) external returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    /**
     *  @dev function allowing to issue forced transfers in batch
     *  Require that `amounts[i]` should not exceed available balance of `_fromList[i]`.
     *  Require that the `_toList` addresses are all verified addresses
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_fromList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param fromList The addresses of the senders
     *  @param toList The addresses of the receivers
     *  @param ids The token ids
     *  @param amounts The number of tokens to transfer to the corresponding receiver
     *  This function can only be called by a wallet set as agent of the token
     *  emits `TokensUnfrozen` events if `amounts[i]` is higher than the free balance of `_fromList[i]`
     *  emits _fromList.length `Transfer` events
     */
    function batchForcedTransfer(address[] memory fromList, address[] memory toList, uint256[] memory ids, uint256[] memory amounts, bytes[] memory dataList) external override;


    /**
     *  @dev mint tokens on a wallet
     *  Improved version of default mint method. Tokens can be minted
     *  to an address if only it is a verified address as per the security token.
     *  @param to Address to mint the tokens to.
     *  @param id Token id.
     *  @param amount Amount of tokens to mint.
     *  @param data Data field
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `Transfer` event
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

 
    /**
     *  @dev function allowing to mint tokens in batch
     *  Require that the `_toList` addresses are all verified addresses
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param accounts The addresses of the receivers
     *  @param ids The token ids
     *  @param amounts The number of tokens to mint to the corresponding receiver
     *  @param data of the corresponding data
     *  This function can only be called by a wallet set as agent of the token
     *  emits _toList.length `Transfer` events
     */
    function mintBatch(address[] memory accounts, uint256 id, uint256[] memory amounts, bytes memory data) external;


    /**
     *  this event is emitted when the wallet of an investor is frozen or unfrozen
     *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
     *  `userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `isFrozen` is the freezing status of the wallet
     *  if `isFrozen` equals `true` the wallet is frozen after emission of the event
     *  if `isFrozen` equals `false` the wallet is unfrozen after emission of the event
     *  `owner` is the address of the agent who called the function to freeze the wallet
     */
    function setAddressFrozen(address account, uint256 id, bool freeze) external;


    /**
     *  @dev function allowing to set frozen addresses in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `accounts.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param accounts The addresses for which to update frozen status
     *  @param ids The ids of the tokens to freeze
     *  @param freeze Frozen status of the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits accounts.length `AddressFrozen` events
     */
    function batchSetAddressFrozen(address[] memory accounts, uint256[] memory ids, bool[] memory freeze) external override;

  
    /**
     *  this event is emitted when a certain amount of tokens is frozen on a wallet
     *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
     *  `userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `amount` is the amount of tokens that are frozen
     */
    function freezePartialTokens(address account, uint256 id, uint256 amount) external;


    /**
     *  @dev function allowing to freeze tokens partially in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `accounts.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param accounts The addresses on which tokens need to be frozen
     *  @param ids  of tokens to freeze on the corresponding address
     *  @param amounts the amount of tokens to freeze on the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits accounts.length `TokensFrozen` events
     */
    function batchFreezePartialTokens(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external override;


    /**
     *  this event is emitted when a certain amount of tokens is unfrozen on a wallet
     *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
     *  `userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `amount` is the amount of tokens that are unfrozen
     */
    function unfreezePartialTokens(address account, uint256 id, uint256 amount) external;


    /**
     *  @dev function allowing to unfreeze tokens partially in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `accounts.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param accounts The addresses on which tokens need to be unfrozen
     *  @param ids the amount of tokens to unfreeze on the corresponding address
     *  @param amounts the amount of tokens to unfreeze on the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits accounts.length `TokensUnfrozen` events
     */
    function batchUnfreezePartialTokens(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external override;
    
    // TODO
    function burn(address from, uint256 id, uint256 amount) external;
    
    // TODO
    function burnBatch(address[] memory accounts, uint256 id, uint256[] memory amounts) external;

    // TODO
    function recoveryAddress(address lostWallet, address newWallet, uint256 id, address holderIdentity, bytes memory data) external override returns (bool);

}
