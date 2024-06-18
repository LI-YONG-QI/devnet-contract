pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Plan is ERC721, Ownable {
    event Active(address indexed user, uint256 indexed startTime);

    uint256 immutable TOTAL_SUPPLY;

    uint256 currentSupply;
    uint256 mintPrice;
    uint256 period; // Default plan period timestamp

    // start user => start plan time
    mapping(address => uint256) public startTime;

    constructor(
        address owner,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 mintPrice_,
        uint256 period_
    ) ERC721(name, symbol) Ownable(owner) {
        TOTAL_SUPPLY = totalSupply;
        currentSupply = 0;
        mintPrice = mintPrice_;
        period = period_;
    }

    function active() external {
        require(startTime[msg.sender] == 0, "Plan: user already started plan");
        startTime[msg.sender] = block.timestamp;
    }

    function mint() public payable {
        uint256 time = startTime[msg.sender];

        require(time > 0, "Plan: user did not start plan");
        require(block.timestamp >= time + period, "Plan: time not finished yet");
        require(msg.value >= mintPrice, "Plan: value is not enough for minting");
        require(currentSupply + 1 < TOTAL_SUPPLY, "Plan: total supply reached");

        startTime[msg.sender] = 0;
        currentSupply += 1;
        _mint(msg.sender, currentSupply);
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Plan: withdraw failed");
    }

    //view
    function getPlan(address user) external view returns (uint256) {
        return startTime[user];
    }
}
