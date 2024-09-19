// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Features:
// 1. Users can create swap orders.
// 2. Other users can accept swap orders by sending the requested tokens.
// 3. The contract should handle partial or full swaps, depending on logic.
// 4. (optional) Both fungible and non-fungible tokens should be supported (depending on scope).

contract SwapOrder {

    struct Order {
        address depositor;
        address depositedToken;
        uint256 totalDepositedAmount;
        uint256 availableAmount;
        bool isFulfilled;
    }

    mapping(uint256 => Order) public orders;
    uint256 public orderIdCounter;

    event OrderCreated(uint256 indexed orderId, address indexed depositor, address depositedToken, uint256 depositedAmount);
    event OrderFulfilled(uint256 indexed orderId, address indexed purchaser, uint256 amountPurchased);

    // Store users' balances for different tokens
    mapping(address => mapping(address => uint256)) public balances; // balances[owner][token]

    // Allowances for token spending
    mapping(address => mapping(address => mapping(address => uint256))) public allowances; // allowances[owner][spender][token]

    /// Create an order with token deposit from User1
    function createOrder(address _depositedToken, uint256 _depositedAmount) public {
        require(_depositedAmount > 0, "Deposit amount must be greater than 0");

        // Transfer tokens from User1 to the contract
        require(transferTokens(msg.sender, _depositedToken, _depositedAmount, address(this)), "Token transfer failed");

        // Create the order
        orders[orderIdCounter] = Order({
            depositor: msg.sender,
            depositedToken: _depositedToken,
            totalDepositedAmount: _depositedAmount,
            availableAmount: _depositedAmount,
            isFulfilled: false
        });

        emit OrderCreated(orderIdCounter, msg.sender, _depositedToken, _depositedAmount);

        orderIdCounter++;
    }

    /// User2 swaps tokens with User1's deposit
    function purchaseTokens(
        uint256 _orderId,
        uint256 _amountToPurchase,
        address _paymentToken,
        uint256 _paymentAmount
    ) public {
        Order storage order = orders[_orderId];

        require(!order.isFulfilled, "Order already fulfilled");
        require(_amountToPurchase > 0 && _amountToPurchase <= order.availableAmount, "Invalid amount to purchase");

        // Transfer payment tokens from User2 to User1 (depositor)
        require(transferTokens(msg.sender, _paymentToken, _paymentAmount, order.depositor), "Payment token transfer failed");

        // Transfer deposited tokens from contract to User2 (purchaser)
        require(transferTokens(address(this), order.depositedToken, _amountToPurchase, msg.sender), "Deposited token transfer failed");

        // Update the order's available amount
        order.availableAmount -= _amountToPurchase;

        // If the entire deposit has been swapped, mark the order as fulfilled
        if (order.availableAmount == 0) {
            order.isFulfilled = true;
        }

        emit OrderFulfilled(_orderId, msg.sender, _amountToPurchase);
    }

    /// Helper function to handle token transfers
    function transferTokens(
        address from,
        address token,
        uint256 amount,
        address to
    ) internal returns (bool) {
        require(balances[from][token] >= amount, "Balance too low");
        balances[from][token] -= amount;
        balances[to][token] += amount;
        emit Transfer(from, to, token, amount);
        return true;
    }

    /// Allows `_spender` to spend `_value` on behalf of the sender for the specified token
    function approve(address _spender, address _token, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender][_token] = _value;
        emit Approval(msg.sender, _spender, _token, _value);
        return true;
    }

    /// Transfer `_value` from `_from` to `_to` for a specific token, checking allowance
    function transferFrom(
        address _from,
        address _to,
        address _token,
        uint256 _value
    ) public returns (bool) {
        require(balances[_from][_token] >= _value, "Balance too low");
        require(allowances[_from][msg.sender][_token] >= _value, "Allowance too low");
        allowances[_from][msg.sender][_token] -= _value;
        return transferTokens(_from, _to, _value, _token);
    }

    /// Events
    event Transfer(address indexed _from, address indexed _to, address indexed _token, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, address indexed _token, uint256 _value);
}
