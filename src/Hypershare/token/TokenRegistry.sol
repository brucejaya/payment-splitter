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
    // CONTRACTS
    ////////////////

    // @dev Compliance token limit validator contract
    IComplianceLimitHolder internal _complianceLimitHolder;

    // @dev Compliance claims checker contract
    IComplianceClaimsRequired internal _complianceClaimsRequired;
    
    // @dev Identity registry contract
    IIdentityRegistry internal _identityRegistry;

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
        emit ComplianceClaimsRequiredAdded(complianceClaimsRequired_);
        
        _complianceLimitHolder = IComplianceLimitHolder(complianceLimitHolder_);
        emit ComplianceLimitHolderAdded(complianceLimitHolder_);

        _identityRegistry = IIdentityRegistry(identityRegistry_);
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

    ////////////////////////////////////////////////////////////////
    //                        OWNER CONTROLS
    ////////////////////////////////////////////////////////////////

    function preValidateTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    )
        public
        returns (bool)
    {
        require(_complianceClaimsRequired.isVerified(to, id), "Identity is not verified.");
        require(_complianceLimitHolder.canTransfer(to, from, id, amount), "Violates transfer limitations");
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
    //                        SAFE TRANSFER
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
        require(_complianceClaimsRequired.isVerified(to, id), "Identity is not verified.");
        require(_complianceLimitHolder.canTransfer(to, from, id, amount), "Violates transfer limitations");
        _safeTransferFrom(from, to, id, amount, data);
        _complianceLimitHolder.transferred(from, to, id);
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
        require(_complianceLimitHolder.isNonFractional(amount, id), "Share transfers must be non-fractional");
        require(_complianceClaimsRequired.isVerified(to, id), "Transfer not possible");
        safeTransferFrom(from, to, id, amount, data);
        _complianceLimitHolder.transferred(from, to, id);
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
        require(_complianceClaimsRequired.isVerified(to, id), "Identity is not verified.");
        require(_complianceLimitHolder.canTransfer(to, from, id, amount), "Violates transfer limitations");
        
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
        require(_complianceLimitHolder.isNonFractional(amount, id), "Share transfers must be non-fractional");

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
    //                          RECOVERY
    ////////////////////////////////////////////////////////////////

    function recover(
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
        require(balanceOf(lostWallet, id) != 0, "No tokens to recover");
        require(IIdentity(account).keyHasPurpose( keccak256(abi.encode(newWallet)), 1), "key does not have permission");
        _identityRegistry.registerIdentity(newWallet, IIdentity(account), _identityRegistry.identityCountry(lostWallet));
        _identityRegistry.deleteIdentity(lostWallet);
        forcedTransfer(lostWallet, newWallet, id, balanceOf(lostWallet, id), data);
        if (_complianceLimitHolder._frozenTokens[id][lostWallet] > 0) {
            _complianceLimitHolder.freezePartialTokens(newWallet, id, _complianceLimitHolder._frozenTokens[id][lostWallet]);
        }
        if (_complianceLimitHolder._frozen[id][lostWallet] == true) {
            _complianceLimitHolder.setAddressFrozen(newWallet, id, true);
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