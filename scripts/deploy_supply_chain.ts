import { ethers } from "hardhat";

async function main() {
    const MushroomSupplyChain = await ethers.getContractFactory("MushroomSupplyChain");
    const mushroomSupplyChain = await MushroomSupplyChain.deploy();

    mushroomSupplyChain.waitForDeployment();

    console.log("MushroomSupplyChain deployed to:", mushroomSupplyChain.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error: Error) => {
        console.error(error);
        process.exit(1);
    });
