// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract MicroProxy {
    constructor(address _implementation, bytes memory _data) {
        bytes32 slot = keccak256("eip1967.proxy.implementation");
        assembly {
            sstore(slot, _implementation)
        }
        if (_data.length > 0) {
            (bool success, ) = _implementation.delegatecall(_data);
            require(success, "failed to delegatecall");
        }
    }

    fallback() external payable {
        bytes32 slot = keccak256("eip1967.proxy.implementation");
        assembly {
            let implementation := sload(slot)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            if eq(result, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    receive() external payable {}
}
