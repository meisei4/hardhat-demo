// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LoggingUtil {
    using Strings for uint256;

    function formatAddress(
        address _address
    ) private pure returns (string memory) {
        return Strings.toHexString(uint160(_address), 20);
    }

    function log(string memory message) private pure {
        console.log(message);
    }

    function timestampToDate(
        uint256 timestamp
    ) private pure returns (string memory) {
        uint256 secondsInADay = 86400;
        uint256 secondsInAnHour = 3600;
        uint256 secondsInAMinute = 60;

        uint256 day = timestamp / secondsInADay;
        uint256 year = 1970 + day / 365; // Simplified year calculation
        uint256 month = 1 + (day % 365) / 30; // Simplified month calculation
        day = 1 + ((day % 365) % 30); // Day of the month

        // Calculate hours, minutes, and seconds
        uint256 hour = (timestamp % secondsInADay) / secondsInAnHour;
        uint256 minute = ((timestamp % secondsInADay) % secondsInAnHour) /
            secondsInAMinute;
        uint256 second = ((timestamp % secondsInADay) % secondsInAnHour) %
            secondsInAMinute;

        // Concatenate and return the date and time string
        return
            string(
                abi.encodePacked(
                    year.toString(),
                    "-",
                    month < 10 ? "0" : "",
                    month.toString(),
                    "-",
                    day < 10 ? "0" : "",
                    day.toString(),
                    " ",
                    hour < 10 ? "0" : "",
                    hour.toString(),
                    ":",
                    minute < 10 ? "0" : "",
                    minute.toString(),
                    ":",
                    second < 10 ? "0" : "",
                    second.toString()
                )
            );
    }

    function logDeployment(
        address deployer,
        string memory contractName,
        address contractAddress
    ) public view {
        string memory message = string(
            abi.encodePacked(
                "[",
                timestampToDate(block.timestamp),
                "] -- Deployer ",
                formatAddress(deployer),
                " has deployed a Contract: ",
                contractName,
                " to address: ",
                formatAddress(contractAddress)
            )
        );
        log(message);
    }

    // Update other logging functions similarly to use timestampToDate for formatting dates
    // Example for logRoleAssignment:
    function logRoleAssignment(
        address assigner,
        string memory roleName,
        address actorAddress
    ) public view {
        string memory message = string(
            abi.encodePacked(
                "[",
                timestampToDate(block.timestamp),
                "] -- Assigner ",
                formatAddress(assigner),
                " has assigned Role: ",
                roleName,
                " to Actor at address ",
                formatAddress(actorAddress),
                ", who will from now on be referred to as: ",
                roleName
            )
        );
        log(message);
    }

    function logAuthorization(
        string memory authorizerName,
        address authorizerAddress,
        string memory authorizedContractName,
        address authorizedAddress,
        string memory contractType
    ) public view {
        string memory message = string(
            abi.encodePacked(
                "[",
                timestampToDate(block.timestamp),
                "] -- Authorizer: ",
                authorizerName,
                " at ",
                formatAddress(authorizerAddress),
                " has authorized Contract/Actor: ",
                authorizedContractName,
                " (at address: ",
                formatAddress(authorizedAddress),
                ") the ability to mint tokens of contract type: ",
                contractType
            )
        );
        log(message);
    }

    function logBatchStateUpdate(
        string memory role,
        address actor,
        string memory action,
        string memory state
    ) public view {
        string memory message = string(
            abi.encodePacked(
                "[",
                timestampToDate(block.timestamp),
                "] -- ",
                role,
                " at ",
                formatAddress(actor),
                " has ",
                action,
                " and updated the batch to state ",
                state
            )
        );
        log(message);
    }

    function logMinting(
        string memory authorizedMinterName,
        address authorizedMinterAddress,
        string memory contractType,
        address contractAddress,
        address mintedToAddress,
        string memory details
    ) public view {
        string memory message = string(
            abi.encodePacked(
                "[",
                timestampToDate(block.timestamp),
                "] -- Authorized Minter: ",
                authorizedMinterName,
                "(",
                formatAddress(authorizedMinterAddress),
                ") has minted a ",
                contractType,
                "(",
                formatAddress(contractAddress),
                ") token to address ",
                formatAddress(mintedToAddress),
                " with details ",
                details
            )
        );
        log(message);
    }
}
