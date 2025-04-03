// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/MultiSigWallet.sol";
import "forge-std/Test.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address recipient = address(0x4);

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        wallet = new MultiSigWallet();
        wallet.initialize(owners, 2);
    }

    function testSubmitTransaction() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        assertEq(wallet.transactions(0).value, 1 ether);
    }

    function testConfirmTransaction() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        vm.prank(owner2);
        wallet.confirmTransaction(0);
        assertEq(wallet.transactions(0).confirmations, 1);
    }

    function testExecuteTransaction() public {
        vm.deal(address(wallet), 2 ether);
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        vm.prank(owner2);
        wallet.confirmTransaction(0);
        vm.prank(owner3);
        wallet.confirmTransaction(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);
        assert(wallet.transactions(0).executed);
    }
}
