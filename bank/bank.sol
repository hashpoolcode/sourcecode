pragma solidity >=0.5.0 <0.6.0;

import "./3_bank_api.sol";
import "./3_bank_views.sol";
import "./3_bank_lucky.sol";
import "./3_bank_config.sol";

contract Bank is Bank_API, Bank_Views, Bank_Lucky, Bank_Config {
    
}
