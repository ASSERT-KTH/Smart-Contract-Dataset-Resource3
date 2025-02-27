pragma solidity ^0.4.11;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    
    uint256 c = a / b;
    
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  constructor() public {
    owner = msg.sender;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  
  modifier whenPaused {
    require(paused);
    _;
  }
  
  function pause() public onlyOwner whenNotPaused returns(bool) {
    paused = true;
    emit Pause();
    return true;
  }
  
  function unpause() public onlyOwner whenPaused returns(bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

contract ERC20 {

  uint256 public totalSupply;

  function transfer(address _to, uint256 _value) public returns(bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);

  function balanceOf(address _owner) constant public returns(uint256 balance);

  function approve(address _spender, uint256 _value) public returns(bool success);

  function allowance(address _owner, address _spender) constant public returns(uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BasicToken is ERC20, Pausable {
  using SafeMath for uint256;

  event Frozen(address indexed _address, bool _value);

  mapping(address => uint256) balances;
  mapping(address => bool) public frozens;
  mapping(address => mapping(address => uint256)) allowed;

  function _transfer(address _from, address _to, uint256 _value) internal returns(bool success) {
    require(_to != 0x0);
    require(_value > 0);
    require(frozens[_from] == false);
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transfer(address _to, uint256 _value) public whenNotPaused returns(bool success) {
    require(balances[msg.sender] >= _value);
    return _transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns(bool success) {
    require(balances[_from] >= _value);
    require(allowed[_from][msg.sender] >= _value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    return _transfer(_from, _to, _value);
  }

  function balanceOf(address _owner) constant public returns(uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns(bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant public returns(uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function freeze(address[] _targets, bool _value) public onlyOwner returns(bool success) {
    require(_targets.length > 0);
    require(_targets.length <= 255);
    for (uint8 i = 0; i < _targets.length; i++) {
      assert(_targets[i] != 0x0);
      frozens[_targets[i]] = _value;
      emit Frozen(_targets[i], _value);
    }
    return true;
  }

  function transferMulti(address[] _to, uint256[] _value) public whenNotPaused returns(bool success) {
    require(_to.length > 0);
    require(_to.length <= 255);
    require(_to.length == _value.length);
    require(frozens[msg.sender] == false);
    uint8 i;
    uint256 amount;
    for (i = 0; i < _to.length; i++) {
      assert(_to[i] != 0x0);
      assert(_value[i] > 0);
      amount = amount.add(_value[i]);
    }
    require(balances[msg.sender] >= amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    for (i = 0; i < _to.length; i++) {
      balances[_to[i]] = balances[_to[i]].add(_value[i]);
      emit Transfer(msg.sender, _to[i], _value[i]);
    }
    return true;
  }
}

contract CTCK is BasicToken {

  string public constant name = "CTCK";
  string public constant symbol = "CTCK";
  uint256 public constant decimals = 18;

  constructor() public {
    
    _assign(0xF51E57F12ED5d44761d4480633FD6c5632A5B2B1, 1500);
    
    _assign(0x44C63e5EEa2b75Bb79D77BEF45716724f4A662eC, 1500);
    
    _assign(0x21d47FCDA2FAe5E3D7f45b6f0b71372df3F6acE4, 1000);
    
    _assign(0x64659538446aE6f80b96219B3E2bEe4EED40C045, 250);
    
    _assign(0xAaED68389Fd3f5c3254744c8D3e42E3B141c706D, 250);
    
    _assign(0x35ab3BDEeD40fb8Cd9E5795Ce33A01Ae00d8b59B, 250);
    
    _assign(0x8A3382E8aF54130859Cdd387aeA16B3A3F2A784b, 250);
  }

  function _assign(address _address, uint256 _value) private {
    uint256 amount = _value * (10 ** 6) * (10 ** decimals);
    balances[_address] = amount;
    allowed[_address][owner] = amount;
    totalSupply = totalSupply.add(amount);
  }
}