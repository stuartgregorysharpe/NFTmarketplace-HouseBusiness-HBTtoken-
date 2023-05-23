// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import './interfaces/IStaking.sol';
import './interfaces/IHouseDoc.sol';

contract HouseBusiness is ERC721, ERC721URIStorage {
    string public collectionName;
    string public collectionSymbol;
    uint256 public houseCounter;
    uint256 public soldedCounter;
    uint256 public minPrice;
    uint256 public maxPrice;
    uint256 public allowFee;
    uint256 public hTypeCounter;
    uint256 public royaltyCreator;
    uint256 public royaltyMarket;

    IERC20 _token;
    IHouseDoc houseDoc;

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
        string otherInfo;
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
        bool otherInfo;
        uint256 value;
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

    LabelPercent public labelPercent;

    mapping(address => bool) public member;
    mapping(uint256 => House) public allHouses;
    mapping(uint256 => HistoryType) historyTypes;
    mapping(uint256 => History[]) public houseHistories;
    mapping(uint256 => mapping(address => bool)) public allowedList;

    address stakingContractAddress;
    address operatorAddress;

    event HouseMinted(
        address indexed minter,
        string name,
        string tokenURI,
        string tokenType,
        uint256 year
    );
    event PayableSet(
        address indexed owner,
        uint256 indexed tokenId,
        address buyer,
        bool nftPayable
    );
    event AllowListAdded(
        address indexed currentOwner,
        uint256 indexed tokenId,
        address allowed
    );
    event AllowListRemoved(
        address indexed currentOwner,
        uint256 indexed tokenId,
        address allowed
    );
    event HistoryTypeRemoved(
        address indexed member,
        uint256 indexed hIndex,
        uint256 hTypeCounter
    );
    event HousePriceChanged(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price
    );
    event TokenWithdrawn(address indexed sender, uint256 amount);
    event EthWithdrawn(address indexed sender, uint256 amount);
    event HouseStakedStatusSet(uint256 indexed tokenId, bool status);
    event RoyaltyCreatorSet(address indexed member, uint256 royalty);
    event RoyaltyMarketSet(address indexed member, uint256 royalty);
    event HistoryAdded(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed contractId,
        uint256 historyTypeId,
        string houseImg,
        string houseBrand,
        string desc,
        string brandType,
        uint256 yearField
    );
    event HistoryEdited(
        address indexed editor,
        uint256 indexed tokenId,
        uint256 historyIndex,
        uint256 historyTypeId,
        string houseImg,
        string houseBrand,
        string desc,
        string brandType,
        uint256 yearField
    );
    event HistoryTypeAdded(
        address indexed member,
        uint256 indexed hID,
        string label,
        bool connectContract,
        bool imgNeed,
        bool brand,
        bool description,
        bool brandType,
        bool yearNeed,
        bool otherInfo,
        uint256 value
    );
    event HistoryTypeUpdated(
        address indexed member,
        uint256 indexed hID,
        string label,
        bool connectContract,
        bool imgNeed,
        bool brand,
        bool description,
        bool brandType,
        bool yearNeed,
        bool otherInfo,
        uint256 value
    );
    event ContractDisconnected(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed hIndex,
        uint256 contractId
    );
    event HouseNftBought(
        uint256 indexed tokenId,
        address indexed buyer,
        address previousOwner,
        address creator,
        uint256 price
    );

    constructor(address _tokenAddress) ERC721("HouseBusiness", "HUBS") {
        (collectionName, collectionSymbol) = (name(), symbol());
        member[msg.sender] = true;
        royaltyCreator = 6;
        royaltyMarket = 2;
        minPrice = 10**16;
        maxPrice = 10**18;
        allowFee = 10**17;
        _token = IERC20(_tokenAddress);
    }

    modifier onlyMember() {
        require(member[msg.sender], "Only Member");
        _;
    }

    function setOperatorAddress(address _address) public onlyMember {
        operatorAddress = _address;
    }

    function setStakingContractAddress(address _address) external onlyMember {
        stakingContractAddress = _address;
    }

    // Sets house staked status
    function setHouseStakedStatus(uint256 _tokenId, bool _status) external {
        require(msg.sender == stakingContractAddress, 'Unauthorized: not a Staking contract');
        allHouses[_tokenId].staked = _status;

        emit HouseStakedStatusSet(_tokenId, _status);
    }

    function setMinMaxHousePrice(uint256 _min, uint256 _max)
        external
        onlyMember
    {
        minPrice = _min;
        maxPrice = _max;
    }

    function setHouseDocContractAddress(address _address) external onlyMember {
        houseDoc = IHouseDoc(_address);
    }

    function setLabelPercents(LabelPercent memory newLabelPercent) external onlyMember {
        labelPercent = newLabelPercent;
    }

    function setAllowFee(uint256 _allowFee) external onlyMember {
        allowFee = _allowFee;
    }

    function setConfigToken(address _tokenAddress) external {
        _token = IERC20(_tokenAddress);
    }

    function setPayable(
        uint256 _tokenId,
        address _buyer,
        bool _nftPayable
    ) external {
        // require that token should exist
        require(_exists(_tokenId));
        // check that token"s owner should be equal to the caller of the function
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        require(allHouses[_tokenId].price > 0, 'Pricing has not been set at this time.');
        
        if (allHouses[_tokenId].contributor.buyer != _buyer)
            allHouses[_tokenId].contributor.buyer = _buyer;
        allHouses[_tokenId].nftPayable = _nftPayable;

        emit PayableSet(msg.sender, _tokenId, _buyer, _nftPayable);
    }

    function setRoyaltyCreator(uint256 _royalty) external onlyMember {
        royaltyCreator = _royalty;

        emit RoyaltyCreatorSet(msg.sender, _royalty);
    }

    function setRoyaltyMarket(uint256 _royalty) external onlyMember {
        royaltyMarket = _royalty;

        emit RoyaltyMarketSet(msg.sender, _royalty);
    }

    /**
     * @dev disconnects contract from house history
     */
    function disconnectContract(uint256 _tokenId, uint256 _hIndex, uint256 _contractId) external {
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        History storage history = houseHistories[_tokenId][_hIndex];
        require(history.contractId == _contractId, "id");
        history.contractId = 0;

        emit ContractDisconnected(msg.sender, _tokenId, _hIndex, _contractId);
    }

    // withdraw token
    function withdrawToken(uint256 _amount) external payable onlyMember {
        _token.transfer(msg.sender, _amount);

        emit TokenWithdrawn(msg.sender, _amount);
    }

    // withdraw ETH
    function withdrawETH(uint256 _amount) external payable onlyMember {
        payable(msg.sender).transfer(_amount);

        emit EthWithdrawn(msg.sender, _amount);
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
        uint256 _year
    ) external {
        uint256 houseID = houseCounter + 1;

        // ensure token with id doesn"t already exist
        require(!_exists(houseID), "Token already exists.");

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
                houseImg: "",
                houseBrand: "",
                desc: "",
                otherInfo: "",
                brandType: _tokenType,
                yearField: _year
            })
        );
        houseCounter++;

        emit HouseMinted(
            msg.sender,
            _name,
            _tokenURI,
            _tokenType,
            _year
        );
    }

    // by a token by passing in the token"s id
    function buyHouseNft(uint256 _houseId, address _buyer) public payable {
        House memory house = allHouses[_houseId];
        Contributor memory _contributor = house.contributor;

        uint256 housePrice = getHousePrice(_houseId);

        require(msg.value >= housePrice, 'Insufficient value.');
        require(house.nftPayable, 'House is not for sale.');
        require(_contributor.currentOwner != address(0), 'House does not exist.');
        require(_contributor.currentOwner != _buyer, 'You are already the owner of this house.');

        if (_contributor.buyer != address(0)) {
            require(_contributor.buyer == _buyer, 'You are not authorized to buy this house.');
        }
        _contributor.buyer = _buyer;

        // calculate the payouts
        uint256 creatorCut = (housePrice * royaltyCreator) / 100;
        uint256 marketCut = (housePrice * royaltyMarket) / 100;
        uint256 ownerCut = housePrice - creatorCut - marketCut;

        // transfer the funds to the previous owner and creators
        payable(_contributor.currentOwner).transfer(ownerCut);
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
        emit HouseNftBought(_houseId, _buyer, _contributor.previousOwner, _contributor.creator, housePrice);
        emit HouseNftBought(
            _houseId,
            msg.sender,
            _contributor.previousOwner,
            _contributor.creator,
            housePrice
        );
    }

    // Add allow list
    function addAllowList(uint256 _tokenId, address _allowed) external payable {
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        require(msg.value >= allowFee, "Insufficient value.");
        allowedList[_tokenId][_allowed] = true;
        emit AllowListAdded(msg.sender, _tokenId, _allowed);
    }

    // Remove allow list
    function removeAllowList(uint256 _tokenId, address _allowed) external {
        require(ownerOf(_tokenId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        allowedList[_tokenId][_allowed] = false;
        emit AllowListRemoved(msg.sender, _tokenId, _allowed);
    }

    // Add history of house
    function addHistory(
        uint256 _houseId,
        uint256 _contractId,
        uint256 _historyTypeId,
        string memory _houseImg,
        string memory _houseBrand,
        string memory _otherInfo,
        string memory _desc,
        string memory _brandType,
        uint256 _yearField
    ) external {
        require(ownerOf(_houseId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        if (_contractId != 0) {
            require(
                houseDoc.getContractById(_contractId) == msg.sender,
                "You are owner of that contract"
            );
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
                otherInfo: _otherInfo,
                brandType: _brandType,
                yearField: _yearField
            })
        );

        emit HistoryAdded(
            msg.sender,
            _houseId,
            _contractId,
            _historyTypeId,
            _houseImg,
            _houseBrand,
            _desc,
            _brandType,
            _yearField
        );
    }

    // Edit history of house
    function editHistory(
        uint256 _houseId,
        uint256 _historyIndex,
        uint256 _historyTypeId,
        string memory _houseImg,
        string memory _houseBrand,
        string memory _otherInfo,
        string memory _desc,
        string memory _brandType,
        uint256 _yearField
    ) external {
        require(ownerOf(_houseId) == msg.sender || operatorAddress == msg.sender, 'Unauthorized.');
        History storage _houseHistory = houseHistories[_houseId][_historyIndex];
        _houseHistory.historyTypeId = _historyTypeId;
        _houseHistory.houseImg = _houseImg;
        _houseHistory.houseBrand = _houseBrand;
        _houseHistory.otherInfo = _otherInfo;
        _houseHistory.desc = _desc;
        _houseHistory.brandType = _brandType;
        _houseHistory.yearField = _yearField;

        // transfer the token from owner to the caller of the function (buyer)
        emit HistoryEdited(
            msg.sender,
            _houseId,
            _historyIndex,
            _historyTypeId,
            _houseImg,
            _houseBrand,
            _desc,
            _brandType,
            _yearField
        );
    }

    // Remove History Type
    function removeHistoryType(uint256 _hIndex) external onlyMember {
        for (uint i = _hIndex; i < hTypeCounter; i++) {
            historyTypes[i] = historyTypes[i + 1];
        }
        hTypeCounter--;

        emit HistoryTypeRemoved(msg.sender, _hIndex, hTypeCounter);
    }

    function changeHousePrice(uint256 houseId, uint256 newPrice) external {
        require(
            allHouses[houseId].contributor.currentOwner == msg.sender || operatorAddress == msg.sender,
            'Caller is not owner or house does not exist'
        );
        require(newPrice >= minPrice && newPrice <= maxPrice, 'Price must be within the limits');

        allHouses[houseId].price = newPrice;

        emit HousePriceChanged(houseId, msg.sender, newPrice);
    }

    function _burn(uint256 _houseId) internal override(ERC721, ERC721URIStorage) {
        super._burn(_houseId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 houseId,
        uint256 batchSize
    ) internal override {
        House storage house = allHouses[houseId];
        // update the token"s previous owner
        house.contributor.previousOwner = house.contributor.currentOwner;
        // update the token"s current owner
        house.contributor.currentOwner = to;
        // update the how many times this token was transfered
        house.numberOfTransfers += 1;
        _transferHistoryContracts(houseId, from, to);
    }

    /**
     * @dev transfer ownership of connected contracts
     */
    function _transferHistoryContracts(
        uint256 houseId,
        address from,
        address to
    ) private {
        History[] storage histories = houseHistories[houseId];

        unchecked {
            for (uint256 i = 0; i < histories.length; ++i) {
                if (histories[i].contractId > 0) {
                    houseDoc.transferContractOwnership(
                        histories[i].contractId,
                        from,
                        to
                    );
                }
            }
        }
    }

    // Get All Houses
    function getAllHouses() external view returns (House[] memory) {
        House[] memory tempHouses = new House[](houseCounter);
        for (uint256 i = 0; i < houseCounter; i++) {
            tempHouses[i] = allHouses[i + 1];
        }
        return tempHouses;
    }

    function getAllHistoryTypes() external view returns (HistoryType[] memory) {
        HistoryType[] memory tempHistoryType = new HistoryType[](hTypeCounter);
        for (uint256 i = 0; i < hTypeCounter; i++) {
            tempHistoryType[i] = historyTypes[i];
        }
        return tempHistoryType;
    }

    // Get Overall total information
    function getTotalInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            houseCounter,
            IStaking(stakingContractAddress).getStakedCounter(),
            soldedCounter
        );
    }

    function tokenURI(uint256 _houseId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_houseId);
    }

    function approveDelegator(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to == owner);
        _approve(to, tokenId);
    }

    function checkAllowedList(uint256 _tokenId, address allowed) external view returns (bool) {
        return allowedList[_tokenId][allowed];
    }

    function getHistory(uint256 _houseId)
        external
        view
        returns (History[] memory)
    {
        return houseHistories[_houseId];
    }

    function getHousePrice(uint256 _houseId) public view returns (uint256) {
        House memory house = allHouses[_houseId];

        uint256 price = house.price;
        History[] memory temp = houseHistories[_houseId];
        for (uint256 i = 0; i < temp.length; i++) {
            uint256 percent = (temp[i].contractId > 0 ? labelPercent.connectContract : 0) +
                (bytes(temp[i].houseImg).length > 0 ? labelPercent.image : 0) +
                (bytes(temp[i].houseBrand).length > 0? labelPercent.brand: 0) +
                (bytes(temp[i].desc).length > 0 ? labelPercent.desc : 0) +
                (bytes(temp[i].brandType).length > 0 ? labelPercent.brandType : 0) +
                (temp[i].yearField > 0 ? labelPercent.year : 0) +
                (bytes(temp[i].otherInfo).length > 0 ? labelPercent.otherInfo : 0);
            price += (historyTypes[temp[i].historyTypeId].value * percent) / 100;
        }
        return price;
    }
}