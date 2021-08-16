pragma solidity >=0.5.0 <0.6.0;

import "../core/k.sol";
import "../tokens/interface/IERC20.sol";
import "../tokens/interface/IERC777_1.sol";

interface SwapInterface {

    struct Info {
               uint roundID;
               uint total;
               uint current;
               uint prop;
    }

       event Log_UpdateSwapInfo(uint when, address who, uint total, uint prop);

       event Log_Swaped(address indexed owner, uint time, uint inAmount, uint outAmount);
}
