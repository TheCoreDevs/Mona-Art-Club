// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1967Proxy.sol";
import "./Ownable.sol";

contract MonaProxy is ERC1967Proxy, Ownable {

    constructor (address _logic) ERC1967Proxy(_logic, "") {}

    function upgradeTo(address newImplementation, bytes calldata data) external onlyOwner {
        _upgradeToAndCall(newImplementation, data, false);
    }

}