// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./MultiSigWallet.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MultiSigWalletFactory {
    event MultiSigWalletCreated(address indexed wallet);

    address public walletImplementation;

    constructor(address _walletImplementation) {
        require(
            _walletImplementation != address(0),
            "Invalid wallet implementation"
        );
        walletImplementation = _walletImplementation;
    }

    function createMultiSigWallet(
        address[] memory _owners,
        uint _required
    ) public returns (address) {
        ERC1967Proxy proxy = new ERC1967Proxy(
            walletImplementation,
            abi.encodeWithSignature(
                "initialize(address[],uint256)",
                _owners,
                _required
            )
        );

        emit MultiSigWalletCreated(address(proxy));
        return address(proxy);
    }
}
