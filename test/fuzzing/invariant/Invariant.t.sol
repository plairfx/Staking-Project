// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "src/Staking.sol";
import {Deploy} from "script/DeployScript.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

// Fuzzing will call out that the mint will cause an overflow, this is expected to happen because of an handler missing in this fuzz test suite.
contract Invariants is StdInvariant, Test {
    Staking public stake;
    ERC20Mock public stakedPlair;
    address alice = makeAddr("user");

    Staking sg;

    function setUp() public {
        // Deploy ERC20Mock instances for testing

        stakedPlair = new ERC20Mock();

        address keeper = makeAddr("Keeper");

        // Deploy Stake contract with ERC20Mock addresses
        sg = new Staking(address(stakedPlair), address(keeper));
    }

    modifier stakedTokens() {
        uint256 amountToStake = 10 ether;
        sg.setStakingRewards(10000);
        sg.setLockTime(14);
        vm.startPrank(alice);
        deal(address(stakedPlair), alice, 10 ether);
        stakedPlair.approve(address(sg), 10 ether);
        sg.stake(amountToStake); // Stake tokens
        vm.stopPrank();
        _;
    }

    modifier unstakedTokens() {
        // Setting up.....
        uint256 amountTS = 10 ether;
        sg.setLockTime(14);
        vm.startPrank(alice);

        // Staking...
        deal(address(stakedPlair), alice, 10 ether);
        stakedPlair.approve(address(sg), 10 ether);
        sg.stake(amountTS); // Stake tokens
        vm.stopPrank();

        // Unstaking ...
        vm.startPrank(alice);
        console.log(vm.getBlockTimestamp());
        vm.warp(1209602);
        console.log(vm.getBlockTimestamp());
        sg.unstake(amountTS);
        vm.stopPrank();
        _;
    }

    // Important for the `StakeContract.sol::earned` function

    function invariant_totalStakedShouldUpdateAfterStakingAndUnstaking() public stakedTokens {
        uint256 afterStaking = sg.getTotalStaked();
        assertEq(afterStaking, 10 ether);

        vm.warp(15 days);
        vm.prank(alice);

        uint256 amountToStake = 10 ether;
        sg.unstake(amountToStake);

        uint256 afterUnstaking = sg.getTotalStaked();

        assertEq(afterUnstaking, 0);
    }

    function invariant_stakerBalanceShouldUpdateAfterStakingAndUnstaking() public stakedTokens {
        uint256 afterStaking = sg.getStakedBalanceUser(alice);
        assertEq(afterStaking, 10 ether);

        vm.warp(15 days);
        vm.prank(alice);

        uint256 amountToStake = 10 ether;
        sg.unstake(amountToStake);

        uint256 afterUnstaking = sg.getStakedBalanceUser(alice);

        assertEq(afterUnstaking, 0);
    }

    function invariant_StakerTokenBalanceShouldIncreaseAfterStaking() public stakedTokens {
        uint256 amountToStake = 10 ether;
        uint256 stakedBalanceAlice = sg.getStakedBalanceUser(alice);
        assertEq(amountToStake, stakedBalanceAlice);
    }

    function invariant_StakerTokenBalanceShouldDecreaseAfterUnStaking() public unstakedTokens {
        uint256 stakedBalanceAlice = sg.getStakedBalanceUser(alice);
        uint256 amountLeft = 0 ether;

        assertEq(stakedBalanceAlice, amountLeft);
    }
}
