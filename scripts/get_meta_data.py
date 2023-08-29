from thirdweb import ThirdwebSDK

# Set your RPC_URL
RPC_URL = "https://goerli.base.org"
# https://skilled-old-crater.base-goerli.discover.quiknode.pro/c19690ab103ce261edc15eb2e0e272b0414830a1/

NFT_COLLECTION_ADDRESS = "0x298e9b59175Bd2919EDFDD4a591aaCAc32BACAC6"

sdk = ThirdwebSDK(RPC_URL)



# And you can instantiate your contract with just one line
nft_collection = sdk.get_nft_collection(NFT_COLLECTION_ADDRESS)

# Now you can use any of the read-only SDK contract functions
nfts = nft_collection.get_all()
print(nfts)
