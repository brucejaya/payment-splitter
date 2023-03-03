import pytest
from brownie import accounts, PaymentSplitterCloneable, PaymentSplitterFactory, ERC20Token, Contract

def main():
		
	# Get accounts
	DEPLOYER = accounts[0]
	PAYEE1 = accounts[1]
	PAYEE2 = accounts[2]
	PAYEE3 = accounts[3]
	PAYEE4 = accounts[4]

	# Deploy the paymentSplitterFactory contract
	FACTORY = PaymentSplitterFactory.deploy({"from": DEPLOYER})

	# Create the paymentSplitter contract
	tx = FACTORY.newSplitter([PAYEE1, PAYEE2, PAYEE3, PAYEE4], [1, 1, 1, 1], {"from": DEPLOYER, "value": "1 ether"})

	# Get the return address and contract of the tx
	SPLITTER_ADDR = tx.return_value

	# Send ether to the paymentSplitter contract
	tx = DEPLOYER.transfer(SPLITTER_ADDR, "4 ether")
	tx.wait(1)

	# Release the funds
	tx = FACTORY.releaseAll(SPLITTER_ADDR, {"from": DEPLOYER})
	tx.wait(1)

	# Check the balances
	print("Balance of PAYEE1: ", PAYEE1.balance())
	print("Balance of PAYEE2: ", PAYEE2.balance())
	print("Balance of PAYEE3: ", PAYEE3.balance())
	print("Balance of PAYEE4: ", PAYEE4.balance())

	# Test getRegisteredCountOf
	

	# # Get shares
	# print("Shares of PAYEE1: ", FACTORY.getShares(SPLITTER_ADDR))
		
	# # Deploy the mock erc20 token 
	# TOKEN = ERC20Token.deploy({"from": DEPLOYER})

	# # Mint tokens to the deployer
	# TOKEN.mint(DEPLOYER, 4)

	# # Transfer tokens to the paymentSplitter contract
	# tx = TOKEN.transfer(SPLITTER_ADDR, 4, {"from": DEPLOYER})

	# # Release the tokens
	# tx = FACTORY.releaseAllTokens(TOKEN.address, SPLITTER_ADDR, {"from": DEPLOYER})
	# tx.wait(1)

	# # Check the balances
	# print("Balance of PAYEE1: ", TOKEN.balanceOf(PAYEE1.address))
	# print("Balance of PAYEE2: ", TOKEN.balanceOf(PAYEE2.address))
	# print("Balance of PAYEE3: ", TOKEN.balanceOf(PAYEE3.address))
	# print("Balance of PAYEE4: ", TOKEN.balanceOf(PAYEE4.address))
