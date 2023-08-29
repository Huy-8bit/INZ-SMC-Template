// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract InZPos is
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    
    /**
     *      @dev Define variables in contract
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");


    // 
    // mapping address collection with (coin token with balance)
    mapping(address => uint256) internal balancePos;

    /**
     *      @dev Define events that contract will emit
     */
    event PosWithdraw(address toAddress, uint256 amount);
    event PosDeposit(address fromAddress, address tokenAddress, uint256 amount, string callBackData);
    event PosTransfer(address toAddress, address tokenAddress, uint256 amount);

    /**
     *      @dev Modifiers using in contract
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     *      @dev Modifiers check msg.sender is Creator
     */
    modifier notCreator(address _collectionAddress) {
        // require(
        //     IConfiguration(nftConfiguration).getCreatorFromTreasury(_collectionAddress) == tx.origin &&  
        //     IConfiguration(nftConfiguration).getCreatorFromTreasury(_collectionAddress) != address(0), 
        //     "permission denied"
        // );
        _;
    }

    function initialize() public initializer{
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);
        _setupRole(TRANSFER_ROLE, msg.sender);
    }

    /**
     *      @dev Function allow wallet with TRANSFER_ROLE can tranfer token from contract to another
     */
    function transferToken(
        address _toAddress,
        address _tokenAddress,
        uint256 _amount
    ) external onlyRole(TRANSFER_ROLE) {
        transfer(
            _toAddress,
            _tokenAddress,
            _amount
        );
    }

    /**
     *      @dev Function allow wallet with WITHDRAW_ROLE can withdraw token
     */
    function withdrawToken(
        address _tokenAddress,
        uint256 _amount
    ) external onlyRole(WITHDRAW_ROLE) {
        withdraw(
            _amount,
            _tokenAddress
        );
    }

    /**
     *      @dev Function use for user deposit to contract and emit event for backend handle transaction from POS
     */
    function depositToken(
        address _tokenAddress,
        uint256 _amount,
        string memory _callBackData
    ) external notContract {
        deposit(_tokenAddress, _amount, _callBackData);
    }

    /**
     *     @dev Function allows admin Treasury contract get balance each Collection
     */
    function getBalance(
        address _tokenAddress
    ) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256){
        return balancePos[_tokenAddress];
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // Internal

    function withdraw(
        uint256 _amount,
        address _tokenAddress
    ) internal {
        require(
            balancePos[_tokenAddress] >= _amount, 
            "Not enough tokens to withdraw"
        );
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
        balancePos[_tokenAddress] -= _amount;
        emit PosWithdraw(msg.sender, _amount); 
    }

    function transfer(
        address _toAddress,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        require(
            balancePos[_tokenAddress] >= _amount, 
            "Not enough tokens to transfer"
        );
        IERC20(_tokenAddress).transfer(_toAddress, _amount);
        balancePos[_tokenAddress] -= _amount;
        emit PosTransfer(_toAddress, _tokenAddress, _amount); 
    }

    function deposit(
        address _tokenAddress,
        uint256 _amount,
        string memory _callBackData
    ) internal {
        require(
            IERC20(_tokenAddress).balanceOf(msg.sender) >= _amount,
            "Not enough tokens to deposit"
        );

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        balancePos[_tokenAddress] += _amount;
        emit PosDeposit(msg.sender, _tokenAddress, _amount, _callBackData);
    }
}
