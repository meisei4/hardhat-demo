// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// TODO: This is a crazy way to work around the 3 parameter limit to formatted prints in the hardhats version of console.log()
library LoggingUtil {
    using Strings for uint256;

    function logDeployment(address deployer, string memory contractName, address contractAddress) public {
        string memory prefix = string(abi.encodePacked("[", block.timestamp.toString(), "] -- Deployer ", Strings.toHexString(uint160(deployer), 20), " has deployed a Contract:"));
        console.log("%s %s to address: %s", prefix, contractName, contractAddress);
    }

    function logRoleAssignment(address assigner, string memory roleName, address actorAddress) public {
        string memory prefix = string(abi.encodePacked("[", block.timestamp.toString(), "] -- Assigner ", Strings.toHexString(uint160(assigner), 20), " has assigned Role: ", roleName));
        console.log("%s to Actor at address %s, who will from now on be referred to as: %s", prefix, Strings.toHexString(uint160(actorAddress), 20), roleName);
    }

    function logAuthorization(string memory authorizerName, address authorizerAddress, string memory authorizedContractName, address authorizedAddress, string memory contractType) public {
        string memory prefix = string(abi.encodePacked("[", block.timestamp.toString(), "] -- Authorizer: ", authorizerName, " at ", Strings.toHexString(uint160(authorizerAddress), 20), " has authorized Contract/Actor: ", authorizedContractName));
        console.log("%s (at address: %s) the ability to mint tokens of contract type: %s", prefix, Strings.toHexString(uint160(authorizedAddress), 20), contractType);
    }

    function logBatchStateUpdate(string memory role, address actor, string memory action, string memory state) public {
        string memory prefix = string(abi.encodePacked("[", block.timestamp.toString(), "] -- ", role, " at ", Strings.toHexString(uint160(actor), 20), " has ", action));
        console.log("%s and updated the batch to state %s", prefix, state);
    }

    function logMinting(string memory authorizedMinterName, address authorizedMinterAddress, string memory contractType, address contractAddress, address mintedToAddress, string memory details) public {
        string memory prefix1 = string(abi.encodePacked("[", block.timestamp.toString(), "] -- Authorized Minter: ", authorizedMinterName, "(", Strings.toHexString(uint160(authorizedMinterAddress), 20), ")"));
        string memory prefix2 = string(abi.encodePacked("has minted a ", contractType, " (", contractAddress, ") token to address ", Strings.toHexString(uint160(mintedToAddress), 20)));
        console.log("%s %s with details %s", prefix1, prefix2, details);
    }
}