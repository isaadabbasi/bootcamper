// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from 'forge-std/Script.sol';
import { console } from 'forge-std/Console.sol';

contract EnvConfig is Script {

  uint public constant GANACHE_CHAINID = 1337;
  uint public constant ANVIL_CHAINID = 31337;
  uint public constant SEPOLIA_CHAINID = 11155111;

  struct Config {
    string name;
    string value;
    uint deployerKey;
  }
  
  Config public activeConfig;

  constructor() {
    console.log("ChainId: ", block.chainid);
    if (block.chainid == ANVIL_CHAINID) {
      setAnvilConfigActive();
    } else if (block.chainid == SEPOLIA_CHAINID) {
      setSepoliaConfigActive();
    } else if (block.chainid == GANACHE_CHAINID) {
      setGanacheConfigActive();
    } else {
      setAnvilConfigActive();
    }
  }

  function setAnvilConfigActive() private {
    activeConfig = Config({
      name: "Bootcamper",
      value: "BCMP",
      deployerKey: vm.envUint("ANVIL_DEPLOYER_PKEY")
    });
  }

  function setGanacheConfigActive() private {
    activeConfig = Config({
      name: "Bootcamper",
      value: "BCMP",
      deployerKey: vm.envUint("GANACHE_DEPLOYER_PKEY")
    });
  }

  function setSepoliaConfigActive() private {
    activeConfig = Config({
      name: "Bootcamper",
      value: "BCMP",
      deployerKey: vm.envUint("ANVIL_DEPLOYER_PKEY")
    });
  }
}