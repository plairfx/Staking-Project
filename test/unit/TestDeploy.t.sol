// SPDX-License-Identifier: MIT

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Staking} from "src/Staking.sol";
import {Deploy} from "script/DeployScript.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {StdUtils} from "lib/forge-std/src/StdUtils.sol";

pragma solidity ^0.8.20;

contract TestDeploy is Test {
    Staking public stake;
    ERC20Mock public stakedPlair;
    address alice = makeAddr("user");

    Staking sg;
    Deploy ds;

    function setUp() public {
        // Deploy ERC20Mock instances for testing

        stakedPlair = new ERC20Mock();
        address keeper = makeAddr("Test");

        // Deploy Stake contract with ERC20Mock addresses
        sg = new Staking(address(stakedPlair), address(keeper));
    }

    // Check if the StakePlair contract is deployed
    function testDeployCorrectly() public view {
        assert(address(stakedPlair) != address(0));
        // assert(address(Keeper) != address(0));
    }
}
