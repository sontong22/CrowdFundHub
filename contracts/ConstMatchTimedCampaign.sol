pragma solidity ^0.4.4;

import './Campaign.sol';

contract ConstMatchTimedCampaign is Campaign{

    // region Constructor

    constructor(string _title, 
                uint256 _openingTime, 
                uint256 _closingTime, 
                uint256 _matchRate, 
                address _beneficiary,
                address _campaignHub
                ) public {
        require(_openingTime < _closingTime);
        title = _title;
        openingTime = now.add(_openingTime);
        closingTime = now.add(_closingTime);
        matchRate = _matchRate;
        beneficiary = _beneficiary;
        campaignHub = _campaignHub;
    }
    
    // endregion Constructor
    

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
    
    /**
    * This is the function called to put fund into the match vault.
    */
    function fundVault(address _from) payable external {
        require(isOpen());
        require(campaignHub == msg.sender);
        totalMatchVault += msg.value;
        currentMatchVault += msg.value;
        contributorToVault[_from] += msg.value;
        emit VaultContributionReceived(address(this), _from, msg.value);
    }
    
    /**
     * If the deadline is passed, allow contributors to withdraw their vault contributions.
     */
    function refund(address _from) external {
        require(!isOpen());
        require(campaignHub == msg.sender);
        require(contributorToVault[_from] > 0);
        
        uint256 amount = (uint256) (contributorToVault[_from] / totalMatchVault) * currentMatchVault;
        
        // prevent re-entrancy
        contributorToVault[_from] = 0;
        
        _from.transfer(amount);
        
        emit RefundSent(address(this), _from, amount);
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