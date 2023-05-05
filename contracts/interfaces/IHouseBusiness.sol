// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHouseBusiness {

    struct House {
        uint256 tokenId;
        uint256 tokenName;
        string tokenURI;
        string tokenType;
        address currentOwner;
        address previousOwner;
        address buyer;
        uint256 price;
        uint256 numberOfTransfers;
        bool nftPayable;
        bool staked;
        bool soldstatus;
    }
    struct StakedNft {
        address owner;
        uint256 tokenId;
        uint256 startedDate;
        uint256 endDate;
        uint256 claimDate;
        uint256 stakingType;
        uint256 perSecRewards;
        bool stakingStatus;
    }

    function member(address) external view returns (bool);

    function allHouses(uint256) external view returns (House calldata);

    function stakedNfts(address) external view returns (StakedNft[] calldata);

    function ownerOf(uint256 tokenId) external returns (address);

    function getTokenPrice(uint256 tokenId) external view returns (uint256);

    function setHouseStakedStatus(uint256 tokenId, bool status) external;
}
