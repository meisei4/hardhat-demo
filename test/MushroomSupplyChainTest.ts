import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer, ContractTransactionResponse } from "ethers";
import { MushroomBatchNFT, MushroomCredit, MushroomSupplyChain } from "../typechain";

enum Role {
  None,
  Owner,
  Harvester,
  Transporter,
  Retailer,
}

let mushroomSupplyChain: MushroomSupplyChain;
let mushroomCredit: MushroomCredit;
let mushroomBatchNFT: MushroomBatchNFT;

describe("MushroomSupplyChain", function () {
  let owner: Signer, harvester: Signer, transporter: Signer, retailer: Signer;
  let ownerAddress: string, harvesterAddress: string, transporterAddress: string, retailerAddress: string;
  const tokenURI = "http://127.0.0.1:3000/testfile.json";

  beforeEach(async function () {
    console.log("Starting test setup...");

    // Getting signers which simulate different participants in the blockchain
    // using actual network/addresses with hardhat node
    const MushroomSupplyChainFactory = await ethers.getContractFactory("MushroomSupplyChain");
    mushroomSupplyChain = await MushroomSupplyChainFactory.deploy();
    console.log("Deployed MushroomSupplyChain contract to:", await mushroomSupplyChain.getAddress());

    const MushroomCreditFactory = await ethers.getContractFactory("MushroomCredit");
    mushroomCredit = await MushroomCreditFactory.deploy();
    console.log("MushroomCredit deployed to:", await mushroomCredit.getAddress());

    const MushroomBatchNFTFactory = await ethers.getContractFactory("MushroomBatchNFT");
    mushroomBatchNFT = await MushroomBatchNFTFactory.deploy();
    console.log("MushroomBatchNFT deployed to:", await mushroomBatchNFT.getAddress());

    mushroomCredit.authorizeActor(mushroomSupplyChain.getAddress());
    mushroomBatchNFT.authorizeActor(mushroomSupplyChain.getAddress());

    mushroomSupplyChain.setMushroomCreditAddress(mushroomCredit.getAddress());
    mushroomSupplyChain.setMushroomBatchNFTAddress(mushroomBatchNFT.getAddress());

    [owner, harvester, transporter, retailer] = await ethers.getSigners();
    //test network prefunds all these addresses with ETH that can be used for gas
    ownerAddress = await owner.getAddress();
    harvesterAddress = await harvester.getAddress();
    mushroomCredit.authorizeActor(harvesterAddress);
    mushroomBatchNFT.authorizeActor(harvesterAddress);

    transporterAddress = await transporter.getAddress();
    mushroomCredit.authorizeActor(transporterAddress);

    retailerAddress = await retailer.getAddress();
    // not yet authorized to mint, because they get money from selling the shrooms anyways? which is not really labor intensive
    console.log("Retrieved addresses for owner, harvester, transporter, and retailer.");
    console.log("Assigning roles...");
    await Promise.all([
      mushroomSupplyChain.assignRole(await owner.getAddress(), Role.Owner).then(() => console.log("Owner role assigned.")),
      mushroomSupplyChain.assignRole(await harvester.getAddress(), Role.Harvester).then(() => console.log("Harvester role assigned.")),
      mushroomSupplyChain.assignRole(await transporter.getAddress(), Role.Transporter).then(() => console.log("Transporter role assigned.")),
      mushroomSupplyChain.assignRole(await retailer.getAddress(), Role.Retailer).then(() => console.log("Retailer role assigned.")),
    ]);
  });

  it("Should correctly process a batch through the supply chain", async function () {
    const batchId = "ROLE_SPECIFIC_BATCH";

    // addresses and private keys
    // EOA: contract without code (wallet)
    // Smart Contract: code associated along with wallet-esque storage
    // private key is used for signing and allowing interaction back and forth (without private key the eth just gets stuck)
    // ABI json in artifacts after compile is the data for deployed code
    // data field in the transaction can involve the code being sent over (not just eth being sent)
    await executeTransaction(() => mushroomSupplyChain.connect(harvester).recordHarvest(batchId, tokenURI), 0, batchId);

    await executeTransaction(() => mushroomSupplyChain.connect(transporter).updateTransport(batchId), 1, batchId);

    await executeTransaction(() => mushroomSupplyChain.connect(retailer).confirmReceipt(batchId), 2, batchId);
  });

  it("Should not allow unauthorized actions", async function () {
    const [_, __, ___, ____, unauthorizedSigner] = await ethers.getSigners();
    const batchId = "UNAUTH_BATCH";

    console.log("Attempting to record harvest with an unauthorized signer...");
    await expect(mushroomSupplyChain.connect(unauthorizedSigner).recordHarvest(batchId, tokenURI)).to.be.revertedWith("Unauthorized role");

    console.log("Attempting to update transport with an unauthorized signer...");
    await expect(mushroomSupplyChain.connect(unauthorizedSigner).updateTransport(batchId)).to.be.revertedWith("Unauthorized role");

    console.log("Attempting to confirm receipt with an unauthorized signer...");
    await expect(mushroomSupplyChain.connect(unauthorizedSigner).confirmReceipt(batchId)).to.be.revertedWith("Unauthorized role");
  });
});


// AUXILIARY
async function executeTransaction(operation: () => Promise<ContractTransactionResponse>, expectedState: number, batchId: string): Promise<void> {
  console.log(`Begin transaction execution for batch ID: ${batchId}...`);

  const tx = await operation();
  const receipt = await tx.wait();
  //TODO figure out a way to print out the prefunded eth amount
  const gasUsed = Number(receipt?.gasUsed);
  const gasPrice = Number(tx.gasPrice);

  const totalCostETH = (gasPrice * gasUsed) / Number(ethers.parseUnits("1", "ether"));

  const ETH_TO_USD = Number(3000); // Example conversion rate
  const totalCostUSD = totalCostETH * ETH_TO_USD;

  const batch = await mushroomSupplyChain.batches(batchId);
  expect(batch.state).to.equal(expectedState);

  console.log(`${operation.toString()} executed and transaction completed successfully.`);
  console.log(`Gas used: ${gasUsed.toString()} units.`);
  console.log(`Gas price: ${ethers.formatUnits(gasPrice, "gwei")} gwei.`);
  console.log(`Total cost: ${totalCostETH.toString()} ETH, approximately $${totalCostUSD.toString()} USD.`);
}
