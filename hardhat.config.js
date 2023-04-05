require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config()

const eth_goerli = process.env.INFURA_ETH_GOERLI_API_KEY
const polygon_mainnet = process.env.ALCHEMY_POLYGON_MAINNET_API_KEY
const deployerPrivateKey = process.env.BALAJI_PRIVATE_KEY
const balajiPrivateKey = process.env.DEPLOYER_PRIVATE_KEY
const anonPrivateKey = process.env.ANON_PRIVATE_KEY

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "polygon",
  networks: {
    hardhat: {},
    polygon: {
      url: polygon_mainnet,
      accounts: [deployerPrivateKey, balajiPrivateKey, anonPrivateKey]
    },
    goerli: {
      url: eth_goerli,
      accounts: [deployerPrivateKey, balajiPrivateKey, anonPrivateKey]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}