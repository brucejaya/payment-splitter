// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import 'openzeppelin-contracts/contracts/utils/introspection/ERC165.sol';

import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IIdentity.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IComplianceLimitHolder.sol';

// TODO
// Move extended controls into the Compliance Limit Holder i.e. Freezing, nonFraciontal etc
// See if with extended controls this can all be hooked into a standard ERC-1155

contract TokenRegistry is ITokenRegistry, Context, ERC165, IERC1155MetadataURI, Ownable {

    using Address for address;

    ////////////////
    // STATES
    ////////////////
    
    // @dev Mapping from toke id to account of token isser
    mapping(uint256 => address) internal _tokenIssuer;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // @dev Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // @dev Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;

    // @dev Mapping from token ID to account balances
    mapping(uint256 => uint256) internal _totalSupply;

    // @dev Mapping of tokens to if it is non-fractional or not 
    mapping(address => bool) private _nonFractional;

    // @dev Mapping of tokens to if it is non-fractional or not 
    mapping(address => uint256) private _tokenMinimum;

    // @dev Mapping from token ID to frozen accounts
    mapping(uint256 => mapping(address => bool)) internal _frozen;

    // @dev Mapping from token ID to freeze and pause functions
	mapping(uint256 => mapping(address => uint256)) internal _frozenTokens;
    
    // @dev Mapping from user address to freeze bool
    mapping(address => bool) internal _frozenAll;

    // @dev Mapping from token id to pause
    mapping(uint256 => bool) internal _tokenPaused;

    // @dev Compliance token limit validator contract
    IComplianceLimitHolder internal _complianceLimitHolder;

    // @dev Compliance claims checker contract
    IComplianceClaimsRequired internal _complianceClaimsRequired;
    
    // @dev Identity registry contract
    IIdentityRegistry internal _identityRegistry;
    
    ////////////////
    // CONSTRUCTOR
    ////////////////
    
    constructor(
        string memory uri_,
        address complianceClaimsRequired_,
        address complianceLimitHolder_,
        address identityRegistry_
    ) {
        _uri = uri_;
        _complianceClaimsRequired = IComplianceClaimsRequired(complianceClaimsRequired_);
        _complianceLimitHolder = IComplianceLimitHolder(complianceLimitHolder_);

        _identityRegistry = IIdentityRegistry(identityRegistry_);

        emit ComplianceClaimsRequiredAdded(complianceClaimsRequired_);
        emit ComplianceLimitHolderAdded(complianceLimitHolder_);
        emit IdentityRegistryAdded(identityRegistry_);
    }

    // TODO @dev initialise a new token

    /*
    function init() {
        _tokenIssuer = tokenIssuer;
    } 
    */

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

    ////////////////////////////////////////////////////////////////
    //                        READ FUNCTIONS
    ////////////////////////////////////////////////////////////////

    function totalSupply(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _totalSupply[id];
    }

    function uri(
        uint256
    )
        public 
        view 
        override(ITokenRegistry, IERC1155MetadataURI)
        returns (string memory)
    {
        return _uri;
    }

    function issuer(
        uint256 id
    )
        public
        view
        returns (address)
    {

        return _tokenIssuer[id];
    }
    
    function complianceClaimsRequired()
        public
        view
        returns (IComplianceClaimsRequired)
    {
        return _complianceClaimsRequired;
    }

    function complianceLimitHolder()
        public
        view
        returns (IComplianceLimitHolder)
    {
        return _complianceLimitHolder;
    }

    function identityRegistry()
        public
        view
        returns (IIdentityRegistry)
    {
        return _identityRegistry;
    }

    function paused(
        uint256 id
    )
        public
        view
        returns (bool)
    {
        return _tokenPaused[id];
    }

    function isFrozen(
        address account,
        uint256 id
    )
        public
        view
        returns (bool)
    {
        return _frozen[id][account];
    }

    function getFrozenTokens(
        address account,
        uint256 id     
    )
        public
        view
        returns (uint256)
    {
        return _frozenTokens[id][account];
    }

    // @notice Checks that modulus of the transfer amount is equal to one (with the standard eighteen decimal places) 
    function isNonFractional(
        address amount,
        uint256 id
    )
        public
        returns (bool)
    {
        if (amount % (1 * 10 ** 18) == 0) return true;  
        else return false;  
    }

    ////////////////////////////////////////////////////////////////
    //                        OWNER CONTROLS
    ////////////////////////////////////////////////////////////////

    function setIdentity(
        uint256 id,
        address Identity
    )
        external
        // TODO, make this safe...
    {
        _tokenIssuer[id] = Identity;
        // emit UpdatedTokenInformation(_tokenIssuer);
    }

    // TODO, enforce this
    function setMinimum(
        uint256 id,
        uint256 minimumAmount
    )
        external
        // TODO, make this safe...
    {
        _tokenMinimum[id] = minimumAmount;
        // emit UpdatedTokenInformation(_tokenIssuer);
    }

    function togglePause(
        uint256 id
    )
        external
        onlyIssuer(id) 
    {
        if (!_tokenPaused[id]) {
            _tokenPaused[id] = true;
            emit Paused(_msgSender(), id);
        }
        else if (!_tokenPaused[id]) {
            _tokenPaused[id] = false;
            emit Unpaused(_msgSender(), id);
        }
    }
    
    function toggleNonFractional(
        uint256 id
    )
        external
        onlyIssuer(id) 
    {
        if (!_nonFractional[id]) {
            _nonFractional[id] = true;
            emit Paused(_msgSender(), id);
        }
        else if (_nonFractional[id]) {
            _nonFractional[id] = false;
            emit Unpaused(_msgSender(), id);
        }
    }

    function preValidateTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    )
        public
        returns (bool)
    {
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        require(!_frozen[id][to] && !_frozen[id][from], 'wallet is frozen');
        require(amount <= balanceOf(from, id) - (_frozenTokens[id][from]), 'Insufficient Balance');
        
        require(_complianceClaimsRequired.isVerified(to, id), "Identity has not been verified");
        require(_complianceLimitHolder.canTransfer(to, id), "Exceeds token limits");
        return true;
    }

    ////////////////////////////////////////////////////////////////
    //                         APPROVALS
    ////////////////////////////////////////////////////////////////

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        virtual
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
    ////////////////////////////////////////////////////////////////
    //                             BALANCE
    ////////////////////////////////////////////////////////////////

    function balanceOf(
        address account,
        uint256 id
    )
        public
        view
        virtual
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
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    ////////////////////////////////////////////////////////////////
    //                          SAFE TRANSFER
    ////////////////////////////////////////////////////////////////

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
    {
        address operator = _msgSender();
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for (uint256 i = 0; i < ids.length; ++i) {
            safeTransferFrom(from, to, ids[i], amounts[i], data);
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
        override(ITokenRegistry, IERC1155)
        virtual
    {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        require(!_frozen[id][to] && !_frozen[id][from], 'wallet is frozen');
        require(amount <= balanceOf(from, id) - (_frozenTokens[id][from]), 'Insufficient Balance');
        if (_complianceClaimsRequired.isVerified(to, id) && _complianceLimitHolder.canTransfer(to, id)) {
            _complianceLimitHolder.transferred(from, to, id);
            _safeTransferFrom(from, to, id, amount, data);
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

    ////////////////////////////////////////////////////////////////
    //                        FORCE TRANSFER
    ////////////////////////////////////////////////////////////////

    function batchForcedTransfer(
        address[] memory fromList,
        address[] memory toList,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes[] memory dataList
    )
        external
    {
        require(
            fromList.length == toList.length &&
            toList.length == ids.length &&
            ids.length == amounts.length &&
            amounts.length == dataList.length,
            "ERC1155: ids and amounts length mismatch"
        );
        for (uint256 i = 0; i < fromList.length; i++) {
            forcedTransfer(fromList[i], toList[i], ids[i], amounts[i], dataList[i]);
        }
    }

    function forcedTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        onlyIssuer(id) 
        returns (bool)
    {
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        uint256 freeBalance = balanceOf(from, id) - (_frozenTokens[id][from]);
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenTokens[id][from] = _frozenTokens[id][from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
        require(_complianceClaimsRequired.isVerified(to, id), 'Transfer not possible');
        _complianceLimitHolder.transferred(from, to, id);
        safeTransferFrom(from, to, id, amount, data);
        return true;
    }

    ////////////////////////////////////////////////////////////////
    //                            MINT
    ////////////////////////////////////////////////////////////////

    function mintBatch(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    )
  		external
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
		onlyIssuer(id) 
	{
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        require(_complianceClaimsRequired.isVerified(to, id), 'Identity is not verified.');
        require(_complianceLimitHolder.canTransfer(to, id), 'Compliance not followed');
        
        _mint(to, id, amount, data);
        _complianceLimitHolder.created(to, id, amount);
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

    ////////////////////////////////////////////////////////////////
    //                           BURN
    ////////////////////////////////////////////////////////////////

    function burnBatch(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts
    )
		external
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
        onlyIssuer(id) 
    {
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        uint256 freeBalance = balanceOf(from, id) - _frozenTokens[id][from];
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenTokens[id][from] = _frozenTokens[id][from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
        _burn(from, id, amount);
        _complianceLimitHolder.destroyed(from, id);		
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

    ////////////////////////////////////////////////////////////////
    //                           FREEZE
    ////////////////////////////////////////////////////////////////

    function batchSetAddressFrozen(
        address[] memory accounts,
        uint256[] memory ids,
        bool[] memory freeze
    )
        external
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
        onlyIssuer(id) 
    {
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
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
        onlyIssuer(id) 
    {        
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        require(_frozenTokens[id][account] >= amount, 'Amount should be less than or equal to frozen tokens');
        _frozenTokens[id][account] = _frozenTokens[id][account] - (amount);
        // emit TokensUnfrozen(account, id, amount); TODO update event
    }

    ////////////////////////////////////////////////////////////////
    //                          RECOVERY
    ////////////////////////////////////////////////////////////////

    function recoveryAddress(
        address lostWallet,
        address newWallet,
        uint256 id,
        address account,
        bytes memory data
    )
        external
        onlyIssuer(id) 
        returns (bool)
    {
        require(balanceOf(lostWallet, id) != 0, 'no tokens to recover');
        require(IIdentity(account).keyHasPurpose( keccak256(abi.encode(newWallet)), 1), 'key does not have permission');
        _identityRegistry.registerIdentity(newWallet, IIdentity(account), _identityRegistry.identityCountry(lostWallet));
        _identityRegistry.deleteIdentity(lostWallet);
        forcedTransfer(lostWallet, newWallet, id, balanceOf(lostWallet, id), data);
        if (_frozenTokens[id][lostWallet] > 0) {
            freezePartialTokens(newWallet, id, _frozenTokens[id][lostWallet]);
        }
        if (_frozen[id][lostWallet] == true) {
            setAddressFrozen(newWallet, id, true);
        }
        emit RecoverySuccess(lostWallet, newWallet, account);
        return true;
    }

    ////////////////////////////////////////////////////////////////
    //                            MISC
    ////////////////////////////////////////////////////////////////

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
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

    ////////////////////////////////////////////////////////////////
    //                          HYPERSURFACE
    ////////////////////////////////////////////////////////////////

    function setURI(
        string memory uri_
    )
        public
        onlyOwner
    {
        _uri = uri_;
    }
    
    function setIdentityRegistry(
        address identityRegistry_
    )
        external
        onlyOwner
    {
        _identityRegistry = IIdentityRegistry(identityRegistry_);
        emit IdentityRegistryAdded(identityRegistry_);
    }

    function setComplianceClaimsRequired(
        address complianceClaimsRequired_
    )
        external
        onlyOwner
    {
        _complianceClaimsRequired = IComplianceClaimsRequired(complianceClaimsRequired_);
        emit ComplianceClaimsRequiredAdded(complianceClaimsRequired_);
    }

    function setComplianceLimitHolder(
        address complianceLimitHolder_
    )
        external
        onlyOwner
    {
        _complianceLimitHolder = IComplianceLimitHolder(complianceLimitHolder_);
        emit ComplianceLimitHolderAdded(complianceLimitHolder_);
    }
    
    function transferOwnershipOnTokenContract(
        address newOwner
    )
        external
        onlyOwner
    {
        transferOwnership(newOwner);
    }
    
}