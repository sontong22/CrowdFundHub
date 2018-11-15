pragma solidity ^0.4.24;

import './ChainlinkLib.sol';
import './Chainlinked.sol';
import './Ownable.sol'; 

contract ARopstenConsumer is Chainlinked, Ownable {
  uint256 public currentPrice;

  address constant ROPSTEN_ENS = 0x112234455C3a32FD11230C42E7Bccd4A84e02010;
  bytes32 constant ROPSTEN_CHAINLINK_ENS = 0xead9c0180f6d685e43522fcfe277c2f0465fe930fb32b5b415826eacf9803727;

  event RequestEthereumPriceFulfilled(
    bytes32 indexed requestId,
    uint256 indexed price
  );

  constructor() Ownable() public {
    newChainlinkWithENS(ROPSTEN_ENS, ROPSTEN_CHAINLINK_ENS);
  }

  function requestEthereumPrice(string _jobId, string _currency) 
    public
    onlyOwner
  {
    ChainlinkLib.Run memory run = newRun(stringToBytes32(_jobId), this, "fulfillEthereumPrice(bytes32,uint256)");
    run.add("url", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD,EUR,JPY");
    string[] memory path = new string[](1);
    path[0] = _currency;
    run.addStringArray("path", path);
    run.addInt("times", 100);
    chainlinkRequest(run, LINK(1));
  }

  function fulfillEthereumPrice(bytes32 _requestId, uint256 _price)
    public
    checkChainlinkFulfillment(_requestId)
  {
    emit RequestEthereumPriceFulfilled(_requestId, _price);
    currentPrice = _price;
  }

  function updateChainlinkAddresses() public onlyOwner {
    newChainlinkWithENS(ROPSTEN_ENS, ROPSTEN_CHAINLINK_ENS);
  }

  function getChainlinkToken() public view returns (address) {
    return chainlinkToken();
  }
  
  function getOracle() public view returns (address) {
    return oracleAddress();
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkToken());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 32))
    }
  }

}