// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    // Simplified access control variables
    address public owner;
    mapping(address => bool) public harvesters;
    mapping(address => bool) public transporters;
    mapping(address => bool) public retailers;

    constructor() {
        owner = msg.sender;
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

    // Functions to manage roles
    function addHarvester(address _harvester) external onlyOwner {
        harvesters[_harvester] = true;
    }

    function addTransporter(address _transporter) external onlyOwner {
        transporters[_transporter] = true;
    }

    function addRetailer(address _retailer) external onlyOwner {
        retailers[_retailer] = true;
    }

    // Contract functions
    function recordHarvest(
        string memory batchId
    ) public onlyHarvester {
        Batch storage batch = batches[batchId];
        batch.id = batchId;
        batch.state = State.Harvested;
        batch.harvester = msg.sender;
        batch.timestamp = block.timestamp;
    }

    function updateTransport(string memory batchId) public onlyTransporter {
        Batch storage batch = batches[batchId];
        require(batch.state == State.Harvested, "Batch must be harvested first");
        batch.state = State.Transported;
    }

    function confirmReceipt(string memory batchId) public onlyRetailer {
        Batch storage batch = batches[batchId];
        require(batch.state == State.Transported, "Batch must be transported first");
        batch.state = State.Received;
    }
}
