// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MushroomBatchNFT is ERC721URIStorage {
    using Strings for uint256;

    address private _supplyChainAddress;
    uint256 private _currentTokenId = 0;

    constructor(
        address supplyChainAddress
    ) ERC721("MushroomBatchNFT", "MBNFT") {
        _supplyChainAddress = supplyChainAddress;
    }

    modifier onlySupplyChain() {
        require(
            msg.sender == _supplyChainAddress,
            "Only supply chain contract can mint"
        );
        _;
    }

    function mintBatchNFT(
        address recipient,
        string memory newTokenURI
    ) public onlySupplyChain returns (uint256) {
        _currentTokenId += 1;
        uint256 newItemId = _currentTokenId;
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, newTokenURI);
        return newItemId;
    }
}
