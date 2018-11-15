pragma solidity ^0.4.24;

import './SafeMath.sol';
import './TimedCampaign.sol';

contract MatchTimedCampaign is TimedCampaign {
    using SafeMath for uint256;
    
    uint256 public matchRate;
    uint256 public matchFund;
    
    uint256 public totalFund;
    uint256 public totalMatchVault;
    uint256 public currentMatchVault;
    
    mapping(address => uint256) public contributorToVault;
    
    event VaultContributionReceived(address campaign, address contributor, uint256 amount);
    event RefundSent(address campaign, address constructor, uint256 amount);
    
    // region Constructor

    constructor(string _title, 
                uint256 _openingTime, 
                uint256 _closingTime, 
                uint256 _matchRate, 
                address _beneficiary,
                address _campaignHub
                ) TimedCampaign(
                    _title, 
                    _openingTime, 
                    _closingTime, 
                    _beneficiary, 
                    _campaignHub
                ) public {
        matchRate = _matchRate;
    }
    
    // endregion Constructor
    
    
    // region Public Functions
    
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
    
     // region Get View Functions
    
    function getContributionToVault(address _from) public view returns(uint256) {
        return contributorToVault[_from];
    }
    
    // endregion Get View Functions
}