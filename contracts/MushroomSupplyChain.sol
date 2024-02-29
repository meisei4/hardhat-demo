// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./MushroomBatchNFT.sol";
import "./MushroomCredit.sol";
import "hardhat/console.sol";

contract MushroomSupplyChain {
    enum State {
        Harvested,
        Transported,
        Received
    }

    struct Batch {
        string id;
        State state;
        address harvester;
        address transporter;
        address retailer;
        uint256 timestamp;
    }

    mapping(string => Batch) public batches;
    address public owner;
    MushroomCredit public mushroomCredit;
    MushroomBatchNFT public mushroomBatchNFT;

    mapping(address => bool) public harvesters;
    mapping(address => bool) public transporters;
    mapping(address => bool) public retailers;

    constructor() {
        owner = msg.sender;
    }

    function setMushroomCreditAddress(
        address _mushroomCreditAddress
    ) external onlyOwner {
        mushroomCredit = MushroomCredit(_mushroomCreditAddress);
    }

    function setMushroomBatchNFTAddress(
        address _mushroomBatchNFTAddress
    ) external onlyOwner {
        mushroomBatchNFT = MushroomBatchNFT(_mushroomBatchNFTAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyHarvester() {
        require(harvesters[msg.sender], "Not harvester");
        _;
    }

    modifier onlyTransporter() {
        require(transporters[msg.sender], "Not transporter");
        _;
    }

    modifier onlyRetailer() {
        require(retailers[msg.sender], "Not retailer");
        _;
    }

    function addHarvester(address _harvester) external onlyOwner {
        harvesters[_harvester] = true;
    }

    function addTransporter(address _transporter) external onlyOwner {
        transporters[_transporter] = true;
    }

    function addRetailer(address _retailer) external onlyOwner {
        retailers[_retailer] = true;
    }

    // TODO look into modifiers and memory writes with gas prices for operatiosn
    // Pure function: (only pass by reference)
    // a+b returns sum, parameters only, (doesnt not access scope outside of function, or state)
    // public: can be called within address and from external address
    // external: can be called by anyone other than the smart contract that owns 
    // view: can pretty much only view the blockchain
    // in order to send gas for another address to run the code you want it to
    function recordHarvest(
        address harvester,
        string memory batchId,
        string memory tokenURI // Metadata URI for the NFT
    ) public onlyHarvester {
        Batch storage batch = batches[batchId];
        require(batch.harvester == address(0), "Batch already recorded."); // Ensure batch hasn't been recorded already

        // Log the action of recording a new batch
        console.log("Recording new batch with ID:", batchId);
        console.log("Harvester address:", harvester);

        // Record the new batch
        batch.id = batchId;
        batch.harvester = harvester;
        batch.state = State.Harvested;
        batch.timestamp = block.timestamp;

        // Mint an NFT for the harvested batch
        uint256 newItemId = mushroomBatchNFT.mintBatchNFT(harvester, tokenURI);
        console.log(
            "Minted NFT with token ID:",
            newItemId,
            "for batch ID:",
            batchId
        );

        uint256 rewardAmount = 50;
        // Mint FT for rewarding the harvester Signer
        mushroomCredit.mint(harvester, rewardAmount);
        console.log(
            "Minted",
            rewardAmount,
            "MushroomCredit tokens for harvester:",
            harvester
        );
    }

    // TODO: Try to make this function have a payable modifier, where it sends ETH during the TX (mint?)
    function updateTransport(string memory batchId) public onlyTransporter {
        Batch storage batch = batches[batchId];
        require(
            batch.state == State.Harvested,
            "Batch must be harvested first"
        );
        console.log("Updating transport for batch ID:", batchId);

        batch.state = State.Transported;
        console.log("Batch ID:", batchId, "state updated to Transported");

        // Reward the transporter with ERC20 tokens
        uint256 rewardAmount = 50; // Define reward amount appropriately
        mushroomCredit.transfer(msg.sender, rewardAmount); // Transfer tokens as reward
        //ERC20 is separate from ether itself, just some token
        console.log(
            "Transferred",
            rewardAmount,
            "MushroomCredit tokens to transporter:",
            msg.sender
        );
    }

    function confirmReceipt(string memory batchId) public onlyRetailer {
        Batch storage batch = batches[batchId];
        require(
            batch.state == State.Transported,
            "Batch must be transported first"
        );
        console.log("Confirming receipt for batch ID:", batchId);

        batch.state = State.Received;
        console.log("Batch ID:", batchId, "state updated to Received");

        // Note: No reward for retailer in this setup
        console.log("No rewards are distributed for confirming receipt.");
    }
}
