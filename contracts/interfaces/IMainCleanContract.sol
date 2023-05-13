// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IMainCleanContract {
    // map house's token id to house
    function getContractById(uint256 contractId) external view returns (address);

    // modifies ownership of `contractId` from `from` to `to`
    function transferContractOwnership(
        uint256 contractId,
        address from,
        address to
    ) external;
}
