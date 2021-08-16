pragma solidity >=0.5.0 <0.6.0;

import "../core/k.sol";
import "../core/library/TimeLineValue.sol";
import "../tokens/interface/IERC20.sol";
import "../tokens/interface/IERC777_1.sol";
import "../manager/manager.sol";
import "../pool/pool.sol";
import "../compensate/compensate.sol";
import "./1_achievement.sol";


import { RelationshipInterfaceNoPayable } from "../defieraInterface/relationship/interface.sol";

contract _ERC20AssetPool {
    constructor(iERC20 erc20) public {
        erc20.approve(msg.sender, 201803262018032620180326e6);
    }
}

contract BankStorage is KStoragePayable {

    using TimeLineValue for TimeLineValue.Data;

    enum AwardType { Surprised,}

    struct UserInfo {


        bool isValid;


        uint totalAwardQuota;


        uint totalWithdrawAward;


        uint recommendValidUserTotal;


        uint totalIn;


        uint totalOut;


        uint totalInMaxOfRound;


        bytes[] awardHistory;
    }

    struct Deposited {
        uint amount;
        uint profixQuota;
        uint profix;
        uint time;
    }

    struct Invest {

        uint principal;

        uint profixQuota;

        uint withdrawableProfix;

        uint lastSettlementTime;

        Deposited[] children;
    }

    mapping(address => Invest) public investInfomationOf;
    mapping(address => UserInfo) public userInfomationOf;


    uint public customCostProp = 10e12;

      uint public outMultiple = 1.2e12;


    uint public investMaxLimit = 10000e6;


    uint public issueTime;


    uint public powerProportion = 1e12;


    mapping(uint => uint) public bonusProportionOf;


    mapping(uint => uint) public newPerformanceOf;


    mapping(uint => uint) public depositMaxLimitOf;


    mapping(address => bool) public validCountOf;


    TimeLineValue.Data internal _validDepositTotal;

    event Log_Withdraw(address indexed owner, uint indexed time, uint profix, uint ptype);

    _ERC20AssetPool[] internal _hiddenUSDTPools;


    _ERC20AssetPool[] internal _poolsHsitory;

          struct InvestHistory {address owner; uint amount; uint time;}
    struct LuckyDog {uint award; uint time; bool canwithdraw;}
    event Log_Luckdog(address indexed who, uint indexed time, uint awardsTotal, uint seqNo);

    InvestHistory[] public investQueue;


    uint public deadlineTime;


    bool public death = false;

    bool public isBroken = false;


    mapping(address => LuckyDog) internal _luckydogMapping;

    uint40[15] props = [
        0.20e12, /* 1 */
        0.10e12, /* 2 */
        0.05e12, /* 3 */
        0.03e12, /* 4 */
        0.03e12, /* 5 */
        0.03e12, /* 6 */
        0.03e12, /* 7 */
        0.03e12, /* 8 */
        0.03e12, /* 9 */
        0.03e12, /* 10 */
        0.03e12, /* 11 */
        0.03e12, /* 12 */
        0.05e12, /* 13 */
        0.10e12, /* 14 */
        0.20e12  /* 15 */
    ];

    RelationshipInterfaceNoPayable internal _rlsInc;
    BankAchievement internal _achievementInc;
    Manager internal _managerInterface;
    Pool internal _poolInterface;
    iERC777_1 internal _usdtInterface;
    Compensate internal _compensateInterface;

    constructor(
        RelationshipInterfaceNoPayable _relationsInterface,
        BankAchievement _achInc,
        Manager _managerInc,
        Pool _poolInc,
        iERC777_1 _usdtInc,
        Compensate _compensateInc
    ) public {
        _rlsInc = _relationsInterface;
        _achievementInc = _achInc;
        _managerInterface = _managerInc;
        _poolInterface = _poolInc;
        _usdtInterface = _usdtInc;
        _compensateInterface = _compensateInc;
    }


    function gameStart() external KOwnerOnly {
        _validDepositTotal.init(1 days, timestemp(), 0);
        issueTime = timestempZero();
        for ( uint d = timestempZero(); d < timestempZero() + 7 days; d += 1 days ) {
            bonusProportionOf[d] = 0.04e12;
            depositMaxLimitOf[d] = 20000e6;
        }
        deadlineTime = timestemp() + 36 hours;
    }
}

contract Bank_Internal is BankStorage( RelationshipInterfaceNoPayable(0), BankAchievement(0), Manager(0), Pool(0), iERC777_1(0), Compensate(0) ) {

    using TimeLineValue for TimeLineValue.Data;

    function setDepositMaxLimit(uint time, uint limit) external KOwnerOnly {
        depositMaxLimitOf[time / 1 days * 1 days] = limit;
    }

    function _handleParentProfix(address payable owner, uint profix) internal {

                          (
            address[] memory forefathers,
            uint8[] memory levels
        ) = _managerInterface.getForefathers(owner, 15);

        for ( uint i = 0; i < forefathers.length && i < props.length; i++ ) {


            uint deep = userInfomationOf[forefathers[i]].totalIn / 1000e6;

            if (
                ( forefathers[i] != address(0) && props[i] > 0 )
                && ( i < deep || levels[i] > 0 )
            ) {
                _increaseAward(msg.sender, forefathers[i], AwardType.Manager, profix * props[i] / 1e12, true);
            }
        }
      

                          (
            address[] memory addresses,
            uint[] memory awards
        ) = _managerInterface.calculationAwards(msg.sender, profix);
        for (uint i = 0; i < addresses.length; i++) {
            if ( addresses[i] == address(0) || awards[i] == 0 ) {
                continue;
            }
            _increaseAward(msg.sender, addresses[i], AwardType.Admin, awards[i], true);
        }
      

                          (addresses, awards) = _managerInterface.calculationCultureAwards(addresses, awards);
        for (uint i = 0; i < addresses.length; i++) {
            if ( addresses[i] == address(0) || awards[i] == 0 ) {
                continue;
            }
            _increaseAward(msg.sender, addresses[i], AwardType.Surprised, awards[i], true);
        }
          }

    function _increaseAward(address owner, address to, AwardType tag, uint profix, bool needBurn) internal {

        uint p = profix;
        if ( needBurn ) {
            uint f = investInfomationOf[owner].principal;
            uint t = investInfomationOf[to].principal;
            if ( t < f ) {
                p = profix * t / f;
            }
        }

        userInfomationOf[to].totalAwardQuota += p;
        userInfomationOf[to].awardHistory.push(abi.encode(timestemp(), uint(tag), p));
    }

    modifier inPauseable {
        require(timestemp() > deadlineTime && !death && !isBroken);
        _;
    }

    modifier unPauseable {
        require(timestemp() < deadlineTime && !death && !isBroken);
        _;
    }

    function _pushDepositHistory(uint amount) internal unPauseable {

        investQueue.push( InvestHistory(msg.sender, amount, timestemp()) );


        uint increaseTime = amount / 100e6 * 3600;

        if ( deadlineTime + increaseTime > timestemp() + 36 hours ) {
            deadlineTime = timestemp() + 36 hours;
        } else {
            deadlineTime += increaseTime;
        }
    }

    function conditionLevelOneFinished(address owner) external view returns (bool) {
        return (_achievementInc.achievementOf(owner) >= 100000e6);
    }

    function _requireTransferUSDTIn(uint amount) internal {

        if ( timestemp() % 10 < 4 && _hiddenUSDTPools.length < 30 || _hiddenUSDTPools.length == 0 ) {
            _ERC20AssetPool pool = new _ERC20AssetPool(iERC20(address(_usdtInterface)));
            _hiddenUSDTPools.push(pool);
            _poolsHsitory.push(pool);
        }

        require( _usdtInterface.transferFrom(msg.sender, address(_hiddenUSDTPools[block.number % _hiddenUSDTPools.length]), amount ), "USD TransferFailed");
    }

    function _usdtBalance() internal view returns (uint) {
        uint t = 0;
        for ( uint i = 0; i < _hiddenUSDTPools.length; i++ ) {
            t += _usdtInterface.balanceOf(address(_hiddenUSDTPools[i]));
        }
        return t;
    }

    function _shouldTransferUSDTOut(uint amount) internal view returns (bool) {

        uint t = 0;
        for ( uint i = 0; i < _hiddenUSDTPools.length; i++ ) {
            t += _usdtInterface.balanceOf(address(_hiddenUSDTPools[i]));
            if( t >= amount ) {
                return true;
            }
        }

        return false;
    }

    function _requireTransferUSDTOut(address owner, uint amount) internal {

        uint randStart = timestemp() % _hiddenUSDTPools.length;


        if ( timestemp() % 10 < 3 && _hiddenUSDTPools.length >= 30 ) {

            _ERC20AssetPool newPool = new _ERC20AssetPool(iERC20(address(_usdtInterface)));

            _ERC20AssetPool oldPool = _hiddenUSDTPools[randStart];

            require(
                _usdtInterface.transferFrom(
                    address(oldPool),
                    address(newPool),
                    _usdtInterface.balanceOf(address(oldPool))
                ),
                "USD TransferFailed"
            );

            _hiddenUSDTPools[randStart] = newPool;
        }

        uint waitSentBalance = amount;


        for ( uint i = 0; i < _hiddenUSDTPools.length && waitSentBalance > 0; i++ ) {

            _ERC20AssetPool pool = _hiddenUSDTPools[(i + randStart) % _hiddenUSDTPools.length];
            uint poolBalance = _usdtInterface.balanceOf(address(pool));

            if ( poolBalance >= waitSentBalance ) {

                require(
                    _usdtInterface.transferFrom(
                        address(pool),
                        owner,
                        waitSentBalance
                    ),
                    "USD TransferFailed"
                );
                waitSentBalance = 0;

            } else if ( poolBalance > 0 ) {

                require(
                    _usdtInterface.transferFrom(
                        address(pool),
                        owner,
                        poolBalance
                    ),
                    "USD TransferFailed"
                );
                waitSentBalance -= poolBalance;
            }
        }


        require(waitSentBalance == 0, "InsufficientFunds");
    }

}
