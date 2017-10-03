var H = function(){};

H.eth_blockNumber = function () {
  return new Promise(function(resolve, reject){
    web3.currentProvider.sendAsync(
      {
        jsonrpc: "2.0",
        method: "eth_blockNumber",
        params: [],
        id: 0
      }, 
      resolve
    )
  })
}

H.evm_increaseTime = function (seconds) {
  return new Promise(function(resolve, reject){
    web3.currentProvider.sendAsync(
      {
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [seconds],
        id: 0
      }, 
      resolve
    )
  })
}

module.exports = H
