// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICampaignNFT.sol";
import "./interfaces/IConfiguration.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IDappCreator.sol";

contract DaapNFTCreator is
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
    // IDappCreator
{
    using SafeERC20 for IERC20;

    /**
     *      @dev Define variables in contract
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    // Signer for mint with signature
    address public signer;

    // Configurations address
    address public nftConfiguration;

    // InZTreasury;
    address public inZTreasury;

    // GatewayNFT
    address public gatewayNFT;

    // Platform Fee Wallet
    address public platformFeeAddress;

    /**
     *      @dev Define events that contract will emit
     */
    event SetNewSigner(address oldSigner, address newSigner);
    event SetNewTreasury(address oldTreasury, address newTreasury);
    event SetNewGateway(address oldGatewayNFT, address gatewayNFT);
    event UpdatePrice(address nftCollection, uint8 rarity, uint256 newPrice);
    event MakingMintingAction(
        uint8 nftType,
        uint256 amount,
        uint256 payAmount,
        uint256 discount,
        uint256 platformFee,
        address to,
        address _payToken
    );
    event SetNewPayToken(
        address oldPayToken,
        address newPayToken,
        address creator
    );
    event SetNewCreatorCollection(
        address oldCreator,
        address newCreator,
        address collection
    );
    event AddNewCollection(address nftCollection, uint256[] prices);
    event SetNewPlatformFeeAddress(address oldAddress, address newAddress);

    /**
     *      @dev Modifiers using in contract
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     *      @dev Modifiers verify msg.sender is Creator
     */
    modifier notCreator(address _collectionAddress) {
        require(
            IConfiguration(nftConfiguration).getCreatorCollection(
                _collectionAddress
            ) ==
                tx.origin ||
                IConfiguration(nftConfiguration).getCreatorCollection(
                    _collectionAddress
                ) !=
                address(0),
            "permission denied"
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
     *      @dev Contructor
     */
    constructor(address _signer) {
        signer = _signer;
    }

    /**
     *      @dev Initialize function
     */
    function initialize(
        address _nftConfiguration,
        address _treasury,
        address _gatewayNFT,
        address _plaformFeeAddress
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);
        nftConfiguration = _nftConfiguration;
        inZTreasury = _treasury;
        gatewayNFT = _gatewayNFT;
        platformFeeAddress = _plaformFeeAddress;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     *  @notice Function allows Creator Collection to set new PayToken
     */
    function setPayToken(
        address _newPayToken,
        address _collectionAddress
    ) external notCreator(_collectionAddress) {
        address _oldPayToken = IConfiguration(nftConfiguration)
            .getPayTokenCollection(_collectionAddress);
        IConfiguration(nftConfiguration).updatePayTokenCollection(
            _collectionAddress,
            _newPayToken
        );
        emit SetNewPayToken(_oldPayToken, _newPayToken, msg.sender);
    }

    /**
     *  @notice Function allows Creator Collection to set new Creator
     */
    function updateCreatorCollection(
        address _newCreator,
        address _collectionAddress
    ) external notCreator(_collectionAddress) {
        IConfiguration(nftConfiguration).updateCreatorCollection(
            _newCreator,
            _collectionAddress
        );
        emit SetNewCreatorCollection(
            msg.sender,
            _newCreator,
            _collectionAddress
        );
    }

    /**
     *  @notice Set new signer who confirm a call from daap
     */
    function setNewSigner(address _newSigner) external onlyRole(UPGRADER_ROLE) {
        address oldSigner = signer;
        signer = _newSigner;
        emit SetNewSigner(oldSigner, _newSigner);
    }

    /**
     *  @notice Set new treasury
     */
    function setNewTreasury(
        address _treasury
    ) external onlyRole(UPGRADER_ROLE) {
        address oldInZTreasury = inZTreasury;
        inZTreasury = _treasury;
        emit SetNewTreasury(oldInZTreasury, _treasury);
    }

    /**
     *  @notice Set new GatwayNFT
     */
    function setNewGateway(address _gateway) external onlyRole(UPGRADER_ROLE) {
        address oldGatewayNFT = gatewayNFT;
        gatewayNFT = _gateway;
        emit SetNewGateway(oldGatewayNFT, gatewayNFT);
    }

    /**
     *  @notice Reset the platform fee wallet
     */
    function setPlatformFee(
        address _newPlaformFee
    ) external onlyRole(UPGRADER_ROLE) {
        require(
            platformFeeAddress != _newPlaformFee,
            "New Platform Fee Address must be different"
        );
        address oldAddress = platformFeeAddress;
        platformFeeAddress = _newPlaformFee;
        emit SetNewPlatformFeeAddress(oldAddress, _newPlaformFee);
    }

    /**
     *  @notice Function return chainID of current implemented chain
     */
    function getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     *      @notice Function verify signature from daap sent out
     */
    function verifySignature(
        address _signer,
        address _nftCollection,
        uint256 _discount,
        bool _isWhitelistMint,
        uint8 _nftType,
        uint256 _amount,
        uint256 _platformFee,
        IDappCreator.Proof memory _proof
    ) private view returns (bool) {
        if (_signer == address(0x0)) {
            return true;
        }
        bytes32 digest = keccak256(
            abi.encode(
                getChainID(),
                tx.origin,
                address(this),
                _nftCollection,
                _discount,
                _isWhitelistMint,
                _nftType,
                _amount,
                _platformFee,
                _proof.deadline
            )
        );
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory == _signer && _proof.deadline >= block.timestamp;
    }

    /**
     *  @notice Function allow call external from daap to make miting action
     *
     */
    function makeMintingAction(
        ICampaignNFT _nftCollection,
        uint8 _nftType,
        uint256 _amount,
        uint256 _discount,
        uint256 _platformFee,
        bool _isWhitelistMint,
        IDappCreator.Proof memory _proof,
        string memory _callbackData,
        address _to
    ) external payable notContract {
        verifyAndMint(
            _nftCollection,
            _nftType,
            _amount,
            _discount,
            _platformFee,
            _isWhitelistMint,
            _proof,
            _callbackData,
            _to
        );
    }

    /**
     *  @notice Function allow call external from GatewayNFT to make miting action
     *
     */
    function mintingFromGateway(
        ICampaignNFT _nftCollection,
        uint8 _nftType,
        uint256 _amount,
        uint256 _platformFee,
        uint256 _discount,
        bool _isWhitelistMint,
        IDappCreator.Proof memory _proof,
        string memory _callbackData,
        address _to
    ) external payable notGatewayNFT {
        verifyAndMint(
            _nftCollection,
            _nftType,
            _amount,
            _discount,
            _platformFee,
            _isWhitelistMint,
            _proof,
            _callbackData,
            _to
        );
    }

    function verifyAndMint(
        ICampaignNFT _nftCollection,
        uint8 _nftType,
        uint256 _amount,
        uint256 _discount,
        uint256 _platformFee,
        bool _isWhitelistMint,
        IDappCreator.Proof memory _proof,
        string memory _callbackData,
        address _to
    ) internal {
        require(_amount > 0, "Amount of minting NFTs must be greater than 0");
        require(
            IConfiguration(nftConfiguration).checkValidMintingAttributes(
                address(_nftCollection),
                _nftType
            ),
            "Invalid NFT Type"
        );
        require(
            verifySignature(
                signer,
                address(_nftCollection),
                _discount,
                _isWhitelistMint,
                _nftType,
                _amount,
                _platformFee,
                _proof
            ),
            "Invalid Signature"
        );
        require(msg.value >= _platformFee, "Not enough platform fee");
        payable(platformFeeAddress).transfer(_platformFee);
        (uint256 _amountPrice, address _payToken) = IConfiguration(
            nftConfiguration
        ).getCollectionPrice(address(_nftCollection), _nftType);
        if (_amountPrice > 0) {
            _amountPrice = _amountPrice * _amount;
            _amountPrice = _amountPrice - _discount;
            require(
                IERC20(_payToken).balanceOf(msg.sender) > _amountPrice,
                "User needs to hold enough token to buy this token"
            );
            IERC20(_payToken).transferFrom(
                msg.sender,
                inZTreasury,
                _amountPrice
            );
            ITreasury(inZTreasury).updateBalanceCollection(
                address(_nftCollection),
                _payToken,
                _amountPrice
            );
        }
        _nftCollection.mint(_amount, _nftType, _to, _callbackData);
        emit MakingMintingAction(
            _nftType,
            _amount,
            _amountPrice,
            _discount,
            _platformFee,
            _to,
            _payToken
        );
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
