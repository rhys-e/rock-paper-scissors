import style from "./stylesheets/app.css";
import React from "react";
import ReactDOM from "react-dom";
import { default as contract } from "truffle-contract";
import playerHubArtifacts from "../build/contracts/PlayerHub.json";
import { bootstrap } from "./bootstrap";

class RockPaperScissorsApp {
  constructor() {
    bootstrap((web3) => {
      Promise.promisifyAll(web3.eth, { suffix: "Promise" });
      this.start(web3);
    }, () => {
      this.initFailed();
    });
  }

  start(web3) {
    this.web3 = web3;
    const PlayerHubContract = contract(playerHubArtifacts);
    PlayerHubContract.setProvider(web3.currentProvider);
    this.PlayerHubContract = PlayerHubContract;

    PlayerHubContract.deployed()
      .then(instance => this.playerHubInstance = instance)
      .finally();
  }

  initFailed() {
    ReactDOM.render(
      <Status
          state="error"
          message="Error connecting to web3 provider" />,
      document.getElementById("root"));
  }
}

new RockPaperScissorsApp();