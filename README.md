# Hypersurface Protocol

Welcome to Hypersurface. A protocol for lightweight, accessible and open digital equity on the blockchain. Hypersurface makes the issuance, management, and transfer of digital equity as easy as sending email. 

## Structure
The Hypersurface Protocol primarily consists of two core components, each with several sub-components split into folders.

Full folder structure is as follows:

	Hypersurface (src)
	├── Hyperbase
	│   ├── claims
	│   │   ├── ClaimValidator.sol
	│   │   └── ClaimVerifiersRegistry.sol
	│   └── identity
	│       ├── IdentityRegistry.sol
	│       ├── IdentityRegistryStorage.sol
	│       ├── Identity.sol
	│       ├── storage
	│       │   ├── Storage.sol
	│       │   └── Structs.sol
	│       └── version
	│           └── Version.sol
	├── Hypershare
	│   ├── compliance
	│   │   ├── ComplianceClaimsRequired.sol
	│   │   ├── ComplianceDefault.sol
	│   │   └── ComplianceLimitHolder.sol
	│   ├── token
	│   │   ├── TokenRegistry.sol
	│   │   └── TokenRegistryStorage.sol
	│   └── wrapper
	│       └── Wrapper.sol
	├── Role
	│	├── agent
	│	│   ├── AgentManager.sol
	│	│   ├── AgentRole.sol
	│	│   ├── AgentRoles.sol
	│	│   ├── AgentRolesUpgradeable.sol
	│	│   └── AgentRoleUpgradeable.sol
	│	├── owner
	│	│   ├── OwnerManager.sol
	│	│   ├── OwnerRoles.sol
	│	│   └── OwnerRolesUpgradeable.sol
	│	└── Roles.sol
	├── Interface
	│   ├── ...
	│   ├── ...
	│   └── ...
	└── Proxy
		├── ...
		├── ...
		└── ...

### 1. Hypershare 
Hypershare is the home of all things **equity** related. 

1.1. [token](https://github.com/blit-man/hypersurface-forge/src/Hypershare/token) is a multi-token permissioned implementation that has been restructured with the ERC-1155 as its core standard. This important distinction strips away all unnecessary logic to create a lean, efficient, and flexible equity token implementation which is deployed one-per-organisation (rather than one per asset). By virtue of its ERC-1155 compliance the token also embeds agreements and agreement metadata in it's URI tag.

1.2. [compliance](https://github.com/blit-man/hypersurface-forge/src/Hypershare/compliance) enforces on-chain transfer controls. Unlike other crypto assets, Hypershare transactions can fail for a variety of reasons. These reasons include the receiver not having verified KYC information, assets having been locked or frozen, and economic and jurisdictional constraints such as holder, acquisition, and geographic limits.

1.3. [holder](https://github.com/blit-man/hypersurface-forge/src/Hypershare/holder) records shareholder ownership. In essence, it is the on-chain access point for the shareholder register. As a cap table that offers sophisticated functionality it also allows issuers to use advanced controls such as freezing, force transfers, etc.   

1.4. [wrapper](https://github.com/blit-man/hypersurface-forge/src/Hypershare/wrapper) wraps ERC-1155 contracts for standard ERC-20 that can be used in DeFi. In essence, it takes cash and gives poker chips for use in the casino of DeFi.

### 2. Hyperbase is the home of all things **identity** related.

2.1 [identity](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/identity) is both 

2.2. [claims](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/claims) records verifiable digital claims from a Hyperbase and also records a registry of trusted claim issuers (e.g. KPMG, etc) and claim topics (e.g. accredited: y/n, nationality, etc.)

2.3. [subdomain](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/subdomain) is currently empty but will be responsible for registering new ENS subdomains to an account e.g. "john.hypersurface.finance", "acme.hypersurface.finance". Currently looking for an adequate third-party library that interfaces with ENS.

## To-Do 
The core protocol is still in the early development stage, approaching MVP (approximately 55-65% complete). While the fundamental structure and core components are (most likely) present, it is still a work in progress. Main areas for development are: 

- Restructure for enhanced upgradeability.
- Factory contracts must provide a clean, centralised entry point to all child contracts.
- Subdomain factory for Hyperbase, refer to Argon, et al. 
- IdentityEnforcer with appropriate permission levels across protocol.
- Code comments for clarity.

## Further development 
Rather than continuously upgrading, the protocol should be stabilised as quickly as possible. The ideal is a minimalist control structure that enables a simple, effective base for subsequent development (see below, "Next steps"). If any areas of the core protocol will see significant change in the long-term, it will most likely be the on-chain compliance controls. By adding further sophistication to the compliance contract we will be able to reduce the general tedium of compliance and further increase transferability in a meaningful way for users.

## Next steps
The Hypersurface Protocol itself serves as the foundational infrastructure layer for subsequent development, be it a web application or further applications at the protocol-level (e.g. equity sales, voting, secondary markets, instant equity-backed loans, etc). Primarily, the protocol provides an open standard that enables equity to be represented in a way that is uniform. This enables it to be worked with quickly and safely, whether by Hypersurface, users, or other marketplace actors. As such Hypersurface in it's final form will most likely consist of a minimum of three core libraries: the protocol (this), the application, and the legal modules.