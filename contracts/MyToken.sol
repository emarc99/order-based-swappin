// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**18;  // 1 million tokens with 18 decimals

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // Assign all tokens to the contract deployer (owner)
        balances[msg.sender] = totalSupply;
    }

    // Returns the token balance of a given address
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    // Transfer tokens from the sender to the recipient
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Internal transfer logic to reduce duplication
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");

        balances[sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    // Approve a spender to spend tokens on behalf of the token owner
    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Check how many tokens a spender is allowed to spend on behalf of an owner
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    // Transfer tokens on behalf of the token owner (with allowance)
    function transferFrom(address owner, address recipient, uint256 amount) public returns (bool) {
        require(balances[owner] >= amount, "Insufficient balance");
        require(allowances[owner][msg.sender] >= amount, "Allowance exceeded");

        allowances[owner][msg.sender] -= amount;
        _transfer(owner, recipient, amount);
        return true;
    }
}
