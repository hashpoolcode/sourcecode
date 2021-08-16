pragma solidity >=0.5.0 <0.6.0;

import "../core/k.sol";
import "../pool/pool.sol";
import "../tokens/interface/IERC777_1.sol";

import { RelationshipInterfaceNoPayable } from "../defieraInterface/relationship/interface.sol";

interface LevelMigrater {
       function InfomationOf(address owner) external view returns (
        bool isvaild,
        uint vaildMemberTotal,
        uint selfAchievements,
        uint dlevel
    );
}

interface ConditionDelegate {
    function conditionLevelOneFinished(address owner) external view returns (bool);
    function totalInOut(address owner) external view returns (uint totalIn, uint totalOut);
}

contract ManagerStorage is KStoragePayable {

    uint public dlvDepthMaxLimit = 512;

       uint[] public dlevelAwarProp = [
        0.00e12,
        0.10e12,        0.05e12,        0.05e12,        0.05e12,        0.05e12     ];

       RelationshipInterfaceNoPayable internal _rlsInterface;
    ConditionDelegate internal _mrgInterface;
    Pool internal _poolInterface;
    iERC777_1 internal _usdtInterface;

       uint[6] public latestDistributeTime;

       address payable internal _receiver;

       mapping(address => uint8) public levelOf;

       mapping(uint8 => address[]) internal _levelListMapping;

       mapping(address => uint8) internal _chilrenLevelMaxMapping;

    constructor(
        address payable _rcv,
        RelationshipInterfaceNoPayable rltInc,
        Pool _poolInc,
        iERC777_1 _usdtInc
    ) public {
        _rlsInterface = rltInc;
        _receiver = _rcv;
        _poolInterface = _poolInc;
        _usdtInterface = _usdtInc;
    }
}

contract Manager is ManagerStorage {

    constructor() public ManagerStorage(
        address(0),
        RelationshipInterfaceNoPayable(0),
        Pool(0),
        iERC777_1(0)
    ) {}

    function _upgradeLevel(address owner, uint8 lv) internal {

        require( levelOf[owner] < lv, "LevelLess" );

               for (uint8 i = levelOf[owner] + 1; i <= lv; i++) {
            _levelListMapping[i].push(msg.sender);
        }

        levelOf[owner] = lv;

        for (
            (uint i, address parent) = (0, owner);
            i < 32 && parent != address(0x0) && parent != address(0xdead);
            (parent = _rlsInterface.GetIntroducer(parent), i++)
        ) {
            if ( _chilrenLevelMaxMapping[parent] < lv ) {
                _chilrenLevelMaxMapping[parent] = uint8(lv);
            }
        }
    }

    function migrateOriginLevel() external returns (bool ret, uint lv) {

        (,,,uint old) = LevelMigrater(0xa842d7dB1dc1856e92c8A42ED680a87C9A97c23a).InfomationOf(msg.sender);

        if ( levelOf[msg.sender] < old ) {
            _upgradeLevel(msg.sender, uint8(old));
            return (true, old);
        }

        return (false, 0);
    }

       function _levelDistribution(address owner, uint maxLimit) internal view returns (uint[] memory distribution) {

               (address[] memory directAddresses, ) = _rlsInterface.RecommendList(owner);

               distribution = new uint[](maxLimit + 1);

                      for ( uint i = 0; i < directAddresses.length; i++) {
            uint lv = _chilrenLevelMaxMapping[directAddresses[i]];
            if ( lv <= maxLimit ) {
                distribution[lv]++;
            }
        }
    }

       function getForefathers(address owner, uint depth, uint endLevel) public view returns (uint[] memory seq, address[] memory fathers) {

        seq = new uint[](endLevel + 1);
        fathers = new address[](endLevel + 1);
        uint seqOffset = 0;
        address parent = _rlsInterface.GetIntroducer(owner);

        for (
            uint i = 0;
            ( i < depth && parent != address(0x0) && parent != address(0xdead) );
            ( i++, parent = _rlsInterface.GetIntroducer(parent) )
        ) {
            uint lv = uint(levelOf[parent]);

            if ( fathers[lv] == address(0) ) {
                fathers[lv] = parent;
                seq[seqOffset++] = uint(lv);
            }

            if ( lv >= endLevel + 1 ) {
                break;
            }
        }
    }

       function getForefathers(address owner, uint depth) public view returns (address[] memory, uint8[] memory) {

        address[] memory forefathers = new address[](depth);
        uint8[] memory levels = new uint8[](depth);

        for (
            (address parent, uint i) = (_rlsInterface.GetIntroducer(owner), 0);
            i < depth && parent != address(0) && parent != address(0xdead);
            (i++, parent = _rlsInterface.GetIntroducer(parent))
        ) {
            forefathers[i] = parent;
            levels[i] = levelOf[parent];
        }

        return (forefathers, levels);
    }

    function setConditionDelegateInc(address inc) external KOwnerOnly {
        _mrgInterface = ConditionDelegate(inc);
    }

       function upgradeDLevel() external returns (uint origin, uint current) {

        origin = levelOf[msg.sender];
        current = origin;

               if ( origin == dlevelAwarProp.length - 1 ) {
            return (origin, current);
        }

               uint[] memory childrenDLVSCount = _levelDistribution(msg.sender, dlevelAwarProp.length - 1);

               if ( current == 0 ) {
            if ( _mrgInterface.conditionLevelOneFinished(msg.sender) ) {
                current = 1;
            }
        }

                      if ( current == 1 ) {
            uint effCount = 0;
            for (uint i = current; i < dlevelAwarProp.length; i++ ) {
                effCount += childrenDLVSCount[i];
            }
            if ( effCount >= 2 ) {
                current = 2;
            }
        }

               if ( current == 2 ) {
            uint effCount = 0;
            for (uint i = current; i < dlevelAwarProp.length; i++ ) {
                effCount += childrenDLVSCount[i];
            }
            if ( effCount >= 2 ) {
                current = 3;
            }
        }

               if ( current == 3 ) {
            uint effCount = 0;
            for (uint i = current; i < dlevelAwarProp.length; i++ ) {
                effCount += childrenDLVSCount[i];
            }
            if ( effCount >= 3 ) {
                current = 4;
            }
        }

               if ( current == 4 ) {
            uint effCount = 0;
            for (uint i = current; i < dlevelAwarProp.length; i++ ) {
                effCount += childrenDLVSCount[i];
            }
            if ( effCount >= 3 ) {
                current = 5;
            }
        }

               if ( current > origin ) {
            _upgradeLevel(msg.sender, uint8(current));
        }

        return (origin, current);
    }

       function paymentDLevel(uint lv) external {

        require( lv == 1 || lv == 2);

               require( _rlsInterface.GetIntroducer(msg.sender) != address(0x0), "NoIntroducer" );

               require( levelOf[msg.sender] < lv, "CurrentLvGreatThanTarget" );

        if (lv == 1) {
            _usdtInterface.transferFrom(msg.sender, address(0x7630A0f21Ac2FDe268eF62eBb1B06876DFe71909), 300e6);
        } else {
            _usdtInterface.transferFrom(msg.sender, address(0x7630A0f21Ac2FDe268eF62eBb1B06876DFe71909), 500e6);
        }

        _upgradeLevel(msg.sender, uint8(lv));
    }

       function setDLevelAwardProp(uint dl, uint p) external KOwnerOnly {
        require( dl >= 1 && dl < dlevelAwarProp.length );
        dlevelAwarProp[dl] = p;
    }

       function setDLevelSearchDepth(uint depth) external KOwnerOnly {
        dlvDepthMaxLimit = depth;
    }

       function calculationCultureAwards(address[] calldata dlevelOwners, uint[] calldata dlevelAwards) external view returns (
        address[] memory addresses,
        uint[] memory awards
    ) {
        addresses = new address[](dlevelOwners.length * 3);
        awards = new uint[](dlevelOwners.length * 3);

        for ( uint i = 0; i < dlevelOwners.length; i++ ) {

            uint dlv = levelOf[dlevelOwners[i]];

            if ( dlevelOwners[i] == address(0) || dlv <= 0 ) {
                continue;
            }

            for (
                (uint j, address grower) = (0, _rlsInterface.GetIntroducer(dlevelOwners[i]));
                j < 3 && grower != address(0) && grower != address(0xdead);
                (grower = _rlsInterface.GetIntroducer(grower), j++)
            ) {
                if ( levelOf[grower] <= dlv ) {
                    addresses[i * 3 + j] = grower;
                    awards[i * 3 + j] = dlevelAwards[i] * 0.1e12 / 1e12;
                }
            }
        }
    }

    function calculationAwards(address owner, uint value) external view returns (
        address[] memory addresses,
        uint[] memory awards
    ) {

        uint len = dlevelAwarProp.length;
        addresses = new address[](len);
        awards = new uint[](len);

               uint[] memory awarProps = dlevelAwarProp;

        (
            uint[] memory seq,
            address[] memory fathers
        ) = getForefathers(
            owner,
            dlvDepthMaxLimit,
            dlevelAwarProp.length - 1
        );

        for ( uint i = 0; i < seq.length; i++ ) {

            uint dlv = seq[i];

            uint psum = 0;
                       for ( uint x = dlv; x > 0; x-- ) {
                psum += awarProps[x];
                awarProps[x] = 0;
            }

            if ( psum > 0 ) {
                addresses[dlv] = fathers[dlv];
                awards[dlv] = value * psum / 1e12;
            }

            if ( dlv >= dlevelAwarProp.length - 1 ) {
                break;
            }
        }
    }

    event Log_DoDistributeHolderAward(uint indexed time, uint award, uint lv);
    function distributeHolderAward(uint awardTotal, uint lv) external KOwnerOnly  {

        require( lv >= 3 && lv <= 5, "InvalidLevelParmas" );

               latestDistributeTime[lv] = timestempZero();

        address[] storage lvMembers = _levelListMapping[uint8(lv)];

        uint award = awardTotal / lvMembers.length;

        for ( uint i = 0; i < lvMembers.length; i++ ) {
            _poolInterface.operatorSend(lvMembers[i], award);
        }

        emit Log_DoDistributeHolderAward(timestempZero(), award, lv);

    }

}
