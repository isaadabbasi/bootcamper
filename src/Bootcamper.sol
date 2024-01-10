// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin-contracts/token/ERC721/ERC721.sol";
import "@openzeppelin-contracts/token/ERC721/IERC721.sol";
import "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";

contract Bootcamper is ERC721 {
  // --- Structs and Enum --- //
  struct Bootcamp {
    uint128 id;
    uint128 deposit;
    uint128 deadline;
    uint128 timeToComplete;
    string title; // Important?
    address[] tasks;
    uint8 feePercentage;
  }

  struct Enrollment {
    uint128 courseId;
    uint128 accessNftId;
  }

  // --- Constants and Immutables --- //
  address immutable private i_owner;
  uint constant private RECORDS_PER_PAGE = 10;

  // --- State Variables --- //
  uint128 private s_feeCollected = 0;
  uint128 private s_courseId = 1;
  uint128 private s_accessNftId = 1;

  // --- Complex Structures --- //
  mapping(uint128 => Bootcamp) s_bootcamps;
  EnumerableSet.UintSet private s_bootcampIds;
  mapping(address => Enrollment[]) s_enrolled; 


    // --- Errors --- //
  error BootcamperAlreadyEnrolled(address _user);
  error UnableToUnenrollNow();
  error InvalidDepositAmount(uint _amount);
  error BootcamperNotEnrolled(address _user);
  error TransferFailed(address _from, address _to, uint256 _value);
  error Unauthorised(address _user);
  error TasksNotCompleted();

  // --- Events --- //
  event CourseAdded(uint indexed _courseId);
  event CourseRemoved(uint indexed _courseId);

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(
    _name,
    _symbol
  ) {
    i_owner = msg.sender;
  }

  // fallback() external {
  // todo // enroll(); - what can be done
  // }

  modifier onlyOwner() {
    if (msg.sender != i_owner) {
      revert Unauthorised(msg.sender);
    }
    _;
  }

  function addCourse(
    uint128 _deposit,
    uint128 _deadline,
    uint128 _timeToComplete,
    uint8 _feePercentage,
    string memory _title,
    address[] memory _tasks
  ) external onlyOwner {
    // TODO - implement as CEI
    Bootcamp storage newBootcamp = s_bootcamps[s_courseId];

    newBootcamp.id = s_courseId;
    newBootcamp.deposit = _deposit;
    newBootcamp.deadline = _deadline;
    newBootcamp.timeToComplete = _timeToComplete;
    newBootcamp.feePercentage = _feePercentage;
    newBootcamp.title = _title;
    newBootcamp.tasks = _tasks;

    EnumerableSet.add(s_bootcampIds, s_courseId);

    emit CourseAdded(s_courseId);
    s_courseId = s_courseId + 1;
  }

  function removeCourse(uint128 _id) external onlyOwner {
    // Can we remove an ongoing course? uint128 studentsEnrolled?

    delete s_bootcamps[_id];
    EnumerableSet.remove(s_bootcampIds, _id);
    emit CourseRemoved(_id);
  }

  function collectFees() external onlyOwner {
    (bool success, ) = i_owner.call{value: s_feeCollected}("");
    if (!success) {
      revert TransferFailed(address(this), i_owner, s_feeCollected);
    }
  }

  function enroll(uint128 _id) external payable {    
    // check if user isn't already enrolled
    if (isEnrolled(msg.sender, _id)) {
      revert BootcamperAlreadyEnrolled(msg.sender);
    }

    Bootcamp storage bootcamp = s_bootcamps[_id];
    // check if deadline isn't passed
    // check if deadline has atleast i_idealTimeToComplete left
    if (block.timestamp > bootcamp.deadline - bootcamp.timeToComplete) {
      revert UnableToUnenrollNow();
    }

    // check if deposit is equal to i_deposit
    if (msg.value != bootcamp.deposit) {
      revert InvalidDepositAmount(msg.value);
    }
    
    s_enrolled[msg.sender].push(Enrollment({ courseId: _id, accessNftId: s_accessNftId }));
    // sends the access nft from Bootcamper to msg.sender (user)
    _mint(msg.sender, s_accessNftId);
    s_accessNftId = s_accessNftId + 1;
  }

  function _revertIfTasksNotCompleted(address[] memory _tasks) private view {
    uint totalTasks = _tasks.length;
    for (uint i = 0; i < totalTasks; ++i) {
      uint balance = IERC721(_tasks[i]).balanceOf(msg.sender);
      if (balance == 0) {
        revert TasksNotCompleted();
      }
    }
  }

  function _safeRemoveEntry(uint _idx) private {
    uint lastIndexOfEnrollment = s_enrolled[msg.sender].length - 1;
    s_enrolled[msg.sender][_idx] = s_enrolled[msg.sender][lastIndexOfEnrollment];
    s_enrolled[msg.sender].pop();
  }

  function withdraw(uint128 _id) external {
    // checks if the user is enrolled in the course
    uint enrolledInIndex = _enrolledInIndex(msg.sender, _id);
    if (enrolledInIndex == type(uint).max) {
      revert BootcamperNotEnrolled(msg.sender);
    }

    Bootcamp storage bootcamp = s_bootcamps[_id];
    
    // check if the deadline has passed
    if (block.timestamp > bootcamp.deadline - bootcamp.timeToComplete) {
      revert UnableToUnenrollNow();
    } 

    _revertIfTasksNotCompleted(bootcamp.tasks);

    // unenroll the user from course
    uint128 accessNftId = s_enrolled[msg.sender][enrolledInIndex].accessNftId;

    _safeRemoveEntry(enrolledInIndex);
    // Burn that access nft
    _burn(accessNftId);

    uint128 fees = (bootcamp.deposit * bootcamp.feePercentage) / 100;
    uint refund = bootcamp.deposit - fees;

    s_feeCollected += fees;

    (bool success, ) = msg.sender.call{value: refund}("");
    if (!success) {
      revert TransferFailed(address(this), msg.sender, refund);
    }
  }
  
  function _enrolledInIndex(address _user, uint128 _id) private view returns (uint) {
    uint enrolledIn = s_enrolled[_user].length;
    for (uint i = 0; i < enrolledIn; ++i) {
      if (s_enrolled[_user][i].courseId == _id) {
        return i;
      }
    }
    return type(uint).max;
  }

  // --- Getters --- //
  function isEnrolled(address _user, uint128 _id) public view returns (bool) {
    // bad: but we know a user will only be enrolled in few courses
    uint idx = _enrolledInIndex(_user, _id);
    return idx == type(uint).max;
  }

  function myCourses() public view returns (Bootcamp[] memory) {
    uint enrolledIn = s_enrolled[msg.sender].length;

    if (enrolledIn == 0) {
      return new Bootcamp[](0);
    }

    Bootcamp[] memory courses = new Bootcamp[](enrolledIn);

    for (uint i = 0; i < enrolledIn; ++i) {
      uint128 courseId = s_enrolled[msg.sender][i].courseId;
      Bootcamp memory bc = s_bootcamps[courseId];
      courses[i].title = bc.title;
      courses[i].id = bc.id;
      courses[i].deadline = bc.deadline;
      courses[i].timeToComplete = bc.timeToComplete;
    }

    return courses;
  }

  function getAllCourses(uint pageCount) public view returns (Bootcamp[] memory) {
    uint offset = (pageCount - 1) * RECORDS_PER_PAGE;
    
    uint totalCourses = EnumerableSet.length(s_bootcampIds) - 1;
    if (offset >= totalCourses) {
      return new Bootcamp[](0);
    }
    uint[] memory ids = EnumerableSet.values(s_bootcampIds);
    Bootcamp[] memory courses = new Bootcamp[](RECORDS_PER_PAGE);
    
    for (uint i = 0; i < RECORDS_PER_PAGE; ++i) {
      Bootcamp memory bc = s_bootcamps[uint128(ids[offset + i])];
      courses[i].title = bc.title;
      courses[i].id = bc.id;
      courses[i].deadline = bc.deadline;
      courses[i].timeToComplete = bc.timeToComplete;
    }

    return courses;
  }

}