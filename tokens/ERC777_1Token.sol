pragma solidity >=0.5.1 <0.6.0;

import "../core/k.sol";
import "../core/library/SafeMath.sol";
import "./interface/IERC777_1.sol";

contract ERC777_1TokenStorage is KStorage {

    using SafeMath for uint;

    address[] internal _defaultOperators;

    mapping (address => uint) internal _balances;
    mapping (address => mapping(address => uint)) internal _allowances;
    mapping (address => mapping(address => bool)) internal _authorized;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    uint public granularity = 1;

    /**
     * @dev Constructor.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _totalSupply
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        _balances[address(this)] = _totalSupply;
        _defaultOperators.push(msg.sender);
    }
}

contract ERC777_1Token is iERC777_1, ERC777_1TokenStorage {

    constructor() public ERC777_1TokenStorage("", "", 0, 0) {

    }

       function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint amount) external KWhenNotPaused returns (bool) {
        _send(msg.sender, recipient, amount, "", msg.sender, "");
        return true;
    }

    function approve(address spender, uint value) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external KWhenNotPaused returns (bool) {
        require(amount <= _allowances[sender][msg.sender]);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _send(sender, recipient, amount, "", msg.sender, "");
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

       function addDefaultOperators(address owner) external KOwnerOnly returns (bool) {
        _defaultOperators.push(owner);
    }

    function removeDefaultOperators(address owner) external KOwnerOnly returns (bool) {
        for (uint i = 0; i < _defaultOperators.length; i++) {
            if ( _defaultOperators[i] == owner ) {
                for (uint j = i; j < _defaultOperators.length - 1; j++) {
                    _defaultOperators[j] = _defaultOperators[j+1];
                }
                delete _defaultOperators[_defaultOperators.length - 1];
                _defaultOperators.length --;
                return true;
            }
        }
        return false;
    }

    function defaultOperators() external view returns (address[] memory) {
        return _defaultOperators;
    }

    function authorizeOperator(address _operator) external {
        require(_operator != msg.sender);
        _authorized[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    function revokeOperator(address _operator) external {
        require(_operator != msg.sender);
        _authorized[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    function send(address _to, uint _amount, bytes calldata _userData) external {
        _send(msg.sender, _to, _amount, _userData, msg.sender, "");
    }

    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        for (uint i = 0; i < _defaultOperators.length; i++) {
            if ( _defaultOperators[i] == _operator )  {
                return true;
            }
        }
        return _operator == _tokenHolder || _authorized[_operator][_tokenHolder];
    }

    function operatorSend(address _from, address _to, uint _amount, bytes calldata _userData, bytes calldata _operatorData) external {
        require( isOperatorFor(msg.sender, _from), "NotAuthorized" );
        _send(_from, _to, _amount, _userData, msg.sender, _operatorData);
    }

    function mint(address _tokenHolder, uint _amount, bytes calldata _operatorData) external KOwnerOnly {
        totalSupply = totalSupply.add(_amount);
        _balances[_tokenHolder] = _balances[_tokenHolder].add(_amount);
        emit Minted(msg.sender, _tokenHolder, _amount, "", _operatorData);
    }

    function burn(uint _amount, bytes calldata _data) external {
        _send(msg.sender, address(0x0), _amount, _data, msg.sender, "");
    }

    function operatorBurn(
        address _from,
        uint _amount,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external {
        require(isOperatorFor(msg.sender, _from), "NotAuthorized");

        if ( totalSupply <= 10000000e6 ) {
            _send(_from, KContractOwners[0], _amount, _data, msg.sender, _operatorData);
        } else {
            _send(_from, address(0x0), _amount, _data, msg.sender, _operatorData);
        }
    }

    function _send(
        address _from,
        address _to,
        uint _amount,
        bytes memory _userData,
        address _operator,
        bytes memory _operatorData
    ) internal {

        require(_balances[_from] >= _amount);
        _balances[_from] = _balances[_from].sub(_amount);
        _balances[_to] = _balances[_to].add(_amount);

        if ( _to == address(0) ) {
            totalSupply -= _amount;
            emit Burned(_operator, _from, _amount, _userData, _operatorData);
        } else {
            emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        }

        emit Transfer(_from, _to, _amount);
    }

    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}
