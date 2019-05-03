import BN = require("bn.js");
import { Connector } from "../libraries/Connector";
import { AccountManager } from "../libraries/AccountManager";
import { ContractDeployer } from "../libraries/ContractDeployer";
import { TimeControlled } from "../libraries/ContractInterfaces";

export class TestFixture {
    private static GAS_PRICE: BN = new BN(1);

    private readonly connector: Connector;
    public readonly accountManager: AccountManager;
    // FIXME: extract out the bits of contract deployer that we need access to, like the contracts/abis, so we can have a more targeted dependency
    public readonly contractDeployer: ContractDeployer;

    public constructor(
        connector: Connector,
        accountManager: AccountManager,
        contractDeployer: ContractDeployer
    ) {
        this.connector = connector;
        this.accountManager = accountManager;
        this.contractDeployer = contractDeployer;
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
}
