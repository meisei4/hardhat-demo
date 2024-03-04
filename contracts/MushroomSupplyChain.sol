// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MushroomBatchNFT.sol";
import "./MushroomCredit.sol";
import "../enums/Role.sol";
import "../enums/State.sol";
import "hardhat/console.sol";
import "../library/LoggingUtil.sol";

contract MushroomSupplyChain {
    using Strings for uint256;

    event ContractDeployed(address owner);
    event HarvestRecorded(
        address indexed harvester,
        string batchId,
        uint256 newItemId,
        uint256 blockTimeStamp
    );
    event TransportUpdated(
        address indexed transporter,
        string batchId,
        uint256 rewardAmount,
        uint256 blockTimeStamp
    );
    event ReceiptConfirmed(
        address indexed retailer,
        string batchId,
        uint256 blockTimeStamp
    );
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

    constructor(
        address _mushroomCreditAddress,
        address _mushroomBatchNFTAddress
    ) {
        roles[msg.sender] = Role.Owner;
        mushroomCredit = MushroomCredit(_mushroomCreditAddress);
        mushroomBatchNFT = MushroomBatchNFT(_mushroomBatchNFTAddress);
        LoggingUtil.logDeployment(msg.sender, "MushroomSupplyChain", address(this));
        emit ContractDeployed(msg.sender);
    }

    function recordHarvest(
        string memory batchId,
        string memory tokenURI
    ) public onlyRole(Role.Harvester) {
        Batch storage batch = batches[batchId];
        require(batch.harvester == address(0), "Batch already recorded.");
        batch.id = batchId;
        //TODO: this still seems strange that the actor just gets assigned the msg.sender (look at the test and how it uses:
        // mushroomSupplyChain.connect(harvester).recordHarvest(batchId, tokenURI)
        // how does the above work with determining "who"/which address is actually playing its designated Role etc

        batch.harvester = msg.sender;
        batch.timestamp = block.timestamp;
        batch.state = State.Harvested;
        LoggingUtil.logBatchStateUpdate("Harvester", batch.harvester, "recorded harvest", "Harvested");

        uint256 newItemId = mushroomBatchNFT.mintBatchNFT(batch.harvester, tokenURI);
        
        uint256 rewardAmount = 50;
        mushroomCredit.mint(batch.harvester, rewardAmount);

        emit HarvestRecorded(batch.harvester, batchId, newItemId, block.timestamp);
    }

    function updateTransport(
        string memory batchId
    ) public onlyRole(Role.Transporter) {
        Batch storage batch = batches[batchId];
        require(batch.state == State.Harvested, "Batch must be harvested first");
        batch.transporter = msg.sender;
        batch.state = State.Transported;
        LoggingUtil.logBatchStateUpdate("Transporter", batch.transporter, "updated transport", "Transported");

        uint256 rewardAmount = 10;
        mushroomCredit.mint(batch.transporter, rewardAmount);

        emit TransportUpdated(batch.transporter, batchId, rewardAmount, block.timestamp);
    }

    function confirmReceipt(
        string memory batchId
    ) public onlyRole(Role.Retailer) {
        Batch storage batch = batches[batchId];
        require(batch.state == State.Transported, "Batch must be transported first");
        batch.retailer = msg.sender;
        batch.state = State.Received;
        LoggingUtil.logBatchStateUpdate("Retailer", batch.retailer, "confirmed receipt", "Received");
        emit ReceiptConfirmed(batch.retailer, batchId, block.timestamp);
    }

    modifier onlyRole(Role requiredRole) {
        require(roles[msg.sender] == requiredRole, "Unauthorized role");
        _;
    }

    function assignRole(
        address _actor,
        Role _role
    ) external onlyRole(Role.Owner) {
        require(_role != Role.None, "Invalid role");
        roles[_actor] = _role;
        LoggingUtil.logRoleAssignment(msg.sender, roleToString(_role), _actor);
        emit RoleAssigned(_actor, _role);
    }

    function roleToString(Role _role) public pure returns (string memory) {
        if (_role == Role.Owner) return "Owner";
        if (_role == Role.Harvester) return "Harvester";
        if (_role == Role.Transporter) return "Transporter";
        if (_role == Role.Retailer) return "Retailer";
        return "None";
    }
}
