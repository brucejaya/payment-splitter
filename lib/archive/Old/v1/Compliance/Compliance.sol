/*

When the an equity transfer Takes place it makes a query to the compliance contract. 

	1.The compliance contract enforces compliance on the sender
		a. That the investors assets aren't frozen? This may either be for staff or for 
		c. ...

	2.The compliance contract enforces compliance on the token itself
		a. Investor limit
		b. Investor per country limit
		c. ...

	3.The compliance contract enforces compliance on the user
		a. The compliance contract firstly checks for if the the token owner has whitelisted the receiver. This allows founders to raise investment quickly without forcing their investors to go through CDD externally.
		b. If not, the compliance contract checks that the user has a claim that matches the requirements, if it does not the transaction fails outright. 
		c. If the user does have the appropriate claims for the circumstance the compliance contact then checks the TrustedClaimIssuerRegistry to make sure that the claim came from a trusted issuer
		d. The compliance contract then verifies the signature of the signer to make sure it belongs to who it says it does?

*/