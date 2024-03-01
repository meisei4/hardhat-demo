// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MushroomBatchNFT is ERC721URIStorage {
    using Strings for uint256;

    mapping(address => bool) public authorizedActors;
    uint256 private _currentTokenId = 0;

    constructor() ERC721("MushroomBatchNFT", "MBNFT") {}

    function authorizeActor(address _actor) external {
        authorizedActors[_actor] = true;
    }

    function deauthorizeActor(address _actor) external {
        authorizedActors[_actor] = false;
    }

    function mintBatchNFT(
        address to,
        string memory newTokenURI
    ) public returns (uint256) {
        require(authorizedActors[msg.sender], "Unauthorized to mint");
        _currentTokenId += 1;
        uint256 newItemId = _currentTokenId;
        _mint(to, newItemId);
        _setTokenURI(newItemId, newTokenURI);
        return newItemId;
    }
}
