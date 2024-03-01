import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  typechain: {
    outDir: "typechain",
    target: "ethers-v6",
  },
  networks: {
    localhost: {
      // url: "http://localhost:5100", // Replace with your node's URL
      // chainId: 1337, // Replace with your chain ID
    },
  },
};

export default config;
