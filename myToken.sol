//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract MyToken is ERC20Interface{
    string public name = "Omer";
    string public symbol = "OFC";
    uint public decimals = 18; //18 is very common
    uint public override totalSupply;
    
    address public founderOfToken;
    mapping(address => uint) public balances;
    // balances[0x1111...] = 100;
    
    mapping(address => mapping(address => uint)) allowed;
    // allowed[0x111][0x222] = 100;
    
    
    constructor(){
        totalSupply = 1000000;
        founderOfToken = msg.sender;
        balances[founderOfToken] = totalSupply;
    }
    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    
    function approve(address spender, uint tokens) public  override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public virtual  override returns (bool success){
         require(allowed[from][msg.sender] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         allowed[from][msg.sender] -= tokens;
         balances[to] += tokens;
 
         emit Transfer(from, to, tokens);
         
         return true;
     }
}

contract MyTokenICO is MyToken {
    address public admin;
    address payable public deposit;
    uint public saleDeadline;
    uint public saleStart;
    uint public tokenPrice;
    uint public hardCap; 
    uint public tokenTradeStart;
    uint public minInvestment;
    uint public maxInvestment;
    uint public raisedAmount;
    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;

    constructor (address payable _deposit){
        admin = msg.sender;
        saleStart = block.timestamp; // the contract created date is saleStart for now
        saleDeadline = block.timestamp + 604800; // 1 week later
        tokenTradeStart = saleDeadline + 604800; // 1 week later after sale ending
        hardCap = 300 ether; // the token max ICO
        tokenPrice = 0.00002 ether; // 1 ETH = 0.00002 OFC
        maxInvestment = 2 ether; // max investment is 2 eth
        minInvestment = 1000 wei; // min investment is 1000 wei
        icoState = State.beforeStart;
        deposit = _deposit;
    }

    // EVENTS
    event Invest(address _investor, uint value, uint tokenCount);

    // MODIFIERS
    modifier onlyAdmin {
        require(admin == msg.sender);
        _;
    }

    function changeDepositAddress(address payable _addressOfDeposit) external onlyAdmin {
        deposit = _addressOfDeposit;
    }

    function getCurrentState() public view returns(State){
        if(saleStart > block.timestamp){
            return State.beforeStart;
        }
        else if(saleStart < block.timestamp && saleDeadline > block.timestamp){
            return State.running;
        }
        else if(saleDeadline < block.timestamp && tokenTradeStart > block.timestamp){
            return State.afterEnd;
        }
        else {
            return State.halted;
        }
    }

    receive() payable external {
        investForProject();
    }
    
    function investForProject() public payable {
        require(getCurrentState() == State.running, "The ICO is finished.");
        require((balances[msg.sender] * tokenPrice) + msg.value <= maxInvestment, "You have invested enough.");
        require(minInvestment <= msg.value, "Deposit above the minimum value.");
        require(maxInvestment >= msg.value, "Make a deposit below the maximum value.");

        address payable _deposit = payable(deposit);
        bool isSent = _deposit.send(msg.value);
        require(isSent);

        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);

        uint tokens = msg.value / tokenPrice;
        balances[msg.sender] += tokens;
        balances[founderOfToken] -= tokens;

        emit Invest(msg.sender, msg.value, tokens);
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart, "For token transfering the time is early.");
        MyToken.transferFrom(from, to, tokens);
        return true;
    }
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(block.timestamp > tokenTradeStart);
        MyToken.transfer(to, tokens);
        return true;
    }
    function burn() public view returns(bool){
        require(getCurrentState() == State.afterEnd);
        balances[founderOfToken] == 0;
        return true;
    }
}
