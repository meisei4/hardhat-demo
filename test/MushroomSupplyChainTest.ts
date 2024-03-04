import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer, ContractTransactionResponse, ContractTransactionReceipt, Contract, EventLog, Log } from "ethers";
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

  before(async function () {
    console.log("Starting test setup...");

    const MushroomCreditFactory = await ethers.getContractFactory("MushroomCredit");
    mushroomCredit = await MushroomCreditFactory.deploy();

    const MushroomBatchNFTFactory = await ethers.getContractFactory("MushroomBatchNFT");
    mushroomBatchNFT = await MushroomBatchNFTFactory.deploy();

    const MushroomSupplyChainFactory = await ethers.getContractFactory("MushroomSupplyChain");
    mushroomSupplyChain = await MushroomSupplyChainFactory.deploy(mushroomCredit.target, mushroomBatchNFT.target);

    //TODO: why does this have to be ran here and cant be ran in the deployment process of the supplychain
    mushroomCredit.authorizeActor(mushroomSupplyChain.target);
    mushroomBatchNFT.authorizeActor(mushroomSupplyChain.target);

    [owner, harvester, transporter, retailer] = await ethers.getSigners();

    ownerAddress = await owner.getAddress();
    // TODO: why does the next line even need to happen if its already the owner address?
    // mushroomSupplyChain.assignRole(ownerAddress, Role.Owner);

    harvesterAddress = await harvester.getAddress();
    await mushroomSupplyChain.assignRole(harvesterAddress, Role.Harvester);

    transporterAddress = await transporter.getAddress();
    await mushroomSupplyChain.assignRole(transporterAddress, Role.Transporter);

    retailerAddress = await retailer.getAddress();
    await mushroomSupplyChain.assignRole(retailerAddress, Role.Retailer);

    console.log("Finished test setup...");
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
      () => mushroomSupplyChain.connect(harvester).recordHarvest(batchId, tokenURI),
      0,
      batchId,
      mushroomSupplyChain,
      "HarvestedRecord"
    );

    await executeTransaction(
      () => mushroomSupplyChain.connect(transporter).updateTransport(batchId),
      1,
      batchId,
      mushroomSupplyChain,
      "HarvestedRecord"
    );

    await executeTransaction(() => mushroomSupplyChain.connect(retailer).confirmReceipt(batchId),
      2,
      batchId,
      mushroomSupplyChain,
      "HarvestedRecord"
    );
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
async function executeTransaction(
  operation: () => Promise<ContractTransactionResponse>,
  expectedState: number,
  batchId: string,
  contract: Contract,
  eventName: string
): Promise<void> {
  // contract.on(eventName, (data) => { logEvent() });

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

  console.log(`Gas used: ${gasUsed.toString()} units.`);
  console.log(`Gas price: ${ethers.formatUnits(gasPrice, "gwei")} gwei.`);
  console.log(`Total cost: ${totalCostETH.toString()} ETH, approximately $${totalCostUSD.toString()} USD.`);
  await logEventsAfterTransaction(contract, receipt);

  // TODO

  // outside of blockchain or contracts events are the best way to access the blockchain stuff
  // try using subscriptions (not in a Hardhat Test but rather just
  // two systems: 
  // 
  // libaries can work across different smart contracts, 
  //
  // async vs callbacks with then, 

  // make a simple test js server that listens to the blockchain events (like how you would access the 
  // blockchain in a more integration testy way)
  // 1. npx hardhat node (get remix all set up)
  // 2. use web3js/ethers to connect to the network that remix/hardhat has spun up
  // 3. 
}

async function logEventsAfterTransaction(contract: Contract, receipt: ContractTransactionReceipt | null) {
  if (receipt != null) {
    const eventFilter = contract.filters.Transfer;
    // only get events from the immediate blocknumber of transaction receipt
    const events = await contract.queryFilter(eventFilter, receipt.blockNumber, receipt.blockNumber);
    for (const event in events) {
      const block = await contract.getBlock(receipt.blockNumber);
      const blockTimestamp = new Date(block.timestamp * 1000).toLocaleString(); // Convert Unix timestamp to Date object and then to string
      const message = `Event ${contract.eventName}: ${JSON.stringify(event.data)}`;
      console.log(`[${blockTimestamp.toLocaleLowerCase()}] ${message}`);
    }
  }
}

async function logEventsAfterTransaction(contract: Contract, receipt: ContractTransactionReceipt, eventName: string) {
  const eventFilter = contract.filters.Transfer;
  // only get events from the immediate blocknumber of transaction receipt
  const events = await contract.queryFilter(eventFilter, receipt.blockNumber, receipt.blockNumber);
  const block = await contract.getBlock(receipt.blockNumber);
  const blockTimestamp = new Date(block.timestamp * 1000).toLocaleString(); // Convert Unix timestamp to Date object and then to string

  //never multiple events? or maybe
  for (const event of events) {
    const message = `Event ${eventName}: ${JSON.stringify(event.data)}`;
    console.log(`[${blockTimestamp}] ${message}`);
  }
}
