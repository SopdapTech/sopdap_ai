// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SopdapAI is ERC20 {
    using SafeMath for uint256;
    address private _owner;
    uint256 private _treasuryLocked;
    uint256 private _devLocked;
    uint256 private _vestingDuration;
    uint256 private _vestingCliff;
    uint256 private _treasuryvestingCliff;
    uint256 private _intialAvaliablelSupply;
    mapping(address => uint256) public lockupPeriods;
    mapping(address => uint256) private lockedBalances;
      
    // event to notify when tokens are locked
    event TokensLocked(address indexed recipient, uint256 amount, uint256 lockupPeriod);

    // This smart contract is developed by Sopdap Technologies www.sopdap.com.ng for Sopdap AI
    constructor() ERC20("SOPDAP AI", "SOP") {
        _owner = msg.sender;
        uint256 totalSupply = 840_000_000 * 10**decimals();    
        _treasuryLocked = totalSupply * 30 / 100;
        __devLocked = totalSupply * 40 / 100;
        _vestingStart = block.timestamp;
        _vestingDuration = 1460 days;
        _vestingCliff = 365 days;
        _treasuryvestingCliff = 1825 days;
        _intialAvaliablelSupply = totalSupply  - _treasuryLocked - _devLocked;
        _mint(msg.sender, totalSupply);
        
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner, "Sopdap AI: only owner can call this function");
        _;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    // token To distribut Airdrop with lock feature.
    function AirdropDistribution(address[] memory recipients, uint256[] memory amounts, uint256 lockupPeriod) public returns (bool) {
        require(recipients.length == amounts.length, "Invalid input");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            require(recipient != address(0), "Invalid recipient address");
            require(amount > 0, "Invalid amount");
            require(balanceOf(msg.sender) >= amount, "Insufficient balance");

            transfer(recipient, amount);

            if (lockupPeriod > 0) {
                lockedBalances[recipient] = lockedBalances[recipient].add(amount);
                lockupPeriods[recipient] = lockupPeriod;
                emit TokensLocked(recipient, amount, lockupPeriod);
            }
        }

        return true;
    }


// function to enable lockup period for specific recipient
    function enableLockupPeriod(address recipient, uint256 lockupPeriod) public onlyOwner returns (bool) {
        lockupPeriods[recipient] = lockupPeriod;
        return true;
    }

// function to get locked balance of a recipient
    function lockedBalanceOf(address account) public view returns (uint256) {
        uint256 lockupPeriod = lockupPeriods[account];
        if (lockupPeriod == 0 || block.timestamp >= lockupPeriod) {
            return 0;
        } else {
            return lockedBalances[account];
        }
    }

    function burn(uint256 amount) public {
        require(_msgSender() == _owner, "Sopdap AI: only owner can burn");
        _burn(_msgSender(), amount);
    }

    function SopdapAITreasuryLocked() external {
        require(_msgSender() == _owner, "Sopdap AI: only owner can lock treasury");
        _transfer(_owner, address(this), _treasuryLocked);
    }

    function SopdapAITokeLocked() external {
        require(_msgSender() == _owner, "Sopdap AI: only owner can lock SOP");
        _transfer(_owner, address(this), _devLocked);
    }

    function releaseTreasury() external {
        require(_msgSender() == _owner, "Sopdap AI: only owner can release treasury");
        require(block.timestamp >= _vestingStart + _treasuryvestingCliff, "Sopdap AI: vesting cliff not reached");
        uint256 vestedAmount = calculateVestedAmount(_treasuryLocked);
        _transfer(address(this), _owner, vestedAmount);
    }

    function releaseDev() external {
        require(_msgSender() == _owner, "Sopdap AI: only owner can release dev");
        require(block.timestamp >= _vestingStart + _vestingCliff, "Sopdap AI: vesting cliff not reached");
        uint256 vestedAmount = calculateVestedAmount(_devLocked);
        _transfer(address(this), _owner, vestedAmount);
    }

    function calculateVestedAmount(uint256 lockedAmount) private view returns (uint256) {
        if (block.timestamp >= _vestingStart + _vestingDuration) {
            return lockedAmount;
        } else {
            uint256 timeSinceStart = block.timestamp - _vestingStart;
            return lockedAmount * timeSinceStart / _vestingDuration;
        }
    }
  
    function totalAvailableSupply() public view returns (uint256) {
        return _intialAvaliablelSupply;
    }
    function totalLockedSOP() public view returns (uint256) {
        return balanceOf(address(this));
    }
    //lock struct

        struct Lock {
        uint256 amount;
        uint256 releaseTime;
    }

    mapping(address => Lock[]) locks;

    function getLockTime(address account, uint256 amount) public view returns (uint256) {
        for (uint256 i = 0; i < locks[account].length; i++) {
            if (locks[account][i].amount == amount) {
                return locks[account][i].releaseTime;
            }
        }
        return 0;
    }


    //lock tokens

    function lockTokens(address account, uint256 amount, uint256 duration) public {
    require(_msgSender() == _owner, "Sopdap AI: only owner can lock tokens");
    _transfer(account, address(this), amount);
    uint256 releaseTime = block.timestamp + duration;
    // store the lock details in a mapping
    locks[account].push(Lock(amount, releaseTime));
    }


    //Unlock tokens

    function unlockTokens(address account, uint256 amount) public {
        require(_msgSender() == _owner, "Sopdap AI: only owner can unlock tokens");
        uint256 releaseTime = 0;
        // search for the lock with the given amount and set the release time
        for (uint256 i = 0; i < locks[account].length; i++) {
            if (locks[account][i].amount == amount) {
                releaseTime = locks[account][i].releaseTime;
                break;
            }
        }
        require(releaseTime != 0, "Sopdap AI: tokens not locked");
        require(block.timestamp >= releaseTime, "Sopdap AI: lock duration not reached");
        _transfer(address(this), account, amount);
    }

}

