// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Operator is Ownable {
    // Contract addresses
    IERC20 HBToken;

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
        HBToken = IERC20(_houseBusinessToken);
        houseBusinessToken = _houseBusinessToken;
    }

    /**
     * Provides the ability to update smart contract addresses for scalability.
     * @param _houseBusinessToken HouseBusinessToken address
     */
    function setHBToken(address _houseBusinessToken) external onlyOwner {
        houseBusinessToken = _houseBusinessToken;
        HBToken = IERC20(_houseBusinessToken);
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
        require(amount > 0, 'Amount must be greater than zero');
        require(HBToken.transferFrom(msg.sender, address(this), amount), 'Transfer failed');
        _balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, 'Amount must be greater than zero');
        require(_balances[msg.sender] >= amount, 'Insufficient balance');
        require(HBToken.transfer(msg.sender, amount), 'Transfer failed');
        _balances[msg.sender] -= amount;
    }

    function callContract(address contractAddress, bytes memory data, uint256 gasFee) external {
        require(_authorizedContracts[contractAddress], 'Contract not authorized');
        require(_balances[msg.sender] >= gasFee, 'Insufficient balance');
        require(HBToken.transferFrom(msg.sender, address(this), gasFee), 'Transfer failed');
        _balances[msg.sender] -= gasFee;
        (bool success, ) = contractAddress.call(data);
        require(success, 'Contract call failed');
    }
}
