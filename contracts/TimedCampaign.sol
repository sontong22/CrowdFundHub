pragma solidity ^0.4.4;

import './Campaign.sol';

contract TimedCampaign is Campaign{

    // region Constructor

    constructor(string _title, 
                uint256 _openingTime, 
                uint256 _closingTime,
                address _beneficiary,
                address _campaignHub
                ) public {
        require(_openingTime < _closingTime);
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
    * Cannot fund to vault with this contract.
    */
    function fundVault(address _from) payable external {
        require(false);
    }
    
    /**
     * Cannot claim refund with this contract.
     */
    function refund(address _from) external {
        require(false);
    }
    
    // endregion Public Functions
}