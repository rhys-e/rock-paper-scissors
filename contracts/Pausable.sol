pragma solidity ^0.4.19;

import "./Owned.sol";

contract Pausable is Owned {
  bool private paused;

  event LogPausedSet(
    address indexed sender,
    bool indexed newPausedState);

  modifier whenPaused() {
    require(paused == true);
    _;
  }

  modifier whenNotPaused() {
    require(paused == false);
    _;
  }

  function Pausable(bool _isPaused)
    public
  {
    paused = _isPaused;
  }

  function setPaused(bool newState)
    public
    fromOwner
    returns(bool success)
  {
    require(paused != newState);
    paused = newState;
    emit LogPausedSet(msg.sender, newState);
    return true;
  }

  function isPaused()
    view
    public
    returns(bool isIndeed)
  {
    return paused;
  }
}