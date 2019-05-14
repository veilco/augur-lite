const abi: {
  AugurLite: any;
  Universe: any;
  Market: any;
  Mailbox: any;
  ShareToken: any;
  ClaimTradingProceeds: any;
  CompleteSets: any;
  [contract: string]: any;
} = require("./contracts/abi");
const addresses = require("./contracts/addresses");

declare module "augur-lite" {
  export const AugurLite: any;
  export const Universe: any;
  export const Market: any;
  export const Mailbox: any;
  export const ShareToken: any;
  export const ClaimTradingProceeds: any;
  export const CompleteSets: any;
  export const addresses: {
    [networkId: string]: { [contract: string]: string };
  };
}

module.exports = abi;
module.exports.addresses = addresses;
