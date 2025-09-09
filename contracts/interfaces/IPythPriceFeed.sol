// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPythPriceFeed {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint256 publishTime;
    }

    function getPriceUnsafe(bytes32 id) external view returns (Price memory price);
}
