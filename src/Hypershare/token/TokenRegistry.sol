// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';
import 'openzeppelin-contracts/contracts/utils/introspection/ERC165.sol';

// TODO Maybe add a frozen for all function

import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IERC734.sol';
import '../../Interface/IERC735.sol';
import '../../Interface/IIdentity.sol';
import '../../Interface/IHolderTokenRequiredClaims.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IComplianceTokenRegistry.sol';

import './TokenRegistryStorage.sol';
import '../roles/agent/AgentRoleUpgradeable.sol';

contract TokenRegistry is ITokenRegistry, AgentRoleUpgradeable, TokenRegistryStorage, ERC165, IERC1155MetadataURI {

    using Address for address;

    /**
     *  @dev the constructor initiates the token contract
     *  _msgSender() is set automatically as the owner of the smart contract
     *  @param uri_ @dev See {setURI}.
     *  @param _identityRegistry the address of the Identity registry linked to the token
     *  @param _compliance the address of the compliance contract linked to the token
     *  @param _ownerIdentity the address of the Identity of the token
     *  emits an `UpdatedTokenInformation` event
     *  emits an `_identityRegistryAdded` event
     *  emits a `ComplianceAdded` event
     */
    function init(
        string memory uri_,
        address _identityRegistry,
        address _compliance,
        bytes32 _ownerIdentity
    ) public initializer {
        _uri = uri_;
        _tokenIdentity = _ownerIdentity;
        _tokenIdentityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
        _tokenCompliance = IComplianceTokenRegistry(_compliance);
        emit ComplianceAdded(_compliance);
        // emit UpdatedTokenInformation(uri, _tokenIdentity); TODO: update event
        __Ownable_init();
    }

    // @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!_tokenPaused, 'Pausable: paused');
        _;
    }

    // @dev Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(_tokenPaused, 'Pausable: not paused');
        _;
    }


    /**
     *  @dev 
     */
    function totalSupply(uint256 id) external view override returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }


    /**
     *  @dev See {ITokenRegistry-Identity}.
     */
    function Identity() external view override returns (address) {
        return _tokenIdentity;
    }
    
    /**
     *  @dev See {ITokenRegistry-identityRegistry}.
     */
    function identityRegistry() external view override returns (IIdentityRegistry) {
        return _tokenIdentityRegistry;
    }

    /**
     *  @dev See {ITokenRegistry-compliance}.
     */
    function compliance() external view override returns (IComplianceTokenRegistry) {
        return _tokenCompliance;
    }

    /**
     *  @dev See {ITokenRegistry-paused}.
     */
    function paused() external view override returns (bool) {
        return _tokenPaused;
    }
    
    /**
     *  @dev See {ITokenRegistry-Wrapper}.
     */
    function Wrapper(
        uint256 id
    ) external view override returns (address) {
        return _tokenWrapper[id];
    }

    /**
     *  @dev See {ITokenRegistry-isFrozen}.
     */
    function isFrozen(
        address account,
        uint256 id
    ) external view override returns (bool) {
        return _frozen[id][account];
    }

    /**
     *  @dev See {ITokenRegistry-getFrozenTokens}.
     */
    function getFrozenTokens(
        address account,
        uint256 id     
    ) external view override returns (uint256) {
        return _frozenTokens[id][account];
    }
    
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
        string memory uri_
    ) internal virtual {
        _uri = uri_;
    }

    /**
     *  @dev See {ITokenRegistry-setIdentity}.
     */
    function setIdentity(address Identity) external override onlyOwner {
        _tokenIdentity = Identity;
        // emit UpdatedTokenInformation(_tokenIdentity);
    }

    /**
     *  @dev See {ITokenRegistry-pause}.
     */
    function pause() external override onlyAgent whenNotPaused {
        _tokenPaused = true;
        emit Paused(_msgSender());
    }

    /**
     *  @dev See {ITokenRegistry-unpause}.
     */
    function unpause() external override onlyAgent whenPaused {
        _tokenPaused = false;
        emit Unpaused(_msgSender());
    }

    
    /**
     *  @dev See {ITokenRegistry-setidentityRegistry}.
     */
    function setidentityRegistry(address identityRegistry) external override onlyOwner {
        _tokenIdentityRegistry = IIdentityRegistry(identityRegistry);
        emit IdentityRegistryAdded(identityRegistry);
    }

    /**
     *  @dev See {ITokenRegistry-setCompliance}.
     */
    function setCompliance(address compliance) external override onlyOwner {
        _tokenCompliance = IComplianceTokenRegistry(compliance);
        emit ComplianceAdded(compliance);
    }

    
    /**
     *  @dev See {ITokenRegistry-transferOwnershipOnTokenContract}.
     */
    function transferOwnershipOnTokenContract(address newOwner) external override onlyOwner {
        transferOwnership(newOwner);
    }

    /**
     *  @dev See {ITokenRegistry-addAgentOnTokenContract}.
     */
    function addAgentOnTokenContract(address agent) external override {
        addAgent(agent);
    }

    /**
     *  @dev See {ITokenRegistry-removeAgentOnTokenContract}.
     */
    function removeAgentOnTokenContract(address agent) external override {
        removeAgent(agent);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }
    

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(!_frozen[id][to] && !_frozen[id][from], 'wallet is frozen');
        require(amount <= balanceOf(from, id) - (_frozenTokens[id][from]), 'Insufficient Balance');
        if (_tokenIdentityRegistry.isVerified(to) && _tokenCompliance.canTransfer(from, to, id, amount)) { // TODO, add id to the token compliance contracts
            _tokenCompliance.transferred(from, to, id, amount);
            safeTransferFrom(from, to, id, amount, data);
            // approve(from, _msgSender(), allowances[id][from][_msgSender()] - (amount)); // TODO allowances?
        }

        revert('Transfer not possible');
    }
    
    /**
     *  @dev See {ITokenRegistry-forcedTransferFrom}.
     */
    function forcedTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyAgent returns (bool) {
        uint256 freeBalance = balanceOf(from, id) - (_frozenTokens[id][from]);
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenTokens[id][from] = _frozenTokens[id][from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
        if (_tokenIdentityRegistry.isVerified(to)) {
            _tokenCompliance.transferred(from, to, id, amount, data); // TODO update to relect extended fields
            safeTransferFrom(from, to, id, amount, data); // TODO update to relect extended fields
            return true;
        }
        revert('Transfer not possible');
    }


    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();
        
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            
            require(!_frozen[id][to] && !_frozen[id][from], 'wallet is frozen');
            require(amount <= balanceOf(from, id) - (_frozenTokens[id][from]), 'Insufficient Balance');
            if (_tokenIdentityRegistry.isVerified(to) && _tokenCompliance.canTransfer(from, to, id, amount)) { // TODO, add id to the token compliance contracts
                _tokenCompliance.transferred(from, to, id, amount);
                safeTransferFrom(from, to, id, amount, data);
                // approve(from, _msgSender(), allowances[id][from][_msgSender()] - (amount)); // TODO allowances?
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        afterTokenTransfer(operator, from, to, ids, amounts, data);

        doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);    
    }

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
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = asSingletonArray(id);
        uint256[] memory amounts = asSingletonArray(amount);

        beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        afterTokenTransfer(operator, from, to, ids, amounts, data);

        doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     *  @dev See {ITokenRegistry-batchForcedTransfer}.
     */
    function batchForcedTransfer(
        address[] memory fromList,
        address[] memory toList,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes[] memory dataList
    ) external override {
        for (uint256 i = 0; i < fromList.length; i++) {
            address from = fromList[i];
            address to = toList[i];
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            bytes memory data = dataList[i];
            
            forcedTransferFrom(from, to, id, amount, data);
        }
    }


    /**
     *  @dev See {ITokenRegistry-mint}.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyAgent {
        require(_tokenIdentityRegistry.isVerified(to), 'Identity is not verified.');
        require(_tokenCompliance.canTransfer(to, id, amount, data), 'Compliance not followed');
        mint(to, id, amount, data);
        _tokenCompliance.created(to, id, amount, data);
    }


    /**
     *  @dev See {ITokenRegistry-batchMint}.
     */
    function batchMint(
        address[] memory fromList,
        address[] memory toList,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes[] memory dataList
    ) public override onlyAgent {
        for (uint256 i = 0; i < ids.length; ++i) {
            address from = fromList[i];
            address to = toList[i];
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            bytes memory data = dataList[i];
            
            require(_tokenIdentityRegistry.isVerified(to), 'Identity is not verified.');
            require(_tokenCompliance.canTransfer(to, id, amount, data), 'Compliance not followed');
            mint(to, id, amount, data);
            _tokenCompliance.created(to, id, amount, data);
        }
    }


    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = asSingletonArray(id);
        uint256[] memory amounts = asSingletonArray(amount);

        beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }


    /**
     *  @dev See {ITokenRegistry-setAddressFrozen}.
     */
    function setAddressFrozen(
        address account,
        uint256 id,
        bool freeze
    ) public override onlyAgent {
        _frozen[id][account] = freeze;
        emit AddressFrozen(account, freeze, _msgSender());
    }

    
    /**
     *  @dev See {ITokenRegistry-batchSetAddressFrozen}.
     */
    function batchSetAddressFrozen(
        address[] memory accounts,
        uint256[] memory ids,
        bool[] memory freeze
    ) external override {
        for (uint256 i = 0; i < accounts.length; i++) {
            setAddressFrozen(accounts[i], ids[i], freeze[i]);
        }
    }

    /**
     *  @dev See {ITokenRegistry-freezePartialTokens}.
     */
    function freezePartialTokens(
        address account,
        uint256 id,
        uint256 amount
    ) public override onlyAgent {
        uint256 balance = balanceOf(account, id);
        require(balance >= _frozenTokens[id][account] + amount, 'Amount exceeds available balance');
        _frozenTokens[id][account] = _frozenTokens[id][account] + (amount);
        emit TokensFrozen(account, amount);
    }

    /**
     *  @dev See {ITokenRegistry-batchFreezePartialTokens}.
     */
    function batchFreezePartialTokens(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external override {

        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch");
        
        for (uint256 i = 0; i < accounts.length; i++) {
            freezePartialTokens(accounts[i], ids[i], amounts[i]);
        }
    }

    /**
     *  @dev See {ITokenRegistry-unfreezePartialTokens}.
     */
    function unfreezePartialTokens(
        address account,
        uint256 id,
        uint256 amount
    ) public override onlyAgent {
        
        require(_frozenTokens[id][account] >= amount, 'Amount should be less than or equal to frozen tokens');

        _frozenTokens[id][account] = _frozenTokens[id][account] - (amount);
        // emit TokensUnfrozen(account, id, amount); TODO update event
    }

    /**
     *  @dev See {ITokenRegistry-batchUnfreezePartialTokens}.
     */
    function batchUnfreezePartialTokens(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external override {

        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch");

        for (uint256 i = 0; i < accounts.length; i++) {
            unfreezePartialTokens(accounts[i], ids[i], amounts[i]);
        }
    }
    
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
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = asSingletonArray(id);
        uint256[] memory amounts = asSingletonArray(amount);

        beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

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
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }


    /**
     *  @dev See {ITokenRegistry-recoveryAddress}.
     */
    function recoveryAddress(
        address lostWallet,
        address newWallet,
        uint256 id,
        address investorIdentity,
        bytes memory data
    ) external override onlyAgent returns (bool) {
        require(balanceOf(lostWallet, id) != 0, 'no tokens to recover');
        IIdentityRegistry _ownerIdentity = IIdentityRegistry(investorIdentity);
        bytes32 key = keccak256(abi.encode(newWallet));
        if (_ownerIdentity.keyHasPurpose(key, 1)) {
            uint256 investorTokens = balanceOf(lostWallet, id);
            uint256 frozenTokens = _frozenTokens[id][lostWallet];
            _tokenIdentityRegistry.registerIdentity(newWallet, _ownerIdentity, _tokenIdentityRegistry.investorCountry(lostWallet));
            _tokenIdentityRegistry.deleteIdentity(lostWallet);
            forcedTransferFrom(lostWallet, newWallet, id, investorTokens, data);
            if (frozenTokens > 0) {
                freezePartialTokens(newWallet, id, frozenTokens);
            }
            if (_frozen[id][lostWallet] == true) {
                setAddressFrozen(newWallet, id, true);
            }
            emit RecoverySuccess(lostWallet, newWallet, investorIdentity);
            return true;
        }
        revert('Recovery not possible');
    }


    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address account,
        address operator,
        bool approved
    ) internal virtual {
        require(account != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[account][operator] = approved;
        emit ApprovalForAll(account, operator, approved);
    }

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
    ) internal virtual {}

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
    ) internal virtual {}

    function doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
