// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IPStandardizedYieldWithAdapter {
    event SetAdapter(address indexed adapter);

    function setAdapter(address adapter) external;
}
