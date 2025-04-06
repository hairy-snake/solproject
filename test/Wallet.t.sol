// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";
import "../src/MultiSigWalletFactory.sol";
import "../src/MicroProxy.sol";

contract MultiSigWalletTest is Test {
    MultiSigWalletFactory factory;
    address walletImpl;
    MultiSigWallet wallet;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address nonOwner = address(0x4);
    address payable recipient = payable(address(0xdead));

    function setUp() public {
        vm.prank(address(this));
        MultiSigWallet impl = new MultiSigWallet();
        walletImpl = address(impl);

        factory = new MultiSigWalletFactory(walletImpl);

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vm.prank(address(this));
        address proxyAddr = factory.createMultiSigWallet(owners, 2);
        wallet = MultiSigWallet(payable(proxyAddr));
    }

    function testInitialization() public {
        assertEq(wallet.required(), 2);
        assertEq(wallet.owners(0), owner1);
        assertEq(wallet.owners(1), owner2);
        assertEq(wallet.owners(2), owner3);
    }

    function testDeposit() public {
        vm.deal(owner1, 1 ether);
        vm.prank(owner1);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(wallet).balance, 1 ether);
    }

    function testSubmitAndExecuteTransaction() public {
        vm.deal(address(wallet), 1 ether);

        bytes memory data = "";
        vm.prank(owner1);
        uint txId = wallet.submitTransaction(recipient, 0.5 ether, data);

        vm.prank(owner1);
        wallet.confirmTransaction(txId);

        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.prank(owner3);
        wallet.executeTransaction(txId);

        assertEq(address(recipient).balance, 0.5 ether);
    }

    function testNonOwnerCannotSubmit() public {
        vm.expectRevert("Not an owner");
        vm.prank(nonOwner);
        wallet.submitTransaction(recipient, 1 ether, "");
    }

    function testNonOwnerCannotConfirm() public {
        vm.prank(owner1);
        uint txId = wallet.submitTransaction(recipient, 0, "");

        vm.expectRevert("Not an owner");
        vm.prank(nonOwner);
        wallet.confirmTransaction(txId);
    }

    function testDoubleExecutionFails() public {
        vm.deal(address(wallet), 1 ether);

        vm.prank(owner1);
        uint txId = wallet.submitTransaction(recipient, 0.1 ether, "");

        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.prank(owner3);
        wallet.executeTransaction(txId);

        vm.expectRevert("faulty transaction");
        vm.prank(owner3);
        wallet.executeTransaction(txId);
    }

    receive() external payable {}
}
