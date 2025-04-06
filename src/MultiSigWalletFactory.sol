// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./MultiSigWallet.sol";
import "./MicroProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface IMultiSig {
    function initialize(address[] memory _owners, uint256 _required) external;
}

contract MultiSigWalletFactory {
    event MultiSigWalletCreated(address indexed wallet);

    address public immutable walletImplementation;

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
        bytes memory data = abi.encodeWithSignature(
            "initialize(address[],uint256)",
            _owners,
            _required
        );
        MicroProxy proxy = new MicroProxy(walletImplementation, data);
        emit MultiSigWalletCreated(address(proxy));
        return address(proxy);
    }
}
