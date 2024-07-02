// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Plair is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Plair", "PFX") Ownable(initialOwner) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
