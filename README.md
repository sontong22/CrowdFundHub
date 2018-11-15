# CampaignHub

CampaignHub.sol is responsible for creating and maintaining a list of all Campaign contracts. CampaignHub also offers a contribute method which can be used to contribute directly to a Campaign. Campaigns have been locked to only allow receiving of funds and claiming refund from their managing Campaign Hub to allow for the scenario in which the CampaignHub takes a small fee for managing each campaign. CampainHub contract can also query external information using ChainLink oracle.  Since query external information requires ChainLink token, we restrict that function to the owner (manager) of Campain Hub. 

(1) TimedCampaign.sol  When the campaign is closed, no one can send money to the campaign. The beneficiary can only claim the raised fund after the campaign is closed. 

(2) RateMatchTimedCampaign.sol 
- Every direct contribution would be matched with the match rate.  A donor can choose to back the campaign by either contributing to the match vault or contributing directly to the fund.
- If a donor contributes X amount directly to the fund, X * matchRate amount would be contributed to the fund from the match vault. In the case the match vault does not have enough money to match, we simply cancel the fund action. 
- If a donor contributes X amount to the match vault, the money would stay in the match vault waiting to be matched. At the end of the campaign, if there is money left in the match vault, we return them to owner.

(3) ConstMatchTimedCampaign.sol offers the feature to match any contribution with a const amount.  

There are currently three main functions: fund, fundVault, payout, and refund
- FundDirect This is the function called when the CampaignHub receives a contribution. If the campaign is a MatchTimedCampaign, match the contribution with the amount from the match vault according to the rule of the contract. If the contribution was sent after the deadline of the project passed or there is not enough money to match in the match vault, the function must return the value to the originator of the transaction.
- FundVault Transfer the contribution to the Match Vault of MatchTimedCampaign. 
- Payout If funding goal has been met, transfer fund to project creator. This function protects against re-entrancy and is only payable to the project creator.
- Refund If the deadline is passed and the match vault is not used up, allow contributors to withdraw their vault contributions. The refund is calculated based on the proportion of their vault contribution to the total money in the match vault. The contributor has to call this function to receive the refund. We choose this withdrawal pattern over a group send to avoid the pitfalls of call depth, out-of-gas issues, and to ensure contributor's total control over their money. 

## Set up
The easiet way to test the project is to use Remix IDE at https://remix.ethereum.org and MetaMask.

Add all contracts in contracts/ to Remix. Change the compiler version to 0.4.24 since ChainLink has not adapted to later Solidity version. Some notifications and warnings may pop up but that is normal. Can select the Run tab (at upper right-hand corner of Remix), change Environment to  Javascript VM to perform quick test for contracts functionality without querying external data through ChainLink.

To test ChainLink, we would need to install MetaMask and acquire Test LINK.
- Create a new vault, change the network selection to the Ropsten Test Network, hit Deposit the account, and choose the Test Faucet Get Ether option, which open up a new browser window. Click request 1 ether from testnet (can require several ethers) to perform testing.
- Next, we will need Chain Link Token to use the oracle. Open up MetaMask, click the Wallet account name at the top to copy the address to your clipboard. Navigate to https://ropsten.chain.link, paste the your wallet address, and click Send me 100 Test LINK. In order to see LINK token balance in MetaMask, click the hamburger button (at top-left), Add Token, Custom Token, paste the the LINK token address on Ropsten: 0x20fE562d797A42Dcb3399062AE9546cd06f63280, and click Add. 
- Go to https://remix.ethereum.org. Select the Run tab, change the Environment to Injected Web3 to use your Ropsten wallet account. Click deploy, wait until the transaction is confirmed, and the Remix UI will update upon completion, displaying the title of the contract. (ex: CampaignHub at 0xb67...abc2e)


## TODO

Implement web UI.

Allow for more customizable for a campaign:
- more appropriate usage of the oracle.
- honor token distribution.
- more strategy of money matching.
- customizable match time.
- campaign goal so that the campaign ends when it reachs the goal or the closing time.



