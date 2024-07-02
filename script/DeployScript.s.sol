// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Plair} from "../src/PFXcoin.sol";

contract Deploy is Script {
    Staking public stake;
    ERC20Mock public stakedPlair;
    Plair public PFXcoin;

    function run() external {
        // Deploy ERC20Mock tokens
        vm.startBroadcast();

        // Deploy Stake contract with ERC20Mock addresses
        address keeper = makeAddr("Keeper");
        stakedPlair = new ERC20Mock();
        stake = new Staking(address(stakedPlair), address(keeper));
        PFXcoin = new Plair(address(msg.sender));

        vm.stopBroadcast();
    }
}
