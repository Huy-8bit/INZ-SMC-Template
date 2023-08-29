// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library StorageSlot{
    struct AddressSlot{
        address value;
    }
    function getAddressSlot(bytes32 slot) external pure returns (AddressSlot storage r){
        assembly{
            r.slot := slot
        }
    }
}