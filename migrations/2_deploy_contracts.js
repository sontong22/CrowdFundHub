var CampaignHub = artifacts.require("./CampaignHub.sol");

module.exports = function(deployer) {
  deployer.deploy(CampaignHub);
};