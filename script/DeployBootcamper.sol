// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { Bootcamper } from 'src/Bootcamper.sol';
import { EnvConfig } from './EnvConfig.sol';

contract DeployBootcamper is Script {
    Bootcamper bootcamper;

    function run() public returns (Bootcamper) {
        EnvConfig envConfig = new EnvConfig();
        (
            string memory name,
            string memory symbol,
            uint256 deployerKey
        ) = envConfig.activeConfig();
        
        vm.startBroadcast(deployerKey);
        bootcamper = new Bootcamper(name, symbol);
        vm.stopBroadcast();
        
        return bootcamper;
    }
}
