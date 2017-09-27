var W = function(){};

W.eth_blockNumber = function (seconds) {
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

module.exports = W
