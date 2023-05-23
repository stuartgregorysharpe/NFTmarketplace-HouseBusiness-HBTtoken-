// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';

pragma solidity ^0.8.0;

contract HouseBusinessToken is Context, ERC20 {
    address private _owner;

    constructor() ERC20('House Business Token', 'HBT') {
        _owner = msg.sender;
        _mint(_owner, 10 ** 26);
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner, 'ERC20: Only owner can run this event');
        _;
    }

    function setOperator(address _address, bool _isOperator) public onlyOwner() {
        operators[_address] = _isOperator;
    }

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public virtual {
        _burn(from, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
