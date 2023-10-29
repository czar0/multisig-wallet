// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    uint256 public constant OWNERS = 3;
    uint256 public constant REQUIRED = 2;
    address[] public owners = new address[](OWNERS);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    // Setting owners and passing them to the constructor together with required
    function setUp() public {
        for (uint160 i = 1; i <= OWNERS; ++i) {
            owners[i - 1] = address(i);
        }

        wallet = new MultiSigWallet(owners, REQUIRED);
    }

    // Owners and required should be correctly initialized
    function test_setUpState() public {
        for (uint160 i = 1; i <= OWNERS; ++i) {
            assertEq(wallet.owners(i - 1), address(i));
            assertTrue(wallet.isOwner(address(i)));
        }
        assertEq(wallet.required(), REQUIRED);
    }

    // Anyone should be able to transfer ether to the contract
    function test_Payable() public {
        vm.expectEmit();
        emit Deposit(address(123), 5 ether);

        hoax(address(123), 5 ether);
        payable(address(wallet)).transfer(5 ether);
        assertEq(address(wallet).balance, 5 ether);
    }

    // Owners should be able to submit a transaction
    function test_submit_OwnerCanSubmit() public {
        vm.expectEmit();
        emit Submit(0);

        vm.prank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");
        (address to, uint256 value, bytes memory data, bool executed) = wallet.transactions(0);
        assertEq(to, address(123));
        assertEq(value, 1 ether);
        assertEq(data, bytes("gm"));
        assertFalse(executed);
    }

    // Non-owners should not be able to submit a transaction
    function test_submit_RevertIf_NonOwner() public {
        vm.prank(address(123));
        vm.expectRevert("not owner");
        wallet.submit(address(123), 1 ether, "gm");
    }

    // An owner should be able to approve a transaction that has already been submitted (`txId` exists)
    function test_approve_OwnerCanApprove() public {
        vm.startPrank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");

        vm.expectEmit();
        emit Approve(owners[0], 0);
        wallet.approve(0);
        assertTrue(wallet.approved(0, owners[0]));
    }

    // Non-owners should not be able to approve a transaction
    function test_approve_RevertIf_NonOwner() public {
        vm.prank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");

        vm.prank(address(123));
        vm.expectRevert("not owner");
        wallet.approve(0);
    }

    // Approve should revert if the transaction does not exists
    function test_approve_RevertIf_TxNotExist() public {
        vm.prank(owners[0]);
        vm.expectRevert();
        wallet.approve(0);
    }

    // An owner should not be able to approve a transaction that they have already approved
    function test_approve_RevertIf_OwnerAlreadyApproved() public {
        vm.startPrank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");
        wallet.approve(0);

        vm.expectRevert("tx already approved");
        wallet.approve(0);
    }

    // An owner should be able to revoke a transaction that has already been submitted (`txId` exists) and approved
    function test_revoke_OwnerCanRevoke() public {
        vm.startPrank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");
        wallet.approve(0);

        vm.expectEmit();
        emit Revoke(owners[0], 0);

        wallet.revoke(0);
        assertFalse(wallet.approved(0, owners[0]));
    }

    // An owner should not be able to revoke a transaction that they haven't already approved
    function test_revoke_RevertIf_OwnerDidNotApprove() public {
        vm.startPrank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");

        vm.expectRevert("tx not approved");
        wallet.revoke(0);
    }

    // Non-owners should not be able to revoke a transaction
    function test_revoke_RevertIf_NonOwner() public {
        vm.prank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");

        vm.prank(address(123));
        vm.expectRevert("not owner");
        wallet.revoke(0);
    }

    // Revoke should revert if the transaction does not exists
    function test_revoke_RevertIf_TxNotExist() public {
        vm.prank(owners[0]);
        vm.expectRevert("tx not exist");
        wallet.revoke(0);
    }

    // An owner should not be able to revoke a transaction that they did not approved
    function test_revoke_RevertIf_TxNotApproved() public {
        vm.startPrank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");
        wallet.approve(0);
        wallet.revoke(0);

        vm.expectRevert("tx not approved");
        wallet.revoke(0);
    }

    // An owner should be able to execute a transaction that has required approvals
    function test_execute_WithEnoughApprovals() public {
        deal(owners[0], 5 ether);
        assertEq(owners[0].balance, 5 ether);

        vm.startPrank(owners[0]);
        payable(address(wallet)).transfer(5 ether);
        assertEq(address(wallet).balance, 5 ether);
        wallet.submit(address(123), 1 ether, "gm");
        vm.stopPrank();

        for (uint256 i = 0; i < REQUIRED; ++i) {
            vm.prank(owners[i]);
            wallet.approve(0);
        }

        vm.expectEmit();
        emit Execute(0);

        wallet.execute(0);
        (address to, uint256 value, bytes memory data, bool executed) = wallet.transactions(0);
        assertEq(to, address(123));
        assertEq(value, 1 ether);
        assertEq(data, bytes("gm"));
        assertTrue(executed);
        assertEq(address(123).balance, 1 ether);
    }

    // Execute should revert if there is the transaction has already been executed (tx.executed=true)
    function test_execute_RevertIf_AlreadyExecuted() public {
        deal(owners[0], 5 ether);
        assertEq(owners[0].balance, 5 ether);

        vm.startPrank(owners[0]);
        payable(address(wallet)).transfer(5 ether);
        assertEq(address(wallet).balance, 5 ether);
        wallet.submit(address(123), 1 ether, "gm");
        vm.stopPrank();

        for (uint256 i = 0; i < REQUIRED; ++i) {
            vm.prank(owners[i]);
            wallet.approve(0);
        }

        vm.expectEmit();
        emit Execute(0);

        wallet.execute(0);
        vm.expectRevert("tx already executed");
        wallet.execute(0);
    }

    // An owner should not be able to execute a transaction that did not reach the threshod of approvals set in `REQUIRED`
    function test_execute_RevertIf_NotEnoughApprovals() public {
        vm.prank(owners[0]);
        wallet.submit(address(123), 1 ether, "gm");

        for (uint256 i = 0; i < REQUIRED - 1; ++i) {
            vm.prank(owners[i]);
            wallet.approve(0);
        }

        vm.expectRevert("not enough approvals");
        wallet.execute(0);
    }

    // Execute should revert if there is not enough balance in the contract to be transferred out to the recipient of the transaction
    function test_execute_RevertIf_NotEnoughBalance() public {
        deal(owners[0], 0.1 ether);
        assertEq(owners[0].balance, 0.1 ether);

        vm.startPrank(owners[0]);
        payable(address(wallet)).transfer(0.1 ether);
        assertEq(address(wallet).balance, 0.1 ether);
        wallet.submit(address(123), 1 ether, "gm");
        vm.stopPrank();

        for (uint256 i = 0; i < REQUIRED; ++i) {
            vm.prank(owners[i]);
            wallet.approve(0);
        }

        vm.expectRevert("not enough balance");
        wallet.execute(0);
    }
}
