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
        uint256 tokenId;
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
        uint256 contractId;
        string houseImg;
        string houseBrand;
        string desc;
        string history;
        string brandType;
        uint256 yearField;
    }
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
    
    HistoryType[] historyTypes;

    mapping(address => bool) public member;
    mapping(uint256 => House) public allHouses;
    mapping(uint256 => History[]) houseHistories;
    mapping(uint256 => mapping(address => bool)) public allowedList;

    address stakingContractAddress;

    event HouseMinted(
        address indexed minter,
        string name,
        string tokenURI,
        string tokenType,
        string initialDesc,
        uint256 timestamp
    );
    event PayableSet(
        address indexed owner,
        uint256 indexed tokenId,
        address buyer,
        bool nftPayable,
        uint256 timestamp
    );
    event AllowListAdded(
        address indexed currentOwner,
        uint256 indexed tokenId,
        address allowed,
        uint256 timestamp
    );
    event AllowListRemoved(
        address indexed currentOwner,
        uint256 indexed tokenId,
        address allowed,
        uint256 timestamp
    );
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
    event HistoryTypeRemoved(
        address indexed member,
        uint256 indexed hIndex,
        uint256 timestamp
    );
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
    event HousePriceChanged(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price
    );
    event TokenWithdrawn(
        address indexed sender,
        uint256 amount,
        uint256 timestamp
    );
    event EthWithdrawn(
        address indexed sender,
        uint256 amount,
        uint256 timestamp
    );
    event HouseStakedStatusSet(
        uint256 indexed tokenId,
        bool status,
        uint256 timestamp
    );
    event RoyaltyCreatorSet(
        address indexed member,
        uint256 royalty,
        uint256 timestamp
    );
    event RoyaltyMarketSet(
        address indexed member,
        uint256 royalty,
        uint256 timestamp
    );
    event TokenPriceChanged(
        uint256 indexed tokenId,
        uint256 newPrice,
        uint256 timestamp
    );

    constructor(address _tokenAddress) ERC721("HouseBusiness", "HUBS") {
        (collectionName, collectionNameSymbol) = (name(), symbol());
        member[msg.sender] = true;
        royaltyCreator = 6;
        royaltyMarket = 2;
        historyTypes.push(
            HistoryType(
                hTypeCounter++,
                "Construction",
                false,
                false,
                false,
                false,
                false,
                false,
                false
            )
        );
        historyTypes.push(
            HistoryType(
                hTypeCounter++,
                "Floorplan",
                true,
                true,
                true,
                true,
                false,
                false,
                false
            )
        );
        historyTypes.push(
            HistoryType(
                hTypeCounter++,
                "Pictures",
                true,
                true,
                true,
                true,
                false,
                false,
                false
            )
        );
        historyTypes.push(
            HistoryType(
                hTypeCounter++,
                "Blueprint",
                true,
                true,
                true,
                true,
                false,
                false,
                false
            )
        );
        historyTypes.push(
            HistoryType(
                hTypeCounter++,
                "Solarpanels",
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        historyTypes.push(
            HistoryType(
                hTypeCounter++,
                "Airconditioning",
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        historyTypes.push(
            HistoryType(
                hTypeCounter++,
                "Sonneboiler",
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );
        historyTypes.push(
            HistoryType(
                hTypeCounter++,
                "Housepainter",
                false,
                false,
                false,
                false,
                false,
                false,
                true
            )
        );
        minPrice = 10**17;
        maxPrice = 10**18;
        _token = IERC20(_tokenAddress);
    }

    modifier onlyMember() {
        require(member[msg.sender], "Only Member");
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
        require(msg.sender == stakingContractAddress, "sc");
        allHouses[tokenId].staked = status;

        emit HouseStakedStatusSet(tokenId, status, block.timestamp);
    }

    function setMinMaxHousePrice(uint256 _min, uint256 _max) external onlyMember {
        minPrice = _min;
        maxPrice = _max;
    }

    function setConfigToken(address _tokenAddress) external {
        _token = IERC20(_tokenAddress);
    }

    function setPayable(
        uint256 _tokenId,
        address _buyer,
        bool _nftPayable
    ) external {
        House memory house = allHouses[_tokenId];
        // require that token should exist
        require(_exists(_tokenId));
        // check that token's owner should be equal to the caller of the function
        require(house.contributor.currentOwner == msg.sender, "Only owner can call this func.");
        require(house.price > 0, "Pricing has not been set at this time.");
        if (house.contributor.buyer != _buyer)
            house.contributor.buyer = _buyer;
        house.nftPayable = _nftPayable;

        emit PayableSet(
            msg.sender,
            _tokenId,
            _buyer,
            _nftPayable,
            block.timestamp
        );
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
    function disconnectContract(
        uint256 tokenId,
        uint256 hIndex,
        uint256 contractId
    ) external {
        require(ownerOf(tokenId) == msg.sender, "owner");
        History storage history = houseHistories[tokenId][hIndex];
        require(history.contractId == contractId, "id");
        history.contractId = 0;

        emit ContractDisconnected(
            msg.sender,
            tokenId,
            hIndex,
            contractId,
            block.timestamp
        );
    }

    // change token price by token id
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) external {
        require(_exists(_tokenId), "TNE");
        require(ownerOf(_tokenId) == msg.sender, "OOCC/RO");
        House memory house = allHouses[_tokenId];
        require(_newPrice >= minPrice && _newPrice <= maxPrice, "PII");
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

    function addMember(address _newMember) external onlyMember {
        member[_newMember] = true;
    }

    function removeMember(address _newMember) external onlyMember {
        member[_newMember] = false;
    }

    function mintHouse(
        string memory _name,
        string memory _tokenURI,
        string memory _tokenType,
        string memory initialDesc
    ) external {
        // check if a token exists with the above token id => incremented counter
        uint256 tokenId = houseCounter + 1;

        // ensure token with id doesn't already exist
        require(!_exists(tokenId), "Token already exists.");

        // mint the token
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        allHouses[houseCounter] = House({
            tokenId: houseCounter,
            tokenName: _name,
            tokenURI: _tokenURI,
            tokenType: _tokenType,
            price: 0,
            numberOfTransfers: 0,
            nftPayable: false,
            staked: false,
            soldStatus: false,
            contributor: Contributor({
                currentOwner: msg.sender,
                previousOwner: address(0),
                buyer: address(0),
                creator: msg.sender
            })
        });

        // new house history push into the House struct
        houseHistories[houseCounter].push(
            History({
                hID: 0,
                contractId: houseCounter,
                houseImg: "",
                houseBrand: "",
                desc: "",
                history: initialDesc,
                brandType: "",
                yearField: 0
            })
        );
        houseCounter++;

        emit HouseMinted(
            msg.sender,
            _name,
            _tokenURI,
            _tokenType,
            initialDesc,
            block.timestamp
        );
    }

    // Add allow list
    function addAllowList(uint256 _tokenId, address allowed) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Only the owner can add to the allowlist."
        );
        allowedList[_tokenId][allowed] = true;
        emit AllowListAdded(msg.sender, _tokenId, allowed, block.timestamp);
    }

    // Remove allow list
    function removeAllowList(uint256 _tokenId, address allowed) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Only the owner can remove from the allowlist."
        );
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
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "owner");
        require(
            cContract.getContractById(contractId).owner == msg.sender,
            "cowner"
        );

        History[] storage histories = houseHistories[_tokenId];
        histories.push(
            History({
                hID: _tokenId,
                contractId: contractId,
                houseImg: houseImg,
                houseBrand: houseBrand,
                desc: _desc,
                history: _history,
                brandType: brandType,
                yearField: yearField
            })
        );

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
    ) external {
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
    ) external onlyMember {
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
    function removeHistoryType(uint256 _hIndex) external onlyMember {
        delete historyTypes[_hIndex];

        emit HistoryTypeRemoved(msg.sender, _hIndex, block.timestamp);
    }

    function changeHousePrice(uint256 tokenId, uint256 newPrice) external {
        require(
            allHouses[tokenId].contributor.currentOwner == msg.sender,
            "Only the owner can change the price and tokenId must exist"
        );
        require(
            newPrice >= minPrice && newPrice <= maxPrice,
            "Price must be within the limits"
        );

        allHouses[tokenId].price = newPrice;

        emit HousePriceChanged(tokenId, msg.sender, newPrice);
    }

    // by a token by passing in the token's id
    function buyHouseNft(uint256 tokenId) public payable {
        House memory house = allHouses[tokenId];
        Contributor memory _contributor = house.contributor;

        require(msg.value >= house.price, "Insufficient payment.");
        require(house.nftPayable, "House is not for sale.");
        require(
            _contributor.currentOwner != address(0),
            "House does not exist."
        );
        require(
            _contributor.currentOwner != msg.sender,
            "You are already the owner of this house."
        );

        if (_contributor.buyer != address(0)) {
            require(
                _contributor.buyer == msg.sender,
                "You are not authorized to buy this house."
            );
        }
        _contributor.buyer = msg.sender;

        // calculate the payouts
        uint256 creatorCut = (house.price * royaltyCreator) / 100;
        uint256 marketCut = (house.price * royaltyMarket) / 100;
        uint256 ownerCut = house.price - creatorCut - marketCut;

        // transfer the funds to the previous owner and creators
        sendValue(payable(_contributor.previousOwner), ownerCut);
        sendValue(payable(_contributor.creator), creatorCut);

        // transfer the token to the new owner
        _transfer(_contributor.currentOwner, msg.sender, tokenId);

        // update the house details
        _contributor.previousOwner = _contributor.currentOwner;
        _contributor.currentOwner = msg.sender;
        house.nftPayable = false;
        house.soldStatus = true;
        house.numberOfTransfers++;

        // update the counters
        soldedCounter++;

        // emit an event
        emit HouseNftBought(
            tokenId,
            msg.sender,
            _contributor.previousOwner,
            _contributor.creator,
            house.price,
            block.timestamp
        );
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient balance.");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to sendETH.");
    }

    // by a token by passing in the token's id
    function sendToken(address receiver, uint256 tokenId) external payable {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0));

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(msg.sender, receiver, tokenId);

        // Transfer ownership of connected contracts
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        House storage house = allHouses[tokenId];
        // update the token's previous owner
        house.contributor.previousOwner = house.contributor.currentOwner;
        // update the token's current owner
        house.contributor.currentOwner = to;
        // update the how many times this token was transfered
        house.numberOfTransfers += 1;
        _transferHistoryContracts(tokenId, from, to);
    }

    /**
     * @dev transfer ownership of connected contracts
     */
    function _transferHistoryContracts(
        uint256 tokenId,
        address from,
        address to
    ) private {
        History[] storage histories = houseHistories[tokenId];

        unchecked {
            for (uint256 i = 0; i < histories.length; ++i) {
                if (histories[i].contractId > 0) {
                    cContract.transferContractOwnership(
                        histories[i].contractId,
                        from,
                        to
                    );
                }
            }
        }
    }

    // get all houses NFT
    function getAllHouses() external view returns (House[] memory) {
        House[] memory tempHouses = new House[](houseCounter);
        uint256 index = 0;
        for (uint256 i = 0; i < houseCounter; i++) {
            tempHouses[i] = allHouses[i];
            index++;
        }
        return tempHouses;
    }

    // get all payable houses NFT
    function getAllPayableHouses() external view returns (House[] memory) {
        House[] memory allPayableHouse;
        uint256 j = 0;
        for (uint256 i = 0; i < houseCounter; i++) {
            House storage temp_house = allHouses[i];
            if (temp_house.nftPayable == true && temp_house.staked == false) {
                allPayableHouse[j++] = temp_house;
            }
        }
        return allPayableHouse;
    }

    // get all my houses NFT
    function getAllMyHouses() external view returns (House[] memory) {
        House[] memory allMyHouse = new House[](houseCounter);
        uint256 j = 0;

        for (uint256 i = 0; i < houseCounter; i++) {
            if (allHouses[i].contributor.currentOwner == msg.sender) {
                allMyHouse[j++] = allHouses[i];
            }
        }

        assembly {
            mstore(allMyHouse, j)
        }
        return allMyHouse;
    }

    // Returns price of a house with `tokenId`
    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        require(msg.sender == stakingContractAddress, "sc");
        return allHouses[tokenId].price;
    }

    // Get Overall total information
    function getTotalInfo()
        external
        view
        onlyMember
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            houseCounter,
            IStaking(stakingContractAddress).stakedCounter(),
            soldedCounter
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function checkAllowedList(uint256 _tokenId, address allowed)
        external
        view
        returns (bool)
    {
        return allowedList[_tokenId][allowed];
    }

    function getHistory(uint256 _tokenId)
        external
        view
        returns (History[] memory)
    {
        return houseHistories[_tokenId];
    }

    // Get History Type
    function getHistoryType() external view returns (HistoryType[] memory) {
        HistoryType[] memory aHistoryTypes = new HistoryType[](
            historyTypes.length
        );
        for (uint256 i = 0; i < historyTypes.length; i++) {
            aHistoryTypes[i] = historyTypes[i];
        }
        return aHistoryTypes;
    }

    // get owner of the token
    function getTokenOwner(uint256 _tokenId) external view returns (address) {
        address _tokenOwner = ownerOf(_tokenId);
        return _tokenOwner;
    }
}