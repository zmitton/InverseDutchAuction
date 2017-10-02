var TrueToken           = artifacts.require("./token/TrueToken.sol")
var Auction = artifacts.require("./InverseDutchAuction.sol")

module.exports = function(deployer, network, accounts) {
  var _tokenParticlesToAuction = 30000000e18;
  deployer.deploy(
    TrueToken,
    100000000e18, //_totalSupply
    "True Token", //_name
    18, //_decimals
    "TRU" //_symbol
  ).then(function(){
    return deployer.deploy(
      Auction,
      accounts[0],// _wallet,
      TrueToken.address,// _token,
      _tokenParticlesToAuction,// _tokenParticlesToAuction,
      Math.floor(Date.now()/1000) + 150,// startTime,
      1000000000,// usdTargetAfter1Day,
      10000000,// usdFloor,
      300// usdPerEth
    )
  }).then(function(){
    return TrueToken.deployed()
  }).then(function(trueToken){
    return trueToken.transfer(Auction.address, _tokenParticlesToAuction, {from:accounts[0]})
  })
}
