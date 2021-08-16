pragma solidity >=0.5.1 <0.7.0;

interface RelationshipInterface {

    enum AddRelationError {
               NoError,
               CannotBindYourSelf,
               AlreadyBinded,
               ParentUnbinded,
               ShortCodeExisted
    }

                function totalAddresses() external view returns (uint);

       function rootAddress() external view returns (address);

                function GetIntroducer(address owner ) external returns (address);

       function RecommendList(address owner) external returns (address[] memory list, uint256 len );

       function ShortCodeToAddress(bytes6 shortCode ) external returns (address);

       function AddressToShortCode(address addr ) external returns (bytes6);

       function AddressToNickName(address addr ) external returns (bytes16);

       function Depth(address addr) external returns (uint);

                function RegisterShortCode(bytes6 shortCode ) external returns (bool);

       function UpdateNickName(bytes16 name ) external;

       function AddRelation(address recommer ) external returns (AddRelationError);

       function AddRelationEx(address recommer, bytes6 shortCode, bytes16 nickname) external returns (AddRelationError);

       function Import(address owner, address recommer, bytes6 shortcode, bytes16 nickname) external;
}


interface RelationshipInterfaceNoPayable {

    enum AddRelationError {
               NoError,
               CannotBindYourSelf,
               AlreadyBinded,
               ParentUnbinded,
               ShortCodeExisted
    }

                function totalAddresses() external view returns (uint);

       function rootAddress() external view returns (address);

                function GetIntroducer(address owner ) external view returns (address);

       function RecommendList(address owner) external view returns (address[] memory list, uint256 len );

       function ShortCodeToAddress(bytes6 shortCode ) external view returns (address);

       function AddressToShortCode(address addr ) external view returns (bytes6);

       function AddressToNickName(address addr ) external view returns (bytes16);

       function Depth(address addr) external view returns (uint);
}
