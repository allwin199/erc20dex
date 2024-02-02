// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    error DEX__OnlyOwnerCan_CallSell();
    error DEX__InvalidAllowance();
    error DEX__TransferFailed();
    error DEX__InsufficientBalance();
    error DEX__IncorrectPrice();

    IERC20 private immutable s_associatedToken;
    uint256 private immutable i_price;
    address private immutable i_owner;

    constructor(address token, uint256 price) {
        i_owner = msg.sender;
        s_associatedToken = IERC20(token); // Token contract address
        i_price = price; // price of 1 Token
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert DEX__OnlyOwnerCan_CallSell();
        }
        _;
    }

    function sell() external onlyOwner {
        uint256 allowance = s_associatedToken.allowance(msg.sender, address(this));

        if (allowance == 0) {
            revert DEX__InvalidAllowance();
        }

        bool sent = s_associatedToken.transferFrom(msg.sender, address(this), allowance);

        if (!sent) {
            revert DEX__TransferFailed();
        }
    }

    function withdrawTokens() external onlyOwner {
        uint256 balance = s_associatedToken.balanceOf(address(this));

        s_associatedToken.transfer(msg.sender, balance);
    }

    function withdrawFunds() external onlyOwner {
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!sent) {
            revert DEX__TransferFailed();
        }
    }

    function getPrice(uint256 numTokens) public view returns (uint256) {
        return numTokens * i_price;
    }

    function getTokenBalance() public view returns (uint256) {
        uint256 tokenBalance = s_associatedToken.balanceOf(address(this));
        return tokenBalance;
    }

    function buy(uint256 numTokens) external payable {
        if (numTokens > getTokenBalance()) {
            revert DEX__InsufficientBalance();
        }

        if (msg.value < getPrice(numTokens)) {
            revert DEX__IncorrectPrice();
        }

        bool sent = s_associatedToken.transfer(msg.sender, numTokens);

        if (!sent) {
            revert DEX__TransferFailed();
        }
    }
}
