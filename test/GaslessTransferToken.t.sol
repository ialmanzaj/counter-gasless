// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { GaslessTransferToken } from "../src/GaslessTransferToken.sol";
import { ERC20Permit } from "../src/ERC20Permit.sol";

contract GaslessTransferTokenTest is PRBTest, StdCheats {
    ERC20Permit private token;
    GaslessTransferToken internal gasless;
    uint256 constant AMOUNT = 1000;
    uint256 constant SENDER_PRIVATE_KEY = 111;
    uint256 constant FEE = 10;
    address sender;
    address receiver;

    function setUp() public virtual {
        sender = vm.addr(SENDER_PRIVATE_KEY);
        receiver = address(2);
        token = new ERC20Permit("Test", "TEST", 18);
        token.mint(sender, AMOUNT + FEE);
        gasless = new GaslessTransferToken();
    }

    function testValidSig() public {
        uint256 deadline = block.timestamp + 60;
        //prepare permit message
        bytes32 permitHash = _getPermitHash(sender, address(gasless), AMOUNT + FEE, token.nonces(sender), deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SENDER_PRIVATE_KEY, permitHash);
        //excecute send
        gasless.send(address(token), sender, receiver, AMOUNT, FEE, deadline, v, r, s);
        //check token balances

        //sender should be zero due amount goes to receiver
        assertEq(token.balanceOf(sender), 0, "sender balance");
        //receiver should be total amount due to sender sending it all
        assertEq(token.balanceOf(receiver), AMOUNT, "receiver balance");
        //the contract relayer(gasless) should has the fee
        assertEq(token.balanceOf(address(this)), FEE, "fee");
    }

    function _getPermitHash(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    )
        private
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value,
                        nonce,
                        deadline
                    )
                )
            )
        );
    }
}
