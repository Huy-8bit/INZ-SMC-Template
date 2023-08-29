// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library InterfaceFunction {
    enum Operation {
        Call,
        DelegateCall
    }

    event Execution(
        address to,
        uint256 value,
        bytes data,
        Operation operation,
        bool status
    );

    /**
     *  @notice Function execute flex by abi decoded and params
     */
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(
                    txGas,
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(
                    txGas,
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        }
    }

    /*
        @dev This method is only meant for estimation purpose, therefore the call will always revert and encode the result in the revert data.
    */
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }

    // Execute tx
    function execTx(
        address to,
        uint256 value,
        uint256 txGas,
        bytes calldata data,
        Operation operation
    ) external {
        bool success = execute(to, value, data, operation, txGas);
        emit Execution(to, value, data, operation, success);
    }
}
