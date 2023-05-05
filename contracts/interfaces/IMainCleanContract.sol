// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IMainCleanContract {
    // define contract struct
    struct CleanContract {
        uint256 contractId;
        string companyName;
        string contractType;
        string contractURI;
        uint256 dateFrom;
        uint256 dateTo;
        uint256 agreedPrice;
        string currency;
        address creator;
        address owner;
        bool creatorApproval;
        uint256 creatorSignDate;
        address contractSigner;
        bool signerApproval;
        uint256 signerSignDate;
        string status;
    }

    // map house's token id to house
    function getContractById(uint256 contractId) external view returns (CleanContract memory);

    // modifies ownership of `contractId` from `from` to `to`
    function transferContractOwnership(
        uint256 contractId,
        address from,
        address to
    ) external;
}
