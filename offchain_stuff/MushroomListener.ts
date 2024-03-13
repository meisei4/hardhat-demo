import { ethers } from 'ethers';
import MushroomSupplyChainABI from '../artifacts/contracts/MushroomSupplyChain.sol/MushroomSupplyChain.json'


// MushroomCredit Address: 0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
// MushroomBatchNFT Address: 0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0
// MushroomSupplyChain Address: 0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9


const rpcURL: string = 'http://localhost:8545';

const provider = new ethers.JsonRpcProvider(rpcURL);
// ??????
const privateKey: string = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'; // MUST MATCH THE PRIVATE KEY OF THE HARVESTER in order to record harvest
const wallet = new ethers.Wallet(privateKey, provider);

const mushroomSupplyChainAddress = '0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9';
const mushroomSupplyChain = new ethers.Contract(mushroomSupplyChainAddress, MushroomSupplyChainABI.abi, wallet);

async function recordHarvest(batchId: string, tokenURI: string): Promise<void> {
    try {

        const tx = await mushroomSupplyChain.recordHarvest(batchId, tokenURI);
        await tx.wait();
        console.log(`Harvest recorded for batchId: ${batchId}`);
    } catch (error) {
        console.error(`Failed to record harvest: ${error}`);
    }
}

function listenForHarvestEvents(): void {
    mushroomSupplyChain.on('HarvestRecorded', (harvester, batchId, newItemId, blockTimeStamp) => {
        console.log(`Harvest Recorded: Harvester: ${harvester}, Batch ID: ${batchId}, New Item ID: ${newItemId.toString()}, Timestamp: ${blockTimeStamp.toString()}`);
    });
}

async function main(): Promise<void> {
    listenForHarvestEvents();

    await recordHarvest('batch123', 'http://127.0.0.1:3000/testfile.json');
}

main().catch(console.error);
