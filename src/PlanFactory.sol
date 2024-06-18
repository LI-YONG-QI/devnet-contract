pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Plan} from "./Plan.sol";

contract PlanFactory {
    event PlanCreated(
        address indexed creator,
        string indexed name,
        address plan,
        uint256 createAt
    );

    using Strings for string;

    mapping(address => address[]) public userToPlans;

    function _getBytecode(
        address owner,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 mintPrice_,
        uint256 period_
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(Plan).creationCode;
        return
            abi.encodePacked(
                bytecode,
                abi.encode(
                    owner,
                    name,
                    symbol,
                    totalSupply,
                    mintPrice_,
                    period_
                )
            );
    }

    function createPlan(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 mintPrice_,
        uint256 period_
    ) external returns (address plan) {
        require(
            !(name.equal("") || symbol.equal("")),
            "PlanFactory: Not empty name or symbol"
        );

        bytes memory bytecode = _getBytecode(
            msg.sender,
            name,
            symbol,
            totalSupply,
            mintPrice_,
            period_
        );

        plan = Create2.deploy(0, keccak256(bytecode), bytecode);
        userToPlans[msg.sender].push(plan);

        emit PlanCreated(msg.sender, name, plan, block.timestamp);
    }

    //-----VIEW------//
    function getPlans(
        address creator
    ) external view returns (address[] memory) {
        return userToPlans[creator];
    }

    function isPlan(
        address creator,
        address plan
    ) external view returns (bool) {
        for (uint256 i = 0; i < userToPlans[creator].length; i++) {
            if (userToPlans[creator][i] == plan) return true;
        }
        return false;
    }
}
