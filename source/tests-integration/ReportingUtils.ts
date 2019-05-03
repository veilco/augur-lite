import BN = require("bn.js");
import { TestFixture } from "./TestFixture";
import { Market } from "../libraries/ContractInterfaces";

export class ReportingUtils {
    public async proceedToDesignatedReporting(
        fixture: TestFixture,
        market: Market
    ) {
        const marketEndTime = await market.getEndTime_();
        await fixture.setTimestamp(marketEndTime.add(new BN(1)));
    }
}
