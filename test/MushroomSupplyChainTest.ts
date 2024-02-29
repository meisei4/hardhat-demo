import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer, ContractTransactionResponse } from "ethers";
import { MushroomSupplyChain } from "../typechain";

let mushroomSupplyChain: MushroomSupplyChain;

async function executeTransaction(
    operation: () => Promise<ContractTransactionResponse>,
    expectedState: number,
    batchId: string
): Promise<void> {
    console.log(`Begin transaction execution for batch ID: ${batchId}...`);

    const tx = await operation();
    const receipt = await tx.wait();
    //TODO figure out a way to print out the prefunded eth amount
    const gasUsed = Number(receipt?.gasUsed);
    const gasPrice = Number(tx.gasPrice);

    const totalCostETH = gasPrice * gasUsed / Number(ethers.parseUnits("1", "ether"));

    const ETH_TO_USD = Number(3000); // Example conversion rate
    const totalCostUSD = totalCostETH * ETH_TO_USD;

    const batch = await mushroomSupplyChain.batches(batchId);
    expect(batch.state).to.equal(expectedState);

    console.log(`${operation.toString()} executed and transaction completed successfully.`);
    console.log(`Gas used: ${gasUsed.toString()} units.`);
    console.log(`Gas price: ${ethers.formatUnits(gasPrice, "gwei")} gwei.`);
    console.log(`Total cost: ${totalCostETH.toString()} ETH, approximately $${totalCostUSD.toString()} USD.`);
}

describe("MushroomSupplyChain", function () {
    let owner: Signer, harvester: Signer, transporter: Signer, retailer: Signer;
    const tokenURI = "http://127.0.0.1:3000/testfile.json";
    const initialFungibleTokenSupply = 10000

    let ownerAddress: string, harvesterAddress: string, transporterAddress: string, retailerAddress: string;

    beforeEach(async function () {
        console.log("Starting test setup...");

        // Getting signers which simulate different participants in the blockchain
        //using actual network/addresses with hardhat node
        //

        const MushroomSupplyChainFactory = await ethers.getContractFactory("MushroomSupplyChain");
        mushroomSupplyChain = await MushroomSupplyChainFactory.deploy();
        console.log("Deployed MushroomSupplyChain contract to:", mushroomSupplyChain.getAddress());

        const MushroomCreditFactory = await ethers.getContractFactory("MushroomCredit");
        const mushroomCredit = await MushroomCreditFactory.deploy(initialFungibleTokenSupply, mushroomSupplyChain.getAddress());
        console.log("MushroomCredit deployed to:", mushroomCredit.getAddress());

        const MushroomBatchNFTFactory = await ethers.getContractFactory("MushroomBatchNFT");
        const mushroomBatchNFT = await MushroomBatchNFTFactory.deploy(mushroomSupplyChain.getAddress());
        console.log("MushroomBatchNFT deployed to:", mushroomBatchNFT.getAddress());

        mushroomSupplyChain.setMushroomCreditAddress(mushroomCredit.getAddress());
        mushroomSupplyChain.setMushroomBatchNFTAddress(mushroomBatchNFT.getAddress());

        [owner, harvester, transporter, retailer] = await ethers.getSigners();
        //test network prefunds all these addresses with ETH that can be used for gas
        ownerAddress = await owner.getAddress();
        harvesterAddress = await harvester.getAddress();
        transporterAddress = await transporter.getAddress();
        retailerAddress = await retailer.getAddress();
        console.log("Retrieved addresses for owner, harvester, transporter, and retailer.");

        const harvesterRoleTx = await mushroomSupplyChain.connect(owner).addHarvester(harvesterAddress);
        //precr
        const harvesterRoleTxReceipt = await harvesterRoleTx.wait();
        console.log(`Assigned harvester role to address: ${harvesterAddress}, and confirmed in block number: ${harvesterRoleTxReceipt?.blockNumber}`);

        const transporterRoleTx = await mushroomSupplyChain.connect(owner).addTransporter(transporterAddress);
        const transporterRoleTxReceipt = await transporterRoleTx.wait();
        console.log(`Assigned transporter role to address: ${transporterAddress}, and confirmed in block number: ${transporterRoleTxReceipt?.blockNumber}`);

        const retailerRoleTx = await mushroomSupplyChain.connect(owner).addRetailer(retailerAddress);
        const retailerRoleTxReceipt = await retailerRoleTx.wait();
        console.log(`Assigned retailer role to address: ${retailerAddress}, and confirmed in block number: ${retailerRoleTxReceipt?.blockNumber}`);
    });

    it("Should correctly process a batch through the supply chain", async function () {
        const batchId = "ROLE_SPECIFIC_BATCH";


        // addresses and private keys
        // EOA: contract without code (wallet)
        // Smart Contract: code associated along with wallet-esque storage
        // private key is used for signing and allowing interaction back and forth (without private key the eth just gets stuck)
        // ABI json in artifacts after compile is the data for deployed code
        // data field in the transaction can involve the code being sent over (not just eth being sent)
        await executeTransaction(
            () => mushroomSupplyChain.connect(harvester).recordHarvest(harvesterAddress, batchId, tokenURI),
            0,
            batchId
        );

        await executeTransaction(
            () => mushroomSupplyChain.connect(transporter).updateTransport(batchId),
            1,
            batchId
        );

        await executeTransaction(
            () => mushroomSupplyChain.connect(retailer).confirmReceipt(batchId),
            2,
            batchId
        );

    });

    it("Should not allow unauthorized actions", async function () {
        const [_, __, ___, ____, unauthorizedSigner] = await ethers.getSigners(); // Assuming there's a fifth signer not assigned a role
        const batchId = "UNAUTH_BATCH";

        console.log("Attempting to record harvest with an unauthorized signer...");
        await expect(mushroomSupplyChain.connect(unauthorizedSigner).recordHarvest(harvesterAddress, batchId, tokenURI))
            .to.be.revertedWith("Not harvester"); // Assuming your contract reverts with this error

        console.log("Attempting to update transport with an unauthorized signer...");
        await expect(mushroomSupplyChain.connect(unauthorizedSigner).updateTransport(batchId))
            .to.be.revertedWith("Not transporter"); // Similar assumption for transporter

        console.log("Attempting to confirm receipt with an unauthorized signer...");
        await expect(mushroomSupplyChain.connect(unauthorizedSigner).confirmReceipt(batchId))
            .to.be.revertedWith("Not retailer"); // And for retailer
    });
});
