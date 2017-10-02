Inverse Dutch Auction
=====================

<img src="logo.png" style="height: 200px;"/>

Truffle Project containing the Inverse Dutch Auction smart contracts. Ideas were taking from he Gnosis token launch and improved upon. The auction drops the ETH being raised over time while fixing the number of tokens sold. 


Why This Architecture
---------------------
The Gnosis model was revolutionary and afforded the following improvements:

 - It allowed participants to imply a market cap with there bid.
 -  By tying the implied market cap to a time variable, it solved Ethereum-specific throughput issues. Guaranteeing participation for those willing to pay the highest price.

Unfortunately the Gnosis model was not received as well as it should have because the tokens sold out immediately. Why?

 - The Initially token price was not set high enough to dissuade investors from going in too early
 -  Although this investor behavior resulted in a high token price, The unsold tokens were kept out of circulation by the Gnosis team, essentially acting as a capped sale of 250,000 ETH with participants receiving just a large a large chunk of the "circulating" tokens.

The Inverse Dutch Auction presented here, solves these problems entirely. Instead of fixing the ETH to be raised and dropping the ratio of equity over time, it fixes the amount of equity sold and drops the ETH being raised over time.


Install
-------
### Get Truffle:
```
npm install -g truffle
```

### Clone the Repo:
```
git clone https://github.com/zmitton/InverseDutchAuction.git
```

Test
----
### Run the Tests:
```
truffle test
```

Deploy
------
### Deploy your Token and Auction:
Change the migration arguments in `migrations/2_deploy_contracts.js`, and deploy your auction.
```
truffle migrate --network rinkeby
```

License
-------
Just use it, but give me a shout out.

Contributors
------------
- Zac Mitton ([zmitton](https://github.com/zmitton))
- Stefan George ([Georgi87](https://github.com/Georgi87))
