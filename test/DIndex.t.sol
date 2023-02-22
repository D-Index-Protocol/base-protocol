// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { console } from "forge-std/console.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import "../src/DIndex.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract DIndexTest is PRBTest, StdCheats {
    DIndex internal dIndex;

    function setUp() public {
        dIndex = new DIndex();
        dIndex.createIndexProfile("Ethereum");

        dIndex.addAttribute(0, 0, "Holders");
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testCreateIndex() public {
        dIndex.createIndexProfile("Uniswap");
    }

    function testGetIndexAverage() public {
        assertEq(dIndex.getIndexAverage(1), 0);
    }

    function testRateIndex() public {
        uint256 globalAvg1 = dIndex.rateIndex(0, 0, 8);
        assertEq(globalAvg1, 8);

        // uint256 attributeAvg1 = dIndex.getAttributeAverage(0, 0);
        // assertEq(attributeAvg1, 8);

        vm.warp(block.timestamp + 4 weeks);

        uint256 globalAvg2 = dIndex.rateIndex(0, 0, 10);
        assertEq(globalAvg2, 18);

        // uint256 attributeAvg2 = dIndex.getAttributeAverage(0, 0);
        // assertEq(attributeAvg2, 9);
    }

    function testRateWithManyAttrs() public {
        dIndex.addAttribute(0, 1, "Geographic Nodes Distribution");
        dIndex.addAttribute(0, 2, "Multisig");
        dIndex.addAttribute(0, 3, "Developers");
        dIndex.addAttribute(0, 4, "Issuance");

        dIndex.rateIndex(0, 1, 4);
        dIndex.rateIndex(0, 2, 6);
        dIndex.rateIndex(0, 3, 8);
        dIndex.rateIndex(0, 4, 1);

        //  uint256 globalIndexAvg = dIndex.getIndexAverage(0);
        uint256 attributeAvg2 = dIndex.getAttributeAverage(0, 1);
        console.log(attributeAvg2 * 1e18);
        // assertEq(globalIndexAvg, b);
    }
}
