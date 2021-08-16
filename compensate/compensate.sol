pragma solidity >=0.5.1 <0.7.0;

import "../core/k.sol";

contract CompensateStorage is KStoragePayable {

    struct Compensate {
              uint total;
              uint currentWithdraw;
              uint latestWithdrawTime;
    }

      mapping(address => Compensate) public compensateMapping;

    constructor() public {

    }
}

contract Compensate is CompensateStorage {

    constructor() public CompensateStorage() {}

      event Log_CompensateCreated(address indexed owner, uint when, uint compensateAmount);

      event Log_CompensateRelase(address indexed owner, uint when, uint relaseAmount);

    function increaseCompensateAmountDelegate(address owner, uint amount) external KDelegateMethod {
        compensateMapping[owner].total += amount;

        if ( compensateMapping[owner].latestWithdrawTime == 0 ) {
            compensateMapping[owner].latestWithdrawTime = timestemp() / 1 days * 1 days;
        }

        emit Log_CompensateCreated(msg.sender, timestemp(), amount);
    }

    function withdrawCompensate() external returns (uint amount) {

        Compensate storage c = compensateMapping[msg.sender];

        if ( c.total == 0 || c.currentWithdraw >= c.total ) {
            return 0;
        }

              uint deltaDay = (now / 1 days * 1 days - c.latestWithdrawTime / 1 days * 1 days) / 1 days;
        if ( deltaDay > 0 ) {
            amount = (c.total * 0.01e12 / 1e12) * deltaDay;
        } else {
            return 0;
        }

        if ( (amount + c.currentWithdraw) > c.total ) {
            amount = c.total - c.currentWithdraw;
        }

        if ( amount > 0 ) {
            c.currentWithdraw += amount;
            c.latestWithdrawTime = timestemp() / 1 days * 1 days;

            uint256 size;
            address payable to = msg.sender;
            assembly {size := extcodesize(to)}
            require(size == 0);

            to.transfer(amount);

            emit Log_CompensateRelase(msg.sender, timestemp(), amount);
        }

    }

}
