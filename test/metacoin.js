var TrueToken = artifacts.require("./token/TrueToken.sol");
var InverseDutchAuction = artifacts.require("./InverseDutchAuction.sol");
var W = require('./W'); //a helper like web3 but with promises

contract('TrueToken', function(accounts) {
  it("token should have the right init values", function() {
    var trueToken 
    return TrueToken.deployed().then(function(_trueToken) {
      trueToken = _trueToken
      return trueToken.name();
    }).then(function(valueReturned) {
      assert.equal(valueReturned, "True Token", "name");
      return trueToken.decimals();
    }).then(function(valueReturned) {
      assert.equal(valueReturned.toNumber(), 18, "decimals");
      return trueToken.symbol();
    }).then(function(valueReturned) {
      assert.equal(valueReturned, "TRU", "symbol");
      return trueToken.version();
    }).then(function(valueReturned) {
      assert.equal(valueReturned, "H0.1", "version");
      return
    });
  });

  it("auction should have the right init values", function() {
    var inverseDutchAuction, trueToken, blockNumber
    return InverseDutchAuction.deployed().then(function(_inverseDutchAuction) {
      inverseDutchAuction = _inverseDutchAuction
      return TrueToken.deployed();
    }).then(function(_trueToken) {
      trueToken = _trueToken
      return inverseDutchAuction.multiplier();
    }).then(function(valueReturned) {
      // console.log("Multiplier:", valueReturned.toNumber())
      assert.approximately(valueReturned.toNumber(), 192e26, 1e20, "multiplier");
      return inverseDutchAuction.tokenParticlesForSale();
    }).then(function(valueReturned) {
      assert.equal(valueReturned.toNumber(), 3e25, "tokenParticlesForSale");
      return inverseDutchAuction.totalWeiReceived();
    }).then(function(valueReturned) {
      assert.equal(valueReturned.toNumber(), 0, "totalWeiReceived");
      return inverseDutchAuction.weiFloor();
    }).then(function(valueReturned) {
      assert.approximately(valueReturned.toNumber() / 1e18 * 300, 10000000 , 2, "weiFloor");
      return W.eth_blockNumber();
    }).then(function(valueReturned) {
      blockNumber = valueReturned
      return inverseDutchAuction.startBlock();
    }).then(function(valueReturned) {
      assert.approximately(valueReturned.toNumber(), blockNumber + 15, 2, "startBlock");
      return inverseDutchAuction.wallet();
    }).then(function(valueReturned) {
      assert.equal(valueReturned, accounts[0], "wallet");
      return inverseDutchAuction.token();
    }).then(function(valueReturned) {
      assert.equal(valueReturned, trueToken.address, "token");
      return
    });
  });
});
