pragma solidity >=0.5.1 <0.7.0;

import "../../core/k.sol";
import './interface.sol';

contract RelationshipStorage is KStorage {

       address public constant rootAddress = address(0xdead);
       uint public totalAddresses;
       mapping ( address => address ) internal _recommerMapping;
       mapping ( address => address[] ) internal _recommerList;
       mapping ( bytes6 => address ) internal _shortCodeMapping;
       mapping ( address => bytes6 ) internal _addressShotCodeMapping;
       mapping ( address => bytes16 ) internal _nickenameMapping;
       mapping ( address => uint ) internal _depthMapping;

    constructor() public {

        address defaultAddr = address(0xdead);

                      _shortCodeMapping[0x305844454144] = defaultAddr;
        _addressShotCodeMapping[defaultAddr] = 0x305844454144;

               _recommerMapping[defaultAddr] = address(0xdeaddead);
    }
}

contract Relationship is RelationshipInterface, RelationshipStorage {
                function GetIntroducer(address owner ) external returns (address) {
        return _recommerMapping[owner];
    }

       function RecommendList(address owner) external returns (address[] memory list, uint256 len ) {
        return (_recommerList[owner], _recommerList[owner].length );
    }

       function ShortCodeToAddress(bytes6 shortCode ) external returns (address) {
        return _shortCodeMapping[shortCode];
    }

       function AddressToShortCode(address addr ) external returns (bytes6) {
        return _addressShotCodeMapping[addr];
    }

       function AddressToNickName(address addr) external returns (bytes16) {
        return _nickenameMapping[addr];
    }

    function Depth(address addr) external returns (uint) {
        return _depthMapping[addr];
    }

                function RegisterShortCode(bytes6 shortCode ) external returns (bool) {

               if ( _shortCodeMapping[shortCode] != address(0x0) ) {
            return false;
        }

               if ( _addressShotCodeMapping[msg.sender] != bytes6(0x0) ) {
            return false;
        }

               _shortCodeMapping[shortCode] = msg.sender;
        _addressShotCodeMapping[msg.sender] = shortCode;

        return true;
    }

       function UpdateNickName(bytes16 name) external {
        _nickenameMapping[msg.sender] = name;
    }

    function AddRelation(address recommer) external returns (AddRelationError) {

               if ( recommer == msg.sender ) {
            return AddRelationError.CannotBindYourSelf;
        }

               if ( _recommerMapping[msg.sender] != address(0x0) ) {
            return AddRelationError.AlreadyBinded;
        }

               if ( recommer != rootAddress && _recommerMapping[recommer] == address(0x0) ) {
            return AddRelationError.ParentUnbinded;
        }

        totalAddresses++;

               _recommerMapping[msg.sender] = recommer;
        _recommerList[msg.sender].push(msg.sender);

               _depthMapping[msg.sender] = _depthMapping[recommer] + 1;

        return AddRelationError.NoError;
    }

       function AddRelationEx(address recommer, bytes6 shortCode, bytes16 nickname) external returns (AddRelationError) {

               if ( _shortCodeMapping[shortCode] != address(0x0) ) {
            return AddRelationError.ShortCodeExisted;
        }

               if ( _addressShotCodeMapping[msg.sender] != bytes6(0x0) ) {
            return AddRelationError.ShortCodeExisted;
        }

               if ( recommer == msg.sender )  {
            return AddRelationError.CannotBindYourSelf;
        }

               if ( _recommerMapping[msg.sender] != address(0x0) ) {
            return AddRelationError.AlreadyBinded;
        }

               if ( recommer != rootAddress && _recommerMapping[recommer] == address(0x0) ) {
            return AddRelationError.ParentUnbinded;
        }

               totalAddresses++;

               _shortCodeMapping[shortCode] = msg.sender;
        _addressShotCodeMapping[msg.sender] = shortCode;
        _nickenameMapping[msg.sender] = nickname;

               _recommerMapping[msg.sender] = recommer;
        _recommerList[recommer].push(msg.sender);

               _depthMapping[msg.sender] = _depthMapping[recommer] + 1;

        return AddRelationError.NoError;
    }

       function Import(address owner, address recommer, bytes6 shortcode, bytes16 nickname) external KOwnerOnly {

               totalAddresses++;

               _shortCodeMapping[shortcode] = owner;
        _addressShotCodeMapping[owner] = shortcode;
        _nickenameMapping[owner] = nickname;

               _recommerMapping[owner] = recommer;
        _recommerList[recommer].push(owner);

               _depthMapping[owner] = _depthMapping[recommer] + 1;
    }
}
