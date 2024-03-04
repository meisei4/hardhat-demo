// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract MushroomCredit is ERC20 {

    event ContractDeployed(address owner);
    event ActorAuthorized(address indexed actor, address owner);
    event ActorDeauthorized(address indexed actor, address owner);
    event MushroomCreditMinted(address indexed from, address indexed to, uint256 amount);

    mapping(address => bool) public authorizedActors;

    constructor() ERC20("MushroomCredit", "MC") {
        // console.log("MushroomCredit Contract deployed by Owner: %s", msg.sender);
        emit ContractDeployed(msg.sender);
    }

    function authorizeActor(address _actor) external {
        authorizedActors[_actor] = true;
        emit ActorAuthorized(_actor, msg.sender);
    }
    
    function deauthorizeActor(address _actor) external {
        authorizedActors[_actor] = false;
        emit ActorDeauthorized(_actor, msg.sender);
    }

    function mint(address to, uint256 amount) external {
        require(authorizedActors[msg.sender], "Unauthorized to mint");
        _mint(to, amount);
        emit MushroomCreditMinted(msg.sender, to, amount);
    }
}
