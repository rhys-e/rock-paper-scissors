import React from "react";

export default class Status extends React.Component {
  render() {
    return (
      <div className={"status " + this.props.state}>
        <code>{this.props.message}</code>
      </div>
    );
  }
}