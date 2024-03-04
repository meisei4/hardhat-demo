// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./MushroomBatchNFT.sol";
import "./MushroomCredit.sol";
import "../enums/Role.sol";
import "hardhat/console.sol";

contract MushroomSupplyChain {

    enum State { Harvested, Transported, Received }

    struct Batch {
        string id;
        State state;
        address harvester;
        address transporter;
        address retailer;
        uint256 timestamp;
    }

    mapping(string => Batch) public batches;
    mapping(address => Role) public roles;
    
    MushroomCredit public mushroomCredit;
    MushroomBatchNFT public mushroomBatchNFT;

    constructor() {
        roles[msg.sender] = Role.Owner;
    }

    function setMushroomCreditAddress( address _mushroomCreditAddress) external onlyRole(Role.Owner) {
        mushroomCredit = MushroomCredit(_mushroomCreditAddress);
    }

    function setMushroomBatchNFTAddress(address _mushroomBatchNFTAddress) external onlyRole(Role.Owner) {
        mushroomBatchNFT = MushroomBatchNFT(_mushroomBatchNFTAddress);
    }

    // TODO look into modifiers and memory writes with gas prices for operations
    // Pure function: (only pass by reference)
    // a+b returns sum, parameters only, (doesnt not access scope outside of function, or state)
    // public: can be called within address and from external address
    // external: can be called by anyone other than the smart contract that owns 
    // view: can pretty much only view the blockchain
    // in order to send gas for another address to run the code you want it to
    function recordHarvest(string memory batchId, string memory tokenURI) public onlyRole(Role.Harvester) {
        Batch storage batch = batches[batchId];
        require(batch.harvester == address(0), "Batch already recorded."); // Ensure batch hasn't been recorded already
        batch.id = batchId;
        batch.harvester = msg.sender;
        batch.state = State.Harvested;
        batch.timestamp = block.timestamp;
        uint256 newItemId = mushroomBatchNFT.mintBatchNFT(msg.sender, tokenURI);
        console.log("Minted NFT with token ID:", newItemId, "for batch ID:", batchId);
        uint256 rewardAmount = 50;
        mushroomCredit.mint(msg.sender, rewardAmount);
        console.log("Minted", rewardAmount,"MushroomCredit tokens for harvester:", msg.sender);
    }

    // TODO: Try to make this function have a payable modifier, where it sends ETH during the TX (mint?)
    function updateTransport(string memory batchId) public onlyRole(Role.Transporter) {
        Batch storage batch = batches[batchId];
        require(
            batch.state == State.Harvested,
            "Batch must be harvested first"
        );
        batch.state = State.Transported;
        uint256 rewardAmount = 10;
        mushroomCredit.mint(msg.sender, rewardAmount); 
        console.log("Transferred", rewardAmount, "MushroomCredit tokens to transporter:", msg.sender);
    }

    function confirmReceipt(string memory batchId) public onlyRole(Role.Retailer) {
        Batch storage batch = batches[batchId];
        require(
            batch.state == State.Transported,
            "Batch must be transported first"
        );
        batch.state = State.Received;
    }
 
    modifier onlyRole(Role requiredRole) {
        require(roles[msg.sender] == requiredRole, "Unauthorized role");
        _;
    }

    function assignRole(address _actor, Role _role) external onlyRole(Role.Owner) {
        require(_role != Role.None, "Invalid role");
        roles[_actor] = _role;
    }
}
