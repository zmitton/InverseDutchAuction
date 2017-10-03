pragma solidity ^0.4.11;
import "./token/ERC20Token.sol";

/// @title Inverse Dutch Auction Contract - A dutch auction that drops the ETH
//    being raised over time while fixing the number of tokens sold.
/// @author Zac Mitton - <zacmitton22@gmail.com>
//    Modified from the Gnosis Reverse Dutch Auction by Stefan George - <stefan@gnosis.pm>
contract InverseDutchAuction {
    event BidSubmission(address indexed sender, uint256 amount);

    uint  constant WEI_PER_ETH = 10**18;
    uint  constant BLOCKS_PER_DAY = 5760;

    uint public multiplier;
    uint public tokenParticlesForSale;
    uint public totalWeiReceived;
    uint public weiFloor;
    uint public startBlock;

    address    public wallet;
    ERC20Token public token;
    mapping (address => uint) public bids;

    Stages public stage;
    enum Stages { Deployed, Started, Fulfilled, Reverted }

    // @dev Updates stage then checks for equality
    modifier isAtStage(Stages _stage){ if(updateAndReturnStage() == _stage) _; }

    //  The ratio of usdTargetAfter1Day & usdFloor determine max length of sale
    /// @param _wallet Secure wallet to send ETH
    /// @param _token Address of token for sale
    /// @param _tokenParticlesToAuction amount of tokens for sale in elementary units
    /// @param startTime Unix timestamp to begin auction
    /// @param usdTargetAfter1Day affects the curve/determines weiCap() after 24hrs
    /// @param usdFloor Minimum to raise in USD
    /// @param usdPerEth Current ETH price estimate
    function InverseDutchAuction(
        address _wallet,
        address _token,
        uint _tokenParticlesToAuction,
        uint startTime,
        uint usdTargetAfter1Day,
        uint usdFloor,
        uint usdPerEth
    ){
        wallet = _wallet;
        token = ERC20Token(_token);
        tokenParticlesForSale = _tokenParticlesToAuction;
        startBlock = block.number + ((startTime - now)/15);
        weiFloor = usdFloor * WEI_PER_ETH / usdPerEth;
        multiplier = usdTargetAfter1Day * WEI_PER_ETH * BLOCKS_PER_DAY / usdPerEth;
        // stage = Stages.Deployed; // is this required or will it be default?
    }

    /// @dev Returns correct stage, after updating (if relevant)
    /// @return Returns current auction stage
    function updateAndReturnStage() returns(Stages){
        if(
            stage == Stages.Deployed
            && block.number > startBlock
            && token.balanceOf(this) >= tokenParticlesForSale
        ){
            stage = Stages.Started;
        }
        if(stage == Stages.Started){
            if(weiCap() <= weiFloor){
                if(totalWeiReceived < weiFloor){
                    stage = Stages.Reverted;
                }else{
                    stage = Stages.Fulfilled;
                }
            } else if(weiCap() <= totalWeiReceived){
                stage = Stages.Fulfilled;
            }
        }
        return stage;
    }

    /// @dev Allows to send a bid to the auction
    function bid() payable isAtStage(Stages.Started){
        uint maxWei = weiCap() - totalWeiReceived;

        if (msg.value >= maxWei) {
            if(msg.value > maxWei)
                msg.sender.transfer(msg.value - maxWei);
            _bid(maxWei);
            updateAndReturnStage(); // or just: stage = Stages.Fulfilled;
        } else{// (msg.value < maxWei)
            _bid(msg.value);
        }
    }

    /// @dev Claims tokens to bidder after auction fulfilled
    function claimTokens() isAtStage(Stages.Fulfilled){
        // finalPrice = totalWeiReceived / tokenParticlesForSale;
        uint tokenCount = bids[msg.sender] * totalWeiReceived / tokenParticlesForSale;
        bids[msg.sender] = 0;
        token.transfer(msg.sender, tokenCount);
    }

    /// @dev Refunds ether to bidder after auction reverted
    function refundTokens() isAtStage(Stages.Reverted){
        uint refund = bids[msg.sender];
        bids[msg.sender] = 0;
        msg.sender.transfer(refund);
    }

    //read only
    /// @dev Gives the Wei Cap implied by a bid at current moment in time
    // note that although its read only, return values do change automatically over time.
    function weiCap() constant returns(uint){
        return multiplier / (block.number - startBlock);
    }

    //private
    function _bid(uint amount) private{
        wallet.transfer(amount); // Forward funding to ether wallet
        bids[msg.sender] += amount;
        totalWeiReceived += amount;
        BidSubmission(msg.sender, amount);
    }
}


// EXAMPLE SCHEDULE
// Day -> $M
// ---------------
// 0   -> Infinity
// 1   -> 1000
// 2   ->  500
// 3   ->  333
// 4   ->  250
// 5   ->  199
// 6   ->  166
// 7   ->  142
// 8   ->  125
// 9   ->  111
// 10  ->  100
// 11  ->   90
// 12  ->   83
// 13  ->   76
// 14  ->   71
// 15  ->   66
// 16  ->   62
// ...
// 32  ->   31

