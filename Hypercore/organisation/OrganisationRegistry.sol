// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./OrganisationManaged.sol";

contract OrganisationFactory {

    // GovernedOrganisation private _governed;

    // OrganisationManaged private _managed;

    address[] public Organisations;

    event Deployed(address indexed _organisation, address indexed deployer);

    // @dev returns total number of organisations deployed
    function getOrganisationCount()
        public
        view
        returns (uint256 OrganisationCount)
    {
        return Organisations.length;
    }

    // @dev returns organsiation by index
    function getOrganisationByIndex(
        uint256 index
    )
        public
        view
        returns (uint256 OrganisationCount)
    {
        return Organisations[index];
    }
    
    // @dev deploy a strictly managed organisation account
    // function deployManagedOrganisation(
    //     address deployer
    // )
    //     public
    // {
    //     _managed = new ManagedOrganisation(deployer);
    //     Organisations.push(address(_managed));
    //     emit Deployed(address(_managed), deployer);
    // }

}