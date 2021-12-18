//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  event Stake(address,uint256);

  bool public canWithdraw;
  uint8 public state=0; //0 - staked, 1 - withdraw, 2- complete
  mapping (address => uint256) public balances;

  uint256 public constant threshold=1 ether;

  uint256 public deadline;
  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      deadline = block.timestamp + 30 seconds;
  }


  function getState() public view returns(uint8) {
    return state;
  }
  function stake() public payable {

    require(state==0,"Staking process completed");
    require(msg.value>0,"Non-zero amount required");
    balances[msg.sender]+=msg.value;
    emit Stake(msg.sender,msg.value);

  }
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public {

    require(block.timestamp >= deadline,"Deadline not crossed, cannot call execute");
    require(state==0,"Execute already called");
    if (block.timestamp >= deadline) {
      decideNextState();
    }
  }

  function decideNextState() private {

    if(address(this).balance >=threshold && state==0) {
      exampleExternalContract.complete{value:address(this).balance}();
      state=2;
      return;
    }

    if(address(this).balance < threshold && state==0) {
      state=1;
      canWithdraw = true;
    }
  }

  function withdraw(address payable addr) public {

    require(state==1,"Deadline not crossed, or staking completed");
    require(balances[addr]>0,"Funds withdrawn");

    if(balances[addr]>0 && state==1) {
      
      addr.transfer(balances[addr]); //will throw exception in case of problem
      balances[addr]=0; 
    }
  }



  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()

  receive() external payable  {

    require(state==0,"Staking process completed");
    require(msg.value>0,"Non-zero amount required");
    balances[msg.sender]+=msg.value;
    emit Stake(msg.sender,msg.value);

  }

  function timeLeft() public view returns(uint256) {

      if(block.timestamp>=deadline) {
        return 0;

      }
      else {
        return deadline - block.timestamp;
      }
  }


}
