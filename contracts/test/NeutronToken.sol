//Contract for NeutronToken
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract NeutronToken is ERC20Capped, ERC20Burnable {
    address payable public owner;
    uint256 public blockReward;

    constructor(
        uint256 cap,
        uint256 reward
    ) ERC20("NeutronToken", "NTRO") ERC20Capped(cap * (10 ** decimals())) {
        owner = payable(msg.sender);
        _mint(owner, 500000 * (10 ** decimals()));
        blockReward = reward;
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20Capped, ERC20) {
        require(
            ERC20.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only Owner is allowed to call this function"
        );
        _;
    }

    function setReward(uint256 newReward) public onlyOwner {
        blockReward = newReward * (10 ** decimals());
    }

    function _mintMinerReward() internal {
        _mint(block.coinbase, blockReward);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        if (
            from != address(0) &&
            to != block.coinbase &&
            block.coinbase != address(0)
        ) {
            _mintMinerReward();
        }
        super._beforeTokenTransfer(from, to, value);
    }
}
