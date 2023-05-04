// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import './interfaces/IStaking.sol';
import './interfaces/IContract.sol';

contract HouseBusiness is ERC721, ERC721URIStorage {
    // this contract's token collection name
    string public collectionName;
    // this contract's token symbol
    string public collectionNameSymbol;
    // total number of houses minted
    uint256 public houseCounter;

    // total number of solded nft
    uint256 public soldedCounter;
    // total number of history type
    uint256 public hTypeCounter;
    // reward token
    IERC20 _token;
    // min house nft price
    uint256 public minPrice;
    // max house nft price
    uint256 public maxPrice;
    // token royalty
    uint256 public royaltyCreator;
    uint256 public royaltyMarket;
    // CleanContract address
    IMainCleanContract cContract;
    // define house struct
    struct House {
        uint256 tokenId;
        string tokenName;
        string tokenURI;
        string tokenType;
        address currentOwner;
        address previousOwner;
        address buyer;
        address creator;
        uint256 price;
        uint256 numberOfTransfers;
        bool nftPayable;
        bool staked;
        bool soldStatus;
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
    HistoryType[] historyTypes;
    // all house histories
    mapping(uint256 => History[]) houseHistories;
    // map members
    mapping(address => bool) public allMembers;
    // map house's token id to house
    mapping(uint256 => House) public allHouses;
    // map house's token id to house
    mapping(uint256 => mapping(address => bool)) public allowedList;

    // HouseStaking contract address
    address stakingContractAddress;

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
        uint256 HistoryType,
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
        string houseImg,
        string houseBrand,
        string history,
        string desc,
        string brandType,
        uint256 yearField,
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
    event HistoryTypeRemoved(address indexed member, uint256 indexed hIndex, uint256 timestamp);
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
        allMembers[msg.sender] = true;
        royaltyCreator = 6;
        royaltyMarket = 2;
        historyTypes.push(HistoryType(hTypeCounter++, 'Construction', false, false, false, false, false, false, false));
        historyTypes.push(HistoryType(hTypeCounter++, 'Floorplan', true, true, true, true, false, false, false));
        historyTypes.push(HistoryType(hTypeCounter++, 'Pictures', true, true, true, true, false, false, false));
        historyTypes.push(HistoryType(hTypeCounter++, 'Blueprint', true, true, true, true, false, false, false));
        historyTypes.push(HistoryType(hTypeCounter++, 'Solarpanels', true, true, true, true, true, true, false));
        historyTypes.push(HistoryType(hTypeCounter++, 'Airconditioning', true, true, true, true, true, true, false));
        historyTypes.push(HistoryType(hTypeCounter++, 'Sonneboiler', true, true, true, true, true, true, true));
        historyTypes.push(HistoryType(hTypeCounter++, 'Housepainter', false, false, false, false, false, false, true));
        minPrice = 10 ** 17;
        maxPrice = 10 ** 18;
        _token = IERC20(_tokenAddress);
    }

    modifier onlyMember() {
        require(allMembers[msg.sender], "Only Member");
        _;
    }

    function setCContractAddress(address addr) external onlyMember {
        cContract = IMainCleanContract(addr);
    }

    function setStakingContractAddress(address addr) external onlyMember {
        stakingContractAddress = addr;
    }
    // Sets house staked status
    function setHouseStakedStatus(uint256 tokenId, bool status) external {
        require(msg.sender == stakingContractAddress, 'sc');
        allHouses[tokenId].staked = status;

        emit HouseStakedStatusSet(tokenId, status, block.timestamp);
    }

    function setMinMaxHousePrice(uint256 _min, uint256 _max) public onlyMember {
        minPrice = _min;
        maxPrice = _max;
    }

    function setConfigToken(address _tokenAddress) public {
        _token = IERC20(_tokenAddress);
    }

    function setPayable(uint256 tokenId, address _buyer, bool nftPayable) public {
        // require that token should exist
        require(_exists(tokenId));
        // get the token's owner
        address tokenOwner = ownerOf(tokenId);
        // check that token's owner should be equal to the caller of the function
        require(tokenOwner == msg.sender, 'Only owner can call this func.');
        allHouses[tokenId].buyer = _buyer;
        allHouses[tokenId].nftPayable = nftPayable;

        emit PayableSet(msg.sender, tokenId, _buyer, nftPayable, block.timestamp);
    }

    function setRoyaltyCreator(uint256 _royalty) public onlyMember {
        royaltyCreator = _royalty;

        emit RoyaltyCreatorSet(msg.sender, _royalty, block.timestamp);
    }

    function setRoyaltyMarket(uint256 _royalty) public onlyMember {
        royaltyMarket = _royalty;

        emit RoyaltyMarketSet(msg.sender, _royalty, block.timestamp);
    }

    /**
     * @dev disconnects contract from house history
     */
    function disconnectContract(uint256 tokenId, uint256 hIndex, uint256 contractId) external {
        require(ownerOf(tokenId) == msg.sender, 'owner');
        History storage history = houseHistories[tokenId][hIndex];
        require(history.contractId == contractId, 'id');
        history.contractId = 0;

        emit ContractDisconnected(msg.sender, tokenId, hIndex, contractId, block.timestamp);
    }

    // change token price by token id
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) external {
        require(_exists(_tokenId), 'TNE');
        require(ownerOf(_tokenId) == msg.sender, 'OOCC/RO');
        House memory house = allHouses[_tokenId];
        require(_newPrice >= minPrice && _newPrice <= maxPrice, 'PII');
        house.price = _newPrice;
        allHouses[_tokenId] = house;

        emit TokenPriceChanged(_tokenId, _newPrice, block.timestamp);
    }

    // withdraw token
    function withdrawToken(uint256 _amountToken) external payable onlyMember {
        _token.transfer(msg.sender, _amountToken);

        emit TokenWithdrawn(msg.sender, _amountToken, block.timestamp);
    }

    // withdraw ETH
    function withdrawETH(uint256 _amountEth) external payable onlyMember {
        payable(msg.sender).transfer(_amountEth);

        emit EthWithdrawn(msg.sender, _amountEth, block.timestamp);
    }

    function addMember(address _newMember) public onlyMember {
        allMembers[_newMember] = true;
    }

    function removeMember(address _newMember) public onlyMember {
        allMembers[_newMember] = false;
    }

    function mintHouse(
        string memory _name,
        string memory _tokenURI,
        string memory _tokenType,
        string memory initialDesc 
    ) public {
        // check if a token exists with the above token id => incremented counter
        require(!_exists(houseCounter + 1), 'NIE!');

        // increase house count
        houseCounter++;

        // mint the token
        _mint(msg.sender, houseCounter);
        // set token URI (bind token id with the passed in token URI)
        _setTokenURI(houseCounter, _tokenURI);

        allHouses[houseCounter] = House({
            tokenId: houseCounter,
            tokenName: _name,
            tokenURI: _tokenURI,
            tokenType: _tokenType,
            currentOwner: msg.sender,
            previousOwner: address(0),
            buyer: address(0),
            creator: msg.sender,
            price: 0,
            numberOfTransfers: 0,
            nftPayable: false,
            staked: false,
            soldStatus: false
        });

        // new house history push into the House struct
        houseHistories[houseCounter].push(
            History({
                hID: 0,
                contractId: houseCounter,
                houseImg: '',
                houseBrand: '',
                desc: '',
                history: initialDesc,
                brandType: '',
                yearField: 0
            })
        );

        emit HouseMinted(msg.sender, _name, _tokenURI, _tokenType, initialDesc, block.timestamp);
    }

    // Add allow list
    function addAllowList(uint256 _tokenId, address allowed) public {
        require(allHouses[_tokenId].currentOwner == msg.sender, 'OOCA');
        allowedList[_tokenId][allowed] = true;

        emit AllowListAdded(msg.sender, _tokenId, allowed, block.timestamp);
    }

    // Remove allow list
    function removeAllowList(uint256 _tokenId, address allowed) public {
        require(allHouses[_tokenId].currentOwner == msg.sender, 'OOCR');
        allowedList[_tokenId][allowed] = false;

        emit AllowListRemoved(msg.sender, _tokenId, allowed, block.timestamp);
    }

    // Add history of house
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
    ) public {
        require(ownerOf(_tokenId) == msg.sender, 'owner');
        require(cContract.getContractById(contractId).owner == msg.sender, 'cowner');

        History[] storage histories = houseHistories[_tokenId];
        History memory _houseHistory = History({
            hID: _tokenId,
            contractId: contractId,
            houseImg: houseImg,
            houseBrand: houseBrand,
            desc: _desc,
            history: _history,
            brandType: brandType,
            yearField: yearField
        });
        histories.push(_houseHistory);

        emit HistoryAdded(
            msg.sender,
            _tokenId,
            contractId,
            newHistoryType,
            houseImg,
            houseBrand,
            _history,
            _desc,
            brandType,
            yearField,
            block.timestamp
        );
    }

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
    ) public {
        History storage _houseHistory = houseHistories[_tokenId][historyIndex];
        _houseHistory.houseImg = houseImg;
        _houseHistory.houseBrand = houseBrand;
        _houseHistory.brandType = brandType;
        _houseHistory.yearField = yearField;
        _houseHistory.history = _history;
        _houseHistory.desc = _desc;

        emit HistoryEdited(
            msg.sender,
            _tokenId,
            historyIndex,
            houseImg,
            houseBrand,
            _history,
            _desc,
            brandType,
            yearField,
            block.timestamp
        );
    }

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
    ) public onlyMember {
        HistoryType storage newHistory = historyTypes[_historyIndex];
        newHistory.hID = _historyIndex;
        newHistory.hLabel = _label;
        newHistory.connectContract = _connectContract;
        newHistory.imgNeed = _imgNeed;
        newHistory.brandNeed = _brandNeed;
        newHistory.descNeed = _descNeed;
        newHistory.brandTypeNeed = _brandTypeNeed;
        newHistory.yearNeed = _yearNeed;
        newHistory.checkMark = _checkMark;

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
    function removeHistoryType(uint256 _hIndex) public onlyMember {
        delete historyTypes[_hIndex];

        emit HistoryTypeRemoved(msg.sender, _hIndex, block.timestamp);
    }

    function changeHousePrice(uint256 tokenId, uint256 newPrice) public {
        require(allHouses[tokenId].currentOwner == msg.sender, 'Only the owner can change the price and tokenId must exist');
        require(newPrice >= minPrice && newPrice <= maxPrice, 'Price must be within the limits');
    
        allHouses[tokenId].price = newPrice;
    
        emit HousePriceChanged(tokenId, msg.sender, newPrice);
    }

    // by a token by passing in the token's id
    function buyHouseNft(uint256 tokenId) public payable {
        House memory house = allHouses[tokenId];

        // check if owner call this request
        require(house.currentOwner != msg.sender, 'CBON');
        // price sent in to buy should be equal to or more than the token's price
        require(house.nftPayable && (house.buyer == address(0) || house.buyer == msg.sender), 'NNP/OBCB');
        require(msg.value >= house.price, 'PIW');

        // transfer
        address payable sendTo = payable(house.previousOwner);
        address payable creator = payable(house.creator);
        // send token's worth of ethers to the owner
        sendTo.transfer((house.price * (100 - royaltyCreator - royaltyMarket)) / 100);
        creator.transfer((house.price * royaltyCreator) / 100);
        // transfer the token from owner to the caller of the function (buyer)
        _transfer(house.currentOwner, msg.sender, house.tokenId);

        // Set Payable
        house.nftPayable = false;
        // ++ soldedCounter
        if (!house.soldStatus) {
            house.soldStatus = true;
            soldedCounter++;
        }

        emit HouseNftBought(
            house.tokenId,
            msg.sender,
            house.previousOwner,
            house.creator,
            house.price,
            block.timestamp
        );
    }

    // by a token by passing in the token's id
    function sendToken(address receiver, uint256 tokenId) public payable {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0));

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(msg.sender, receiver, tokenId);

        // Transfer ownership of connected contracts
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        House storage house = allHouses[tokenId];
        // update the token's previous owner
        house.previousOwner = house.currentOwner;
        // update the token's current owner
        house.currentOwner = to;
        // update the how many times this token was transfered
        house.numberOfTransfers += 1;
        _transferHistoryContracts(tokenId, from, to);
    }
    /**
     * @dev transfer ownership of connected contracts
     */
    function _transferHistoryContracts(uint256 tokenId, address from, address to) private {
        History[] storage histories = houseHistories[tokenId];

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
        uint256 index = 0;
        for (uint256 i = 1; i < houseCounter; i++) {
            tempHouses[i] = allHouses[i];
            index++;
        }
        return tempHouses;
    }

    // get all payable houses NFT
    function getAllPayableHouses() external view returns (House[] memory) {
        uint256 iNum;
        for (uint256 i = 1; i < houseCounter; i++) {
            if (allHouses[i].nftPayable == true && allHouses[i].staked == false) {
                iNum++;
            }
        }
        House[] memory tempHouses = new House[](iNum);
        iNum = 0;
        for (uint256 i = 1; i < houseCounter; i++) {
            if (allHouses[i].nftPayable == true && allHouses[i].staked == false) {
                tempHouses[iNum] = allHouses[i];
                iNum++;
            }
        }

    
        return tempHouses;
    }
    
    // get all my houses NFT
    function getAllMyHouses() external view returns (House[] memory) {
        uint256 iNum;
        for (uint256 i = 1; i < houseCounter; i++) {
            if (allHouses[i].currentOwner == msg.sender) {
                iNum++;
            }
        }
        House[] memory tempHouses = new House[](iNum);
        iNum = 0;
        for (uint256 i = 1; i < houseCounter; i++) {
            if (allHouses[i].currentOwner == msg.sender) {
                tempHouses[iNum] = allHouses[i];
                iNum++;
            }
        }
        return tempHouses;
    }

    // Returns price of a house with `tokenId`
    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        require(msg.sender == stakingContractAddress, 'sc');
        return allHouses[tokenId].price;
    }
    
    // Get Overall total information
    function getTotalInfo() public view onlyMember returns (uint256, uint256, uint256) {
        return (houseCounter, IStaking(stakingContractAddress).stakedCounter(), soldedCounter);
    }

    function isMember() public view returns (bool) {
        return allMembers[msg.sender];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function checkAllowedList(uint256 _tokenId, address allowed) public view returns (bool) {
        return allowedList[_tokenId][allowed];
    }

    function getHistory(uint256 _tokenId) public view returns (History[] memory) {
        return houseHistories[_tokenId];
    }

    // Get History Type
    function getHistoryType() public view returns (HistoryType[] memory) {
        HistoryType[] memory aHistoryTypes = new HistoryType[](historyTypes.length);
        for (uint256 i = 0; i < historyTypes.length; i++) {
            aHistoryTypes[i] = historyTypes[i];
        }
        return aHistoryTypes;
    }

    // get owner of the token
    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        address _tokenOwner = ownerOf(_tokenId);
        return _tokenOwner;
    }
}
