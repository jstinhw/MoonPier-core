import moonpierrun from '../broadcast/moonpierPolygon.s.sol/137/run-latest.json';

const address = moonpierrun.transactions.filter((t) => t.contractName && (t.transactionType === 'CREATE' || t.transactionType === 'CREATE2')).map((tx) => ({
  address: tx.contractAddress,
  contractName: tx.contractName
}))

console.log(address);