import moonpierrun from '../broadcast/moonpier.s.sol/31337/run-latest.json';

const address = moonpierrun.transactions.filter((t) => t.contractName && t.transactionType === 'CREATE').map((tx) => ({
  address: tx.contractAddress,
  contractName: tx.contractName
}))

console.log(address);