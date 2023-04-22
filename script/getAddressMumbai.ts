import moonpierrun from '../broadcast/moonpierMumbai.s.sol/80001/run-latest.json';

const address = moonpierrun.transactions.filter((t) => t.contractName && (t.transactionType === 'CREATE' || t.transactionType === 'CREATE2')).map((tx) => ({
  address: tx.contractAddress,
  contractName: tx.contractName
}))

console.log(address);