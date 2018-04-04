pragma solidity ^0.4.19;

import "./Ownable.sol";

contract Stoppable is Ownable {
  bool private active = true;

  event LogActiveState(bool state);

  modifier isActive() {
    require(active == true);
    _;
  }

  modifier isInactive() {
    require(active == false);
    _;
  }

  function resume()
    public
    onlyOwner
    isInactive
    returns(bool success)
  {
    active = true;
    LogActiveState(active);
    return true;
  }

  function pause()
    public
    onlyOwner
    isActive
    returns(bool success)
  {
    active = false;
    LogActiveState(active);
    return true;
  }

  function isRunning()
    public
    view
    returns(bool running)
  {
    return active;
  }

  function() private {}
}