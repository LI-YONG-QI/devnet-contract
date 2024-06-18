// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Plan} from "../src/Plan.sol";

interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

contract PlanTest is Test, IERC721 {
    Plan plan;
    address owner = address(1);
    address user = address(2);

    string constant NAME = "PlanToken";
    string constant SYMBOL = "PTK";
    uint256 constant TOTAL_SUPPLY = 1000;
    uint256 constant MINT_PRICE = 1 ether;
    uint256 constant PERIOD = 1 days;

    function setUp() public {
        vm.startPrank(owner);
        plan = new Plan(owner, NAME, SYMBOL, TOTAL_SUPPLY, MINT_PRICE, PERIOD);
        vm.stopPrank();
        uint256 fund = 100000 ether;
        vm.deal(user, fund);
    }

    function test_Active() public {
        vm.startPrank(user);
        plan.active();
        assertEq(plan.getPlan(user), block.timestamp);
        vm.stopPrank();
    }

    function test_RevertIf_ActiveTwice() public {
        vm.startPrank(user);
        plan.active();
        vm.expectRevert("Plan: user already started plan");
        plan.active();
        vm.stopPrank();
    }

    function test_RevertIf_NotStartedPlan() public {
        vm.startPrank(user);
        vm.expectRevert("Plan: user did not start plan");
        plan.mint{value: MINT_PRICE}();
        vm.stopPrank();
    }

    function test_RevertIf_MintInsufficientValue() public {
        vm.startPrank(user);
        plan.active();
        vm.warp(block.timestamp + PERIOD);

        vm.expectRevert("Plan: value is not enough for minting");
        plan.mint{value: 0.5 ether}();
        vm.stopPrank();
    }

    function test_RevertIf_MintTooSoon() public {
        vm.startPrank(user);
        plan.active();

        vm.expectRevert("Plan: time not finished yet");

        plan.mint{value: MINT_PRICE}();
        vm.stopPrank();
    }

    function test_RevertIf_MintTotalSupplyReached() public {
        vm.startPrank(user);

        for (uint256 i = 0; i < TOTAL_SUPPLY - 1; i++) {
            plan.active();
            vm.warp(block.timestamp + PERIOD);
            plan.mint{value: MINT_PRICE}();
        }

        plan.active();
        vm.warp(block.timestamp + PERIOD);
        vm.expectRevert("Plan: total supply reached");
        plan.mint{value: MINT_PRICE}();
        vm.stopPrank();
    }

    function test_ExpectEmit_Mint() public {
        vm.startPrank(user);
        plan.active();
        vm.warp(block.timestamp + PERIOD);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), user, 1);

        plan.mint{value: MINT_PRICE}();

        assertEq(plan.balanceOf(user), 1);
        assertEq(plan.getPlan(user), 0);
        vm.stopPrank();
    }

    function test_Withdraw() public {
        vm.startPrank(user);
        plan.active();
        vm.warp(block.timestamp + PERIOD);
        plan.mint{value: MINT_PRICE}();
        vm.stopPrank();

        vm.startPrank(owner);
        uint256 ownerBalanceBefore = owner.balance;
        plan.withdraw();
        uint256 ownerBalanceAfter = owner.balance;

        assertTrue(ownerBalanceAfter > ownerBalanceBefore);
        vm.stopPrank();
    }
}
