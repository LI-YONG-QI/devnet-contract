// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Plan.sol";
import "../src/PlanFactory.sol";

interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

contract PlanFactoryTest is Test, IERC721 {
    PlanFactory factory;
    Plan plan;

    address owner = address(0x1);
    string name = "Test Plan";
    string symbol = "TPLAN";
    uint256 totalSupply = 100;
    uint256 mintPrice = 1 ether;
    uint256 period = 1 days;

    event PlanCreated(address indexed creator, string indexed name, address plan, uint256 createAt);

    function setUp() public {
        factory = new PlanFactory();
        uint256 fund = 100000 ether;
        vm.deal(owner, fund);
    }

    function test_CreatePlan() public {
        vm.prank(owner);

        factory.createPlan(name, symbol, totalSupply, mintPrice, period);

        address[] memory plans = factory.getPlans(owner);
        assertEq(plans.length, 1, "Plan creation failed");

        plan = Plan(plans[0]);
        assertNotEq(address(plan), address(0), "Plan creation failed");

        assertEq(plan.name(), name, "Plan name mismatch");
        assertEq(plan.symbol(), symbol, "Plan symbol mismatch");
    }

    function test_RevertIf_CreatePlanEmptyName() public {
        vm.prank(owner);

        string memory emptyName = "";
        vm.expectRevert("PlanFactory: Not empty name or symbol");
        factory.createPlan(emptyName, symbol, totalSupply, mintPrice, period);
    }

    function test_RevertIf_CreatePlanEmptySymbol() public {
        vm.prank(owner);

        string memory emptySymbol = "";
        vm.expectRevert("PlanFactory: Not empty name or symbol");
        factory.createPlan(name, emptySymbol, totalSupply, mintPrice, period);
    }

    function test_RevertIf_NotStarted() public {
        vm.prank(owner);
        factory.createPlan(name, symbol, totalSupply, mintPrice, period);

        address[] memory plans = factory.getPlans(owner);
        plan = Plan(plans[0]);

        vm.prank(owner);
        vm.expectRevert("Plan: user did not start plan");
        plan.mint{value: mintPrice}();
    }

    function test_Withdraw() public {
        vm.prank(owner);
        factory.createPlan(name, symbol, totalSupply, mintPrice, period);

        address[] memory plans = factory.getPlans(owner);
        plan = Plan(plans[0]);

        vm.prank(owner);
        plan.active();

        vm.warp(block.timestamp + period);

        vm.prank(owner);
        vm.deal(owner, 2 ether); // Fund the owner with enough ether
        plan.mint{value: mintPrice}();

        uint256 balanceBefore = owner.balance;

        vm.prank(owner);
        plan.withdraw();

        uint256 balanceAfter = owner.balance;
        assertTrue(balanceAfter > balanceBefore, "Withdraw failed");
    }

    // Additional test cases for full coverage

    function test_ExpectEmit_CreatePlan() public {
        vm.prank(owner);

        vm.expectEmit(true, true, false, false);
        emit PlanCreated(owner, name, address(0), 0); // Address not known beforehand

        factory.createPlan(name, symbol, totalSupply, mintPrice, period);
    }

    function test_GetPlans() public {
        vm.prank(owner);
        factory.createPlan(name, symbol, totalSupply, mintPrice, period);

        address[] memory plans = factory.getPlans(owner);
        assertEq(plans.length, 1, "Owner should have one plan");

        vm.prank(owner);
        factory.createPlan("Second Plan", "SPLAN", 200, 2 ether, 2 days);

        plans = factory.getPlans(owner);
        assertEq(plans.length, 2, "Owner should have two plans");
    }

    function test_ExpectEmit_MintPlanTransfer() public {
        vm.prank(owner);
        factory.createPlan(name, symbol, totalSupply, mintPrice, period);

        address[] memory plans = factory.getPlans(owner);
        plan = Plan(plans[0]);

        vm.prank(owner);
        plan.active();

        vm.warp(block.timestamp + period);

        vm.prank(owner);
        vm.deal(owner, 2 ether); // Fund the owner with enough ether

        // Expect the Transfer event from ERC721
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), owner, 1);

        plan.mint{value: mintPrice}();

        assertEq(plan.balanceOf(owner), 1, "Minting failed");
    }
}
