// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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

contract GaslessTransferToken {
    function send(
        address token,
        address sender,
        address receiver,
        uint256 amount,
        uint256 fee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        //Allow someone to spend tokens on behalf of the sender
        IERC20Permit(token).permit(sender, address(this), amount + fee, deadline, v, r, s);
        // Transfer an amount of tokens from one person to another.
        IERC20Permit(token).transferFrom(sender, receiver, amount);
        // Transfer the fee amount of tokens from sender to the smart contract(relayer).
        IERC20Permit(token).transferFrom(sender, msg.sender, fee);
    }
}
