// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';
import 'openzeppelin-contracts/contracts/utils/introspection/ERC165.sol';

import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IERC734.sol';
import '../../Interface/IERC735.sol';
import '../../Interface/IIdentity.sol';
import '../../Interface/IIdentityRegistry.sol';
// import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IComplianceLimitHolder.sol';

import './TokenRegistryStorage.sol';
import '../../Role/agent/AgentRoleUpgradeable.sol';

contract TokenRegistry is ITokenRegistry, AgentRoleUpgradeable, TokenRegistryStorage, ERC165, IERC1155MetadataURI {

    using Address for address;
    function init(
        string memory uri_,
        address identityRegistry_,
        address compliance_,
        address agentIdentity_
    ) public initializer {
        _uri = uri_;
        _tokenIdentity = agentIdentity_;
        _identityRegistry = IIdentityRegistry(identityRegistry_);
        emit IdentityRegistryAdded(identityRegistry_);
        _compliance = ICompliance(compliance_);
        emit ComplianceAdded(compliance_);

        // emit UpdatedTokenInformation(uri, _tokenIdentity); TODO: update event
        __Ownable_init();
    }

    ////////////////
    // MODIFIERS
    ////////////////

    modifier whenNotPaused(
        uint256 id
    ) {
        require(!_tokenPaused[id], 'Pausable: paused');
        _;
    }

    modifier whenPaused(
        uint256 id
    ) {
        require(_tokenPaused[id], 'Pausable: not paused');
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function totalSupply(uint256 id) external view override returns (uint256) {
        return _totalSupply[id];
    }

    function uri(
        uint256 id
    ) 
        external 
        view 
        returns (string memory)
    {
        return _uri;
    }

    function identity()
        external
        view
        override
        returns (address)
    {
        return _tokenIdentity;
    }
    
    function identityRegistry()
        external
        view
        override
        returns (IIdentityRegistry)
    {
        return _identityRegistry;
    }

    function compliance()
        external
        view
        override
        returns (ICompliance)
    {
        return _compliance;
    }

    function paused(
        uint256 id
    )
        external
        view
        override
        returns (bool)
    {
        return _tokenPaused[id];
    }

    function isFrozen(
        address account,
        uint256 id
    )
        external
        view
        override
        returns (bool)
    {
        return _frozen[id][account];
    }

    function getFrozenTokens(
        address account,
        uint256 id     
    )
        external
        view
        override
        returns (uint256)
    {
        return _frozenTokens[id][account];
    }

    /*//////////////////////////////////////////////////////////////
                             OWNER CONTROLS
    //////////////////////////////////////////////////////////////*/

    function setURI(
        string memory uri_
    )
        public
        onlyOwner
    {
        _uri = uri_;
    }

    function setIdentity(
        address Identity
    )
        external
        override
        onlyOwner
    {
        _tokenIdentity = Identity;
        // emit UpdatedTokenInformation(_tokenIdentity);
    }

    function pause(
        uint256 id
    )
        external
        override
        onlyAgent
        whenNotPaused(id)
    {
        _tokenPaused[id] = true;
        emit Paused(_msgSender(), id);
    }

    function unpause(
        uint256 id
    )
        external
        override
        onlyAgent
        whenPaused(id)
    {
        _tokenPaused[id] = false;
        emit Unpaused(_msgSender(), id);
    }

    
    function setIdentityRegistry(
        address identityRegistry
    )
        external
        override
        onlyOwner
    {
        _identityRegistry = IIdentityRegistry(identityRegistry);
        emit IdentityRegistryAdded(identityRegistry);
    }

    function setCompliance(
        address compliance
    )
        external
        override
        onlyOwner
    {
        _compliance = ICompliance(compliance);
        emit ComplianceAdded(compliance);
    }

    
    function transferOwnershipOnTokenContract(
        address newOwner
    )
        external
        override
        onlyOwner
    {
        transferOwnership(newOwner);
    }

    function addAgentOnTokenContract(
        address agent
    )
        external
        override
    {
        addAgent(agent);
    }

    function removeAgentOnTokenContract(
        address agent
    )
        external
        override
    {
        removeAgent(agent);
    }

    /*//////////////////////////////////////////////////////////////
                                 BALANCE
    //////////////////////////////////////////////////////////////*/

    function balanceOf(
        address account,
        uint256 id
    )
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }
    
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /*//////////////////////////////////////////////////////////////
                                 APPROVALS
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    )
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }
    
    function _setApprovalForAll(
        address account,
        address operator,
        bool approved
    )
        internal
        virtual
    {
        require(account != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[account][operator] = approved;
        emit ApprovalForAll(account, operator, approved);
    }

    /*//////////////////////////////////////////////////////////////
                                SAFE TRANSFER
    //////////////////////////////////////////////////////////////*/

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
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
            if (_identityRegistry.isVerified(to) && _compliance.canTransfer(to, id, amount, data)) { // TODO, add id to the token compliance contracts
                _compliance.transferred(from, to, id, amount, data);
                safeTransferFrom(from, to, id, amount, data);
                // approve(from, _msgSender(), allowances[id][from][_msgSender()] - (amount)); // TODO allowances?
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        afterTokenTransfer(operator, from, to, ids, amounts, data);

        doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);    
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(!_frozen[id][to] && !_frozen[id][from], 'wallet is frozen');
        require(amount <= balanceOf(from, id) - (_frozenTokens[id][from]), 'Insufficient Balance');
        if (_identityRegistry.isVerified(to) && _compliance.canTransfer(to, id, amount, data)) {
            _compliance.transferred(from, to, id, amount, data);
            _safeTransferFrom(from, to, id, amount, data);
            // approve(from, _msgSender(), allowances[id][from][_msgSender()] - (amount)); // TODO allowances?
        }

        revert('Transfer not possible');
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        internal
        virtual
    {
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

    /*//////////////////////////////////////////////////////////////
                              FORCE TRANSFER
    //////////////////////////////////////////////////////////////*/

    function forcedTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        override
        onlyAgent
        returns (bool)
    {
        uint256 freeBalance = balanceOf(from, id) - (_frozenTokens[id][from]);
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenTokens[id][from] = _frozenTokens[id][from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
        if (_identityRegistry.isVerified(to)) {
            _compliance.transferred(from, to, id, amount, data); // TODO update to relect extended fields
            safeTransferFrom(from, to, id, amount, data); // TODO update to relect extended fields
            return true;
        }
        revert('Transfer not possible');
    }

    function batchForcedTransfer(
        address[] memory fromList,
        address[] memory toList,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes[] memory dataList
    )
        external
        override
    {
        for (uint256 i = 0; i < fromList.length; i++) {
            address from = fromList[i];
            address to = toList[i];
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            bytes memory data = dataList[i];
            
            forcedTransfer(from, to, id, amount, data);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 MINT
    //////////////////////////////////////////////////////////////*/

    function mintBatch(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    )
  		external
  		override
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            mint(accounts[i], id, amounts[i], data);
        }
    }

    function mintMisc(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
  		external
  		override
    {
        for (uint256 i = 0; i < amounts.length; ++i) {
            burn(to, ids[i], amounts[i]);
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
	)
		public
		override
		onlyAgent
	{
        require(_identityRegistry.isVerified(to), 'Identity is not verified.');
        require(_compliance.canTransfer(to, id, amount, data), 'Compliance not followed');
        
        _mint(to, id, amount, data);
        _compliance.created(to, id, amount, data);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        internal
        virtual
    {
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

    /*//////////////////////////////////////////////////////////////
                                 BURN
    //////////////////////////////////////////////////////////////*/

    function burnBatch(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts
    )
		external
		override 
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            burn(accounts[i], id, amounts[i]);
        }
    }

    function burnMisc(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    )
		external
		override 
    {
        for (uint256 i = 0; i < amounts.length; ++i) {
            burn(from, ids[i], amounts[i]);
        }
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    )
        public
        override
        onlyAgent
    {
        uint256 freeBalance = balanceOf(from, id) - _frozenTokens[id][from];
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenTokens[id][from] = _frozenTokens[id][from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
        _burn(from, id, amount);
        _compliance.destroyed(from, id, amount);		
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    )
		internal
		virtual
	{
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

    /*//////////////////////////////////////////////////////////////
                                 FREEZE
    //////////////////////////////////////////////////////////////*/

    function batchSetAddressFrozen(
        address[] memory accounts,
        uint256[] memory ids,
        bool[] memory freeze
    )
        external
        override
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            setAddressFrozen(accounts[i], ids[i], freeze[i]);
        }
    }

    function setAddressFrozen(
        address account,
        uint256 id,
        bool freeze
    )
        public
        override
        onlyAgent
    {
        _frozen[id][account] = freeze;
        emit AddressFrozen(account, freeze, _msgSender());
    }
    
    function batchFreezePartialTokens(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
        override
    {

        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch");
        
        for (uint256 i = 0; i < accounts.length; i++) {
            freezePartialTokens(accounts[i], ids[i], amounts[i]);
        }
    }

    function freezePartialTokens(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        override
        onlyAgent
    {
        uint256 balance = balanceOf(account, id);
        require(balance >= _frozenTokens[id][account] + amount, 'Amount exceeds available balance');
        _frozenTokens[id][account] = _frozenTokens[id][account] + (amount);
        emit TokensFrozen(account, amount);
    }

    function batchUnfreezePartialTokens(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
        override
    {

        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch");

        for (uint256 i = 0; i < accounts.length; i++) {
            unfreezePartialTokens(accounts[i], ids[i], amounts[i]);
        }
    }

    function unfreezePartialTokens(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        override
        onlyAgent
    {
        
        require(_frozenTokens[id][account] >= amount, 'Amount should be less than or equal to frozen tokens');

        _frozenTokens[id][account] = _frozenTokens[id][account] - (amount);
        // emit TokensUnfrozen(account, id, amount); TODO update event
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/

    function recoveryAddress(
        address lostWallet,
        address newWallet,
        uint256 id,
        address account,
        bytes memory data
    )
        external
        override
        onlyAgent
        returns (bool)
    {
        require(balanceOf(lostWallet, id) != 0, 'no tokens to recover');
        IIdentity _holderIdentity = IIdentity(account);
        bytes32 key = keccak256(abi.encode(newWallet));
        if (_holderIdentity.keyHasPurpose(key, 1)) {
            uint256 holderTokens = balanceOf(lostWallet, id);
            uint256 frozenTokens = _frozenTokens[id][lostWallet];
            _identityRegistry.registerIdentity(newWallet, _holderIdentity, _identityRegistry.holderCountry(lostWallet));
            _identityRegistry.deleteIdentity(lostWallet);
            forcedTransfer(lostWallet, newWallet, id, holderTokens, data);
            if (frozenTokens > 0) {
                freezePartialTokens(newWallet, id, frozenTokens);
            }
            if (_frozen[id][lostWallet] == true) {
                setAddressFrozen(newWallet, id, true);
            }
            emit RecoverySuccess(lostWallet, newWallet, account);
            return true;
        }
        revert('Recovery not possible');
    }

    /*//////////////////////////////////////////////////////////////
                                MISC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}


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
    )
        private
    {
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
    )
        private
    {
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

    function asSingletonArray(
        uint256 element
    )
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
