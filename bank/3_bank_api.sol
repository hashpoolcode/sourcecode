pragma solidity >=0.5.0 <0.6.0;

import "./2_bank_internal.sol";

contract Bank_API is Bank_Internal {

    using TimeLineValue for TimeLineValue.Data;

    function validDepositTotalOf(uint time) external view returns (uint) {
        return _validDepositTotal.bestMatchValue(time);
    }

    function depositList(address owner) external view returns (uint[] memory amount, uint[] memory quota, uint[] memory profix, uint[] memory time) {

        Invest storage invest = investInfomationOf[owner];

        amount = new uint[](invest.children.length);
        quota = new uint[](invest.children.length);
        profix = new uint[](invest.children.length);
        time = new uint[](invest.children.length);

        for (uint i = 0; i < invest.children.length; i++) {
            amount[i] = invest.children[i].amount;
            quota[i] = invest.children[i].profixQuota;
            profix[i] = invest.children[i].profix;
            time[i] = invest.children[i].time;
        }
    }

    function depositMaxLimit() public view returns (uint prop, uint depositQuota, uint power) {

        uint dayz = timestempZero();
        prop = bonusProportionOf[dayz];
        depositQuota = depositMaxLimitOf[dayz];
        power = 1e12;

        if ( prop == 0 || depositQuota == 0 ) {

                      uint average = 0;
            uint average_pp = 0;
            for (uint d = dayz - 7 days; d < dayz; d += 1 days) {
                uint t = _validDepositTotal.bestMatchValue(d);
                average += newPerformanceOf[d];
                depositQuota += (t * bonusProportionOf[d] / 1e12) * 2;
            }
            average /= 7;
            average_pp = depositQuota / 7;

                      if ( depositQuota < 2400e6 ) {
                depositQuota = 2400e6;
            }

                      if ( _validDepositTotal.latestValue() == 0 ) {
                prop = 0.003e12;
            } else {
                prop = average * 1e12 / average_pp / 100;
                power = 1e12;

                if ( prop < 0.003e12 ) {
                    prop = 0.003e12;
                } else if ( prop > 0.01e12 ) {
                    prop = 0.04e12;
                }

                if ( prop < 0.01e12 ) {
                    power = prop * 100;
                }
            }
        }

              power = 1e12;
    }

    function _upgradeDate() internal {
        uint dayz = timestempZero();
        if ( bonusProportionOf[dayz] == 0 || depositMaxLimitOf[dayz] == 0 ) {
            (bonusProportionOf[dayz], depositMaxLimitOf[dayz], powerProportion) = depositMaxLimit();
        }
    }

      function depositQuotaRange(address owner) external view returns (uint min, uint max) {

        min = 100e6;
        max = 10000e6;

        UserInfo storage info = userInfomationOf[owner];

        if ( investInfomationOf[owner].lastSettlementTime == 0 ) {
            if ( info.totalInMaxOfRound > 0 ) {
                min = info.totalInMaxOfRound * 0.2e12 / 1e12 / 1e6 * 1e6;
                if (min < 100e6) {
                    min = 100e6;
                }
            }
        }
              else {
            if ( investInfomationOf[owner].principal < investMaxLimit ) {
                max = investMaxLimit - investInfomationOf[owner].principal;
            } else {
                max = 0;
            }
        }
    }

    event Log_Deposit(address indexed owner, uint indexed time, uint amount);
    function deposit(uint amountOfUSD) external unPauseable KRejectContractCall {
        _upgradeDate();

        uint dayz = timestempZero();

        address parent = _rlsInc.GetIntroducer(msg.sender);

        require( investInfomationOf[msg.sender].lastSettlementTime == dayz || investInfomationOf[msg.sender].lastSettlementTime == 0, "BeforDepositMustSettlement" );

        require( parent != address(0), "NoIntroducer" );

        require( amountOfUSD > 0);

              require( newPerformanceOf[dayz] + amountOfUSD <= depositMaxLimitOf[dayz], "InsufficientQuota" );

              newPerformanceOf[dayz] += amountOfUSD;

        _validDepositTotal.increase(amountOfUSD);

              _pushDepositHistory(amountOfUSD);

        UserInfo storage info = userInfomationOf[msg.sender];

              if ( investInfomationOf[msg.sender].lastSettlementTime == 0 ) {

                      require( info.totalInMaxOfRound <= 0 || amountOfUSD >= info.totalInMaxOfRound * 0.2e12 / 1e12 / 1e6 * 1e6 );

            investInfomationOf[msg.sender].principal = amountOfUSD;
            investInfomationOf[msg.sender].profixQuota = amountOfUSD * outMultiple / 1e12;
            investInfomationOf[msg.sender].withdrawableProfix = 0;
            investInfomationOf[msg.sender].lastSettlementTime = dayz;

            delete investInfomationOf[msg.sender].children;

            investInfomationOf[msg.sender].children.push(
                Deposited(
                    amountOfUSD,
                    amountOfUSD * outMultiple / 1e12,
                    0,
                    dayz
                )
            );
        }
              else {
            require( investInfomationOf[msg.sender].principal + amountOfUSD <= investMaxLimit, "GreaterThanLimit" );

            investInfomationOf[msg.sender].principal += amountOfUSD;
            investInfomationOf[msg.sender].profixQuota += (amountOfUSD * outMultiple / 1e12);
            investInfomationOf[msg.sender].children.push(
                Deposited(
                    amountOfUSD,
                    amountOfUSD * outMultiple / 1e12,
                    0,
                    dayz
                )
            );
        }

              if ( info.totalInMaxOfRound < investInfomationOf[msg.sender].principal ) {
            info.totalInMaxOfRound = investInfomationOf[msg.sender].principal;
        }

              if ( !info.isValid && investInfomationOf[msg.sender].principal >= 1000e6) {
            info.isValid = true;
            userInfomationOf[parent].recommendValidUserTotal++ ;
        }
        info.totalIn += amountOfUSD;

              _usdtInterface.transferFrom(
            msg.sender,
            address(_poolInterface),
            amountOfUSD * 0.06e12 / 1e12
        );
              _poolInterface.recipientQuotaDelegate(PoolStorage.AssertPoolName.Insurance, amountOfUSD * 0.02e12 / 1e12);
              _poolInterface.recipientQuotaDelegate(PoolStorage.AssertPoolName.RightsAndInterests, amountOfUSD * 0.02e12 / 1e12);
              _poolInterface.recipientQuotaDelegate(PoolStorage.AssertPoolName.Operate, amountOfUSD * 0.01e12 / 1e12);
              _poolInterface.recipientQuotaDelegate(PoolStorage.AssertPoolName.Bonus, amountOfUSD * 0.01e12 / 1e12);

        _requireTransferUSDTIn(amountOfUSD * 0.94e12 / 1e12);
      
              _achievementInc.increaseDelegate(msg.sender, amountOfUSD);

        emit Log_Deposit(msg.sender, dayz, amountOfUSD);
    }

    function profixDY() public view returns (uint profix, uint cost) {

        UserInfo storage info = userInfomationOf[msg.sender];

        if ( info.totalAwardQuota > info.totalWithdrawAward ) {
            profix = info.totalAwardQuota - info.totalWithdrawAward;
            if ( info.totalWithdrawAward + profix > info.totalIn ) {
                profix = info.totalIn - info.totalWithdrawAward;
            }
        }

        cost = profix * 0.02e12 / 1e12 * customCostProp;
    }
    function withdrawDY() external payable unPauseable KRejectContractCall {
        _upgradeDate();
         (uint profix, uint cost) = profixDY();
        require(msg.value >= cost, "NotPaymentFee");

        uint dayz = timestempZero();
        UserInfo storage info = userInfomationOf[msg.sender];

        if ( profix > 0 ) {
            info.totalWithdrawAward += profix;

                      address payable brunedAddress = address(uint160(address(0xdead)));
            brunedAddress.transfer(cost);

                      info.totalOut += profix;

                      uint realTransferOut = profix * powerProportion / 1e12;
            _requireTransferUSDTOut( msg.sender, realTransferOut * 0.9e12 / 1e12);

                      _requireTransferUSDTOut( address(_poolInterface),  realTransferOut * 0.1e12 / 1e12);
            _poolInterface.recipientQuotaDelegate(PoolStorage.AssertPoolName.RightsAndInterests, realTransferOut * 0.1e12 / 1e12);

            emit Log_Withdraw(msg.sender, dayz, profix, 1);
        }
    }

    function profixST() public view returns (uint profix, uint cost) {
        uint dayz = timestempZero();

        Invest storage invest = investInfomationOf[msg.sender];
        UserInfo storage info = userInfomationOf[msg.sender];

              for ( uint d = invest.lastSettlementTime; d < dayz; d += 1 days ) {
            if ( info.totalIn > info.totalOut || bonusProportionOf[d] >= 0.04e12 ) {
                for ( uint i = 0; i < invest.children.length; i++ ) {
                    Deposited storage dep = invest.children[i];
                    if ( dep.profix >= dep.profixQuota ) {
                        continue;
                    }
                    uint sub_profix = dep.amount * bonusProportionOf[d] / 1e12;
                    if ( dep.profix + sub_profix > dep.profixQuota) {
                        profix += (dep.profixQuota - dep.profix);
                    } else {
                        profix += sub_profix;
                    }
                }
            }
        }

        uint delteQuota = invest.profixQuota - invest.withdrawableProfix;
        if ( profix > delteQuota ) {
            profix = delteQuota;
        }

        cost = profix * 0.02e12 / 1e12 * customCostProp;
    }
    function withdrawST() external payable unPauseable KRejectContractCall returns (uint profix, uint cost) {
        _upgradeDate();

        uint dayz = timestempZero();

        Invest storage invest = investInfomationOf[msg.sender];
        UserInfo storage info = userInfomationOf[msg.sender];

        {
                      for ( uint d = invest.lastSettlementTime; d < dayz; d += 1 days ) {
                if ( info.totalIn > info.totalOut || bonusProportionOf[d] >= 0.04e12 ) {
                    for ( uint i = 0; i < invest.children.length; i++ ) {
                        Deposited storage dep = invest.children[i];
                        if ( dep.profix >= dep.profixQuota ) {
                            continue;
                        }
                        uint sub_profix = dep.amount * bonusProportionOf[d] / 1e12;
                        if ( dep.profix + sub_profix > dep.profixQuota) {
                                                      _validDepositTotal.decrease(dep.amount);
                            profix += (dep.profixQuota - dep.profix);
                            dep.profix = dep.profixQuota;
                        } else {
                            dep.profix += sub_profix;
                            profix += sub_profix;
                        }
                    }
                }
            }

            uint delteQuota = invest.profixQuota - invest.withdrawableProfix;
            if ( profix > delteQuota ) {
                profix = delteQuota;
            }

            cost = profix * 0.02e12 / 1e12 * customCostProp;
        }

        require(msg.value >= cost, "NotPaymentFee");

              if ( profix > 0 ) {

            _handleParentProfix(msg.sender, profix * 0.2e12 / 1e12);

            invest.withdrawableProfix += profix;
            invest.lastSettlementTime = dayz;

                      address payable brunedAddress = address(uint160(address(0xdead)));
            brunedAddress.transfer(cost);

                      info.totalOut += profix;
            _requireTransferUSDTOut(msg.sender, profix * powerProportion / 1e12);

            emit Log_Withdraw(msg.sender, dayz, profix, 0);
        }

              if ( invest.withdrawableProfix >= invest.profixQuota ) {
            delete investInfomationOf[msg.sender];
            _validDepositTotal.decrease(invest.principal);
        }
    }
}
