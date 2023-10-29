// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console2} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MultiSigWallet} from "src/MultiSigWallet.sol";

contract MultiSigWalletScript is Script {
    address[] public owners;

    // Setting owners
    function setUp() public {
        owners.push(vm.envAddress("OWNER1"));
        owners.push(vm.envAddress("OWNER2"));
        owners.push(vm.envAddress("OWNER3"));
    }

    // Private key is used to sign the CREATE opcode and deploy the contract
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new MultiSigWallet(owners,uint(owners.length/2 + 1));

        vm.stopBroadcast();
    }
}