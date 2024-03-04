// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MushroomCredit is ERC20 {
    mapping(address => bool) public authorizedActors;

    constructor() ERC20("MushroomCredit", "MC") {}

    function authorizeActor(address _actor) external {
        authorizedActors[_actor] = true;
    }
    
    function deauthorizeActor(address _actor) external {
        authorizedActors[_actor] = false;
    }

    function mint(address to, uint256 amount) external {
        require(authorizedActors[msg.sender], "Unauthorized to mint");
        _mint(to, amount);
    }
}
