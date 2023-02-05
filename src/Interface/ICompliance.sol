// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface ICompliance {

    event RecoverySuccess(address lostWallet, address newWallet, address holderIdentity);
    event AddressFrozen(address indexed account, bool indexed isFrozen, address indexed owner);
    event TokensFrozen(address indexed account, uint256 amount);
    event TokensUnfrozen(address indexed account, uint256 amount);
    event Paused(address account, uint256 id);
    event Unpaused(address account, uint256 id);
    
    function canTransfer(address to, uint256 id) external view returns (bool);
    function transferred(address from, address to, uint256 id) external;
    function created(address to, uint256 id, uint256 amount) external;
    function destroyed(address from, uint256 id) external;

}
