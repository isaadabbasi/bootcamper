// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from 'forge-std/Script.sol';
import { console } from 'forge-std/Console.sol';

import { Bootcamper } from 'src/Bootcamper.sol';
import { DeployBootcamper } from 'script/DeployBootcamper.sol';
import { TaskCompletionCertificate, DeployCompletionCert } from 'script/DeployCompletionCert.sol';



contract BootcamperInteraction is Script {

  Bootcamper bootcamper;
  TaskCompletionCertificate taskCompletionCert;
  function run() external {
    console.log("deploying...");

    DeployBootcamper deployBootcamper = new DeployBootcamper();
    bootcamper = deployBootcamper.run();

    console.log("bootcamp created: ", address(bootcamper));
    
    DeployCompletionCert deployCompletionCert = new DeployCompletionCert();
    taskCompletionCert = deployCompletionCert.run();

    addCourse("Foundry Bootcamp");
  }

  function addCourse(string memory _name) private {
    address[] memory tasks = new address[](1);
    tasks[0] = address(taskCompletionCert);

    // vm.prank(bootcamper.getOwner());
    vm.startBroadcast(vm.envUint("ANVIL_DEPLOYER_PKEY"));
    bootcamper.addCourse(
      1 ether,
      1735516800, // new Date("2024-12-30").valueOf()
      0,
      5,
      _name,
      tasks
    );
  
    vm.stopBroadcast();
    console.log("course added");
  }


}
