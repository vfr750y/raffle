// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CreateSubscription} from "../../script/Interactions.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";

contract CreateSubscriptionTest is Test, CodeConstants {
    CreateSubscription public createSubscription;
    HelperConfig public helperConfig;
    VRFCoordinatorV2_5Mock public vrfCoordinatorMock;

    address public constant TEST_ACCOUNT = address(0x123); // Test account for broadcasting

    function setUp() public {
        // Deploy the VRFCoordinatorV2_5Mock using inherited constants
        vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );

        // Deploy HelperConfig
        helperConfig = new HelperConfig();

        // Deploy CreateSubscription
        createSubscription = new CreateSubscription();

        // Set the chain ID to LOCAL_CHAIN_ID (Anvil)
        vm.chainId(LOCAL_CHAIN_ID);

        // Log the deployed VRFCoordinator address
        console.log(
            "Deployed vrfCoordinatorMock:",
            address(vrfCoordinatorMock)
        );
    }

    function testCreateSubscriptionCreatesValidSubscriptionId() public {
        // Arrange
        address vrfCoordinator = address(vrfCoordinatorMock);
        address account = TEST_ACCOUNT;

        // Log the input vrfCoordinator
        console.log("Input vrfCoordinator:", vrfCoordinator);

        // Act
        (uint256 subId, address returnedVrfCoordinator) = createSubscription
            .createSubscription(vrfCoordinator, account);

        // Log the returned vrfCoordinator
        console.log("Returned vrfCoordinator:", returnedVrfCoordinator);

        // Assert
        assertGt(subId, 0); // Subscription ID should be non-zero
        assertEq(
            returnedVrfCoordinator,
            vrfCoordinator,
            "VRF Coordinator address mismatch"
        ); // Should match input
        (, , , address owner, ) = vrfCoordinatorMock.getSubscription(subId); // Access subOwner from getSubscription
        assertEq(owner, account); // Subscription owner should be the account
    }

    /* function testCreateSubscriptionUsingConfigCreatesValidSubscriptionId()
        public
    {
        // Arrange
        HelperConfig.NetworkConfig memory config = HelperConfig.NetworkConfig({
            entryFee: 0.01 ether,
            interval: 30 seconds,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: bytes32(0),
            callbackGasLimit: 500000,
            subscriptionId: 0,
            link: address(0), // Not used in createSubscription
            account: TEST_ACCOUNT
        });

        // Log the config VRF Coordinator
        console.log("Config vrfCoordinator:", config.vrfCoordinator);

        // Mock the getConfig function to return our test config
        vm.mockCall(
            address(helperConfig),
            abi.encodeWithSelector(HelperConfig.getConfig.selector),
            abi.encode(config)
        );

        // Act
        (uint256 subId, address returnedVrfCoordinator) = createSubscription
            .CreateSubscriptionUsingConfig();

        // Log the returned vrfCoordinator
        console.log(
            "Returned vrfCoordinator (UsingConfig):",
            returnedVrfCoordinator
        );

        // Assert
        assertGt(subId, 0); // Subscription ID should be non-zero
        assertEq(
            returnedVrfCoordinator,
            address(vrfCoordinatorMock),
            "VRF Coordinator address mismatch"
        ); // Should match mock
        (, , , address owner, ) = vrfCoordinatorMock.getSubscription(subId); // Access subOwner from getSubscription
        assertEq(owner, TEST_ACCOUNT); // Subscription owner should be TEST_ACCOUNT
    }
*/
    function testCreateSubscriptionRevertsWithInvalidVrfCoordinator() public {
        // Arrange
        address invalidVrfCoordinator = address(0x456); // Non-contract address
        address account = TEST_ACCOUNT;

        // Act & Assert
        vm.expectRevert(); // Expect revert due to invalid contract address
        createSubscription.createSubscription(invalidVrfCoordinator, account);
    }
}
