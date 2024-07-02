// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "src/Staking.sol";
import {Deploy} from "script/DeployScript.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

pragma solidity ^0.8.20;

contract TestStaking is Test {
    Staking public stake;
    ERC20Mock public stakedPlair;

    address alice = makeAddr("user");
    address bob = makeAddr("user2");

    Staking sg;

    function setUp() public {
        // Deploy ERC20Mock instances for testing

        stakedPlair = new ERC20Mock();
        address keeper = makeAddr("newKeeper");

        // Deploy Stake contract with ERC20Mock addresses
        sg = new Staking(address(stakedPlair), address(keeper));
    }

    function testIfContractIsOwner() public view {
        assert(sg.owner() == address(this));
    }

    function testIfNonOwnerCanChangeOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        sg.transferOwnership(alice);
        vm.stopPrank();
        console.log(sg.owner(), alice);
    }

    function testIfNonOwnerCanChangeKeeper() public {
        vm.prank(alice);
        vm.expectRevert();
        sg.setKeeper(alice);
        vm.stopPrank();
        console.log(sg.getKeeper(), alice);
    }

    // Staking

    function testIfStakingWorks() public {
        // Mint some stakedPlair tokens for alice

        uint256 amountToStake = 10 ether;

        vm.startPrank(alice);
        deal(address(stakedPlair), alice, 10 ether);
        stakedPlair.approve(address(sg), 10 ether);
        sg.stake(amountToStake); // Stake tokens
        vm.stopPrank();

        // Assert
        assert(sg.getStakedBalanceUser(alice) == amountToStake); // Check if staking was successful
    }

    function testIfStakingReverts() public {
        uint256 amountToStake = 10 ether;
        // i dont mint myself tokens..
        vm.startPrank(alice);
        vm.expectRevert();
        sg.stake(amountToStake);
        vm.stopPrank();
    }

    modifier stakedTokens() {
        uint256 amountToStake = 10 ether;
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
        stakedPlair.mint(alice, 100 ether); // Mint 100 stakedPlair tokens for alice
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

    modifier pausedState() {
        uint256 amountToStake = 10 ether;
        sg.setLockTime(14);
        vm.startPrank(alice);
        deal(address(stakedPlair), alice, 10 ether);
        stakedPlair.approve(address(sg), 10 ether);
        sg.stake(amountToStake); // Stake tokens
        vm.stopPrank();
        sg.pause();
        _;
    }

    // Claiming

    // function testClaimRevertsIfMoreThanMaxRewardsClaimed() public stakedTokens {
    //     address keeperTest = makeAddr("KeeperTest");
    //     sg.setStakingRewards(7200);

    //     // Setting up keeper and calling earned
    //     sg.setKeeper(keeperTest);
    //     vm.prank(keeperTest);
    //     vm.warp(7200);
    //     sg.earned();
    //     vm.stopPrank();

    //     // Alice is claiming.

    //     vm.prank(alice);
    //     sg.claim();
    //     vm.stopPrank();

    //     vm.prank(keeperTest);
    //     vm.warp(7200);
    //     sg.earned();
    //     vm.stopPrank();

    //     vm.prank(alice);
    //     vm.expectRevert();
    //     sg.claim();
    // }

    // As totalRewardsPerDay is immutable, we can't call earned for multiple timss really.

    // Unstaking

    function testIfUnlockTimeHasNotPassedItShouldRevert() public stakedTokens {
        uint256 amountTS = 10 ether;

        console.log("Unlock-Time-User:", sg.getUnlockTimeUser(alice));
        vm.startPrank(alice);
        console.log("Staked-Balance:", sg.getStakedBalanceUser(alice));
        console.log(vm.getBlockTimestamp());
        vm.warp(100);
        console.log("Unlock-Time-User After Warp:", sg.getUnlockTimeUser(alice));
        console.log(vm.getBlockTimestamp());
        vm.expectRevert();
        sg.unstake(amountTS);
        console.log("Unlock-Time-User After Warp:", sg.getUnlockTimeUser(alice));
        vm.stopPrank();
        console.log(sg.getStakedBalanceUser(alice));
    }

    function testUserCanUnstakeAfterUnlockTimeHasPassed() public stakedTokens {
        uint256 amountTS = 10 ether;

        console.log("Unlock-Time-User:", sg.getUnlockTimeUser(alice));
        vm.startPrank(alice);
        console.log("Staked-Balance:", sg.getStakedBalanceUser(alice));
        console.log(vm.getBlockTimestamp());
        vm.warp(1209602);
        console.log(vm.getBlockTimestamp());
        sg.unstake(amountTS);
        console.log(sg.getStakedBalanceUser(alice));
        vm.stopPrank();
        assert(sg.getStakedBalanceUser(alice) == 0);
        assert(stakedPlair.balanceOf(alice) == amountTS);
    }

    function testIfUserCanUnstakeTokensThatHeHasntStaked() public {
        uint256 amountTUS = 10 ether;

        vm.startPrank(alice);
        vm.expectRevert();
        sg.unstake(amountTUS);
    }

    function testIfOnlyOwnerCanSetLockTime() public {
        vm.prank(alice);
        vm.expectRevert();
        sg.setLockTime(0);
        vm.stopPrank();
    }

    function testIfOnlyOwnerCanSetStakingReward() public {
        vm.prank(alice);
        vm.expectRevert();
        sg.setStakingRewards(1);
        vm.stopPrank();
    }

    function testIfOnlyOwnerCanPause() public {
        vm.prank(alice);
        vm.expectRevert();
        sg.pause();
    }

    function testIfOnlyOwnerCanUnPause() public pausedState {
        vm.prank(alice);
        vm.expectRevert();
        sg.unpause();
    }

    //////////////////
    ///PAUSE //////
    ////////////////

    function testIfUserCanTransactWhenPaused() public {
        deal(address(stakedPlair), alice, 10 ether);
        stakedPlair.approve(address(sg), 10 ether);
        sg.pause();
        vm.prank(alice);
        vm.expectRevert();
        sg.stake(1);
    }

    function testIfUserCanTransactWhenUnpaused() public pausedState {
        console.log(sg.getStakedBalanceUser(alice));
        uint256 amountToStake = 10 ether;
        vm.warp(1209602);
        sg.unpause();
        vm.prank(alice);
        sg.unstake(amountToStake);

        assertEq(amountToStake, stakedPlair.balanceOf(alice));
    }

    //////////////////
    ///KEEPER//////
    ////////////////

    function testIfNonKeeperCanCallEarned() public {
        // address keeperTest = makeAddr("KeeperTest");
        vm.prank(alice);
        vm.expectRevert();
        sg.earned();
    }

    function testIfEarnedCanBeCalledWithin24Hours() public stakedTokens {
        address keeperTest = makeAddr("KeeperTest");

        sg.setKeeper(keeperTest);
        vm.warp(7200);

        vm.prank(keeperTest);
        sg.earned();
        vm.warp(100);
        vm.expectRevert();
        sg.earned();
    }

    function testIfSetMaxRewardsWorks() public {
        sg.setStakingRewards(1000);

        vm.prank(alice);
        assert(sg.getMaxStakingReward() == 1000);
    }

    function testWhenEarnedCalledUsersGetsRewards() public stakedTokens {
        address keeperTest = makeAddr("KeeperTest");

        sg.setKeeper(keeperTest);
        vm.warp(7200);

        vm.prank(keeperTest);
        sg.earned();
        uint256 balanceBefore = stakedPlair.balanceOf(alice);
        vm.prank(alice);
        sg.claim();
        uint256 balanceAfter = stakedPlair.balanceOf(alice);

        assertEq(balanceBefore + block.timestamp, balanceAfter);
    }

    function testRevertShouldWorkOnClaim() public stakedTokens {
        vm.startPrank(alice);
        vm.expectRevert();
        sg.claim();

        // Can't claim when keeper does not call earned function
    }

    function testIfRevrtWorksWithEarned() public {
        vm.startPrank(alice);
        vm.expectRevert();
        sg.claim();
    }

    function testTotalStakeShouldUpdate() public {
        uint256 amountTS = 10 ether;
        // Setting locktime to 14 days.
        sg.setLockTime(14);
        vm.startPrank(alice);

        // Staking...
        stakedPlair.mint(alice, 100 ether); // Mint 100 stakedPlair tokens for alice
        deal(address(stakedPlair), alice, 10 ether);
        stakedPlair.approve(address(sg), 10 ether);
        console.log("(STAKING)Total Staked Before:", sg.getTotalStaked());
        sg.stake(amountTS); // Stake tokens
        console.log("(STAKING)Total Staked After:", sg.getTotalStaked());
        assert(sg.getTotalStaked() == 10 ether);
        vm.stopPrank();

        // Unstaking...
        vm.startPrank(alice);
        vm.warp(1209602); // warping after the 14 days locktime...
        console.log("(UNSTAKING) Total Staked Before:", sg.getTotalStaked());
        sg.unstake(amountTS);
        assert(sg.getTotalStaked() == 0 ether);
        console.log("(UNSTAKING) Total Staked After:", sg.getTotalStaked()); // Insanity check lol.
        vm.stopPrank();
        // }
    }

    function testIfClaimingRewardsWork() public stakedTokens {
        address keeperTest = makeAddr("KeeperTest");
        sg.setKeeper(keeperTest);
        vm.prank(keeperTest);
        vm.warp(7200);
        sg.earned();
        vm.startPrank(alice);
        // Expected rewards are, 7200 per day. and the max.

        sg.claim();
        stakedPlair.balanceOf(alice);
        assertEq(stakedPlair.balanceOf(alice), 7200);
    }

    function testClaimingRewardsWillFailWithNoRewards() public stakedTokens {
        vm.prank(alice);
        vm.expectRevert();

        sg.claim();
    }

    function testIfClaimMinLimitWorks() public stakedTokens {
        vm.startPrank(alice);
        vm.warp(7199);
        vm.expectRevert();
        sg.claim();
    }

    function testIfGetTotalStakeWorks() public stakedTokens {
        vm.prank(alice);
        sg.getTotalStaked();

        assert(sg.getTotalStaked() == 10 ether);
    }

    function testIfGetTotalClaimedWorks() public stakedTokens {
        address keeperTest = makeAddr("KeeperTest");
        sg.setKeeper(keeperTest);
        vm.prank(keeperTest);
        vm.warp(7200);
        sg.earned();

        vm.startPrank(alice);

        sg.claim();
        assert(sg.getTotalClaimed() == 7200);
    }

    function testIfGetKeeperWorks() public {
        address keeperTest = makeAddr("KeeperTest");
        sg.setKeeper(keeperTest);
        assertEq(sg.getKeeper(), keeperTest);
    }

    function testIfGetStakedBalanaceUserWorks() public stakedTokens {
        vm.prank(alice);
        uint256 stakedBalanceAlice = 10 ether;
        uint256 stakedBalanceAliceFunc = sg.getStakedBalanceUser(alice);

        assertEq(stakedBalanceAlice, stakedBalanceAliceFunc);
    }

    function testIfGetUnlockTimeUser() public stakedTokens {
        vm.prank(alice);

        uint256 unlockTime = 14 days + 1;
        uint256 unlockTimeUser = sg.getUnlockTimeUser(alice);

        assertEq(unlockTime, unlockTimeUser);
    }

    function testIfGetRewardsUSerWorks() public stakedTokens {
        address keeperTest = makeAddr("KeeperTest");
        sg.setKeeper(keeperTest);
        vm.prank(keeperTest);
        vm.warp(7200);
        sg.earned();
        uint256 rewardsUser = sg.getRewardsUser(alice);
        vm.prank(alice);
        sg.claim();

        uint256 balanceAfterClaiming = stakedPlair.balanceOf(alice);

        assertEq(balanceAfterClaiming, rewardsUser);
    }
}
