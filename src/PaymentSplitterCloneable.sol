//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PaymentSplitterCloneable is Context {
    
    using SafeERC20 for IERC20;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    
    uint256 private _totalShares;
    uint256 private _totalTokenReleased;
    uint256 private _totalEthReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _ethReleased;
    mapping(address => uint256) private _tokenReleased;

    address public paymentToken;
    address[] private _payees;

    constructor() {}

    function initialize(address[] memory payees, uint256[] memory shares_, address _paymentToken) public {
        require(_payees.length == 0, "PaymentSplitterCloneable: already initialized");
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");
        
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
        paymentToken = _paymentToken;
    }

    /**
     * @dev For handling network tokens i.e. matic, eth
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
   
    /**
     * @dev Returns total shares
     */
    function totalShares() public view returns (uint256) { 
        return _totalShares;
    }

    /**
     * @dev Returns the amount of shares by address
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }
    
    /**
     * @dev Returns the address of payee by index
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Returns number of payees
     */
    function numPayees() public view returns(uint) {
        return _payees.length;
    }

    /**
     * @dev Returns the total amount of Eth already released
     */
    function totalEthReleased() public view returns (uint256) {
        return _totalEthReleased;
    }

    /**
     * @dev Returns the total amount of Tokens already released
     */
    function totalTokenReleased() public view returns (uint256) {
        return _totalTokenReleased;
    }

    /**
     * @dev Returns the amount of Eth released to an address
     */
    function ethReleased(address account) public view returns (uint256) {
        return _ethReleased[account];
    }

    /**
     * @dev Returns the amount of tokens released to an address
     */
    function tokenReleased(address account) public view returns (uint256) {
        return _tokenReleased[account];
    }

    /**
     * @dev Returns the eth balance of contract (not necessry but included for simplicity + symmetry)
     */
    function ethBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the amount of Eth released to an address
     */
    function tokenBalance() public view returns (uint256) { 
        return IERC20(paymentToken).balanceOf(address(this));
    }

    /**
     * @dev Releases funds to account nu address
     */
    function release(address payable account) public virtual {
        
        require(_payees.length > 0, "PaymentSplitterCloneable: not initialized");
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 tokenTotalReceived = IERC20(paymentToken).balanceOf(address(this)) + _totalTokenReleased;
        uint256 tokensOwed = (tokenTotalReceived * _shares[account]) / _totalShares - _tokenReleased[account];

        uint256 totalEthReceived = address(this).balance + _totalEthReleased;
        uint256 ethOwed = (totalEthReceived * _shares[account]) / _totalShares - _ethReleased[account];

        if (tokensOwed > 0) { // Release tokens to user
            _tokenReleased[account] = _tokenReleased[account] + tokensOwed;
            _totalTokenReleased = _totalTokenReleased + tokensOwed;

            IERC20(paymentToken).safeTransfer(account, tokensOwed);
            emit PaymentReleased(account, tokensOwed);
        }
        if (ethOwed > 0) { // Release ERC20 to user
            _ethReleased[account] = _ethReleased[account] + ethOwed;
            _totalEthReleased = _totalEthReleased + ethOwed;

            Address.sendValue(account, ethOwed);
            emit PaymentReleased(account, ethOwed);
        }
    }

    /**
     * @dev Appends payee to list of payees
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}
