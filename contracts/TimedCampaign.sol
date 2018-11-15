pragma solidity ^0.4.24;

import './SafeMath.sol';

contract TimedCampaign {
    using SafeMath for uint256;
    
    string public title;
    uint256 public openingTime;
    uint256 public closingTime;
    
    // 1: Simple timed campaign without match vault.
    // 2: Constant match timed campaign.
    // 3: Rate match timed campaign.
    uint8 public campaignType;
    
    address public beneficiary;
    address public campaignHub;
    
    uint256 public totalFund;
    
    event DirectContributionReceived(address campaign, address contributor, uint256 amount);
    
    // region Constructor

    constructor(string _title, 
                uint256 _openingTime, 
                uint256 _closingTime,
                address _beneficiary,
                address _campaignHub
                ) public {
        require(_openingTime < _closingTime);
        campaignType = 1;
        title = _title;
        openingTime = now.add(_openingTime);
        closingTime = now.add(_closingTime);
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
        totalFund = totalFund.add(msg.value);
        emit DirectContributionReceived(address(this), _from, msg.value);
    }
    
    /**
    * Transfer fund to the beneficiary of this campaign.
    */
    function payOut(address _from) external {

        require(isBeneficiary(_from));
        require(!isOpen());
        
        uint256 amount = totalFund;
        // prevent re-entrancy
        totalFund = 0;
        
        beneficiary.transfer(amount);
    }
    
    // endregion Public Functions
    
    
    // region Condition validation Functions
    
    /**
     * Revert to inital state if called by any account other than the beneficiary.
     */
    function isBeneficiary(address _from) public view returns(bool) {
        return beneficiary == _from;
    }
    
    /**
     * Return true if the campaign is open, false otherwise.
     * Should call this function before fund() to avoid unnecessary gas fee.
     */
    function isOpen() public view returns (bool) {
        return now >= openingTime && now <= closingTime;
    }
    
    // endregion Condition validation Functions
}