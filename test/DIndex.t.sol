// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import "../src/DIndex.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract DIndexTest is PRBTest, StdCheats {
    DIndex internal dIndex;

    function setUp() public {
        dIndex = new DIndex();
        dIndex.createDappProfile("Maker");

        dIndex.addAttribute(0, 0, "Holders");
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testCreateDapp() public {
        dIndex.createDappProfile("Uniswap");
    }

    function testGetDappAverage() public {
        assertEq(dIndex.getDappAverage(1), 0);
    }

    function testRateDapp() public {
        uint256 average = dIndex.rateDapp(0, 0, 8);
        assertEq(average, 8);

        uint256 attributeAvg = dIndex.getAttributeAverage(0, 0);
        assertEq(attributeAvg, 8);

        vm.warp(block.timestamp + 4 weeks);

        dIndex.rateDapp(0, 0, 10);
    }
}
