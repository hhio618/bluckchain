// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import "./reactive/IReactive.sol";
import "./reactive/ISubscriptionService.sol";

contract OracleReactive is IReactive {
    uint256 private constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;

    uint256 private constant EVENT_SETTLED_TOPIC_0 = 0x73c08c7fbb4102254cad83cf325b0e5065e821b6b2fbd6c6e3776a49581707a1;

    uint64 private constant CALLBACK_GAS_LIMIT = 1000000;

    /**
     * Indicates whether this is the contract instance deployed to ReactVM.
     */
    bool private vm;

    // State specific to reactive network contract instance

    ISubscriptionService private service;

    // State specific to ReactVM contract instance

    address private l1;

    constructor(address service_address, address _l1) {
        l1 = _l1;
        service = ISubscriptionService(service_address);
        bytes memory payload = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            SEPOLIA_CHAIN_ID,
            0,
            EVENT_SETTLED_TOPIC_0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        (bool subscription_result,) = address(service).call(payload);
        if (!subscription_result) {
            vm = true;
        }
    }

    modifier rnOnly() {
        require(!vm, "Reactive Network only");
        _;
    }

    modifier vmOnly() {
        // TODO: fix the assertion after testing.
        //require(vm, 'VM only');
        _;
    }

    // Methods specific to ReactVM contract instance

    function react(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3,
        bytes calldata data,
        uint256 block_number,
        uint256 /* op_code */
    ) external vmOnly {
        if (topic_0 == EVENT_SETTLED_TOPIC_0) {
            bytes memory payload = abi.encodeWithSignature("settleMarket(uint256)", topic_1);
            emit Callback(chain_id, l1, CALLBACK_GAS_LIMIT, payload);
        } else {
            // Unreachable code
        }
    }
}
