## Mushroom Supply Chain 

Ethereum project for smart contracts that models a Mushroom supply chain (from harvesting/farming to retail/selling)

## Components

- **MushroomSupplyChain**: Base contract for supply chain States: Harvested, Transported, Received; Roles:Harvester, Transporter, Retailer
- **MushroomCredit**: ERC20 contract for rewarding supply chain entities
- **MushroomBatchNFT**: ERC721 contract for unique batches of harvested mushrooms

## ASCII Diagram

```
[Deployer] 0x698129894b21c91d289yd9g812 (some address)
    |                         
    |----deploys---->[MushroomCredit: ERC20 Fungible contract] 
    |
    |----sets--->[MushroomCredit Address] 0x3512f8976asf7589asf234 (some address)      
    |
    |----deploys---->[MushroomBatchNFT: ERC721 Non-fungible contract]
    |
    |----sets--->[MushroomBatchNFT Address] etc. 
    |
    |----deploys---->[MushroomSupplyChain: Base Contract] 
    |
    '----sets--->[MushroomBatchNFT Address] etc. 
    |
[MushroomSupplyChain] 
    |
ethers.getSigners()
    |
    v
[Owner] 0x6875876asdf5687saf587d (some address)                                  
    |                                     
    |----sets--->[MushroomCredit Address] 0x3512f8976asf7589asf234 (some address)      
    |                                     
    |----sets--->[MushroomBatchNFT Address] etc. 
    |
    '----owns---->[MushroomSupplyChain] ewt.
    
---After adding Harvester, Transporter, Retailer Signers---

[Harvester] etc.                         [MushroomCredit] 0x3512f8976asf7589asf234
    |                                           |
    |--------------recordHarvest()------------->' (Mints ERC20 tokens as a reward
    |                                           |  for the Harvester)
    '<-----------------mint(ERC20)--------------'
                   [MushroomBatchNFT]|  (Mints a unique NFT for the batch)
                                     |  ^   
                                     |  | mint(ERC721)
                                     |  |
                                     '->'

[Transporter] etc.                       [MushroomCredit] 0x3512f8976asf7589asf234
    |                                           |
    |-------------updateTransport()------------>'  Transfers pre-funded ERC20 tokens
    |                                           |  as a reward to Transporter
    '<-------------trasfer(ERC20)---------------'

[Retailer] etc.
    '-----------confirmReceipt()---------------->  Updates batch state to Received
                                                   No transfer or minting in this model
```