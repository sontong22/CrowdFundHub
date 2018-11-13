# CampaignHub

CampaignHub.sol is responsible for creating and maintaining a list of all Campaign contracts. CampaignHub also offers a contribute method which can be used to contribute directly to a Campaign. Campaigns have been locked to only allow receiving of funds and claiming refund from their managing Campaign Hub to allow for the scenario in which the CampaignHub takes a small fee for managing each campaign.

(1) TimedCampaign.sol  When the campaign is closed, no one can send money to the campaign. The beneficiary can only claim the raised fund after the campaign is closed. 

(2) RateMatchTimedCampaign.sol 
- Regaring the match rate, we consider the scenario in which every normal contribution would be matched with that amount times the match rate.  A donor can choose to back the campaign by either contributing to the match vault or contributing directly to the fund.
- If a donor contributes X amount directly to the fund, X * matchRate amount would be contributed to the fund from the match vault. In the case the match vault does not have enough money to match, we simply cancel the fund action. 
- If a donor contributes X amount to the match vault, the money would stay in the match vault waiting to be matched. At the end of the campaign, if there is money left in the match vault, we return them to owner.

(3) ConstMatchTimedCampaign.sol offers the feature to match any contribution with a const amount.  

There are currently three main functions: fund, payout, and refund
- Fund This is the function called when the CampaignHub receives a contribution. If the contribution was sent after the deadline of the project passed, the function must return the value to the originator of the transaction. 
- Payout If funding goal has been met, transfer fund to project creator. This function protects against re-entrancy and is only payable to the project creator.
- Refund If the deadline is passed and the goal was not reached, allow contributors to withdraw their contributions. The contributor has to call this function to receive the refund. We choose this withdrawal pattern over a group send to avoid the pitfalls of call depth, out-of-gas issues, and to enforce contributor's total control over their money. 

### TODO

Integrate Oraclize

Allow for more customizable for a campaign:
- honor token distribution
- more strategy of money matching
- customizable match time
- campaign goal so that the campaign ends when it reachs the goal or the closing time

Create UI.
