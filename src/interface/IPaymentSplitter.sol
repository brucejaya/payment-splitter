// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IPaymentSplitter {
    
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(address indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    receive() external payable;
    function totalShares() external view returns (uint256);
    function totalReleased() external view returns (uint256);
    function totalTokensReleased(address token) external view returns (uint256);
    function shares(address account) external view returns (uint256);
    function payeeIndex(uint256 index) external view returns (address);
    function released(address account) external view returns (uint256);
    function releasedTokens(address token, address account) external view returns (uint256);
    function release(address payable account) external;
    function releaseTokens(address token, address account) external;

}