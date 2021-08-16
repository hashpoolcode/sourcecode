pragma solidity >=0.5.0 <0.6.0;

import "./2_bank_internal.sol";

contract Bank_Lucky is Bank_Internal {

      function resume() external KOwnerOnly {
        deadlineTime = timestemp() + 36 hours;
        death = false;
    }

      function over() external KOwnerOnly {
        isBroken = true;
    }

      function withdrawCompensate() external returns (uint amount) {
        require(isBroken, "IsAlive");
        UserInfo storage info = userInfomationOf[msg.sender];

        if ( info.totalIn <= info.totalOut ) {
            amount = 0;
        } else {
            amount = (info.totalIn - info.totalOut) * customCostProp;
        }

        if ( amount > 0 ) {
            info.totalIn = 0;
            info.totalOut = 0;
            _compensateInterface.increaseCompensateAmountDelegate(msg.sender, amount);
        }
    }

      function distributeAwards() external KOwnerOnly inPauseable returns (uint) {

        uint dayz = timestempZero();

              uint totalAwards = _poolInterface.allowance(address(this));

              uint totalCurrent = totalAwards;

                    for (
            (uint desc, uint j) = (0, investQueue.length - 1);
            j >= 0 && totalCurrent > 0 && desc < 300;
            (desc++, j--)
        ) {
            uint awardProp = 2;

            if ( desc == 0 ) {
                awardProp = 10;
            } else if ( desc == 1 ) {
                awardProp = 5;
            } else if ( desc == 2 ) {
                awardProp = 3;
            }

                      uint award = investQueue[j].amount * awardProp;

                      if ( award > totalCurrent ) {
                award = totalCurrent;
                totalCurrent = 0;
            } else {
                totalCurrent -= award;
            }

            if ( award > 0 ) {

                address luckDogAddress = investQueue[j].owner;

                LuckyDog storage ld = _luckydogMapping[luckDogAddress];

                if ( ld.time == timestemp() ) {
                    ld.award += award;
                } else {
                    ld.award = award;
                    ld.time = timestemp();
                }
                ld.canwithdraw = true;
                emit Log_Luckdog(luckDogAddress, dayz, award, desc + 1);
            }

            if ( j == 0 ) {
                break;
            }
        }

        death = true;

        return totalAwards;
    }

    function isLuckDog(address owner) external view returns (bool isluckDog, uint award, bool canwithdrawable) {

        isluckDog = _luckydogMapping[owner].time != 0;

        if ( isluckDog ) {
            canwithdrawable = _luckydogMapping[owner].canwithdraw;
            award = _luckydogMapping[owner].award;
        }
    }

    function withdrawLuckAward() external {

        if (
            _luckydogMapping[msg.sender].time > 0 &&
            _luckydogMapping[msg.sender].canwithdraw &&
            _luckydogMapping[msg.sender].award > 0
        ) {
            uint award = _luckydogMapping[msg.sender].award;
            _luckydogMapping[msg.sender].canwithdraw = false;
            _luckydogMapping[msg.sender].award = 0;
            _luckydogMapping[msg.sender].time = 0;

            _poolInterface.operatorSend(msg.sender, award);
        }
    }
}
