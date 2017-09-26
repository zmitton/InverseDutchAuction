pragma solidity 0.4.11;
import "Tokens/AbstractToken.sol";


/// @title Dutch auction contract - distribution of RightTokens tokens using an auction
/// @authors Zac Mitton - <zacmitton22@gmail.com>, Stefan George - <stefan@gnosis.pm>
contract DutchAuction {
    event BidSubmission(address indexed sender, uint256 amount);

    uint constant WEI_PER_ETH = 10**18;
    uint constant BLOCKS_PER_DAY = 5760;
    uint multiplier;
    uint tokensForSale;
    Token public token;
    address public wallet;
    uint public startBlock;
    uint public endBlock;
    uint public totalReceived;
    uint public finalPriceReciprical; // atomic tokens per wei- to ensure whole numbers
    mapping (address => uint) public bids;
    Stages public stage;

    enum Stages {AuctionDeployed, AuctionStarted, AuctionEnded}

    //z: note that this will update the stage before checking
    modifier isAtStage(Stages _stage){ if(updateAndReturnStage() == _stage) _; }

    function DutchAuction(
        address _wallet,
        uint _weiFloor,
        address _token,
        uint _startBlock,
        uint usdTargetAfter1Day,
        uint usdPerEth
    ){
        wallet = _wallet;
        weiFloor = _weiFloor;
        token = Token(_token);
        tokensForSale = token.balanceOf(this);
        startBlock = _startBlock;
        multiplier = _usdTargetAfter1Day * WEI_PER_ETH * BLOCKS_PER_DAY / _usdPerEth;
        stage = Stages.AuctionStarted;
    }

    /// @dev Returns correct stage, 
    /// even if a function with updateStage modifier has not been called yet
    /// @return Returns current auction stage
    function updateAndReturnStage() returns(Stages){
        if (stage == Stages.AuctionDeployed && block.number > startBlock){
            stage = Stages.AuctionStarted;
        }
        if (stage == Stages.AuctionStarted){
            if(totalReceived >= weiCap() || weiCap() <= weiFloor){
                stage = Stages.AuctionEnded;
            }
        }
        return stage;
    }

    /// @dev Allows to send a bid to the auction
    /// @param receiver Bid will be assigned to this address if set
    function bid() payable isAtStage(Stages.AuctionStarted){
        // returned (uint amount) //z: why return for external tx?
        uint maxWei = weiCap() - totalReceived;

        if (msg.value >= maxWei) {
            if(msg.value > maxWei)
                msg.sender.transfer(msg.value - maxWei);
            _bid(maxWei);
            stage = Stages.AuctionEnded;
        } else{// (msg.value < maxWei)
            _bid(msg.value);
        }
    }

    /// @dev Claims tokens for bidder after auction
    /// @param receiver Tokens will be assigned to this address if set
    function claimTokens() isAtStage(Stages.AuctionEnded){
        // finalPrice = totalReceived / tokensForSale;
        uint tokenCount = bids[msg.sender] * totalReceived / tokensForSale;
        bids[msg.sender] = 0;
        token.transfer(msg.sender, tokenCount);
    }

//read only
    function weiCap() constant returns(uint){
        return MULTIPLIER / (block.number - startBlock);
    }
    // sanity check, remove after testing and create a js helper
    function usdCap() constant returns(uint){
        return weiCap() * 300 / WEI_PER_ETH; // 300ish
    }

//private
    function _bid(uint amount) private{
        // Forward funding to ether wallet
        wallet.transfer(amount);
        bids[msg.sender] += amount;
        totalReceived += amount;
        BidSubmission(msg.sender, amount);
    }
}


//z: try to adhere to the API
// /// @title Abstract dutch auction contract - Functions to be implemented 
// /// by dutch auction contracts
// contract DutchAuction {

//     function bid(address receiver) payable returns (uint);
//     function claimTokens(address receiver);
//     function stage() returns (uint);
//     function calcTokenPrice() constant returns (uint);
//     Token public gnosisToken;
// }

    // /// @dev Calculates stop price
    // /// @return Returns stop price
    // function calcMinTokenPrice() constant returns (uint){
    //     return totalReceived * 10**18 / token.balanceOf(this) + 1;
    // }

    // z:why is this function here. It never gets called and is not part of the 
    // API defined by DutchAuction abstraction
    /// @dev Calculates current token price
    /// @return Returns token price
    // function calcCurrentTokenPrice() updateStage returns (uint) {
    //     if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
    //         return finalPriceReciprical;
    //     return calcTokenPrice();
    // }

    /// @dev Calculates token price
    /// @return Returns token price

    //z: this function should be set at deployment (all factors remain constant); edit: WHAt??? no
    // why the plus 1? pf is set as positive int. why + 7500?
    // prices seem to be in units of wei/GNO.
    // function calcTokenPrice() constant returns (uint){
    //     return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    // }

        // if (totalReceived == ceiling)
        // else
            // finalPriceReciprical = calcMinTokenPrice();
        // uint soldTokens = totalReceived * 10**18 / finalPriceReciprical;
        // Auction contract transfers all unsold tokens to Tokens inventory multisig
        //z: which we dont need
        // token.transfer(wallet, MAX_TOKENS_SOLD - soldTokens);
        //z: do we need this? do we need the distinction `TradingStarted`? thoughts: seems not
        // endTime = now;

    // function _finalizeAuction() private {
    //     require(totalReceived != 0);
    //     stage = Stages.AuctionEnded;
    //     finalPriceReciprical = token.balanceOf(this) / totalReceived;
    //     price rounded up (because finalPriceReciprical rounded down)
    // }


// SCHEDULE
// Wk-> $M
// ===========
// Might want to start at a billion just to be safe (should start at an impossible number)

// 0  -> infinite
// 1  -> 1000
// 2  ->  500
// 3  ->  333
// 4  ->  250
// 5  ->  199
// 6  ->  166
// 7  ->  142
// 8  ->  125
// 9  ->  111
// 10 ->  100
// 11 ->   90
// 12 ->   83
// 13 ->   76
// 14 ->   71
// 15 ->   66
// 16 ->   62
















// 32 ->   31.25

// call it 6 weeks. aim for 4. aim for a full week between 125 and 62

