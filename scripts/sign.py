import os

from web3 import Web3
from pydash import get
from dotenv import load_dotenv

load_dotenv()

_privateKeySigner = "98102796d0dfe116f5af6e9a3c10dc38d316f6c98b3ded8d008b962c7d126460"  # from BackEnd Dev's Wallet

_user_address = (
    "0xf25abdb08ff0e0e5561198a53f1325dcfbe92428"  # for user want minting NFT
)

_contract_address = "0x7e75d72AAcF09De4D221a81892f5d3cb2Cd3b4A5"  # DaapNFTCreator

_nft_collection_address = "0x9a16d81055e82174f230384d983960adfa0de7e5"  # Collection[0]

# Base Goerli

# DaapNFTCreator=0xB7557b1EF53a235a7f5e206CCF725dB1a2ceB030
# InZTreasury=0xA5647cA32CAe4330fcb4ADBDE6538Ff4A4A4B53E
# Configurations=0x66377B2E1c36a47bb4d673e28BD5Bf5166d20478
# GatewayNFT=0x5031B819BE3BB8f55a303311EF26643F97Fb8f37
# Collection=0x1093182B5EBe37103A9De50101a3189F534cBA0a

# BSC


# Scroll Alpha Testnet


BASE_GOERLI = 84531
SCROLL_ALPHA_TEST = 534353
BSC_TESTNET = 97
SEPOLIA = 11155111

_data = {
    "chain_network": BASE_GOERLI,
    "discount": 0,
    "nft_type": 1,
    "amount": 1,
    "platformFee": 500000000000000,
    "deadline": 1793220257,
}


def generate_signature():
    _w3 = Web3()
    _encode = _w3.codec.encode_abi(
        [
            "uint256",  # chain
            "address",  # _user_address
            "address",  # contract creator
            "address",  # nft address
            "uint256",  # discount
            "bool",  # is whitelist
            "uint8",  # nft_type
            "uint256",  # amount
            "uint256",  # platformFee
            "uint256",  # deadline
        ],
        [
            get(_data, "chain_network"),
            _user_address,
            _contract_address,
            _nft_collection_address,
            get(_data, "discount"),
            False,
            get(_data, "nft_type"),  # NFT type
            get(_data, "amount"),  # amount
            get(_data, "platformFee"),  # platformFee
            get(_data, "deadline"),
        ],
    )

    digest = Web3.solidityKeccak(["bytes"], [f"0x{_encode.hex()}"])
    _signed_message = _w3.eth.account.signHash(digest, private_key=_privateKeySigner)

    return _signed_message.signature.hex()


print("* Signature = ", generate_signature())


# base = 0x5a0b849136aa2b8b822342934bad251c191c4cb1bc57770af734e7e868ac03df70c17ee5659b97121b02dfc8ab3786b7940adb07a00269d187a495af2a7766821c
