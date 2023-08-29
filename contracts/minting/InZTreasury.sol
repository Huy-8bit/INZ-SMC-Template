// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICampaignNFT.sol";
import "./interfaces/IConfiguration.sol";

contract InZTreasury is
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

    // Configurations address
    address public nftConfiguration;

    // Creator contract address
    address public creatorNFT;

    // marketplace address
    address public marketplace;

    // GatewayNFT
    address public gatewayNFT;

    //
    // mapping address collection with (coin token with balance)
    mapping(address => mapping(address => uint256)) internal balanceCreator;

    /**
     *      @dev Define events that contract will emit
     */
    event Withdraw(uint256 amount);
    event SetNewGateway(address oldGatewayNFT, address gatewayNFT);

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
        require(
            IConfiguration(nftConfiguration).getCreatorFromTreasury(
                _collectionAddress
            ) ==
                tx.origin &&
                IConfiguration(nftConfiguration).getCreatorFromTreasury(
                    _collectionAddress
                ) !=
                address(0),
            "permission denied"
        );
        _;
    }

    // modifier to check from Creator contract or not
    modifier onlyFromCreatorOrMarketplace() {
        require(
            msg.sender == creatorNFT || msg.sender == marketplace,
            "Can only call from Creator contract"
        );
        _;
    }

    /**
     *      @dev Modifiers veryfy wallet call is contract GatewayNFT
     */
    modifier notGatewayNFT() {
        require(msg.sender == gatewayNFT, "Proxy contract not allowed");
        _;
    }

    /**
     *      @dev Initialize function
     */
    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);
    }

    /**
     *      @dev Function allows Creator contract send token to Treasury
     */
    function updateBalanceCollection(
        address _collectionAddress,
        address _payToken,
        uint256 _amount
    ) external onlyFromCreatorOrMarketplace {
        balanceCreator[_collectionAddress][_payToken] += _amount;
    }

    /**
     *      @dev Function allows Creator Collection to withdraw Token in contract
     */
    function withdraw(
        uint256 _amount,
        address _collectionAddress,
        address _payToken
    ) external notCreator(_collectionAddress) {
        withdrawToken(_amount, _collectionAddress, _payToken);
    }

    /**
     *      @dev Function allows GatewayNFT contract withdraw and transfer Native Token for creator collection
     */
    function withdrawFromGateway(
        uint256 _amount,
        address _collectionAddress,
        address _payToken
    ) external notCreator(_collectionAddress) notGatewayNFT {
        withdrawToken(_amount, _collectionAddress, _payToken);
    }

    function withdrawToken(
        uint256 _amount,
        address _collectionAddress,
        address _payToken
    ) internal {
        require(
            balanceCreator[_collectionAddress][_payToken] >= _amount,
            "Not enough tokens to withdraw"
        );
        IERC20(_payToken).transfer(msg.sender, _amount);
        balanceCreator[_collectionAddress][_payToken] -= _amount;
        // send fee to INZ [TODO]
        emit Withdraw(_amount);
    }

    /**
     *      @dev Function allows admin set DappCreator contract address
     */
    function setCreator(
        address _creator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        creatorNFT = _creator;
    }

    /**
     *      @dev Function allows admin set marketplace contract address
     */
    function setMarketplace(
        address _marketplace
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketplace = _marketplace;
    }

    /**
     *  @notice Set new GatwayNFT
     */
    function setNewGateway(
        address _gateway
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldGatewayNFT = gatewayNFT;
        gatewayNFT = _gateway;
        emit SetNewGateway(oldGatewayNFT, gatewayNFT);
    }

    /**
     *      @dev Function allows admin set config Configurations address
     */
    function setNftConfiguration(
        address _nftConfiguration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftConfiguration = _nftConfiguration;
    }

    /**
     *      @dev Function allows admin Treasury contract get balance each Collection
     */
    function getBalance(
        address _collectionAddress,
        address _payToken
    ) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return balanceCreator[_collectionAddress][_payToken];
    }

    /**
     *      @dev Function allows Creator get balanace in Treasury contract
     */
    function getBalanceCollection(
        address _collectionAddress,
        address _payToken
    ) external view notCreator(_collectionAddress) returns (uint256) {
        return balanceCreator[_collectionAddress][_payToken];
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
}
