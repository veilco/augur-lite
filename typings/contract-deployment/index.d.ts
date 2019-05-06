declare module "contract-deployment" {
  interface ContractBlockchainData {
    abi: any;
    query: any;
    address: string;
    bytecode: string;
    defaultTxObject: any;
    filters: any;
  }

  interface ContractReceipt {
    transactionHash: string;
    transactionIndex: any;
    blockHash: string;
    blockNumber: any;
    gasUsed: any;
    cumulativeGasUsed: any;
    contractAddress: string;
    logs: any;
  }
}
