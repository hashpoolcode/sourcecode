pragma solidity >=0.5.0 <0.6.0;

contract KTimeController {

    uint public offsetTime;

    function timestemp() external view returns (uint) {
        return now + offsetTime;
    }

    function increaseTime(uint t) external {
        offsetTime += t;
    }
}
