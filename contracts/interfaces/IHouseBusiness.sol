// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHouseBusiness {
    // this contract's token collection name
    function collectionName() external view returns (string calldata);

    // this contract's token symbol
    function collectionNameSymbol() external view returns (string calldata);

    // total number of houses minted
    function houseCounter() external view returns (uint256);

    // total number of staked nft
    function stakedCounter() external view returns (uint256);

    // total number of solded nft
    function soldedCounter() external view returns (uint256);

    // total number of history type
    function hTypeCounter() external view returns (uint256);

    // min house nft price
    function minPrice() external view returns (uint256);

    // max house nft price
    function maxPrice() external view returns (uint256);

    // token panalty
    function penalty() external view returns (uint256);

    // token royalty
    function royalty() external view returns (uint256);

    // define house struct
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
    // Staking NFT struct
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
    // House history struct
    struct History {
        uint256 hID;
        uint256 contractId;
        string houseImg;
        string houseBrand;
        string desc;
        string history;
        string brandType;
        uint256 yearField;
    }
    // History Type Struct
    struct HistoryType {
        uint256 hID;
        string hLabel;
        bool connectContract;
        bool imgNeed;
        bool brandNeed;
        bool descNeed;
        bool brandTypeNeed;
        bool yearNeed;
        bool checkMark;
    }

    // history types
    function historyTypes(uint256) external view returns (HistoryType calldata);

    // all house histories
    function houseHistories(uint256) external view returns (History[] calldata);

    // All APY types
    function APYtypes(uint256) external view returns (uint256);

    // APY
    function APYConfig(uint256) external view returns (uint256);

    // map members
    function allMembers(address) external view returns (bool);

    // map house's token id to house
    function allMembers(uint256) external view returns (House calldata);

    // map house's token id to house
    function allowedList(uint256, address) external view returns (bool);

    // check if token name exists
    // mapping(string => bool) external tokenNameExists;
    // check if token URI exists
    // mapping(string => bool) external tokenURIExists;
    // All Staked NFTs
    function stakedNfts(address) external view returns (StakedNft[] calldata);

    function setMinMaxHousePrice(uint256 _min, uint256 _max) external;

    function setConfigToken(address _tokenAddress) external;

    function isMember() external view returns (bool);

    function addMember(address _newMember) external;

    function removeMember(address _newMember) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function setPayable(
        uint256 tokenId,
        address _buyer,
        bool nftPayable
    ) external;

    function mintHouse(
        string memory _name,
        string memory _tokenURI,
        string memory _tokenType,
        string memory initialDesc,
        uint256 _price
    ) external payable;

    // Add allow list
    function addAllowList(uint256 _tokenId, address allowed) external;

    // Remove allow list
    function removeAllowList(uint256 _tokenId, address allowed) external;

    // Confirm is allowed list
    function checkAllowedList(uint256 _tokenId, address allowed) external view returns (bool);

    // Add history of house
    function addHistory(
        uint256 _tokenId,
        uint256 newHistoryType,
        string memory houseImg,
        string memory houseBrand,
        string memory _history,
        string memory _desc,
        string memory brandType,
        uint256 yearField
    ) external;

    function getHistory(uint256 _tokenId) external view returns (History[] memory);

    // Edit history of house
    function editHistory(
        uint256 _tokenId,
        uint256 historyIndex,
        string memory houseImg,
        string memory houseBrand,
        string memory _history,
        string memory _desc,
        string memory brandType,
        uint256 yearField
    ) external;

    // Get History Type
    function getHistoryType() external view returns (HistoryType[] memory);

    // Add Or Edit History Type
    function addOrEditHType(
        uint256 _historyIndex,
        string memory _label,
        bool _connectContract,
        bool _imgNeed,
        bool _brandNeed,
        bool _descNeed,
        bool _brandTypeNeed,
        bool _yearNeed,
        bool _checkMark
    ) external;

    // Remove History Type
    function removeHistoryType(uint256 _hIndex) external;

    function getMinMaxNFT() external view returns (uint256, uint256);

    // get owner of the token
    function getTokenOwner(uint256 _tokenId) external view returns (address);

    // by a token by passing in the token's id
    function buyHouseNft(uint256 tokenId) external payable;

    // by a token by passing in the token's id
    function sendToken(address receiver, uint256 tokenId) external payable;

    // change token price by token id
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) external;

    // get all houses NFT
    function getAllHouses() external view returns (House[] memory);

    // get all payable houses NFT
    function getAllPayableHouses() external view returns (House[] memory);

    // get all my houses NFT
    function getAllMyHouses() external view returns (House[] memory);

    // withdraw token
    function withdrawToken(uint256 _amountToken) external payable;

    // withdraw ETH
    function withdrawETH(uint256 _amountEth) external payable;

    function setAPYConfig(uint256 _type, uint256 Apy) external;

    function getAllAPYTypes() external view returns (uint256[] memory);

    // stake House Nft
    function stake(uint256 _tokenId, uint256 _stakingType) external;

    // Unstake House Nft
    function unstake(uint256 _tokenId) external;

    function stakingFinished(uint256 _tokenId) external view returns (bool);

    // Claim Rewards
    function totalRewards(address _rewardOwner) external view returns (uint256);

    // Claim Rewards
    function claimRewards(address _stakedNFTowner) external;

    // Gaddress _rewardOwneret All staked Nfts
    function getAllMyStakedNFTs() external view returns (StakedNft[] memory);

    // Get Overall total information
    function getTotalInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    // Get All APYs
    function getAllAPYs() external view returns (uint256[] memory, uint256[] memory);

    // Penalty
    function getPenalty() external view returns (uint256);

    function setPenalty(uint256 _penalty) external;

    // Royalty
    function getRoyalty() external view returns (uint256);

    function setRoyalty(uint256 _royalty) external;
}
