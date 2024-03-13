import { ethers } from "hardhat";

enum Role {
    None,
    Owner,
    Harvester,
    Transporter,
    Retailer,
}

async function main() {
    const LoggingUtilFactory = await ethers.getContractFactory("LoggingUtil");
    const loggingUtil = await LoggingUtilFactory.deploy();

    const MushroomCreditFactory = await ethers.getContractFactory("MushroomCredit", {
        libraries: {
            LoggingUtil: loggingUtil.target,
        },
    });
    const mushroomCredit = await MushroomCreditFactory.deploy();

    const MushroomBatchNFTFactory = await ethers.getContractFactory("MushroomBatchNFT", {
        libraries: {
            LoggingUtil: loggingUtil.target,
        },
    });
    const mushroomBatchNFT = await MushroomBatchNFTFactory.deploy();

    const MushroomSupplyChainFactory = await ethers.getContractFactory("MushroomSupplyChain", {
        libraries: {
            LoggingUtil: loggingUtil.target,
        },
    });
    const mushroomSupplyChain = await MushroomSupplyChainFactory.deploy(mushroomCredit.target, mushroomBatchNFT.target);

    mushroomCredit.authorizeActor(mushroomSupplyChain.target);
    mushroomBatchNFT.authorizeActor(mushroomSupplyChain.target);

    const [owner, harvester, transporter, retailer] = await ethers.getSigners();

    const harvesterAddress = await harvester.getAddress();
    await mushroomSupplyChain.assignRole(harvesterAddress, Role.Harvester);

    const transporterAddress = await transporter.getAddress();
    await mushroomSupplyChain.assignRole(transporterAddress, Role.Transporter);

    const retailerAddress = await retailer.getAddress();
    await mushroomSupplyChain.assignRole(retailerAddress, Role.Retailer);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});