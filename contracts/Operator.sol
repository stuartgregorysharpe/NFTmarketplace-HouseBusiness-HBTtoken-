// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';

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

interface IMainCleanContract {
    // write Contract
    function ccCreation(
        string memory _companyName,
        string memory _contractType,
        address _contractSigner,
        string memory _contractURI,
        uint256 _dateFrom,
        uint256 _dateTo,
        uint256 _agreedPrice,
        string memory _currency
    ) external;

    // Add Contract Signer
    function addContractSigner(uint256 _ccID, address _contractSigner) external;

    // sign contract
    function signContract(uint256 ccID) external;

    // send sign notification
    function sendNotify(address _notifyReceiver, string memory _notifyContent, uint256 ccID) external;

    /**
     * @dev modifies ownership of `contractId` from `from` to `to`
     */
    function transferContractOwnership(uint256 contractId, address from, address to) external;
}

interface IHouseBusinessToken {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

contract Operator is Ownable {
    IHouseBusiness HouseBusiness;
    IMainCleanContract CContract;
    IHouseBusinessToken ERC20Token;

    // Utility tokens and NFT address
    address houseBusiness;
    address cContract;
    address erc20Token;

    constructor(address _houseBusiness, address _cContract, address _erc20) {
        // init contract interfaces
        HouseBusiness = IHouseBusiness(_houseBusiness);
        CContract = IMainCleanContract(_cContract);
        ERC20Token = IHouseBusinessToken(_erc20);
    }

    /**
     * Provides the ability to update smart contract addresses for scalability.
     * @param _houseBusiness HouseBusiness NFT address
     */
    function setHouseBusiness(address _houseBusiness) public onlyOwner {
        houseBusiness = _houseBusiness;
        HouseBusiness = IHouseBusiness(_houseBusiness);
    }

    /**
     * Provides the ability to update smart contract addresses for scalability.
     * @param _cContract MainCleanContract address
     */
    function setCContract(address _cContract) public onlyOwner {
        cContract = _cContract;
        CContract = IMainCleanContract(_cContract);
    }

    /**
     * Provides the ability to update smart contract addresses for scalability.
     * @param _erc20Token HouseBusinessToken address
     */
    function setERC20Token(address _erc20Token) public onlyOwner {
        erc20Token = _erc20Token;
        ERC20Token = IHouseBusinessToken(_erc20Token);
    }
}
