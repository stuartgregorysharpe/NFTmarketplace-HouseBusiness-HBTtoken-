// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import './interfaces/IStaking.sol';
import './interfaces/IMainCleanContract.sol';

contract HouseBusiness is ERC721, ERC721URIStorage {
    string public collectionName;
    string public collectionNameSymbol;
    uint256 public houseCounter;
    uint256 public soldedCounter;
    uint256 public minPrice;
    uint256 public maxPrice;
    uint256 public hTypeCounter;
    uint256 public royaltyCreator;
    uint256 public royaltyMarket;

    IERC20 _token;
    IMainCleanContract cContract;

    struct Contributor {
        address currentOwner;
        address previousOwner;
        address buyer;
        address creator;
    }
    struct House {
        uint256 houseID;
        string tokenName;
        string tokenURI;
        string tokenType;
        uint256 price;
        uint256 numberOfTransfers;
        bool nftPayable;
        bool staked;
        bool soldStatus;
        Contributor contributor;
    }
    struct History {
        uint256 hID;
        uint256 houseID;
        uint256 contractId;
        uint256 historyTypeId;
        string houseImg;
        string houseBrand;
        string desc;
        string history;
        string brandType;
        uint256 yearField;
    }
    struct HistoryType {
        string hLabel;
        bool connectContract;
        bool imgNeed;
        bool brandNeed;
        bool descNeed;
        bool brandTypeNeed;
        bool yearNeed;
        bool checkMark;
    }

    mapping(address => bool) public member;
    mapping(uint256 => House) public allHouses;
    mapping(uint256 => History[]) public houseHistories;
    mapping(uint256 => HistoryType) public historyTypes;
    mapping(uint256 => mapping(address => bool)) public allowedList;

    address stakingContractAddress;
    address operatorAddress;

    event HouseMinted(
        address indexed minter,
        string name,
        string tokenURI,
        string tokenType,
        string initialDesc,
        uint256 timestamp
    );
    event PayableSet(address indexed owner, uint256 indexed tokenId, address buyer, bool nftPayable, uint256 timestamp);
    event AllowListAdded(address indexed currentOwner, uint256 indexed tokenId, address allowed, uint256 timestamp);
    event AllowListRemoved(address indexed currentOwner, uint256 indexed tokenId, address allowed, uint256 timestamp);
    event HistoryAdded(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed contractId,
        uint256 historyTypeId,
        string houseImg,
        string houseBrand,
        string history,
        string desc,
        string brandType,
        uint256 yearField,
        uint256 timestamp
    );
    event HistoryEdited(
        address indexed editor,
        uint256 indexed tokenId,
        uint256 historyIndex,
        uint256 historyTypeId,
        string houseImg,
        string houseBrand,
        string history,
        string desc,
        string brandType,
        uint256 yearField,
        uint256 timestamp
    );
    event HistoryTypeAdded(
        address indexed member,
        uint256 indexed hID,
        string label,
        bool connectContract,
        bool imgNeed,
        bool brandNeed,
        bool descNeed,
        bool brandTypeNeed,
        bool yearNeed,
        bool checkMark,
        uint256 hTypeCounter,
        uint256 timestamp
    );
    event HistoryTypeUpdated(
        address indexed member,
        uint256 indexed hID,
        string label,
        bool connectContract,
        bool imgNeed,
        bool brandNeed,
        bool descNeed,
        bool brandTypeNeed,
        bool yearNeed,
        bool checkMark,
        uint256 timestamp
    );
    event HistoryTypeRemoved(address indexed member, uint256 indexed hIndex, uint256 hTypeCounter, uint256 timestamp);
    event ContractDisconnected(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed hIndex,
        uint256 contractId,
        uint256 timestamp
    );
    event HouseNftBought(
        uint256 indexed tokenId,
        address indexed buyer,
        address previousOwner,
        address creator,
        uint256 price,
        uint256 timestamp
    );
    event HousePriceChanged(uint256 indexed tokenId, address indexed owner, uint256 price);
    event TokenWithdrawn(address indexed sender, uint256 amount, uint256 timestamp);
    event EthWithdrawn(address indexed sender, uint256 amount, uint256 timestamp);
    event HouseStakedStatusSet(uint256 indexed tokenId, bool status, uint256 timestamp);
    event RoyaltyCreatorSet(address indexed member, uint256 royalty, uint256 timestamp);
    event RoyaltyMarketSet(address indexed member, uint256 royalty, uint256 timestamp);
    event TokenPriceChanged(uint256 indexed tokenId, uint256 newPrice, uint256 timestamp);

    constructor(address _tokenAddress) ERC721('HouseBusiness', 'HUBS') {
        (collectionName, collectionNameSymbol) = (name(), symbol());
        member[msg.sender] = true;
        royaltyCreator = 6;
        royaltyMarket = 2;
        minPrice = 10 ** 16;
        maxPrice = 10 ** 18;
        _token = IERC20(_tokenAddress);
        addDefaultHTypes();
    }

    function addDefaultHTypes() internal {
        historyTypes[0] = HistoryType({
            hLabel: 'Construction',
            connectContract: false,
            imgNeed: false,
            brandNeed: false,
            descNeed: false,
            brandTypeNeed: false,
            yearNeed: false,
            checkMark: false
        });
        historyTypes[1] = HistoryType({
            hLabel: 'Floorplan',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false
        });
        historyTypes[2] = HistoryType({
            hLabel: 'Pictures',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false
        });
        historyTypes[3] = HistoryType({
            hLabel: 'Blueprint',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false
        });
        historyTypes[4] = HistoryType({
            hLabel: 'Solarpanels',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false
        });
        historyTypes[5] = HistoryType({
            hLabel: 'Airconditioning',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false
        });
        historyTypes[6] = HistoryType({
            hLabel: 'Sonneboiler',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false
        });
        historyTypes[7] = HistoryType({
            hLabel: 'Housepainter',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false
        });
        hTypeCounter = 7;
    }

    modifier onlyMember() {
        require(member[msg.sender], 'Only Member');
        _;
    }

    function setOperatorAddress(address _address) public onlyMember {
        operatorAddress = _address;
    }

    function setCContractAddress(address _address) external onlyMember {
        cContract = IMainCleanContract(_address);
    }

    function setStakingContractAddress(address _address) external onlyMember {
        stakingContractAddress = _address;
    }

    // Sets house staked status
    function setHouseStakedStatus(uint256 _tokenId, bool _status) external {
        require(msg.sender == stakingContractAddress, 'Unauthorized: not a Staking contract');
        allHouses[_tokenId].staked = _status;

        emit HouseStakedStatusSet(_tokenId, _status, block.timestamp);
    }

    function setMinMaxHousePrice(uint256 _min, uint256 _max) external onlyMember {
        minPrice = _min;
        maxPrice = _max;
    }

    function setConfigToken(address _tokenAddress) external {
        _token = IERC20(_tokenAddress);
    }

    function setPayable(uint256 _tokenId, address _buyer, bool _nftPayable) external {
        // require that token should exist
        require(_exists(_tokenId));
        // check that token's owner should be equal to the caller of the function
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        require(allHouses[_tokenId].price > 0, 'Hasnot set: Pricing.');
        if (allHouses[_tokenId].contributor.buyer != _buyer) allHouses[_tokenId].contributor.buyer = _buyer;
        allHouses[_tokenId].nftPayable = _nftPayable;

        emit PayableSet(msg.sender, _tokenId, _buyer, _nftPayable, block.timestamp);
    }

    function setRoyaltyCreator(uint256 _royalty) external onlyMember {
        royaltyCreator = _royalty;

        emit RoyaltyCreatorSet(msg.sender, _royalty, block.timestamp);
    }

    function setRoyaltyMarket(uint256 _royalty) external onlyMember {
        royaltyMarket = _royalty;

        emit RoyaltyMarketSet(msg.sender, _royalty, block.timestamp);
    }

    /**
     * @dev disconnects contract from house history
     */
    function disconnectContract(uint256 _tokenId, uint256 _hIndex, uint256 _contractId) external {
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        History storage history = houseHistories[_tokenId][_hIndex];
        require(history.contractId == _contractId, 'id');
        history.contractId = 0;

        emit ContractDisconnected(msg.sender, _tokenId, _hIndex, _contractId, block.timestamp);
    }

    // change token price by token id
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) external {
        require(_exists(_tokenId), 'TNE');
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'OOCC/RO');
        House memory house = allHouses[_tokenId];
        require(_newPrice >= minPrice && _newPrice <= maxPrice, 'PII');
        house.price = _newPrice;
        allHouses[_tokenId] = house;

        emit TokenPriceChanged(_tokenId, _newPrice, block.timestamp);
    }

    // withdraw token
    function withdrawToken(uint256 _amount) external payable onlyMember {
        _token.transfer(msg.sender, _amount);

        emit TokenWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // withdraw ETH
    function withdrawETH(uint256 _amount) external payable onlyMember {
        payable(msg.sender).transfer(_amount);

        emit EthWithdrawn(msg.sender, _amount, block.timestamp);
    }

    function addMember(address _newMember) external onlyMember {
        member[_newMember] = true;
    }

    function removeMember(address _newMember) external onlyMember {
        member[_newMember] = false;
    }

    function mintHouse(
        address _dest,
        string memory _name,
        string memory _tokenURI,
        string memory _tokenType,
        string memory _initialDesc
    ) external {
        uint256 houseID = houseCounter + 1;

        // ensure token with id doesn't already exist
        require(!_exists(houseID), 'Token already exists.');

        // mint the token
        _mint(_dest, houseID);
        _setTokenURI(houseID, _tokenURI);

        allHouses[houseID] = House({
            houseID: houseID,
            tokenName: _name,
            tokenURI: _tokenURI,
            tokenType: _tokenType,
            price: 0,
            numberOfTransfers: 0,
            nftPayable: false,
            staked: false,
            soldStatus: false,
            contributor: Contributor({
                currentOwner: _dest,
                previousOwner: address(0),
                buyer: address(0),
                creator: tx.origin
            })
        });

        // new house history push into the House struct
        houseHistories[houseID].push(
            History({
                hID: 0,
                houseID: houseID,
                contractId: 0,
                historyTypeId: 0,
                houseImg: '',
                houseBrand: '',
                desc: '',
                history: _initialDesc,
                brandType: '',
                yearField: 0
            })
        );
        houseCounter++;

        emit HouseMinted(_dest, _name, _tokenURI, _tokenType, _initialDesc, block.timestamp);
    }

    // Add allow list
    function addAllowList(uint256 _tokenId, address _allowed) external {
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        allowedList[_tokenId][_allowed] = true;
        emit AllowListAdded(msg.sender, _tokenId, _allowed, block.timestamp);
    }

    // Remove allow list
    function removeAllowList(uint256 _tokenId, address _allowed) external {
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        allowedList[_tokenId][_allowed] = false;
        emit AllowListRemoved(msg.sender, _tokenId, _allowed, block.timestamp);
    }

    // Add history of house
    function addHistory(
        uint256 _houseId,
        uint256 _contractId,
        uint256 _historyTypeId,
        string memory _houseImg,
        string memory _houseBrand,
        string memory _history,
        string memory _desc,
        string memory _brandType,
        uint256 _yearField
    ) external {
        require(ownerOf(_houseId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        if (_contractId != 0) {
            require(cContract.getContractById(_contractId) == ownerOf(_houseId), 'cowner');
        }

        History[] storage houseHist = houseHistories[_houseId];
        uint256 historyCnt = houseHist.length;

        houseHistories[_houseId].push(
            History({
                hID: historyCnt,
                houseID: _houseId,
                contractId: _contractId,
                historyTypeId: _historyTypeId,
                houseImg: _houseImg,
                houseBrand: _houseBrand,
                desc: _desc,
                history: _history,
                brandType: _brandType,
                yearField: _yearField
            })
        );

        emit HistoryAdded(
            ownerOf(_houseId),
            _houseId,
            _contractId,
            _historyTypeId,
            _houseImg,
            _houseBrand,
            _history,
            _desc,
            _brandType,
            _yearField,
            block.timestamp
        );
    }

    // Edit history of house
    function editHistory(
        uint256 _houseId,
        uint256 _historyIndex,
        uint256 _historyTypeId,
        string memory _houseImg,
        string memory _houseBrand,
        string memory _history,
        string memory _desc,
        string memory _brandType,
        uint256 _yearField
    ) external {
        require(ownerOf(_houseId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        History storage _houseHistory = houseHistories[_houseId][_historyIndex];
        _houseHistory.historyTypeId = _historyTypeId;
        _houseHistory.houseImg = _houseImg;
        _houseHistory.houseBrand = _houseBrand;
        _houseHistory.history = _history;
        _houseHistory.desc = _desc;
        _houseHistory.brandType = _brandType;
        _houseHistory.yearField = _yearField;

        emit HistoryEdited(
            ownerOf(_houseId),
            _houseId,
            _historyIndex,
            _historyTypeId,
            _houseImg,
            _houseBrand,
            _history,
            _desc,
            _brandType,
            _yearField,
            block.timestamp
        );
    }

    // Add History Type
    function addHistoryType(
        uint256 _historyIndex,
        string memory _label,
        bool _connectContract,
        bool _imgNeed,
        bool _brandNeed,
        bool _descNeed,
        bool _brandTypeNeed,
        bool _yearNeed,
        bool _checkMark
    ) external onlyMember {
        historyTypes[_historyIndex] = HistoryType({
            hLabel: _label,
            connectContract: _connectContract,
            imgNeed: _imgNeed,
            brandNeed: _brandNeed,
            descNeed: _descNeed,
            brandTypeNeed: _brandTypeNeed,
            yearNeed: _yearNeed,
            checkMark: _checkMark
        });
        hTypeCounter++;

        emit HistoryTypeAdded(
            msg.sender,
            _historyIndex,
            _label,
            _connectContract,
            _imgNeed,
            _brandNeed,
            _descNeed,
            _brandTypeNeed,
            _yearNeed,
            _checkMark,
            hTypeCounter,
            block.timestamp
        );
    }

    // Edit History Type
    function editHistoryType(
        uint256 _historyIndex,
        string memory _label,
        bool _connectContract,
        bool _imgNeed,
        bool _brandNeed,
        bool _descNeed,
        bool _brandTypeNeed,
        bool _yearNeed,
        bool _checkMark
    ) external onlyMember {
        historyTypes[_historyIndex] = HistoryType({
            hLabel: _label,
            connectContract: _connectContract,
            imgNeed: _imgNeed,
            brandNeed: _brandNeed,
            descNeed: _descNeed,
            brandTypeNeed: _brandTypeNeed,
            yearNeed: _yearNeed,
            checkMark: _checkMark
        });

        emit HistoryTypeUpdated(
            msg.sender,
            _historyIndex,
            _label,
            _connectContract,
            _imgNeed,
            _brandNeed,
            _descNeed,
            _brandTypeNeed,
            _yearNeed,
            _checkMark,
            block.timestamp
        );
    }

    // Remove History Type
    function removeHistoryType(uint256 _hIndex) external onlyMember {
        for (uint i = _hIndex; i < hTypeCounter; i++) {
            historyTypes[i] = historyTypes[i + 1];
        }
        hTypeCounter--;

        emit HistoryTypeRemoved(msg.sender, _hIndex, hTypeCounter, block.timestamp);
    }

    function changeHousePrice(uint256 houseId, uint256 newPrice, address _tokenOwner) external {
        require(allHouses[houseId].contributor.currentOwner == msg.sender || operatorAddress == msg.sender, 'Not-exist token');
        require(newPrice >= minPrice && newPrice <= maxPrice, 'Invalid price range');

        allHouses[houseId].price = newPrice;

        emit HousePriceChanged(houseId, allHouses[houseId].contributor.currentOwner, newPrice);
    }

    // by a token by passing in the token's id
    function buyHouseNft(uint256 _houseId, address _buyer) public payable {
        House memory house = allHouses[_houseId];
        Contributor memory _contributor = house.contributor;

        require(msg.value >= house.price && house.nftPayable, 'Invalid for sale');
        require(_contributor.currentOwner != _buyer || _contributor.buyer == _buyer, 'Invalid buyer.');
        _contributor.buyer = _buyer;

        // calculate the payouts
        uint256 creatorCut = (house.price * royaltyCreator) / 100;

        // transfer the funds to the previous owner and creators
        payable(_contributor.currentOwner).transfer(house.price - creatorCut - (house.price * royaltyMarket) / 100);
        payable(_contributor.creator).transfer(creatorCut);

        // transfer the token to the new owner
        _transfer(_contributor.currentOwner, _buyer, _houseId);

        // update the house details
        _contributor.previousOwner = _contributor.currentOwner;
        _contributor.currentOwner = _buyer;
        allHouses[_houseId].nftPayable = false;
        allHouses[_houseId].soldStatus = true;
        allHouses[_houseId].numberOfTransfers++;

        // update the counters
        soldedCounter++;

        // emit an event
        emit HouseNftBought(
            _houseId,
            _buyer,
            _contributor.previousOwner,
            _contributor.creator,
            house.price,
            block.timestamp
        );
    }

    // by a token by passing in the token's id
    function sendToken(address _receiver, uint256 _tokenId) external payable {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0));

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(msg.sender, _receiver, _tokenId);
    }

    function _burn(uint256 _houseId) internal override(ERC721, ERC721URIStorage) {
        super._burn(_houseId);
    }

    function _afterTokenTransfer(address from, address to, uint256 houseId, uint256 batchSize) internal override {
        House storage house = allHouses[houseId];
        // update the token's previous owner
        house.contributor.previousOwner = house.contributor.currentOwner;
        // update the token's current owner
        house.contributor.currentOwner = to;
        // update the how many times this token was transfered
        house.numberOfTransfers += 1;
        _transferHistoryContracts(houseId, from, to);
    }

    /**
     * @dev transfer ownership of connected contracts
     */
    function _transferHistoryContracts(uint256 houseId, address from, address to) private {
        History[] storage histories = houseHistories[houseId];

        unchecked {
            for (uint256 i = 0; i < histories.length; ++i) {
                if (histories[i].contractId > 0) {
                    cContract.transferContractOwnership(histories[i].contractId, from, to);
                }
            }
        }
    }

    // get all houses NFT
    function getAllHouses() external view returns (House[] memory) {
        House[] memory tempHouses = new House[](houseCounter);
        for (uint256 i = 0; i < houseCounter; i++) {
            tempHouses[i] = allHouses[i + 1];
        }
        return tempHouses;
    }

    // Get History Type
    function getAllHistoryTypes() external view returns (HistoryType[] memory) {
        HistoryType[] memory tempHistoryType = new HistoryType[](hTypeCounter);
        for (uint256 i = 0; i < hTypeCounter; i++) {
            tempHistoryType[i] = historyTypes[i];
        }
        return tempHistoryType;
    }

    // Returns price of a house with `tokenId`
    function getTokenPrice(uint256 _tokenId) external view returns (uint256) {
        require(msg.sender == stakingContractAddress, 'sc');
        return allHouses[_tokenId].price;
    }

    // Get Overall total information
    function getTotalInfo() external view returns (uint256, uint256, uint256) {
        return (houseCounter, IStaking(stakingContractAddress).getStakedCounter(), soldedCounter);
    }

    function tokenURI(uint256 _houseId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_houseId);
    }

    function approveDelegator(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || msg.sender == operatorAddress, 'Unauthorized');
        _approve(to, tokenId);
    }

    function checkAllowedList(uint256 _tokenId, address allowed) external view returns (bool) {
        return allowedList[_tokenId][allowed];
    }

    function getHistory(uint256 _houseId) external view returns (History[] memory) {
        return houseHistories[_houseId];
    }
}
