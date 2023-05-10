// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IHBToken {
    function mint(address to, uint256 amount) external;
}

contract Operator is Ownable {
    // Contract addresses
    IHBToken HBToken;
    IERC20 hbToken;

    // IHouseBusiness HouseBusiness;
    // IMainCleanContract CContract;

    // Token balances that can be used as gas fee from the account users
    mapping(address => uint256) private _balances;

    // Authorized contract addresses which will be called from this contract
    mapping(address => bool) private _authorizedContracts;

    // Utility tokens and NFT address
    address public houseBusinessToken;

    constructor(address _houseBusinessToken) {
        // Init contract instances
        HBToken = IHBToken(_houseBusinessToken);
        hbToken = IERC20(houseBusinessToken);
        houseBusinessToken = _houseBusinessToken;
    }

    /**
     * Provides the ability to update smart contract addresses for scalability.
     * @param _houseBusinessToken HouseBusinessToken address
     */
    function setHBToken(address _houseBusinessToken) external onlyOwner {
        houseBusinessToken = _houseBusinessToken;
        HBToken = IHBToken(_houseBusinessToken);
        hbToken = IERC20(_houseBusinessToken);
    }

    function authorizeContracts(address[] memory contractAddresses) external onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            _authorizedContracts[contractAddresses[i]] = true;
        }
    }

    function revokeContracts(address[] memory contractAddresses) external onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            _authorizedContracts[contractAddresses[i]] = false;
        }
    }

    function isContractAuthorized(address contractAddress) external view returns (bool) {
        return _authorizedContracts[contractAddress];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function mintAndStore(address user, uint256 amount) public {
        // Mint the HBToken to the Operator contract
        HBToken.mint(address(this), amount);

        // Store the mapping of the HBToken balance to the user
        _balances[user] += amount;
    }

    // These functions should be called from the account user's virtual wallet address, should be approved first
    function deposit(uint256 amount) external {
        require(amount > 0, 'Amount must be greater than zero');
        require(hbToken.transferFrom(msg.sender, address(this), amount), 'Transfer failed');
        _balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount, address user) external {
        require(amount > 0, 'Amount must be greater than zero');
        require(_balances[user] >= amount, 'Insufficient balance');
        require(hbToken.transfer(user, amount), 'Transfer failed');
        _balances[user] -= amount;
    }

    function callContract(address contractAddress, bytes memory data, uint256 gasFee, address user) external {
        require(_authorizedContracts[contractAddress], 'Contract not authorized');
        require(_balances[user] >= gasFee, 'Insufficient balance');
        // require(hbToken.transferFrom(user, address(this), gasFee), 'Transfer failed');
        _balances[user] -= gasFee;
        (bool success, ) = contractAddress.call(data);
        require(success, 'Contract call failed');
    }

    // Only Admin role can withdraw the balance
    function withdrawToken(uint256 amount) external onlyOwner {
        require(amount > 0, 'Amount must be greater than zero');
        require(hbToken.balanceOf(address(this)) >= amount, 'Insufficient balance');
        require(hbToken.transfer(msg.sender, amount), 'Transfer failed');
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount > 0, 'Amount must be greater than zero');
        require(address(this).balance >= amount, 'Insufficient balance');
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }
}
