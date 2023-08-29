# inz-smc

### Optimize Contracts

```
npm install
pip3 install slither-analyzer
pip3 install solc-select
solc-select install 0.8.2
solc-select use 0.8.2
slither contracts/{FILE_NAME} --solc-remaps @openzeppelin/=$(pwd)/node_modules/@openzeppelin/
```

### Supported chains:

```
zksync, Base (coinbase), ether, polygon, bsc(test)
```

### Required files:

1. File `.env`
2. File `.secret` included 12 mnemonics words to define the wallet that will deploy the contracts
3. `private_key` file included the private key of the deployed wallet
