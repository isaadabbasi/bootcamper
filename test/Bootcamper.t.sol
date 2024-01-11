// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import { Test } from 'forge-std/Test.sol';
import { console } from 'forge-std/Console.sol';
import { ERC721 } from '@openzeppelin-contracts/token/ERC721/ERC721.sol';
import { IERC721 } from '@openzeppelin-contracts/token/ERC721/IERC721.sol';

import { Bootcamper } from '../src/Bootcamper.sol';

contract TaskCompletionCertificate is ERC721 {

  uint private nonce = 1;
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  function mint(address _to) public {
    _mint(_to, nonce);
    ++nonce;
  }

}

contract BootcamperTest is Test {

  address private ALICE = makeAddr("ALICE");
  address private BOB = makeAddr("BOB");
  address private CHARLIE = makeAddr("CHARLIE");
  address private DEPLOYER = makeAddr("DEPLOYER");

  TaskCompletionCertificate private taskCertificate;
  Bootcamper bootcamper;

  function setUp() external {
    vm.startPrank(DEPLOYER);
    bootcamper = new Bootcamper("Bootcamper", "BCMP");
    taskCertificate = new TaskCompletionCertificate("Chapter1", "Chapter1");
    vm.stopPrank();
  }

  modifier addCourse(uint numberOfCourses) {
    address[] memory tasks = new address[](1);
    tasks[0] = address(taskCertificate);

    vm.startPrank(DEPLOYER);
    for (uint i = 0; i < numberOfCourses; ++i) {
      bootcamper.addCourse(
        1 ether,
        1735516800, // new Date("2024-12-30").valueOf()
        0,
        5,
        "Solidity for beginners",
        tasks
      );
    }
    vm.stopPrank();
    _;
  }

  modifier enroll(address _user, uint128 _id) {
    vm.prank(_user);
    vm.deal(_user, 100 ether);
    bootcamper.enroll{ value: 1 ether }(_id);
    _;
  }

  function testOwner() external {
    assertEq(bootcamper.getOwner(), DEPLOYER);
  }

  function testAddCourse() public addCourse(1) {
    console.log("Total courses: ", bootcamper.getTotalCourses());
    assertEq(bootcamper.getTotalCourses(), 1);
  }

  function testRemoveCourse() external addCourse(1) {
    assertEq(bootcamper.getTotalCourses(), 1);

    vm.prank(DEPLOYER);
    bootcamper.removeCourse(1);

    assertEq(bootcamper.getTotalCourses(), 0);
  }

  function testEnroll() external addCourse(1) {
    vm.prank(ALICE);
    vm.deal(ALICE, 100 ether);
    bootcamper.enroll{ value: 1 ether }(1);

    bool isEnrolled = bootcamper.isEnrolled(ALICE, 1);
    assertEq(isEnrolled, true);
  }

  function testWithdraw() addCourse(1) enroll(ALICE, 1) public {
    uint128 COURSE_ID = 1;
    
    vm.prank(DEPLOYER);
    taskCertificate.mint(ALICE);

    vm.prank(ALICE);
    bootcamper.withdraw(COURSE_ID);

    assertEq(bootcamper.balanceOf(ALICE), 0);
  }


  function testCollectFeesOnlyOwner() external {
    vm.prank(ALICE);
    bytes memory err = abi.encodeWithSelector(Bootcamper.Unauthorised.selector, ALICE);
    vm.expectRevert(err);
    bootcamper.collectFees();
  }

  function testCollectFees() external addCourse(1) enroll(ALICE, 1) {
    uint128 COURSE_ID = 1;

    vm.prank(DEPLOYER);
    taskCertificate.mint(ALICE);

    vm.prank(ALICE);
    bootcamper.withdraw(COURSE_ID);
  
    vm.prank(DEPLOYER);
    bootcamper.collectFees();

    uint feeCollected = (1 ether * 5) / 100;

    assertEq(DEPLOYER.balance, feeCollected);
  }

}
