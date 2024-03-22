// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { GaslessTransferToken } from "../src/GaslessTransferToken.sol";
import { CounterERC2771 } from "../src/CounterERC2771.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    function run() public broadcast returns (CounterERC2771 counter) {
        //foo = new GaslessTransferToken();

        // GelatoRelay1BalanceERC2771
        address relayer = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
        counter = new CounterERC2771(relayer);
    }
}
