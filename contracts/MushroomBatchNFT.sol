// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "../library/LoggingUtil.sol";

contract MushroomBatchNFT is ERC721URIStorage {
    using Strings for uint256;

    event ContractDeployed(address owner);
    event ActorAuthorized(address indexed actor, address owner);
    event ActorDeauthorized(address indexed actor, address owner);
    event MushroomBatchNFTMinted(address indexed from, address indexed to, uint256 newItemId, string newTokenURI);

    mapping(address => bool) public authorizedActors;
    uint256 private _currentTokenId = 0;

    constructor() ERC721("MushroomBatchNFT", "MBNFT") {
        LoggingUtil.logDeployment(msg.sender, "MushroomBatchNFT", address(this));
        emit ContractDeployed(msg.sender);
    }

    // TODO: this doesnt actually authorize the Actors? (Signers?), it seems to only work when Contracts are the msg.sender
    function authorizeActor(address _actor) external {
        authorizedActors[_actor] = true;
        LoggingUtil.logAuthorization("Owner", msg.sender, "MushroomBatchNFT", _actor, "MushroomBatchNFT");
        emit ActorAuthorized(_actor, msg.sender);

    }

    function deauthorizeActor(address _actor) external {
        authorizedActors[_actor] = false;
        emit ActorDeauthorized(_actor, msg.sender);

    }

    function mintBatchNFT(address to, string memory newTokenURI) public returns (uint256) {
        require(authorizedActors[msg.sender], "Unauthorized to mint");
        _currentTokenId += 1;
        uint256 newItemId = _currentTokenId;
        _mint(to, newItemId);
        _setTokenURI(newItemId, newTokenURI);
        LoggingUtil.logMinting("Authorized Actor", msg.sender, "MushroomBatchNFT", address(this), to, newTokenURI);
        emit MushroomBatchNFTMinted(msg.sender, to, newItemId, newTokenURI);
        return newItemId;
    }
}
