pragma solidity ^0.8.0;

interface IERC20 {
    function totalSuply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract MyToken is IERC20 {

    string public constant name = "MyToken";
    string public constant symbol = "MT";
    uint8 public constant decimal = 18;
    uint256 private _totalSuply = 100 ether;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = _totalSuply;
    }

    function totalSuply() public override view returns (uint256) {
        return _totalSuply;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return balances[owner];
    }

    function transfer(address recipient, uint amount) public override returns( bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return allowed[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        require(amount <= balances[sender]);
        require(amount <= allowed[sender][msg.sender]);
        allowed[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function burn(uint amount) public {
        balances[msg.sender] -= amount;
        _totalSuply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}

contract TokenDistributor {
    MyToken public token;
    
    address private admin;

    struct TokenClaim {
        address typeOfToken;
        uint256 amount;
    }

    mapping(address =>TokenClaim[]) public claimers;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setTokenDistribute(address tokenContract)  public {
        token = MyToken(tokenContract);
    }

    function createClaimers(
        address addressReceiver, 
        address tokenContract, 
        uint256 totalReceive
    ) onlyAdmin public returns (bool) {
        for (uint256 i; i < claimers[addressReceiver].length; i++) {
            if (claimers[addressReceiver][i].typeOfToken == tokenContract) {
                claimers[addressReceiver][i].amount = totalReceive;
                return true;
            }
        }
        claimers[addressReceiver].push(TokenClaim(tokenContract, totalReceive));
        return true;
    }

    function claim() public returns (bool) {
        require(claimers[msg.sender].length > 0);
        for (uint256 i = 0; i < claimers[msg.sender].length; i++){
            if (claimers[msg.sender][i].amount == 0) {
                continue;
            }
            setTokenDistribute(claimers[msg.sender][i].typeOfToken);
            token.transfer(msg.sender, claimers[msg.sender][i].amount);
            claimers[msg.sender][i].amount = 0;
        }
        return true; 
    }
    
    function transferAdmin(address newAdmin) public onlyAdmin {
        _transferAdmin(newAdmin);
    }

    function _transferAdmin(address newAdmin) internal {
        require(newAdmin != address(0));
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }
    
    //distrubute for one type of token
    // function createClaimers(address addr, uint256 totalReceive) onlyAdmin public returns (bool) {
    //    claimers[addr] = totalReceive;
    //    return true;
    // }

    //Distribute mutil token
    // function distribute(address[] memory users, uint256 amount) onlyOwner public returns (bool){
    //     for (uint i = 0; i < users.length; i++){
    //         token.transfer(users[i], amount);
    //     }
    //     return true;
    // }

}
