// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

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

contract Sangita is ERC20Interface{
    string public name = "Sangita";
    string public symbol = "SAN";
    uint public decimal = 0;
    uint public override totalSupply;

    address public founder;
    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) public allowed;

    constructor(){
        founder = msg.sender;
        totalSupply = 1000;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns(uint) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public virtual override returns(bool) {
        require(balances[msg.sender]>=tokens,"Insufficient funds");

        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns(uint){
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
        require(balances[from] >= tokens);
        require(allowed[from][to] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][msg.sender] -= tokens;

        emit Transfer(from, to, tokens);
        return true;
    }
}

contract SangitaICO is Sangita{
    address public admin;
    address payable public deposit;
    uint public tokenPrice = 0.001 ether;
    uint public hardCap = 300;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800;
    uint public tokenTradeStart = saleEnd + 604800;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;  

    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;

    constructor(address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    modifier onlyAdmin{
        require(msg.sender == admin);
        _;
    }
    
    function halt() public onlyAdmin{
        icoState = State.halted;
    }

    function resume() public onlyAdmin{
        icoState = State.running;
    }

    function changeDepositAddress(address payable _deposit) public onlyAdmin{
        deposit = _deposit;
    }

    function getCurrentState() public view returns (State){
        if(icoState == State.halted){
            return icoState;
        }
        else if(block.timestamp < saleStart){
            return State.beforeStart;
        }
        else if(block.timestamp >= saleStart && block.timestamp < saleEnd){
            return State.running;
        }
        else{
            return State.afterEnd;
        }
    }

    event Invest(address investor, uint amount, uint token);

    function invest() public payable returns(bool){
        icoState = getCurrentState();
        require(icoState == State.running);

        require(msg.value >= minInvestment && msg.value <= maxInvestment);

        require(raisedAmount+msg.value <= hardCap);
        raisedAmount += msg.value;

        uint sanToken = msg.value / tokenPrice;

        balances[msg.sender] +=sanToken;
        balances[founder] -=sanToken;
        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, sanToken);

        return true;

    }

    receive() external payable {
        invest();
    }

}
