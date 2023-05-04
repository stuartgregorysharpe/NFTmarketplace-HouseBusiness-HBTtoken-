// SPDX-License-Identifier: MIT

interface IHouseBusiness {
    function setPayable(uint256 tokenId, address _buyer, bool nftPayable) external;

    function mintHouse(
        string memory _name,
        string memory _tokenURI,
        string memory _tokenType,
        string memory initialDesc
    ) external payable;

    function addHistory(
        uint256 _tokenId,
        uint256 contractId,
        uint256 newHistoryType,
        string memory houseImg,
        string memory houseBrand,
        string memory _history,
        string memory _desc,
        string memory brandType,
        uint256 yearField
    ) external;

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

    function removeHistoryType(uint256 _hIndex) external;

    // Disconnects contract from house history.
    function disconnectContract(uint256 tokenId, uint256 hIndex, uint256 contractId) external;

    function buyHouseNft(uint256 tokenId) external payable;

    function changeHousePrice(uint256 tokenId, uint256 newPrice) external;
}

interface IContract {}

interface IERC20Token {}

contract Operator {
    IHouseBusiness HouseBusiness;
    IContract Contract;
    IERC20Token ERC20Token;

    // Utility tokens and NFT address
    address houseBusiness = 0x0A964d282AF35e81Ad9d72e5c215108B3c43D3c1;
    address contractAddress = 0xaa3Dc2E3ca0FE2dE6E519F0F224456861A7e9cFC;
    address erc20Token = 0x27C1F4539Fd2CcE5394Ea11fA8554937A587d684;

    constructor() {
        // init contract interfaces
        HouseBusiness = IHouseBusiness(houseBusiness);
        Contract = IContract(contractAddress);
        ERC20Token = IERC20Token(erc20Token);
    }
}
