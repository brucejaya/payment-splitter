// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';

contract PaymentSplitterCloneable is Context {
    
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(address indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 internal _totalShares;
    uint256 internal _totalReleased;

    mapping(address => uint256) internal _shares;
    mapping(address => uint256) internal _released;
    
    address[] public _payees;

    mapping(address => uint256) internal _erc20TotalReleased;
    mapping(address => mapping(address => uint256)) internal _erc20Released;

    constructor() {}

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function initialize(
		address[] memory payees,
		uint256[] memory shares_
	)
        public
        payable
    {

        // Iterate through returning balances

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalTokensReleased(address token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function releasedTokens(address token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payeeIndex(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        payable(account).transfer(payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function releaseTokens(address token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = IERC20(token).balanceOf(address(this)) + totalTokensReleased(token);

        uint256 payment = _pendingPayment(account, totalReceived, releasedTokens(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(IERC20(token), account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) internal view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) internal {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    // @notice Return number of payees
    function payeesLength() public view returns (uint256) {
        return _payees.length;
    }

    // @notice Return releasable balance of payee
    function balanceOf(
        address payee
    )
        public
        view
        returns (uint256)
    {
        require(_shares[payee] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(payee, totalReceived, released(payee));
        return payment;
    }

    // @notice Return release token balance of payee
    function balanceOfTokens(
        address token,
        address payee
    )
        public
        view
        returns (uint256)
    {
        require(_shares[payee] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = IERC20(token).balanceOf(address(this)) + totalTokensReleased(token);
        uint256 payment = _pendingPayment(payee, totalReceived, releasedTokens(token, payee));
        return payment;
    }

    // @notice Return the releasable balances of all payees
    function balances() 
        public
        view 
        returns (uint256[] memory)
    {
        // Create uint256 array of size payees.length
        uint256[] memory balances = new uint256[](_payees.length);
        
        // Iterate through returning balances
        for (uint8 i = 0; i < _payees.length; i++) {
            balances[i] = balanceOf(_payees[i]);
        }
        return balances;
    }

    // @notice Return the releaseable balances of all payees tokens
    function balancesTokens(
        address token
    ) 
        public
        view 
        returns (uint256[] memory)
    {
        // Create uint256 array of size payees.length
        uint256[] memory balances = new uint256[](_payees.length);

        // Iterate through returning balances
        for (uint8 i = 0; i < _payees.length; i++) {
            balances[i] = balanceOfTokens(token, _payees[i]);
        }
        return balances;
    }

    // @notice Return payees
    function getPayees()
        public
        view
        returns (address[] memory)
    {
        return _payees;   
    }
}