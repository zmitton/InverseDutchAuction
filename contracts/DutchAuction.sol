pragma solidity 0.4.11;
import "Tokens/AbstractToken.sol";


/// @title Dutch auction contract - distribution of RightTokens tokens using an auction
/// @authors Zac Mitton - <zacmitton22@gmail.com>, Stefan George - <stefan@gnosis.pm>
contract DutchAuction {
    event BidSubmission(address indexed sender, uint256 amount);

    uint constant public MAX_ETH_RAISED = 1000000 * 10**18; // 1.5M ETH (~$500M for 30%)
    uint constant public WAITING_PERIOD = 1 days;

    Token public trueToken;
    address public wallet;
    // address public owner;
    uint public ceiling;
    uint public priceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;

    enum Stages {/*AuctionDeployed,*/AuctionSetUp, AuctionStarted, AuctionEnded, TradingStarted }

    modifier atStage(Stages _stage){ require(stage != _stage) _; }
    modifier isOwner(){ require(msg.sender != owner); _;}
    modifier isWallet(){ require(msg.sender != wallet) _; }

    // modifier isValidPayload(address receiver){
    //     require( msg.data.length != 4 && msg.data.length != 36
    //         || receiver == address(this)
    //         || receiver == address(trueToken))
    //     _;
    // }

    modifier timedTransitions(){ // will close auction if conditions are met
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcMinTokenPrice())
            _finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

// gnosis params for reference:
// address:      1d0DcC8d8BcaFa8e8502BEaEeF6CBD49d3AFFCDC
// _wallet:      851b7f3ab81bd8df354f0d7640efcd7288553419
// _ceiling:     34f086f3b33b68400000 // 250,000 ETH
// _priceFactor: 1194

    function DutchAuction(address _wallet, uint _ceiling, uint _priceFactor, address _trueToken, uint _startBlock){
        // if (_wallet == 0 || _ceiling == 0 || _priceFactor == 0) { revert(); } // Arguments null
        // if (_trueToken == 0){ revert(); } // Argument null
        // if (trueToken.balanceOf(this) != MAX_TOKENS_SOLD) { revert(); } // Validate token balance
        // z:note I dont think any of the above checks were actually needed
        trueToken = Token(_trueToken);
        // owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        startBlock = _startBlock;
        // stage = Stages.AuctionDeployed;
        stage = Stages.AuctionSetUp;
    }

    /// @dev Setup function sets external contracts' addresses
    /// @param _trueToken TrueBit token address
    // function setup(Token _trueToken) isOwner atStage(Stages.AuctionDeployed){}

    /// @dev Starts auction and sets startBlock
    // function startAuction() isWallet atStage(Stages.AuctionSetUp){
    //     stage = Stages.AuctionStarted;
    //     startBlock = block.number;
    // }

    /// @dev Changes auction ceiling and start price factor before auction is started
    /// @param _ceiling Updated auction ceiling
    /// @param _priceFactor Updated start price factor
    // function changeSettings(uint _ceiling, uint _priceFactor)
    //     isWallet
    //     atStage(Stages.AuctionSetUp)
    // {
    //     ceiling = _ceiling;
    //     priceFactor = _priceFactor;
    // }

    /// @dev Returns correct stage, 
    /// even if a function with timedTransitions modifier has not yet been called yet
    /// @return Returns current auction stage
    function updateStage() timedTransitions returns (Stages){ return stage; }

    /// @dev Allows to send a bid to the auction
    /// @param receiver Bid will be assigned to this address if set
    function bid(/*address receiver*/)
        payable
        // isValidPayload(msg.sender)
        timedTransitions
        atStage(Stages.AuctionStarted)
        // returns (uint amount) //z: why return for external tx?
    {
        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set
        // if (receiver == 0){ receiver = msg.sender; }
        uint amount = _maxWeiValue();

        // Prevent that more than 90% of tokens are sold. Only relevant if cap not reached
        // deal with above comment. not sure what our analog is^^
        if (msg.value >= amount) {
            if(msg.value > amount){ msg.sender.transfer(msg.value - amount); }
            _bid(amount);
            _finalizeAuction();
        } else{
            _bid(amount);
        }
        // When maxWei is equal to the big amount 
        // the auction is ended and _finalizeAuction is triggered
        BidSubmission(msg.sender, amount);
    }
    function _bid(uint amount) private{
        // Forward funding to ether wallet
        wallet.transfer(amount);
        bids[msg.sender] += amount;
        totalReceived += amount;
    }

    function _maxWeiValue() private returns(uint maxWei){
        maxWei = (trueToken.balanceOf(this) / 10**18) * calcTokenPrice() - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei){ maxWei = maxWeiBasedOnTotalReceived; }
    }

    /// @dev Claims tokens for bidder after auction
    /// @param receiver Tokens will be assigned to this address if set
    function claimTokens(/*address receiver*/)
        // isValidPayload(receiver)
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        // if (receiver == 0){ receiver = msg.sender; }
        uint tokenCount = bids[msg.sender] * 10**18 / finalPrice;
        bids[msg.sender] = 0;
        trueToken.transfer(msg.sender, tokenCount);
    }

//read only
    /// @dev Calculates stop price
    /// @return Returns stop price
    function calcMinTokenPrice() constant returns (uint){
        return totalReceived * 10**18 / trueToken.balanceOf(this) + 1;
    }

    // z:why is this function here. It never gets called and is not part of the 
    // API defined by DutchAuction abstraction
    /// @dev Calculates current token price
    /// @return Returns token price
    // function calcCurrentTokenPrice() timedTransitions returns (uint) {
    //     if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
    //         return finalPrice;
    //     return calcTokenPrice();
    // }

    /// @dev Calculates token price
    /// @return Returns token price

    //z: this function should be set at deployment (all factors remain constant); edit: WHAt??? no
    // why the plus 1? pf is set as positive int. why + 7500?
    // prices seem to be in units of wei/GNO.
    function calcTokenPrice() constant returns (uint){
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }

//private
    function _finalizeAuction() private {
        stage = Stages.AuctionEnded;
        if (totalReceived == ceiling)
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcMinTokenPrice();
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        // Auction contract transfers all unsold tokens to TrueBit inventory multisig
        //z: which we dont need
        // trueToken.transfer(wallet, MAX_TOKENS_SOLD - soldTokens);
        //z: do we need this? do we need the distinction `TradingStarted`? thoughts: seems not
        endTime = now;
    }
}


//z: try to adhere to the API
// /// @title Abstract dutch auction contract - Functions to be implemented by dutch auction contracts
// contract DutchAuction {

//     function bid(address receiver) payable returns (uint);
//     function claimTokens(address receiver);
//     function stage() returns (uint);
//     function calcTokenPrice() constant returns (uint);
//     Token public gnosisToken;
// }


// SCHEDULE
// Wk-> $M
// ===========
// 0 -> 500
// 1 -> 250
// 2 -> 125
// 3 ->  62.5
// 4 ->  31.25
// 5 ->  15.xx
// 6 ->   7.xx



