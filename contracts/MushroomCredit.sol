// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "../library/LoggingUtil.sol";

contract MushroomCredit is ERC20 {
    using Strings for uint256;

    event ContractDeployed(address owner);
    event ActorAuthorized(address indexed actor, address owner);
    event ActorDeauthorized(address indexed actor, address owner);
    event MushroomCreditMinted(address indexed from, address indexed to, uint256 amount);
    
    mapping(address => bool) public authorizedActors;

    constructor() ERC20("MushroomCredit", "MC") {
        LoggingUtil.logDeployment(msg.sender, "MushroomCredit", address(this));
        emit ContractDeployed(msg.sender);
    }

    function authorizeActor(address _actor) external {
        authorizedActors[_actor] = true;
        LoggingUtil.logAuthorization("Owner", msg.sender, "MushroomCredit", _actor, "MushroomCredit");
        emit ActorAuthorized(_actor, msg.sender);
    }
    
    function deauthorizeActor(address _actor) external {
        authorizedActors[_actor] = false;
        emit ActorDeauthorized(_actor, msg.sender);
    }

    function mint(address to, uint256 amount) external {
        require(authorizedActors[msg.sender], "Unauthorized to mint");
        _mint(to, amount);
        LoggingUtil.logMinting("Authorized Actor", msg.sender, "MushroomCredit", address(this), to, string(abi.encodePacked("Amount: ", amount)));
        emit MushroomCreditMinted(msg.sender, to, amount);
    }

}
