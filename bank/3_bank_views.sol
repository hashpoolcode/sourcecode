pragma solidity >=0.5.0 <0.6.0;

import "./2_bank_internal.sol";

contract Bank_Views is Bank_Internal {

      function selectAwardHistory(
        address owner,
        uint offset,
        uint size
    ) external view returns (
        uint total,
        uint[] memory tags,
        uint[] memory times,
        uint[] memory profixs
    ) {
        require( size <= 64, "SizeToLong" );

        bytes[] storage history = userInfomationOf[owner].awardHistory;

        total = history.length;
        times = new uint[](size);
        tags = new uint[](size);
        profixs = new uint[](size);

        uint rowLen = 0;

        for ( uint i = offset; i < offset + size && i < total; i++ ) {

            bytes memory row = history[i];
            uint seek = i - offset;
            assembly {
                mstore( add(times,   mul(add(seek, 1), 0x20)), mload(add(row, 0x20)) )
                mstore( add(tags,    mul(add(seek, 1), 0x20)), mload(add(row, 0x40)) )
                mstore( add(profixs, mul(add(seek, 1), 0x20)), mload(add(row, 0x60)) )
            }
            ++rowLen;
        }

        assembly {
            mstore( times,   rowLen )
            mstore( tags,    rowLen )
            mstore( profixs, rowLen )
        }
    }

    function selectInvest(uint offset, uint size) external view returns ( uint total, address[] memory owners, uint[] memory amounts, uint[] memory times ) {

        require(size <= 64, "SizeToLong");

        total = investQueue.length;
        owners = new address[](size);
        amounts = new uint[](size);
        times = new uint[](size);

        uint rowLen = 0;

        for (
            uint i = offset;
            i < offset + size && i < total && total > 0;
            i++
        ) {
            uint seek = i - offset;
            owners[seek] = investQueue[(total - 1) - i].owner;
            amounts[seek] = investQueue[(total - 1) - i].amount;
            times[seek] = investQueue[(total - 1) - i].time;
            ++rowLen;
        }

        assembly {
            mstore( owners, rowLen )
            mstore( amounts,rowLen )
            mstore( times,rowLen )
        }
    }

    function totalInOut(address owner) external view returns (uint totalIn, uint totalOut) {
        UserInfo memory info = userInfomationOf[owner];
        return (info.totalIn, info.totalOut);
    }

    function recommendValidUserTotalOf(address owner) external view returns (uint) {
        return userInfomationOf[owner].recommendValidUserTotal;
    }
}
