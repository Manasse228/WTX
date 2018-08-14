pragma solidity 0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 
// 
// ----------------------------------------------------------------------------

contract Wtx is ERC20Interface, Owned {
    using SafeMath for uint;

    string public constant name = "WTX Token";
    string public constant symbol = "WTX";
    uint8 public constant decimals = 18;

    uint constant public _decimals18 = uint(10) ** decimals;

    uint constant public _totalSupply    = 400000000 * _decimals18;
    uint256 public remainTokenSupply;
    
    // Total ICO supply
    uint256 private icoSupply;
    // Allocation for the WTX's founder
    uint256 private founderSupply;
    // Team and Advisor supply
    uint256 private teamAdvisorsSupply;
    // Amount of Business Development 
    uint256 private businessDevSupply;
    // Amount of Research 
    uint256 private researchSupply;
    // Amount of Reserve
    uint256 private reserveSupply;
    
    // Address where funds are collected
    address constant public wallet = 0x255ae182b2e823573FE0551FA8ece7F824Fd1E7F;
    
    address private founderWallet;
    address private teamAdvisorsWallet;
    address private businessDevWallet;
    address private researchWallet;
    address private reserveWallet;

    constructor() public { 
        balances[owner] = _totalSupply;
        whiteList[owner] = true;
        whiteList[0x2F7F14890118f3908732DD3A71bEd7DB886CbA4b] = true;
        
        icoSupply          = 200000000 * _decimals18;
        founderSupply      = 40000000  * _decimals18;
        teamAdvisorsSupply = 10000000  * _decimals18;
        businessDevSupply  = 20000000  * _decimals18;
        researchSupply     = 10000000  * _decimals18;
        reserveSupply      = 120000000 * _decimals18;
        
        founderWallet      = 0x2F7F14890118f3908732DD3A71bEd7DB886CbA4b;
        teamAdvisorsWallet = 0x2F7F14890118f3908732DD3A71bEd7DB886CbA4b;
        businessDevWallet  = 0x2F7F14890118f3908732DD3A71bEd7DB886CbA4b;
        researchWallet     = 0x2F7F14890118f3908732DD3A71bEd7DB886CbA4b;
        reserveWallet      = 0x2F7F14890118f3908732DD3A71bEd7DB886CbA4b;
        
        remainTokenSupply = icoSupply;
        
        emit Transfer(address(0), owner, _totalSupply);
    }


// ----------------------------------------------------------------------------
// mappings for implementing ERC20 
// ERC20 standard functions
// ----------------------------------------------------------------------------
    
    // Balances for each account
    mapping(address => uint) balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint)) allowed;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function _transfer(address _from, address _toAddress, uint _tokens) private {
        balances[_from] = balances[_from].sub(_tokens);
        addToBalance(_toAddress, _tokens);
        emit Transfer(_from, _toAddress, _tokens);
    }
    
    // Transfer the balance from owner's account to another account
    function transfer(address _add, uint _tokens) public returns (bool success) {
        require(_add != address(0));
        require(_tokens <= balances[msg.sender]);
        
        _transfer(msg.sender, _add, _tokens);
        return true;
    }

    /*
        Allow `spender` to withdraw from your account, multiple times, 
        up to the `tokens` amount.If this function is called again it 
        overwrites the current allowance with _value.
    */
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    /*
        Send `tokens` amount of tokens from address `from` to address `to`
        The transferFrom method is used for a withdraw workflow, 
        allowing contracts to send tokens on your behalf, 
        for example to "deposit" to a contract address and/or to charge
        fees in sub-currencies; the command should fail unless the _from 
        account has deliberately authorized the sender of the message via
        some mechanism; we propose these standardized APIs for approval:
    */
    function transferFrom(address from, address _toAddr, uint tokens) public returns (bool success) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, _toAddr, tokens);
        return true;
    }


/////////////////////// Smart Contract //////////////////////////

    // Amount of ETH received during ICO
    uint public weiRaised;
    uint public wtxRaised;
    
    uint constant public softCapWei = 50000 * _decimals18;
    uint constant public hardCapWei = 100000 * _decimals18;
    
    // Minimum purchase Token [20 wtx]
    uint constant public minPurchase = 20 * _decimals18;
    
    // 1 ether  = 2000 WTX
    uint256 public constant oneEtherValue = 2000;
    
    // WhiteList
    mapping(address => bool) public whiteList;
    
    // Ether send by address
    mapping(address => uint256) public ethSent;
    
    // map to indicate who is already received token
    mapping(address => bool) public receivedToken;
    
    
    // All dates are stored as timestamps. GMT
    uint constant public startPresale   = 1541980800; // 12.11.2018 00:00:00
    uint constant public endPresale     = 1546819199; // 06.01.2019 23:59:00
    uint constant public startCrowdsale = 1546819200; // 07.01.2019 00:00:00
    uint constant public endCrowdsale   = 1552953599; // 18.03.2019 23:59:59
    
    bool icoClosed = false;

    // get the token bonus by rate
    function _getTokenBonus(uint256 _wtx) public view returns(uint256) {
        
        if (now <= 1543190399 && now >= startPresale) {
           return _wtx.mul(30).div(100);
        } else if (now <= 1544399999 && now >= 1543190400 ) {
           return _wtx.mul(55).div(100).div(2); 
        } else if (now <= 1545609599 && now >= 1544400000) {
           return _wtx.mul(25).div(100); 
        } else if (now <= 1546819199 && now >= 1545609600) {
           return _wtx.mul(20).div(100); 
        } else if (now <= 1548028799 && now >= 1546819200) {
           return _wtx.mul(20).div(100); 
        } else if (now <= 1550447999 && now >= 1548028800) {
           return _wtx.mul(15).div(100); 
        } else if (now <= endCrowdsale && now >= 1550448000) {
           return _wtx.mul(10).div(100); 
        } else {
           return 0;
        } 
    }
    
/////////////////////// MODIFIERS ///////////////////////

    // In WhiteList
    modifier inwhiteList(address _adr){
        require(whiteList[_adr]);
        _;
    }

    // ico sill runing
    modifier icoNotClosed(){
        require(!icoClosed, "ICO is close, Thanks");
        _;
    }
    
    // address not null
    modifier addressNotNull(address _addr){
        require(_addr != address(0));
        _;
    }

    // amount >0
    modifier amountNotNull(uint256 _unit){
        require(_unit != 0);
        _;
    }
    
    // ready for distribution
    modifier distribution(){
        assert(now >= now + 14 days);
        _;
    }
    
    // ready for founder distribution
    modifier founderVestingPeriod(){
        assert(now >= now + 90 days);
        _;
    }
    
    // ready for teamAdvisor distribution
    modifier teamAdvisorVestingPeriod(){
        assert(now >= now + 90 days);
        _;
    }
    
    // ready for businessDev distribution
    modifier businessDevVestingPeriod(){
        assert(now >= now + 100 days);
        _;
    }
    
    // ready for research distribution
    modifier researchVestingPeriod(){
        assert(now >= now + 150 days);
        _;
    }
    
    // ready for reserve distribution
    modifier reserveVestingPeriod(){
        assert(now >= now + 120 days);
        _;
    }
    
    
/////////////////////// Events ///////////////////////

    /**
     * Event for token withdrawal logging
     * @param receiver who receive the tokens
     * @param amount amount of tokens sent
     */
    event TokenDelivered(address indexed receiver, uint256 amount);
    
    event AddToken(address receiver, uint256 amountToken, uint256 amountWei);


    // Add early investors
    function addInvestors(address[] members) public onlyOwner {
        for(uint i = 0; i < members.length; i++) {
            whiteList[members[i]] = true;
        }
    }
    
    // Add early investor
    function addInvestor(address _member) public onlyOwner {
        whiteList[_member] = true;
    }
    
    // get token amount bu wei send
    function _getTokenAmount(uint256 _weiAmount) private view returns (uint256) {
        uint256 token = _weiAmount * oneEtherValue;
        assert(token >= minPurchase);
        uint256  tokenBonus = _getTokenBonus(token);
        return token.add(tokenBonus);
    }
    
    // Function to purchase token
    function purchaseToken(address _addrTo) payable public 
        inwhiteList(_addrTo)    
        addressNotNull(_addrTo)
        amountNotNull(msg.value)  { 
        
        assert(weiRaised <= hardCapWei);
        assert(now >= startPresale && now <= endCrowdsale);
        assert(!icoClosed);
        
        uint _wei = msg.value;
        uint _wtxToken = _getTokenAmount(_wei);
        
        updateCrowdfundState(_wtxToken, _addrTo, _wei);
        
        _forwardFunds(); 
        emit AddToken(_addrTo, _wtxToken, _wei);
    }
    
    function updateCrowdfundState(uint256 _wtx, address _addr, uint256 _wei) private {
        
        assert(remainTokenSupply >= _wtx);
        remainTokenSupply = remainTokenSupply.sub(_wtx);
        
        // Token raised
        wtxRaised = wtxRaised.add(_wtx);
        // Wei raised by address
        ethSent[_addr] = ethSent[_addr].add(_wei);
        // Total wei raised
        weiRaised = weiRaised.add(_wei);
        // Change balances
        addToBalance(_addr, _wtx);
        // Set this address to false to not receive token before tokenDistribution
        receivedToken[_addr] = false;
    }
    
     /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() private {
        wallet.transfer(msg.value);
    }

    
    /**
     * @dev Deliver tokens to receiver_ after crowdsale ends.
     */
    function withdrawTokensFor(address receiver_) private addressNotNull(receiver_) {
        require(!receivedToken[receiver_]);
        
        uint256 amount = balances[receiver_];
        require(balances[owner] >= amount);
        
        balances[owner] = balances[owner].sub(balances[receiver_]);
        
        emit Transfer(owner, receiver_, amount);
        receivedToken[receiver_] = true;
    }
    
    function tokenDistribution(address[] members) public onlyOwner {
    
        require(icoClosed);
        for(uint i = 0; i < members.length; i++) {
            withdrawTokensFor(members[i]);
        }
        
    }
    
    // Release WTX team supply after vesting period is finished.
    function releaseWtxTeamTokens() public onlyOwner
                            teamAdvisorVestingPeriod returns(bool success) {
        require(teamAdvisorsSupply > 0);
        addToBalance(teamAdvisorsWallet, teamAdvisorsSupply);
        emit Transfer(owner, teamAdvisorsWallet, teamAdvisorsSupply);
        teamAdvisorsSupply = 0;
        return true;
    }
    
    // Add to balance
    function addToBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].add(_amount);
    }

    function () payable external {
        purchaseToken(msg.sender);
    }
    

    // Account 2 0x2F7F14890118f3908732DD3A71bEd7DB886CbA4b

}