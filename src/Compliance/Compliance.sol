// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import 'openzeppelin-contracts/contracts/security/Pausable.sol';

import '../../Interface/IEquity.sol';
import '../../Interface/IAccounts.sol';

// TODO require(msg.sender == address(_equity), "Only token contract can call this function"
);

contract Compliance is Pausable, Ownable  {

    ////////////////
    // CONTRACTS
    ////////////////

    // @notice the token on which this compliance contract is applied
    IEquity public _equity;

    // @notice the Identity registry contract linked to `token`
    IAccounts public _accounts;

    ////////////////
    // STATES
    ////////////////

    // @notice Mapping from token id to issuer
    mapping(uint256 => address) public _equityIssuer;
    
    // @notice Mapping from token ID to the limit of holders for this token
    mapping(uint256 => uint256) public _holderLimit;

    // @notice Mapping from token ID to the index of each shareholder in the array `shareholders`
    mapping(uint256 => mapping(address => uint256)) public _holderIndices;

    // @notice Mapping from token ID to the amount of shareholders per country
    mapping(uint256 => mapping(uint16 => uint256)) public _countryShareHolders;

    // @notice Mapping from token ID to the addresses of all shareholders
    mapping(uint256 => address[]) public _shareholders;

    // @notice Mapping of tokens to if it is non-fractional or not 
    mapping(address => bool) public _nonFractional;

    // @notice Mapping of tokens to if it is non-fractional or not 
    mapping(address => uint256) public _equityMinimum;

    // @notice Mapping from token ID to frozen accounts
    mapping(uint256 => mapping(address => bool)) public _frozen;

    // @notice Mapping from token ID to freeze and pause functions
	mapping(uint256 => mapping(address => uint256)) public _frozenEquity;
    
    // @notice Mapping from user address to freeze bool
    mapping(address => bool) public _frozenAll;

    // @notice Mapping from token id to pause
    mapping(uint256 => bool) public _equityPaused;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address token
    ) {
        _equity = IEquity(token);
        _accounts = _equity.identityRegistry();
    }
    
    ////////////////
    // EVENTS
    ////////////////

    event HolderLimitSet(uint256 _holderLimit, uint256 _id);

    ////////////////
    // MODIFIERS
    ////////////////
    
    modifier onlyEquityOrIssuer(
        uint256 id
    ) {
        require(
            msg.sender == address(_equity) || _msgSender() == _equityIssuer[id],
            "Only token contract can call this function"
        );
        _;
    }

    modifier onlyIssuer(
        uint256 id
    ) {
        require(
            _msgSender() == _equityIssuer[id],
            "Only token issuer can call this function"
        );
        _;
    }

    modifier onlyEquity(
        uint256 id
    ) {
        require(
            msg.sender == address(_equity),
            "Only token contract can call this function"
        );
        _;
    }

    //////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////

    // @notice 
    function holderAt(
        uint256 index,
        uint256 id
    )
        external
        view
        returns (address)
    {
        require(index < _shareholders[id].length, "shareholder doesn\"t exist"
    );
        return _shareholders[id][index];
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

    // @notice
    function isNotFrozen(
        address amount,
        uint256 id,
        address from,
        address to
    )
        public
        returns (bool)
    {
        if (!_frozen[id][to] && !_frozen[id][from]) return true;  
        else return false;  
    }

    // @notice
    function hasSufficientBalance(
        address amount,
        uint256 id,
        address from
    )
        public
        returns (bool)

    {
        if (amount <= _equity.balanceOf(from, id) - (_frozenEquity[id][from])) return true;  
        else return false;  
    }
    
    // @notice
    function holderExists(
        uint256 id,
        address to
    )
        public
        returns (bool)

    {
        if (_holderIndices[id][to] != 0) return true;  
        else return false;  
    }
    
    // @notice
    function transferWithinLimit(
        uint256 id
    )
        public
        returns (bool)
    {
        if (shareholders[id].length < _holderLimit[id]) return true;  
        else return false;  
    }

    // @notice sets the holder limit as required for compliance purpose
    function setHolderLimit(
        uint256 holderLimit,
        uint256 id
    )
        external
        onlyIssuer
    {
        _holderLimit[id] = holderLimit;
        emit HolderLimitSet(holderLimit, id);
    }
    
    // TODO, enforce this
    // @notice
    function setMinimum(
        uint256 id,
        uint256 minimumAmount
    )
        external
        // TODO, make this safe...
    {
        _equityMinimum[id] = minimumAmount;
        emit UpdatedEquityInformation(_equityIssuer);
    }

    // @notice
    function togglePause(
        uint256 id
    )
        external
        onlyIssuer 
    {
        if (!_equityPaused[id]) {
            _equityPaused[id] = true;
            emit Paused(_msgSender(), id);
        }
        else if (!_equityPaused[id]) {
            _equityPaused[id] = false;
            emit Unpaused(_msgSender(), id);
        }
    }
    
    // @notice
    function toggleNonFractional(
        uint256 id
    )
        external
        onlyIssuer 
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

    // @notice
    function updateShareholders(
        address account,
        uint256 id
    )
        public
    {
        if (_holderIndices[id][account] == 0) {
            _shareholders[id].push(account);
            _holderIndices[id][account] = _shareholders[id].length;
            uint16 country = _accounts.identityCountry(account);
            _countryShareHolders[id][country]++;
        }
    }

    // @notice
    function pruneShareholders(
        address account,
        uint256 id
    )
        public
    {
        require(_holderIndices[id][account] != 0, "Shareholder does not exist"
    );
        uint256 balance = _equity.balanceOf(account, id);
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = _holderIndices[id][account] - 1;
        uint256 lastIndex = _shareholders[id].length - 1;
        address lastHolder = _shareholders[id][lastIndex];
        _shareholders[id][holderIndex] = lastHolder;
        _holderIndices[id][lastHolder] = _holderIndices[id][account];
        _shareholders[id].pop();
        _holderIndices[id][account] = 0;
        uint16 country = _accounts.identityCountry(account);
        _countryShareHolders[id][country]--;
    }

    // @notice
    function getShareholderCountByCountry(
        uint16 index,
        uint256 id
    )
        external
        view
        returns (uint256)
    {
        return _countryShareHolders[id][index];
    }

    // @notice
    function batchSetAddressFrozen(
        address[] memory accounts,
        uint256[] memory ids,
        bool[] memory freeze
    )
        external
        onlyEquityOrIssuer
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            setAddressFrozen(accounts[i], ids[i], freeze[i]);
        }
    }

    // @notice
    function setAddressFrozen(
        address account,
        uint256 id,
        bool freeze
    )
        public
        onlyEquityOrIssuer 
    {
        _frozen[id][account] = freeze;
        emit AddressFrozen(account, freeze, _msgSender());
    }
    
    // @notice
    function batchFreezePartialEquity(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
    {
        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch"
    );   
        for (uint256 i = 0; i < accounts.length; i++) {
            freezePartialEquity(accounts[i], ids[i], amounts[i]);
        }
    }

    // @notice
    function freezePartialEquity(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        onlyEquityOrIssuer
    {
        require(isNonFractional(amount, id), "Share transfers must be non-fractional"
    );
        uint256 balance = _equity.balanceOf(account, id);
        require(balance >= _frozenEquity[id][account] + amount, "Amount exceeds available balance"
    );
        _frozenEquity[id][account] = _frozenEquity[id][account] + (amount);
        emit EquityFrozen(account, amount);
    }

    // @notice
    function batchUnfreezePartialEquity(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
    {
        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch"
    );
        for (uint256 i = 0; i < accounts.length; i++) {
            unfreezePartialEquity(accounts[i], ids[i], amounts[i]);
        }
    }

    // @notice
    function unfreezePartialEquity(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        onlyEquityOrIssuer 
    {        
        require(isNonFractional(amount, id), "Share transfers must be non-fractional"
    );
        require(_frozenEquity[id][account] >= amount, "Amount should be less than or equal to frozen tokens"
    );
        _frozenEquity[id][account] = _frozenEquity[id][account] - (amount);
        // emit EquityUnfrozen(account, id, amount); TODO update event
    }

    // #TODO what is going on here?
    // @notice
    function canTransfer(
        address to,
        address from,
        uint256 id,
        uint256 amount
    )
        external
        view
        returns (bool)
    {
        require(isNonFractional(amount, id), "Share transfers must be non-fractional"
    );
        require(isNotFrozen(amount, id, from, to), "wallet is frozen"
    );
        require(hasSufficientBalance(amount, id, from), "Insufficient Balance"
    );
        require(holderExists(id, to), "Holder does not exist"
    );
        require(transferWithinLimit(id), "Transfer exceeds holder limit"
    ); 
        
        return true;
    }

    // @notice
    function updateFreeBalance(
        address from,
        uint256 id
    )
        public
    {
        uint256 freeBalance = _equity.balanceOf(from, id) - (_frozenEquity[id][from]);
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenEquity[id][from] = _frozenEquity[id][from] - (tokensToUnfreeze);
            emit EquityUnfrozen(from, tokensToUnfreeze);
        }
    }

    // @notice
    function transferred(
        address from,
        address to,
        uint256 id
    )
        external
    {
        require(msg.sender == address(_equity), "Only token contract can call this function"
    );
        updateFreeBalance(from, id);
        updateShareholders(to, id);
        pruneShareholders(from, id);
    }

    // @notice
    function created(
        address to,
        uint256 id,
        uint256 amount
    )
        external
    {
        require(msg.sender == address(_equity), "Only token contract can call this function"
    );
        require(amount > 0, "No token created"
    );
        updateShareholders(to, id);
    }

    // @notice
    function destroyed(
        address from,
        uint256 id
    )
        external
    {
        require(msg.sender == address(_equity), "Only token contract can call this function"
    );
        updateFreeBalance(from, id);
        pruneShareholders(from, id);
    }

}