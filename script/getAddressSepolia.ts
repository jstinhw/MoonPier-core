import moonfishrun from '../broadcast/moonfishSepolia.s.sol/11155111/run-latest.json';

const address = moonfishrun.transactions.filter((t) => t.contractName && t.transactionType === 'CREATE').map((tx) => ({
  address: tx.contractAddress,
  contractName: tx.contractName
}))

console.log(address);