// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// TODO UPDATE

interface IComplianceLimitHolder {
    
    function canTransfer(address to, uint256 id) external view returns (bool);

    function transferred(address from, address to, uint256 id) external;

    function created(address to, uint256 id, uint256 amount) external;

    function destroyed(address from, uint256 id) external;

}
