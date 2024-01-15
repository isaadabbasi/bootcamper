// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ERC721 } from '@openzeppelin-contracts/token/ERC721/ERC721.sol';
import { Script } from 'forge-std/Script.sol';

import { EnvConfig } from './EnvConfig.sol';

contract TaskCompletionCertificate is ERC721 {

  uint private nonce = 1;
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  function mint(address _to) public {
    _mint(_to, nonce);
    ++nonce;
  }

}

contract DeployCompletionCert is Script {

  function run() public returns (TaskCompletionCertificate) {
    EnvConfig envConfig = new EnvConfig();
    (,, uint deployerKey) = envConfig.activeConfig();
    
    vm.broadcast(deployerKey);
    TaskCompletionCertificate taskCompletionCertificate = new TaskCompletionCertificate("Task Completion Certificate", "TCC");
    
    return taskCompletionCertificate;
  }

}