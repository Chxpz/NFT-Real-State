import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [{
      version: "0.8.19"
    }],
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000,
      }
    },
  },
  networks: {
    hardhat:
      {},
    mainnet: {
      url: process.env.MAINNET_URL || "",
      accounts:
        process.env.PVT_KEY !== undefined ? [process.env.PVT_KEY] : [],
    },
  }
};

export default config;
