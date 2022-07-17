/* SPDX-License-Identifier: MIT */

pragma solidity 0.8.0;

contract IdentityRegistry {

	bytes32[] public identities;
	mapping(bytes32 => address) public roots;

    // ENS ens;
    // bytes32 rootNode;

    // function SubdomainRegistrar(address ensAddr, bytes32 node)
		// internal
	// {
        // ens = ENS(ensAddr);
        // rootNode = node;
    // }

    // function _transferSubdomain(bytes32 subnode, address from, address to)
	// internal
	// {
        // node = sha3(rootNode, subnode);
        // currentOwner = ens.owner(node);
        // require(currentOwner != 0 && currentOwner != from, "You are not the wonder of this domain");
		// if (currentOwner == 0) {
			// TODO needs to add the given key as the keyholder if this is the first time
		// }
        // ens.setSubnodeOwner(rootNode, subnode, from);
    // }

	function registertIdentity(
		string memory identityName
	)
		public
	{
		identities.append(stringToBytes32(identityName));
	}
	
	function stringToBytes32(
		string memory source
	) public pure returns (bytes32 result) {
   		return bytes32(source);
	}
	
    function addressToBytes32(address toCast)
        public
        pure
        returns(bytes32 key)
    {
        return bytes32(toCast);
    }



	function identityOwner(bytes32 identity)
		public
		view
		returns(address)
	{
		address owner = identities[identity];
		if (owner != address(0x00)) {
			return owner;
		}
		return identity;
	}

	function _changeIdentityOwner(bytes32 identity, address from, address to)
		internal
	{
		identities[identity] = to;
		// emit DIDOwnerChanged(identity, to, changed[identity]);
		// changed[identity] = block.number;
	}

	function changeIdentityOwner(bytes32 identity, address to)
		public
	{		
		// _transferSubdomain(identity, msg.sender, to);
		_changeIdentityOwner(identity, msg.sender, to);
	}

}