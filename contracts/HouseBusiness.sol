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
        bool soldstatus;
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

    // check if token name exists
    // mapping(string => bool) public tokenNameExists;
    // check if token URI exists
    // mapping(string => bool) public tokenURIExists;
    // All Staked NFTs

    constructor(address _tokenAddress) ERC721('HouseBusiness', 'HUBS') {
        collectionName = name();
        collectionNameSymbol = symbol();
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

    function onlyMember() private view {
        require(allMembers[msg.sender], 'OM1');
    }

    function setMinMaxHousePrice(uint256 _min, uint256 _max) public {
        onlyMember();
        minPrice = _min;
        maxPrice = _max;
    }

    function setConfigToken(address _tokenAddress) public {
        _token = IERC20(_tokenAddress);
    }

    function isMember() public view returns (bool) {
        return allMembers[msg.sender];
    }

    function addMember(address _newMember) public {
        onlyMember();
        allMembers[_newMember] = true;
    }

    function removeMember(address _newMember) public {
        onlyMember();
        allMembers[_newMember] = false;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setCContractAddress(address addr) external {
        onlyMember();
        cContract = IMainCleanContract(addr);
    }

    function setStakingContractAddress(address addr) external {
        onlyMember();
        stakingContractAddress = addr;
    }

    function setPayable(uint256 tokenId, address _buyer, bool nftPayable) public {
        // require that token should exist
        require(_exists(tokenId));
        // get the token's owner
        address tokenOwner = ownerOf(tokenId);
        // check that token's owner should be equal to the caller of the function
        require(tokenOwner == msg.sender, 'Only owner can call this func.');
        allHouses[tokenId].nftPayable = nftPayable;
        allHouses[tokenId].buyer = _buyer;
    }

    function mintHouse(
        string memory _name,
        string memory _tokenURI,
        string memory _tokenType,
        string memory initialDesc,
        uint256 _price
    ) public payable {
        // check if a token exists with the above token id => incremented counter
        require(!_exists(houseCounter + 1), 'NIE!');
        // check if the token URI already exists or not
        // require(!tokenURIExists[_tokenURI], "TokenUrl have already exist!");
        // check if the token name already exists or not
        // require(!tokenNameExists[_name], "House Nft name have already exist!");
        // check if the otken price is zero or not
        require(_price >= minPrice && _price <= maxPrice, 'NPIW.');
        // make passed token URI as exists
        // tokenURIExists[_tokenURI] = true;
        // make token name passed as exists
        // tokenNameExists[_name] = true;

        // increase house count
        houseCounter++;

        // mint the token
        _mint(msg.sender, houseCounter);
        // set token URI (bind token id with the passed in token URI)
        _setTokenURI(houseCounter, _tokenURI);

        House storage simpleHouse = allHouses[houseCounter];
        simpleHouse.tokenId = houseCounter;
        simpleHouse.tokenName = _name;
        simpleHouse.tokenURI = _tokenURI;
        simpleHouse.tokenType = _tokenType;
        simpleHouse.currentOwner = msg.sender;
        simpleHouse.previousOwner = address(0);
        simpleHouse.creator = msg.sender;
        simpleHouse.price = _price;
        simpleHouse.numberOfTransfers = 0;
        simpleHouse.nftPayable = false;
        simpleHouse.staked = false;
        simpleHouse.soldstatus = false;

        // new house history push into the House struct
        History[] storage histories = houseHistories[houseCounter];
        History memory simpleHistory;
        simpleHistory.hID = 0;
        simpleHistory.history = initialDesc;
        histories.push(simpleHistory);
    }

    // Add allow list
    function addAllowList(uint256 _tokenId, address allowed) public {
        require(allHouses[_tokenId].currentOwner == msg.sender, 'OOCA');
        allowedList[_tokenId][allowed] = true;
    }

    // Remove allow list
    function removeAllowList(uint256 _tokenId, address allowed) public {
        require(allHouses[_tokenId].currentOwner == msg.sender, 'OOCR');
        allowedList[_tokenId][allowed] = false;
    }

    // Confirm is allowed list
    function checkAllowedList(uint256 _tokenId, address allowed) public view returns (bool) {
        return allowedList[_tokenId][allowed];
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
        History memory _houseHistory;
        _houseHistory.houseImg = houseImg;
        _houseHistory.houseBrand = houseBrand;
        _houseHistory.brandType = brandType;
        _houseHistory.yearField = yearField;
        _houseHistory.hID = newHistoryType;
        _houseHistory.history = _history;
        _houseHistory.desc = _desc;
        _houseHistory.contractId = contractId;

        histories.push(_houseHistory);
    }

    function getHistory(uint256 _tokenId) public view returns (History[] memory) {
        return houseHistories[_tokenId];
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
    }

    // Get History Type
    function getHistoryType() public view returns (HistoryType[] memory) {
        HistoryType[] memory aHistoryTypes = new HistoryType[](historyTypes.length);
        for (uint256 i = 0; i < historyTypes.length; i++) {
            aHistoryTypes[i] = historyTypes[i];
        }
        return aHistoryTypes;
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
    ) public {
        onlyMember();
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
    }

    // Remove History Type
    function removeHistoryType(uint256 _hIndex) public {
        onlyMember();
        delete historyTypes[_hIndex];
    }

    function getMinMaxNFT() public view returns (uint256, uint256) {
        return (minPrice, maxPrice);
    }

    // get owner of the token
    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        address _tokenOwner = ownerOf(_tokenId);
        return _tokenOwner;
    }

    /**
     * @dev transfer ownership of connected contracts
     */
    function _transferHistoryContracts(uint256 tokenId, address from, address to) private {
        History[] memory histories = houseHistories[tokenId];
        uint256 length = histories.length;

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                if (histories[i].contractId > 0) {
                    cContract.transferContractOwnership(histories[i].contractId, from, to);
                }
            }
        }
    }

    /**
     * @dev disconnects contract from house history
     */
    function disconnectContract(uint256 tokenId, uint256 hIndex, uint256 contractId) external {
        require(ownerOf(tokenId) == msg.sender, 'owner');
        History storage history = houseHistories[tokenId][hIndex];
        require(history.contractId == contractId, 'id');
        history.contractId = 0;
    }

    // by a token by passing in the token's id
    function buyHouseNft(uint256 tokenId) public payable {
        House memory house = allHouses[tokenId];

        // check if owner call this request
        require(house.currentOwner != msg.sender, 'CBON');
        // price sent in to buy should be equal to or more than the token's price
        require(house.nftPayable == true, 'NNP');
        // check if buyer added
        if (house.buyer != address(0)) {
            require(msg.sender == house.buyer, 'OBCB');
        }
        // price sent in to buy should be equal to or more than the token's price
        require(msg.value >= house.price, 'PIW');

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(house.currentOwner, msg.sender, house.tokenId);
        // transfer
        // address payable _toOwner = payable(house.currentOwner);
        // address payable _toThis = payable(address(this));
        // uint _price = house.price * royalty / 100;
        // _toOwner.transfer(house.price - _price);
        // _toThis.transfer(_price);
        address payable sendTo = payable(house.previousOwner);
        address payable creator = payable(house.creator);
        // send token's worth of ethers to the owner
        sendTo.transfer((house.price * 100 * (100 - royaltyCreator - royaltyMarket)) / 10000);
        creator.transfer((house.price * 100 * royaltyCreator) / 10000);

        // Set Payable
        allHouses[tokenId].nftPayable = false;
        // ++ soldedCounter
        if (house.soldstatus == false) {
            allHouses[tokenId].soldstatus = true;
            soldedCounter++;
        }
    }

    function sellHouseNft(uint256 tokenId) public payable {
        
    }

    // by a token by passing in the token's id
    function sendToken(address receiver, uint256 tokenId) public payable {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0));

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(msg.sender, receiver, tokenId);

        // Transfer ownership of connected contracts
    }

    // change token price by token id
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) external {
        // require caller of the function is not an empty address
        require(msg.sender != address(0));
        // require that token should exist
        require(_exists(_tokenId));
        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);
        // check that token's owner should be equal to the caller of the function
        require(tokenOwner == msg.sender, 'OOCC');
        // check if the otken price is zero or not
        require(_newPrice >= minPrice && _newPrice <= maxPrice, 'PII');
        // get that token from all houses mapping and create a memory of it defined as (struct => House)
        House storage house = allHouses[_tokenId];
        // update token's price with new price
        house.price = _newPrice;
    }

    // get all houses NFT
    function getAllHouses() external view returns (House[] memory) {
        House[] memory tempHouses = new House[](houseCounter);
        for (uint256 i = 0; i < houseCounter; i++) {
            tempHouses[i] = allHouses[i + 1];
        }
        return tempHouses;
    }

    // get all payable houses NFT
    function getAllPayableHouses() external view returns (House[] memory) {
        uint256 iNum;
        for (uint256 i = 0; i < houseCounter; i++) {
            if (allHouses[i + 1].nftPayable == true && allHouses[i + 1].staked == false) {
                iNum++;
            }
        }
        House[] memory tempHouses = new House[](iNum);
        iNum = 0;
        for (uint256 i = 0; i < houseCounter; i++) {
            if (allHouses[i + 1].nftPayable == true && allHouses[i + 1].staked == false) {
                tempHouses[iNum] = allHouses[i + 1];
                iNum++;
            }
        }
        return tempHouses;
    }

    // get all my houses NFT
    function getAllMyHouses() external view returns (House[] memory) {
        uint256 iNum;
        for (uint256 i = 0; i < houseCounter; i++) {
            if (allHouses[i + 1].currentOwner == msg.sender) {
                iNum++;
            }
        }
        House[] memory tempHouses = new House[](iNum);
        iNum = 0;
        for (uint256 i = 0; i < houseCounter; i++) {
            if (allHouses[i + 1].currentOwner == msg.sender) {
                tempHouses[iNum] = allHouses[i + 1];
                iNum++;
            }
        }
        return tempHouses;
    }

    // withdraw token
    function withdrawToken(uint256 _amountToken) external payable {
        onlyMember();
        _token.transfer(msg.sender, _amountToken);
    }

    // withdraw ETH
    function withdrawETH(uint256 _amountEth) external payable {
        onlyMember();
        payable(msg.sender).transfer(_amountEth);
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

    // Get Overall total information
    function getTotalInfo() public view returns (uint256, uint256, uint256) {
        onlyMember();
        return (houseCounter, IStaking(stakingContractAddress).stakedCounter(), soldedCounter);
    }

    // Returns price of a house with `tokenId`
    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        require(msg.sender == stakingContractAddress, 'sc');
        return allHouses[tokenId].price;
    }

    // Sets house staked status
    function setHouseStakedStatus(uint256 tokenId, bool status) external {
        require(msg.sender == stakingContractAddress, 'sc');
        allHouses[tokenId].staked = status;
    }

    function getRoyaltyCreator() public view returns (uint256) {
        return royaltyCreator;
    }

    function setRoyaltyCreator(uint256 _royalty) public {
        onlyMember();
        royaltyCreator = _royalty;
    }

    function getRoyaltyMarket() public view returns (uint256) {
        return royaltyMarket;
    }

    function setRoyaltyMarket(uint256 _royalty) public {
        onlyMember();
        royaltyMarket = _royalty;
    }
}
