pragma solidity >=0.5.0 <0.6.0;

import "./2_bank_internal.sol";

contract Bank_Config is Bank_Internal {

    function getRecommendProps() external view returns (uint40[15] memory) {
        return props;
    }

      function setRecommendProps(uint40[15] calldata newProps) external KOwnerOnly {
        props = newProps;
    }

    function setTodayDepositMaxLimit(uint quota) external KOwnerOnly {
        depositMaxLimitOf[timestempZero()] = quota;
    }

    function updataProportion() external KOwnerOnly {
        powerProportion = 1e12;
    }

}
