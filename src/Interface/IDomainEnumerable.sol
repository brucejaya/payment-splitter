// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "./IDomain.sol";

interface IDomainEnumerable is IDomain {
    
    /// @notice     Query all subdomains. Must revert if the list of domains is unknown or infinite.
    /// @return     The list of all subdomains.
    function listDomains() external view returns (string[] memory);

}