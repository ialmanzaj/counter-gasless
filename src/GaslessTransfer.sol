// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ERC2771Context } from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";

import { GelatoRelayContext } from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";

interface IERC20Permit {
    function permit(
        // sender
        address owner,
        // on behalf of ...
        address spender,
        // amount
        uint256 value,
        // permit valid for
        uint256 deadline,
        // signature -> v, r, s
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract GaslessTransfer is GelatoRelayContext {
    function send(
        IERC20Permit token,
        address sender,
        address receiver,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        onlyGelatoRelay
    {
        //Allow someone to spend tokens on behalf of the sender
        token.permit(sender, address(this), amount, deadline, v, r, s);
        // Transfer an amount of tokens from one person to another.
        token.transferFrom(sender, receiver, amount);
    }
}
