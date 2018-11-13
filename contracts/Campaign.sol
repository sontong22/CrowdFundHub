pragma solidity ^0.4.4;

import './SafeMath.sol';

contract Campaign {
    using SafeMath for uint256;
    
    address public beneficiary;
    
    string title;
    uint256 openingTime;
    uint256 closingTime;
    uint256 matchRate;
    address public campaignHub;
    
    uint256 totalFund;
    uint256 totalMatchVault;
    uint256 currentMatchVault;
    
    mapping(address => uint256) contributorToVault;
    
    event DirectContributionReceived(address campaign, address contributor, uint256 amount);
    event VaultContributionReceived(address campaign, address contributor, uint256 amount);
    event RefundSent(address campaign, address constructor, uint256 amount);
    
    // region Public Functions
    
    /**
    * This is the function called to fund directly.
    */
    function fundDirect(address _from) payable external;
    
    /**
    * This is the function called to put fund into the match vault.
    */
    function fundVault(address _from) payable external;
    
    /**
     * If the deadline is passed, allow contributors to withdraw their vault contributions.
     */
    function refund(address _from) external;
    
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
    
    
    // region Get View Functions
    
    function getTitle() public view returns (string) {
        return title;
    }

    function getMatchRate() public view returns (uint256) {
        return matchRate;
    }    
    
    function getTotalFund() public view returns (uint256) {
        return totalFund;
    }
    
    function getMatchFund() public view returns (uint256) {
        return totalMatchVault;
    }
    
    function getCurrentMatchVault() public view returns (uint256) {
        return currentMatchVault;
    }
    
    function getContributionToVault(address _from) public view returns (uint256) {
        return contributorToVault[_from];
    }
    
    function getOpenTime() public view returns (uint256) {
        return openingTime;
    }
    
    function getCloseTime() public view returns (uint256) {
        return closingTime;
    }
    
    // endregion Get View Functions
    
    
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