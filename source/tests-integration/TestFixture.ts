import BN = require("bn.js");
import { TestRpc } from "./TestRpc";
import { Connector } from "../libraries/Connector";
import { AccountManager } from "../libraries/AccountManager";
import { ContractCompiler } from "../libraries/ContractCompiler";
import { ContractDeployer } from "../libraries/ContractDeployer";
import { CompilerConfiguration } from "../libraries/CompilerConfiguration";
import { DeployerConfiguration } from "../libraries/DeployerConfiguration";
import { NetworkConfiguration } from "../libraries/NetworkConfiguration";
import {
  ShareToken,
  ClaimTradingProceeds,
  CompleteSets,
  TimeControlled,
  TestNetDenominationToken,
  Universe,
  Market
} from "../libraries/ContractInterfaces";
import { stringTo32ByteHex } from "../libraries/HelperFunctions";

export class TestFixture {
  private static GAS_PRICE: BN = new BN(1);

  private readonly connector: Connector;
  public readonly accountManager: AccountManager;
  public readonly contractDeployer: ContractDeployer;

  public get universe() {
    return this.contractDeployer.universe;
  }
  public get testNetDenominationToken() {
    return <TestNetDenominationToken>(
      this.contractDeployer.getContract("TestNetDenominationToken")
    );
  }

  public constructor(
    connector: Connector,
    accountManager: AccountManager,
    contractDeployer: ContractDeployer
  ) {
    this.connector = connector;
    this.accountManager = accountManager;
    this.contractDeployer = contractDeployer;
  }

  public static create = async (): Promise<TestFixture> => {
    const networkConfiguration = NetworkConfiguration.create("testrpc");
    await TestRpc.startTestRpcIfNecessary(networkConfiguration);

    const compilerConfiguration = CompilerConfiguration.create();
    const compiledContracts = await new ContractCompiler(
      compilerConfiguration
    ).compileContracts();

    const connector = new Connector(networkConfiguration);
    console.log(
      `Waiting for connection to: ${networkConfiguration.networkName} at ${
        networkConfiguration.http
      }`
    );
    await connector.waitUntilConnected();
    const accountManager = new AccountManager(
      connector,
      networkConfiguration.privateKey
    );

    const deployerConfiguration = DeployerConfiguration.createWithControlledTime();
    let contractDeployer = new ContractDeployer(
      deployerConfiguration,
      connector,
      accountManager,
      compiledContracts
    );

    await contractDeployer.deploy();
    return new TestFixture(connector, accountManager, contractDeployer);
  };

  public async approveCentralAuthority(): Promise<void> {
    const authority = this.contractDeployer.getContract("AugurLite");
    const testNetDenominationToken = new TestNetDenominationToken(
      this.connector,
      this.accountManager,
      this.contractDeployer.getContract("TestNetDenominationToken").address,
      TestFixture.GAS_PRICE
    );
    await testNetDenominationToken.approve(
      authority.address,
      new BN(2).pow(new BN(256)).sub(new BN(1))
    );
  }

  public async createMarket(
    universe: Universe,
    outcomes: string[],
    endTime: BN,
    feePerEthInWei: BN,
    denominationToken: string,
    designatedReporter: string
  ): Promise<Market> {
    const marketAddress = await universe.createCategoricalMarket_(
      endTime,
      feePerEthInWei,
      denominationToken,
      designatedReporter,
      outcomes,
      stringTo32ByteHex(" "),
      "description",
      "",
      {}
    );
    if (!marketAddress || marketAddress == "0x") {
      throw new Error("Unable to get address for new categorical market.");
    }
    await universe.createCategoricalMarket(
      endTime,
      feePerEthInWei,
      denominationToken,
      designatedReporter,
      outcomes,
      stringTo32ByteHex(" "),
      "description",
      "",
      {}
    );
    const market = new Market(
      this.connector,
      this.accountManager,
      marketAddress,
      TestFixture.GAS_PRICE
    );
    if ((await market.getTypeName_()) !== stringTo32ByteHex("Market")) {
      throw new Error("Unable to create new categorical market");
    }
    return market;
  }

  public async createReasonableMarket(
    universe: Universe,
    denominationToken: string,
    outcomes: string[]
  ): Promise<Market> {
    const endTime = new BN(
      Math.round(new Date().getTime() / 1000) + 30 * 24 * 60 * 60
    );
    const fee = new BN(10).pow(new BN(16));
    return await this.createMarket(
      universe,
      outcomes,
      endTime,
      fee,
      denominationToken,
      this.accountManager.defaultAddress
    );
  }

  public async claimTradingProceeds(
    market: Market,
    shareholder: string
  ): Promise<void> {
    const claimTradingProceedsContract = await this.contractDeployer.getContract(
      "ClaimTradingProceeds"
    );
    const claimTradingProceeds = new ClaimTradingProceeds(
      this.connector,
      this.accountManager,
      claimTradingProceedsContract.address,
      TestFixture.GAS_PRICE
    );
    await claimTradingProceeds.claimTradingProceeds(
      market.address,
      shareholder
    );
    return;
  }

  public async depositEther(amount: BN): Promise<void> {
    const testNetDenominationToken = new TestNetDenominationToken(
      this.connector,
      this.accountManager,
      this.contractDeployer.getContract("TestNetDenominationToken").address,
      TestFixture.GAS_PRICE
    );
    await testNetDenominationToken.depositEther({ attachedEth: amount });
    return;
  }

  public async buyCompleteSets(market: Market, amount: BN): Promise<void> {
    const completeSetsContract = await this.contractDeployer.getContract(
      "CompleteSets"
    );
    const completeSets = new CompleteSets(
      this.connector,
      this.accountManager,
      completeSetsContract.address,
      TestFixture.GAS_PRICE
    );

    await completeSets.publicBuyCompleteSets(market.address, amount, {});
    return;
  }

  public async sellCompleteSets(market: Market, amount: BN): Promise<void> {
    const completeSetsContract = await this.contractDeployer.getContract(
      "CompleteSets"
    );
    const completeSets = new CompleteSets(
      this.connector,
      this.accountManager,
      completeSetsContract.address,
      TestFixture.GAS_PRICE
    );

    await completeSets.publicSellCompleteSets(market.address, amount);
    return;
  }

  public async getNumSharesInMarket(market: Market, outcome: BN): Promise<BN> {
    const shareTokenAddress = await market.getShareToken_(outcome);
    const shareToken = new ShareToken(
      this.connector,
      this.accountManager,
      shareTokenAddress,
      TestFixture.GAS_PRICE
    );
    return await shareToken.balanceOf_(this.accountManager.defaultAddress);
  }

  public async getUniverse(market: Market): Promise<Universe> {
    const universeAddress = await market.getUniverse_();
    return new Universe(
      this.connector,
      this.accountManager,
      universeAddress,
      TestFixture.GAS_PRICE
    );
  }

  public async setTimestamp(timestamp: BN): Promise<void> {
    const timeContract = await this.contractDeployer.getContract(
      "TimeControlled"
    );
    const time = new TimeControlled(
      this.connector,
      this.accountManager,
      timeContract.address,
      TestFixture.GAS_PRICE
    );
    await time.setTimestamp(timestamp);
    return;
  }

  public async getTimestamp(): Promise<BN> {
    return this.contractDeployer.controller.getTimestamp_();
  }

  public async resolve(
    market: Market,
    payoutNumerators: Array<BN>,
    invalid: boolean
  ): Promise<void> {
    await market.resolve(payoutNumerators, invalid);
    return;
  }

  // TODO: Determine why ETH balance doesn't change when buying complete sets or redeeming reporting participants
  public async getEthBalance(): Promise<BN> {
    return await this.connector.ethjsQuery.getBalance(
      this.accountManager.defaultAddress
    );
  }
}
