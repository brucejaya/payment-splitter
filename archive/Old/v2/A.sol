/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.6;

// A manages identity

contract A {

	mapping(bytes32 => address) public owners;

    ENS ens;
    bytes32 rootNode;

    function SubdomainRegistrar(address ensAddr, bytes32 node) {
        ens = ENS(ensAddr);
        rootNode = node;
    }

    function _transferSubdomain(bytes32 subnode, address from, address to)
		internal
	{
        var node = sha3(rootNode, subnode);
        var currentOwner = ens.owner(node);
        require(currentOwner != 0 && currentOwner != from, "You are not the wonder of this domain");
		if (currentOwner == 0) {
			// TODO needs to add the given key as the keyholder if this is the first time
		}
        ens.setSubnodeOwner(rootNode, subnode, from);
    }

	function identityOwner(bytes32 identity)
		public
		view
		returns(address)
	{
		address owner = owners[identity];
		if (owner != address(0x00)) {
			return owner;
		}
		return identity;
	}

	function _changeIdentityOwner(bytes32 identity, address from, address to)
		internal
		onlyOwner(identity, from)
	{
		owners[identity] = to;
		emit DIDOwnerChanged(identity, to, changed[identity]);
		changed[identity] = block.number;
	}

	function changeIdentityOwner(bytes32 identity, address to)
		public
	{		
		_transferSubdomain(identity, msg.sender, to);
		_changeIdentityOwner(identity, msg.sender, to);
	}

	function changeIdentityOwnerSigned(bytes32 identity, uint8 sigV, bytes32 sigR, bytes32 sigS, address to)
		public
	{		
		bytes32 hash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0), this, nonce[identityOwner(identity)], identity, "changeIdentityOwner", to));
		_changeIdentityOwner(identity, checkSignature(identity, sigV, sigR, sigS, hash), to);
		_transferSubdomain(identity, checkSignature(identity, sigV, sigR, sigS, hash), to);
	}

	// is valid signature ERC1271
	function checkSignature(bytes32 identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 hash)
		internal
		returns(address)
	{
		address signer = ecrecover(hash, sigV, sigR, sigS);
		require(signer == identityOwner(identity), "bad_signature");
		nonce[signer]++;
		return signer;
	}

}