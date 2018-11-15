pragma solidity ^0.4.24;

import './MatchTimedCampaign.sol';

contract ConstMatchTimedCampaign is MatchTimedCampaign{

    // region Constructor

    constructor(string _title, 
                uint256 _openingTime, 
                uint256 _closingTime, 
                uint256 _matchRate, 
                address _beneficiary,
                address _campaignHub
                ) MatchTimedCampaign(
                    _title, 
                    _openingTime, 
                    _closingTime,
                    _matchRate,
                    _beneficiary, 
                    _campaignHub
                ) public {
        campaignType = 2;
    }
    
    // region Constructor
    

    // region Public Functions

    /**
    * This is the function called to fund directly.
    */
    function fundDirect(address _from) payable external {
        require(isOpen());
        require(campaignHub == msg.sender);
        require(isEnoughFundInVault());
        totalFund += msg.value + matchRate;
        currentMatchVault -= matchRate;
        emit DirectContributionReceived(address(this), _from, msg.value);
    }
    
    // endregion Public Functions
    
    
    // region Condition validation Functions
    
    /**
     * Check whether there is enough fund in vault to match.
     * Should call this function before fundDirectly() to avoid unnecessary gas fee.
     */
    function isEnoughFundInVault() public view returns (bool) {
        return currentMatchVault >= matchRate;
    }
    
    // endregion Condition validation Functions
}