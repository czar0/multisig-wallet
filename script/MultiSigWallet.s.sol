// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {MultiSigWallet} from "src/MultiSigWallet.sol";

contract MultiSigWalletScript is Script {
    address[] public owners;
    string[] private ownersStr;
    // 42 chars or 21 bytes (including prefix 0x) is the length of an address
    uint256 public constant ADDRESS_LENGTH = 42;
    bytes1 public constant SEPARATOR = ",";

    // Extracting and setting owners
    function setUp() public {
        string memory rawOwners = vm.envString("OWNERS");
        _split(rawOwners, SEPARATOR);
        for (uint256 i = 0; i < ownersStr.length; i++) {
            require(bytes(ownersStr[i]).length == ADDRESS_LENGTH, "invalid address");
            owners.push(vm.parseAddress(ownersStr[i]));
        }
    }

    // Private key is used to sign the CREATE opcode and deploy the contract
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.broadcast(deployerPrivateKey);
        new MultiSigWallet(owners,uint(owners.length/2 + 1));
    }

    function _split(string memory str, bytes1 separator) internal {
        uint256 parts = 1;
        uint256 position = 0;

        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == separator) {
                parts++;
                ownersStr.push(_substring(str, position, i));
                position = i + 1;
            }
        }

        _substring(str, position, bytes(str).length);
    }

    function _substring(string memory base, uint256 start, uint256 end) internal pure returns (string memory) {
        bytes memory baseBytes = bytes(base);
        bytes memory result = new bytes(end - start);

        for (uint256 i = 0; i < result.length; i++) {
            result[i] = baseBytes[start + i];
        }

        return string(result);
    }
}
