// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract MushroomCredit is ERC20 {
    address private _supplyChainAddress;

    constructor(
        uint256 initialSupply,
        address supplyChainAddress
    ) ERC20("MushroomCredit", "MC") {
        _mint(msg.sender, initialSupply);
        _supplyChainAddress = supplyChainAddress;
    }

    modifier onlySupplyChain() {
        require(
            msg.sender == _supplyChainAddress,
            "Only supply chain contract can mint"
        );
        _;
        // console.log(
        //     "Remaining MushroomCredit supply:",
        //     mushroomCredit.remainingSupply()
        // );
    }

    function mint(address to, uint256 amount) public onlySupplyChain {
        _mint(to, amount);
    }
}
