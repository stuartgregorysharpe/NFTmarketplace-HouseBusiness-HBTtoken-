// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketplace {
    struct HistoryType {
        string hLabel;
        bool connectContract;
        bool imgNeed;
        bool brandNeed;
        bool descNeed;
        bool brandTypeNeed;
        bool yearNeed;
        bool otherInfo;
        uint256 mValue;
        uint256 eValue;
    }

    struct LabelPercent {
        uint256 connectContract;
        uint256 image;
        uint256 brand;
        uint256 desc;
        uint256 brandType;
        uint256 year;
        uint256 otherInfo;
    }

    function getHistoryTypeById(uint256 _typeId) external view returns (HistoryType memory);

    function getMinMaxHousePrice() external view returns (uint256, uint256);

    function getRoyalties() external view returns (uint256, uint256);

    function getLabelPercents() external view returns (LabelPercent memory);
}
