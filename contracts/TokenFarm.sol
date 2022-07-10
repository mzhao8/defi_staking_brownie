// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // stakeTokens - DONE!
    // unStakeTokens - DONE!
    // issueTokens - DONE!
    // addAllowedTokens - DONE!
    // getETHValue - DONE!

    // 100 ETH 1:1. for every 1 ETH, we give 1 DappToken
    // 50 ETH and 50 DAI staked, and we want to give a reward of 1 DAPP / 1 DAI

    IERC20 public dappToken;

    address[] public allowedTokens;
    // stakers on platform
    address[] public stakers;
    // mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // mapping staker address -> unique tokens staked (uint)
    mapping(address => uint256) public uniqueTokensStaked;
    // map token address ->  price feed contract
    mapping(address => address) public tokenPriceFeedMapping;

    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue tokens to all stakers
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            // send token reward
            // based on total value locked
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        // loop through each token address
        // loop through each staker
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0);

        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // price of the token in USD
        // base unit is solidity is 10**18 (generally)
        // so if we have 10 ETH, technically we have 10 * (10**18)
        // 1 wei = 1 eth / (10**18)
        // and if ETH/USD is 100
        // (10 * 10**18) wei * 100 / (10**18) = 1,000
        //
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / 10**decimals);
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        //Price Feed Adresss
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // how much can they stake?
        require(_amount > 0, "Amount must be more than 0");

        // require(_token is allowed?)
        require(tokenIsAllowed(_token), "Token is currently not allowed");

        // if request passes these conditions, call transferFrom function on ERC20
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // update amount of tokens staked
        updateUniqueTokensStaked(msg.sender, _token);
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }

        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
    }

    function unstakeTokens(address _token) public {
        uint256 amount = stakingBalance[_token][msg.sender];
        require(amount > 0, "staking balance has to be > 0");
        IERC20(_token).transfer(msg.sender, amount);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;

        // remove staker from stakers array if the staker has no more staked tokens
        if (uniqueTokensStaked[msg.sender] == 0) {
            removeStaker(msg.sender);
        }
    }

    function removeStaker(address _staker) public {
        require(
            uniqueTokensStaked[_staker] == 0,
            "User still has tokens staked"
        );
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            if (stakers[stakersIndex] == _staker) {
                delete stakers[stakersIndex];

                // still need to delete the removed staker
                stakers[stakersIndex] = stakers[stakers.length - 1];
                stakers.pop();
            }
        }
    }

    function addAllowedTokens(address _token) public onlyOwner returns (bool) {
        allowedTokens.push(_token);
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}
