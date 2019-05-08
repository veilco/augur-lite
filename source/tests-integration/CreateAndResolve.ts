import BN = require("bn.js");
import { expect } from "chai";
import { stringTo32ByteHex } from "../libraries/HelperFunctions";
import { TestFixture } from "./TestFixture";

describe("CreateAndResolve", () => {
  let fixture: TestFixture;

  before(async () => {
    fixture = await TestFixture.create();
  });

  // Create market, buy/sell complete sets, resolve market, and settle shares
  it("#createAndResolve", async () => {
    await fixture.approveCentralAuthority();

    let ethBalance = await fixture.getEthBalance();
    console.log("Starting ETH balance", ethBalance.toString(10));

    // Create a market
    const market = await fixture.createReasonableMarket(
      fixture.universe,
      fixture.testNetDenominationToken.address,
      [stringTo32ByteHex(" "), stringTo32ByteHex(" ")]
    );
    const actualTypeName = await market.getTypeName_();
    const expectedTypeName = stringTo32ByteHex("Market");
    expect(actualTypeName).to.equal(expectedTypeName);

    // Proceed to resolution
    const marketEndTime = await market.getEndTime_();
    await fixture.setTimestamp(marketEndTime.add(new BN(1)));

    // Resolve market
    let isResolved = await market.isResolved_();
    expect(isResolved).to.be.false;

    await fixture.resolve(market, [new BN(10000), new BN(0)], false);

    isResolved = await market.isResolved_();
    expect(isResolved).to.be.true;
  });
});
