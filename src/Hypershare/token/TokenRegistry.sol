// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import 'openzeppelin-contracts/contracts/utils/introspection/ERC165.sol';

import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';

import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IIdentity.sol';
import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IComplianceLimitHolder.sol';

import './TokenRegistryStorage.sol';

// TODO is ownable and deployed per organisation or is _operatorApprovals ???

contract TokenRegistry is ITokenRegistry, TokenRegistryStorage, ERC165, IERC1155MetadataURI {

    using Address for address;

    function init(
        string memory uri_,
        address complianceClaimsRequired_,
        address compliance_,
        address agentIdentity_
    ) public initializer {
        _uri = uri_;
        _tokenIssuer = agentIdentity_;
        _complianceClaimsRequired = IComplianceClaimsRequired(complianceClaimsRequired_);
        _complianceLimitHolder = IComplianceLimitHolder(compliance_);
        emit ComplianceClaimsRequiredAdded(complianceClaimsRequired_);
        emit ComplianceAdded(compliance_);
    }

    ////////////////
    // MODIFIERS
    ////////////////

    modifier onlyIssuer(
        uint256 id
    ) {
        require(_msgSender() == _tokenIssuer[id], 'Only token issuer can call this function');
        _;
    }

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

    function totalSupply(
        uint256 id
    )
        external
        view
        override
        returns (uint256)
    {
        return _totalSupply[id];
    }

    function uri() 
        external 
        view 
        returns (string memory)
    {
        return _uri;
    }

    function issuer(
        uint256 id
    )
        external
        view
        override
        returns (address)
    {
        return _tokenIssuer;
    }
    
    function complianceClaimsRequired()
        external
        view
        override
        returns (IComplianceClaimsRequired)
    {
        return _complianceClaimsRequired;
    }

    function compliance()
        external
        view
        override
        returns (IComplianceLimitHolder)
    {
        return _complianceLimitHolder;
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
        _tokenIssuer = Identity;
        // emit UpdatedTokenInformation(_tokenIssuer);
    }

    function pause(
        uint256 id
    )
        external
        override
        onlyIssuer(id) 
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
        onlyIssuer(id) 
        whenPaused(id)
    {
        _tokenPaused[id] = false;
        emit Unpaused(_msgSender(), id);
    }

    function setComplianceClaimsRequired(
        address complianceClaimsRequired
    )
        external
        override
        onlyOwner
    {
        _complianceClaimsRequired = IComplianceClaimsRequired(complianceClaimsRequired);
        emit ComplianceClaimsRequiredAdded(complianceClaimsRequired);
    }

    function setCompliance(
        address compliance
    )
        external
        override
        onlyOwner
    {
        _complianceLimitHolder = IComplianceLimitHolder(compliance);
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
            if (_complianceClaimsRequired.isVerified(to, id) && _complianceLimitHolder.canTransfer(to, id, amount, data)) {
                _complianceLimitHolder.transferred(from, to, id, amount, data);
                safeTransferFrom(from, to, id, amount, data);
                // TODO allowances?
                // approve(from, _msgSender(), allowances[id][from][_msgSender()] - (amount));
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
        if (_complianceClaimsRequired.isVerified(to, id) && _complianceLimitHolder.canTransfer(to, id, amount, data)) {
            _complianceLimitHolder.transferred(from, to, id, amount, data);
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
        onlyIssuer(id) 
        returns (bool)
    {
        uint256 freeBalance = balanceOf(from, id) - (_frozenTokens[id][from]);
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenTokens[id][from] = _frozenTokens[id][from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
        if (_complianceClaimsRequired.isVerified(to, id)) {
            _complianceLimitHolder.transferred(from, to, id, amount, data); // TODO update to relect extended fields
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

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
	)
		public
		override
		onlyIssuer(id) 
	{
        require(_complianceClaimsRequired.isVerified(to, id), 'Identity is not verified.');
        require(_complianceLimitHolder.canTransfer(to, id, amount, data), 'Compliance not followed');
        
        _mint(to, id, amount, data);
        _complianceLimitHolder.created(to, id, amount, data);
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


    function burn(
        address from,
        uint256 id,
        uint256 amount
    )
        public
        override
        onlyIssuer(id) 
    {
        uint256 freeBalance = balanceOf(from, id) - _frozenTokens[id][from];
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenTokens[id][from] = _frozenTokens[id][from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
        _burn(from, id, amount);
        _complianceLimitHolder.destroyed(from, id, amount);		
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
        onlyIssuer(id) 
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
        onlyIssuer(id) 
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
        onlyIssuer(id) 
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
        onlyIssuer(id) 
        returns (bool)
    {
        require(balanceOf(lostWallet, id) != 0, 'no tokens to recover');
        IIdentity _holderIdentity = IIdentity(account);
        bytes32 key = keccak256(abi.encode(newWallet));
        if (_holderIdentity.keyHasPurpose(key, 1)) {
            uint256 holderTokens = balanceOf(lostWallet, id);
            uint256 frozenTokens = _frozenTokens[id][lostWallet];
            _complianceClaimsRequired.registerIdentity(newWallet, _holderIdentity, _complianceClaimsRequired.identityCountry(lostWallet));
            _complianceClaimsRequired.deleteIdentity(lostWallet);
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
