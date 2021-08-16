pragma solidity >=0.5.0 <0.6.0;

import "./interface.sol";

contract SwapStorage is SwapInterface, KStoragePayable {

       uint public swapedTotalSum;

       Info public swapInfo;

    iERC20 internal usdtInterface;

       uint public swapQuota = 10e6;

       mapping( address => mapping(uint => uint) ) public quotaMapping;

    constructor(iERC20 usdInc) public {

        usdtInterface = usdInc;

               swapInfo = Info(
            1,            100000e18,            0,            10e12        );
    }
}

contract Swap is SwapStorage {

    constructor() public SwapStorage(iERC20(0)) {}

       function swapLimit(address owner) public view returns (uint limit) {
        if ( quotaMapping[owner][timestempZero()] >= swapQuota ) {
            return 0;
        } else {
            return swapQuota - quotaMapping[owner][timestempZero()];
        }
    }


    function doswaping(uint amount) external KRejectContractCall returns (uint tokenAmount) {

        require( amount <= swapLimit(msg.sender), "InsufficientQuota" );

               tokenAmount = amount * swapInfo.prop;

               require(swapInfo.current + tokenAmount <= swapInfo.total, "SwapBalanceInsufficient");

               swapInfo.current += tokenAmount;
        swapedTotalSum += tokenAmount;

        usdtInterface.transferFrom(msg.sender, address(0x7630A0f21Ac2FDe268eF62eBb1B06876DFe71909), amount);

        address payable safeAddress =  msg.sender;
        safeAddress.transfer(tokenAmount);

        emit Log_Swaped(msg.sender, timestemp(), amount, tokenAmount);

        return tokenAmount;
    }

    function updateSwapInfo(uint total, uint prop) external KOwnerOnly {

        swapInfo.roundID ++;
        swapInfo.total = total;
        swapInfo.current = 0;
        swapInfo.prop = prop;

        emit Log_UpdateSwapInfo(timestemp(), msg.sender, total, prop);
    }
}
