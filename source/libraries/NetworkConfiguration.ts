require("dotenv").config();
import BN = require("bn.js");

type NetworkOptions = {
  isProduction: boolean;
  http: string;
  privateKey: string;
  gasPrice: BN;
};

type Networks = {
  [networkName: string]: NetworkOptions;
};

const networks: Networks = {
  kovan: {
    isProduction: false,
    http: process.env.KOVAN_ETHEREUM_HTTP!,
    privateKey: process.env.KOVAN_PRIVATE_KEY!,
    gasPrice: new BN(1)
  },
  rinkeby: {
    isProduction: false,
    http: process.env.RINKEBY_ETHEREUM_HTTP!,
    privateKey: process.env.RINKEBY_PRIVATE_KEY!,
    gasPrice: new BN(31 * 1000000000)
  },
  ropsten: {
    isProduction: false,
    http: process.env.ROPSTEN_ETHEREUM_HTTP!,
    privateKey: process.env.ROPSTEN_PRIVATE_KEY!,
    gasPrice: new BN(20 * 1000000000)
  },
  mainnet: {
    isProduction: true,
    http: process.env.MAINNET_ETHEREUM_HTTP!,
    privateKey: process.env.MAINNET_PRIVATE_KEY!,
    gasPrice: (typeof process.env.ETHEREUM_GAS_PRICE_IN_NANOETH === "undefined"
      ? new BN(20)
      : new BN(process.env.ETHEREUM_GAS_PRICE_IN_NANOETH!)
    ).mul(new BN(1000000000))
  },
  testrpc: {
    isProduction: false,
    http: "http://localhost:8545",
    gasPrice: new BN(1),
    privateKey: process.env.TESTRPC_PRIVATE_KEY!
  }
};

export class NetworkConfiguration {
  public readonly networkName: string;
  public readonly http: string;
  public readonly privateKey: string;
  public readonly gasPrice: BN;
  public readonly isProduction: boolean;

  public constructor(
    networkName: string,
    http: string,
    gasPrice: BN,
    privateKey: string,
    isProduction: boolean
  ) {
    this.networkName = networkName;
    this.http = http;
    this.gasPrice = gasPrice;
    this.privateKey = privateKey;
    this.isProduction = isProduction;
  }

  public static create(networkName: string = "kovan"): NetworkConfiguration {
    const network = networks[networkName];

    if (network === undefined || network === null)
      throw new Error(`Network configuration ${networkName} not found`);
    if (network.privateKey === undefined || network.privateKey === null)
      throw new Error(
        `Network configuration for ${networkName} has no private key available. Check that this key is in the environment ${networkName.toUpperCase()}_PRIVATE_KEY`
      );

    return new NetworkConfiguration(
      networkName,
      network.http,
      network.gasPrice,
      network.privateKey,
      network.isProduction
    );
  }
}
