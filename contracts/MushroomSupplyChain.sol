// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./MushroomBatchNFT.sol";
import "./MushroomCredit.sol";
import "../enums/Role.sol";
import "../enums/State.sol";
import "hardhat/console.sol";

contract MushroomSupplyChain {
    
    event ContractDeployed(address owner);
    event MushroomCreditAddressSet(address indexed mushroomCreditAddress, address owner);
    event MushroomBatchNFTAddressSet(address indexed mushroomBatchNFTAddress, address owner);
    event HarvestRecorded(address indexed harvester, string batchId, uint256 newItemId, uint256 blockTimeStamp);
    event TransportUpdated(address indexed transporter, string batchId, uint256 rewardAmount, uint256 blockTimeStamp);
    event ReceiptConfirmed(address indexed retailer, string batchId, uint256 blockTimeStamp);
    event RoleAssigned(address indexed to, Role role);

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

    constructor(address _mushroomCreditAddress, address _mushroomBatchNFTAddress) {
        roles[msg.sender] = Role.Owner;
        // console.log("MushroomSupplyChain Contract deployed by Owner: %s", msg.sender);
        // TODO: all the below turn into Events and emit them
        mushroomCredit = MushroomCredit(_mushroomCreditAddress);
        // console.log("MushroomCredit contract set to: %s by Owner: %s", _mushroomCreditAddress, msg.sender);
        mushroomBatchNFT = MushroomBatchNFT(_mushroomBatchNFTAddress);
        // console.log("MushroomBatchNFT contract set to: %s by Owner: %s", _mushroomBatchNFTAddress, msg.sender);
        //TODO: these two lines dont do anything, authorization must be called in the test
        // mushroomCredit.authorizeActor(msg.sender);
        //mushroomBatchNFT.authorizeActor(msg.sender);
        emit ContractDeployed(msg.sender);
    }

    function recordHarvest(string memory batchId, string memory tokenURI) public onlyRole(Role.Harvester) {
        Batch storage batch = batches[batchId];
        require(batch.harvester == address(0), "Batch already recorded.");
        batch.id = batchId;
        batch.harvester = msg.sender;
        batch.state = State.Harvested;
        batch.timestamp = block.timestamp;

        uint256 newItemId = mushroomBatchNFT.mintBatchNFT(msg.sender, tokenURI);
        // console.log("Harvester: %s minted NFT with token ID: %s for batch ID: %s", msg.sender, newItemId, batchId);

        uint256 rewardAmount = 50;
        mushroomCredit.mint(msg.sender, rewardAmount);
        // console.log("Minted %s MushroomCredit tokens for Harvester: %s", rewardAmount, msg.sender);
        emit HarvestRecorded(msg.sender, batchId, newItemId, block.timestamp);
    }

    function updateTransport(string memory batchId) public onlyRole(Role.Transporter) {
        Batch storage batch = batches[batchId];
        require(batch.state == State.Harvested, "Batch must be harvested first");
        batch.state = State.Transported;

       uint256 rewardAmount = 10;
       mushroomCredit.mint(msg.sender, rewardAmount);
       // console.log("Transporter: %s transferred %s MushroomCredit tokens for batch ID: %s", msg.sender, rewardAmount, batchId);

        emit TransportUpdated(msg.sender, batchId, rewardAmount, block.timestamp);
    }

    function confirmReceipt(string memory batchId) public onlyRole(Role.Retailer) {
        Batch storage batch = batches[batchId];
        require(batch.state == State.Transported, "Batch must be transported first");
        batch.state = State.Received;
        //console.log("Retailer: %s confirmed receipt for batch ID: %s", msg.sender, batchId);
        emit ReceiptConfirmed(msg.sender, batchId, block.timestamp);
    }

    modifier onlyRole(Role requiredRole) {
        require(roles[msg.sender] == requiredRole, "Unauthorized role");
        _;
    }

    //TODO: Actor is still not the correct word here, since it can be a contract address aswell
    function assignRole(address _actor, Role _role) external onlyRole(Role.Owner) {
        require(_role != Role.None, "Invalid role");
        roles[_actor] = _role;
        // console.log("Assigned role %s to address %s", roleToString(_role), _actor);
        emit RoleAssigned(_actor, _role);
    }

    // Example pure function
    function roleToString(Role _role) public pure returns (string memory) {
        if (_role == Role.Owner) return "Owner";
        if (_role == Role.Harvester) return "Harvester";
        if (_role == Role.Transporter) return "Transporter";
        if (_role == Role.Retailer) return "Retailer";
        return "None";
    }
}
