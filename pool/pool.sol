pragma solidity >=0.5.1 <0.7.0;

import "../core/k.sol";
import "../tokens/interface/IERC777_1.sol";

contract PoolStorage is KStoragePayable {

    enum AssertPoolName {
               Insurance,
               RightsAndInterests,
               Operate,
               Bonus
    }

       uint[4] public availTotalAmouns = [
        0,
        0,
        0,
        0
    ];

       address[4] public operators = [
        address(0x0),
        address(0x0),
        address(0x0),
        address(0x0)
    ];

    iERC777_1 internal _usdtInterface;

    constructor(iERC777_1 usdtInc) public {
        _usdtInterface = usdtInc;
    }
}

contract Pool is PoolStorage(iERC777_1(0)) {

    function poolNameFromOperator(address operator) public view returns (AssertPoolName) {

        for (uint i = 0; i < operators.length; i++) {
            if ( operators[i] == operator ) {
                return AssertPoolName(i);
            }
        }

        require(false, "SenderIsNotOperator");
    }

       function allowance(address operator) external view returns (uint) {

        for (uint i = 0; i < operators.length; i++) {
            if ( operators[i] == operator ) {
                return availTotalAmouns[i];
            }
        }

        return 0;
    }

       function operatorSend(address to, uint amount) external {

        AssertPoolName pname = poolNameFromOperator(msg.sender);

               require( availTotalAmouns[uint(pname)] >= amount );

                      availTotalAmouns[uint(pname)] -= amount;

               _usdtInterface.transfer(to, amount);
    }

       function recipientQuotaDelegate(AssertPoolName name, uint amountQuota) external KDelegateMethod {
        availTotalAmouns[uint8(name)] += amountQuota;
    }

       function setOperator(address operator, AssertPoolName poolName) external KOwnerOnly {
        operators[uint(poolName)] = operator;
    }
}
