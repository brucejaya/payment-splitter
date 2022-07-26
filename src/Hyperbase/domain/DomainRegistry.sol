// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// ! NOTE: This is very untested, and very insecure. Do not use!

import "../../Interface/IDomain.sol";
import "../../Interface/IDomainAccessControl.sol";
import "../../Interface/IDomainEnumerable.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract DomainRegistry is IDomain, IDomainAccessControl, IDomainEnumerable, ERC165Storage, ERC165Checker {

    ////////////////
    // STATES
    ////////////////

    mapping(string => address) public subdomains;
    mapping(string => bool) public subdomainsPresent;
    mapping(string => uint) public subdomainIndices;
    string[] public subdomainList;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor() {
        _registerInterface(type(IDomain).interfaceId);
        _registerInterface(type(IDomainAccessControl).interfaceId);
        _registerInterface(type(IDomainEnumerable).interfaceId);
    }

    ////////////////////////////////////////////////////////////////
    //                        READ FUNCTIONS
    ////////////////////////////////////////////////////////////////

    // @dev Checks to see if the name has already been registered
    function hasDomain(
        string memory name
    )
        public
        view
        returns (bool)
    {
        return subdomainsPresent[name];
    }

    function getDomain(
        string memory name
    ) 
        public 
        view 
        returns (address) 
    {
        require(this.hasDomain(name));
        return subdomains[name];
    }

    function listDomains() 
        external 
        view 
        returns (string[] memory) 
    {
        return subdomainList;
    }

    ////////////////////////////////////////////////////////////////
    //                     DOMAIN MANAGEMENT
    ////////////////////////////////////////////////////////////////
    function createDomain(
        string memory name, 
        IDomain subdomain
    )
        public
    {
        require(!this.hasDomain(name), "Domain already registered");
        require(this.canCreateDomain(msg.sender, name, subdomain), ""); // TODO This seems to just repeat the previous check?
        
        subdomainsPresent[name] = true;
        subdomains[name] = subdomain;

        subdomainIndices[name] = subdomainList.length;
        subdomainList.push(name);

        emit SubdomainCreate(msg.sender, name, subdomain);
    }

    function setDomain(
        string memory name,
        address subdomain
    )
        public
    {
        require(this.canSetDomain(msg.sender, name, subdomain));

        address oldSubdomain = subdomains[name];
        subdomains[name] = subdomain;

        emit SubdomainUpdate(msg.sender, name, subdomain, oldSubdomain);
    }

    function deleteDomain(
        string memory name
    )
        public
    {
        require(this.canDeleteDomain(msg.sender, name));

        subdomainsPresent[name] = false; // Only need to mark it as deleted
        delete subdomainList[subdomainIndices[name]]; // Remove subdomain from list

        emit SubdomainDelete(msg.sender, name, subdomains[name]);
    }

    ////////////////////////////////////////////////////////////////
    //                    PARENT DOMAIN ACCESS
    ////////////////////////////////////////////////////////////////
    
    // @dev 
    function canCreateDomain(
        address updater, 
        string memory name,
        address subdomain
    )
        public
        view
        returns (bool)
    {
        // Existence Check
        if (this.hasDomain(name)) {
            return false;
        }

        // Return
        return true;
    }

    function canSetDomain(
        address updater,
        string memory name,
        address subdomain
    )
        public
        view
        returns (bool)
    {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

        // Auth Check
        bool isMovable = this.supportsInterface(this.getDomain(name), type(IDomainAccessControl).interfaceId) && IDomainAccessControl(this.getDomain(name)).canMoveSubdomain(updater, name, this, subdomain);

        // Return
        return isMovable;
    }

    function canDeleteDomain(
        address updater, 
        string memory name
    )
        public
        view
        returns (bool)
    {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

        // Auth Check
        bool isDeletable = this.supportsInterface(this.getDomain(name), type(IDomainAccessControl).interfaceId) && IDomainAccessControl(this.getDomain(name)).canDeleteSubdomain(updater, name, this);

        // Return
        return isDeletable;
    }


    ////////////////////////////////////////////////////////////////
    //                   SUBDOMAIN DOMAIN ACCESS
    ////////////////////////////////////////////////////////////////    
    function canMoveSubdomain(
        address updater,
        string memory name,
        IDomain parent,
        address newSubdomain
    )
        public
        virtual
        view
        returns (bool)
    {
        return true;
    }

    function canDeleteSubdomain(
        address updater, 
        string memory name, 
        IDomain parent
    )
        public
        virtual
        view
        returns (bool)
    {
        return true;
    }
}
