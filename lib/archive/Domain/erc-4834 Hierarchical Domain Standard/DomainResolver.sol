


contract DomainResolver {
	function resolve(string[] calldata splitName, IDomain root) public view returns (address) {
    IDomain current = root;
    for (uint i = splitName.length - 1; i >= 0; i--) {
        // Require that the current domain has a domain
        require(current.hasDomain(splitName[i]), "Name resolution failed: );
        // Resolve subdomain
        current = current.getDomain(splitName[i]);
    }
    return current;
}
}