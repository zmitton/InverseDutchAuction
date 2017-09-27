pragma solidity ^0.4.8;
import "./StandardToken.sol";


contract TrueToken is StandardToken {

    string public name; 
    uint8 public decimals;
    string public symbol;
    string public version = 'H0.1'; //human 0.1 standard.

    function TrueToken(
        uint256 _totalSupply,
        string _name,
        uint8 _decimals,
        string _symbol
        ) {
        balances[msg.sender] = _totalSupply;
        totalSupply = _totalSupply;
        name = _name;
        decimals = _decimals;
        symbol = _symbol;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    // TODO: check sig then transfer
    function transferEmbeddedSigner(
        address to,
        uint value,
        bytes32 authedHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )public returns (bool success){}
}
