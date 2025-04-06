// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";
import "../src/MultiSigWalletFactory.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        MultiSigWallet logic = new MultiSigWallet();

        MultiSigWalletFactory factory = new MultiSigWalletFactory(
            address(logic)
        );
        console.log("MultiSigWalletFactory deployed at:", address(factory));

        console.log("MultiSigWallet deployed at:", address(logic));

        vm.stopBroadcast();
    }
}
