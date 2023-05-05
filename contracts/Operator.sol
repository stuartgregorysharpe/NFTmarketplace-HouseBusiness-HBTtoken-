// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// interface IHouseBusiness {
//     function setPayable(uint256 tokenId, address _buyer, bool nftPayable) external;

//     function mintHouse(
//         string memory _name,
//         string memory _tokenURI,
//         string memory _tokenType,
//         string memory initialDesc
//     ) external payable;

//     function addHistory(
//         uint256 _tokenId,
//         uint256 contractId,
//         uint256 newHistoryType,
//         string memory houseImg,
//         string memory houseBrand,
//         string memory _history,
//         string memory _desc,
//         string memory brandType,
//         uint256 yearField
//     ) external;

//     function editHistory(
//         uint256 _tokenId,
//         uint256 historyIndex,
//         string memory houseImg,
//         string memory houseBrand,
//         string memory _history,
//         string memory _desc,
//         string memory brandType,
//         uint256 yearField
//     ) external;

//     function addOrEditHType(
//         uint256 _historyIndex,
//         string memory _label,
//         bool _connectContract,
//         bool _imgNeed,
//         bool _brandNeed,
//         bool _descNeed,
//         bool _brandTypeNeed,
//         bool _yearNeed,
//         bool _checkMark
//     ) external;

//     function removeHistoryType(uint256 _hIndex) external;

//     // Disconnects contract from house history.
//     function disconnectContract(uint256 tokenId, uint256 hIndex, uint256 contractId) external;

//     function buyHouseNft(uint256 tokenId) external payable;

//     function changeHousePrice(uint256 tokenId, uint256 newPrice) external;
// }

// interface IMainCleanContract {
//     // write Contract
//     function ccCreation(
//         string memory _companyName,
//         string memory _contractType,
//         address _contractSigner,
//         string memory _contractURI,
//         uint256 _dateFrom,
//         uint256 _dateTo,
//         uint256 _agreedPrice,
//         string memory _currency
//     ) external;

//     // Add Contract Signer
//     function addContractSigner(uint256 _ccID, address _contractSigner) external;

//     // sign contract
//     function signContract(uint256 ccID) external;

//     // send sign notification
//     function sendNotify(address _notifyReceiver, string memory _notifyContent, uint256 ccID) external;

//     /**
//      * @dev modifies ownership of `contractId` from `from` to `to`
//      */
//     function transferContractOwnership(uint256 contractId, address from, address to) external;
// }

// interface IHouseBusinessToken {
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     function approve(address spender, uint256 amount) external returns (bool);

//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

//     function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
// }

contract Operator is Ownable {
    // Contract addresses
    IERC20 ERC20Token;
    
    // IHouseBusiness HouseBusiness;
    // IMainCleanContract CContract;

    // Token balances that can be used as gas fee from the account users
    mapping(address => uint256) private _balances;

    // Authorized contract addresses which will be called from this contract
    mapping(address => bool) private _authorizedContracts;

    // Utility tokens and NFT address
    address erc20Token = 0x27C1F4539Fd2CcE5394Ea11fA8554937A587d684;

    // address houseBusiness = 0x0A964d282AF35e81Ad9d72e5c215108B3c43D3c1;
    // address cContract = 0xaa3Dc2E3ca0FE2dE6E519F0F224456861A7e9cFC;

    constructor() {
        // Init contract instances
        ERC20Token = IERC20(erc20Token);

        // HouseBusiness = IHouseBusiness(houseBusiness);
        // CContract = IMainCleanContract(cContract);
    }

    // /**
    //  * Provides the ability to update smart contract addresses for scalability.
    //  * @param _houseBusiness HouseBusiness NFT address
    //  */
    // function setHouseBusiness(address _houseBusiness) external onlyOwner {
    //     houseBusiness = _houseBusiness;
    //     HouseBusiness = IHouseBusiness(_houseBusiness);
    // }

    // /**
    //  * Provides the ability to update smart contract addresses for scalability.
    //  * @param _cContract MainCleanContract address
    //  */
    // function setCContract(address _cContract) external onlyOwner {
    //     cContract = _cContract;
    //     CContract = IMainCleanContract(_cContract);
    // }

    /**
     * Provides the ability to update smart contract addresses for scalability.
     * @param _erc20Token HouseBusinessToken address
     */
    function setERC20Token(address _erc20Token) external onlyOwner {
        erc20Token = _erc20Token;
        ERC20Token = IERC20(_erc20Token);
    }

    function authorizeContract(address contractAddress) external onlyOwner {
        _authorizedContracts[contractAddress] = true;
    }

    function revokeContract(address contractAddress) external onlyOwner {
        _authorizedContracts[contractAddress] = false;
    }

    function isContractAuthorized(address contractAddress) external view returns (bool) {
        return _authorizedContracts[contractAddress];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // These functions should be called from the account user's virtual wallet address
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(ERC20Token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        _balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        require(ERC20Token.transfer(msg.sender, amount), "Transfer failed");
        _balances[msg.sender] -= amount;
    }

    function callContract(address contractAddress, bytes memory data, uint256 gasFee) external {
        require(_authorizedContracts[contractAddress], "Contract not authorized");
        require(_balances[msg.sender] > 0, "Insufficient balance");
        require(ERC20Token.transferFrom(msg.sender, address(this), gasFee), "Transfer failed");
        _balances[msg.sender] -= gasFee;
        (bool success,) = contractAddress.call(data);
        require(success, "Contract call failed");
    }
}
