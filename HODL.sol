/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract HODL is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    
    IBEP20 public _PRBToken;
    IBEP20 public _BUSD;
    address public _signer;
    uint256 public _weeklyReward;
    uint256 public _monthlyReward;
    uint256 public _adminDeposit;
    
    uint256 public _depositFee;
    uint256 public _withdrawFee;
    
    address public _feeWallet;
    
    struct UserInfo{
        uint256 depositAmount;
        uint256 lastDepositTime;
        uint256 lastWithdrawTime;
        uint256 lastClaim;
        bool depositor;
    }
    
    mapping (address => UserInfo) public userDetails;
    mapping (bytes32 => bool) public hashVerify;
    
    event Deposit(address indexed Depositor);
    event Withdraw(address indexed Depositor,uint256 indexed widthdrawTime, uint256 indexed withdrawAmount);
    event ClaimAmount(address indexed user, uint256 indexed tokenAmount, uint256 indexed claimingTime, uint256 No_Of_times);
    event AdminDeposit(address indexed owner, uint256 indexed tokenAmount);
    event FailSafe(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenAmount);
    event UpdateReward(address indexed owner, uint256 indexed weeklyReward, uint256 indexed monthlyReward);
    event UpdateSigner(address indexed owner, address indexed newSigner);
    event UpdateFeeWallet(address indexed Owner, address indexed newWalletAddress);
    event UpdateFees(address indexed Owner, uint256 indexed DepositFee, uint256 indexed WithdrawFee);
    event UpdateBUSD(address indexed Owner, address indexed BUSD );
    
    constructor (uint256 weeklyReward, uint256 monthlyReward, address signer, address PRBToken,address BUSD,address wallet){
        require(signer != address(0),"signer address must not be a zero address");
        _weeklyReward = weeklyReward;
        _monthlyReward = monthlyReward;
        _signer = signer;
        _PRBToken = IBEP20(PRBToken);
        _BUSD = IBEP20(BUSD);
        _feeWallet = wallet;
        
        _depositFee = 1e15;
        _withdrawFee = 1e15;
    }
    
    function updateWalletAddress(address wallet)external onlyOwner{
        require(wallet != address(0),"wallet address should not be a zero");
        _feeWallet = wallet;
        emit UpdateFeeWallet(msg.sender, wallet);
    }
    
    function updateFees(uint256 depositFee, uint256 withdrawFee) external onlyOwner{
        _depositFee = depositFee;
        _withdrawFee = withdrawFee;
        emit UpdateFees(msg.sender, depositFee, withdrawFee);
    }
    
    function deposit(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Invalid deposit amount");
        require(msg.value >= _depositFee,"Invalid deposit fee");
        UserInfo storage  user = userDetails[msg.sender];
        user.depositAmount = user.depositAmount.add(amount);
        user.lastDepositTime = block.timestamp;
        
        _PRBToken.transferFrom(msg.sender, address(this),amount);
        require(payable(_feeWallet).send(msg.value),"Fee transaction failed");
        
        if(!user.depositor){
            user.depositor = true;
            emit Deposit(msg.sender);
        }
    }
    
    function withdraw(uint256 amount) external payable nonReentrant {
        require(msg.value >= _withdrawFee,"Invalid withdraw fee");
        UserInfo storage  user = userDetails[msg.sender];
        require(user.depositAmount >= amount,"Withdraw amount exceed");
        user.depositAmount = user.depositAmount.sub(amount);
        user.lastWithdrawTime = block.timestamp;
        
        _PRBToken.transfer(msg.sender,amount);
        require(payable(_feeWallet).send(msg.value),"Fee transaction failed");
        
        emit Withdraw(msg.sender, block.timestamp, amount);
    }
    
    function claim(uint256 rewardType, uint256 blockTime, uint256 count, uint8 v, bytes32 r, bytes32 s) external nonReentrant returns(bool){
        require(rewardType > 0 && rewardType < 3,"Claim :: Invalid reward Type");
        require(count > 0,"Claim :: Invalid count");
        UserInfo storage  user = userDetails[msg.sender];
        require(user.depositor,"Claim :: caller not depositor");
        require(blockTime >= block.timestamp,"Claim :: Signature Expiry");
        uint256 amount;
        if(rewardType == 1){
            require(_weeklyReward > 0,"Claim :: WeeklyReward disable");
            amount = _weeklyReward; 
        }else if(rewardType == 2){
            require(_monthlyReward > 0,"Claim :: MonthlyReward disable");
            amount = _monthlyReward;
        }
        
        bytes32 msgHash = toSigEthMsg(msg.sender, rewardType, blockTime, count);
        require(!hashVerify[msgHash],"Claim :: signature already used");
        require(verifySignature(msgHash, v,r,s) == _signer,"Claim :: not a signer address");
        uint256 claimAmount = amount.mul(count);
        hashVerify[msgHash] = true;
        user.lastClaim = block.timestamp;
        _adminDeposit = _adminDeposit.sub(claimAmount,"Claim :: Reward amount exceed in contract");
        _BUSD.transfer(msg.sender, claimAmount);
        emit ClaimAmount(msg.sender, claimAmount, block.timestamp, count);
        return true;
    }
    
    function updateBUSD(address _newBUSD)external onlyOwner{
        _BUSD = IBEP20(_newBUSD);
        emit UpdateBUSD(msg.sender, _newBUSD);
    }
    
    function updateRewardAmount(uint256 weeklyReward,uint256 monthlyReward) external onlyOwner{
        _weeklyReward = weeklyReward;
        _monthlyReward = monthlyReward;
        
        emit UpdateReward(msg.sender, weeklyReward, monthlyReward);
    }
    
    function setSigner(address signer)external onlyOwner{
        require(signer != address(0),"signer address not Zero address");
        _signer = signer;
        
        emit UpdateSigner(msg.sender, signer);
    }
    
    function verifySignature(bytes32 msgHash, uint8 v,bytes32 r, bytes32 s)public pure returns(address signerAdd){
        signerAdd = ecrecover(msgHash, v, r, s);
    }
    
    function toSigEthMsg(address user, uint256 rewardType, uint256 blockTime, uint256 count)internal view returns(bytes32){
        bytes32 hash = keccak256(abi.encodePacked(abi.encodePacked(user, rewardType, blockTime, count),address(this)));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function adminDeposit(uint256 tokenAmount)external onlyOwner {
        _adminDeposit = _adminDeposit.add(tokenAmount);
        _BUSD.transferFrom(msg.sender,address(this),tokenAmount);
        emit AdminDeposit(msg.sender, tokenAmount);
    }
    
    function failSafe(address token, address to, uint256 amount)external onlyOwner{
        if(token == address(0x0)){
            payable(to).transfer(amount);
        } else  {
            IBEP20(token).transfer(to, amount);
        }
        emit FailSafe(to, token, amount);
    }
}
