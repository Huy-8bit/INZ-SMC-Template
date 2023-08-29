// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ExchangeUpgradeable is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    mapping(uint256 => bool) public orderIDUsed;

    event Trade(
        uint256 orderID,
        address[2] fromTo,
        address[2] nftAndToken,
        uint256[2] idAndAmount,
        address[] additionalTokenReceivers,
        uint256[] allAmounts
    );

    event Claim(
        address[2] fromTo,
        address nftAddress,
        uint256[2] idAndAmount
    );

    // constructor() {
    //     _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    // }
    function initialize() public initializer{
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function claimNFT(
        uint256 orderID,
        address[2] calldata fromTo,
        address nftAddress,
        uint256[2] calldata idAndAmount,
        uint256 deadline,
        bytes calldata signature
    ) external payable nonReentrant{
        require(
            hasRole(
                SIGNER_ROLE,
                ECDSAUpgradeable.recover(
                    ECDSAUpgradeable.toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                block.chainid,
                                orderID,
                                fromTo,
                                nftAddress,
                                idAndAmount,
                                deadline
                            )
                        )
                    ),
                    signature
                )
            ),
            "Invalid signature"
        );
        require(deadline >= block.timestamp, "Deadline passed");
        require(!orderIDUsed[orderID], "Order ID already used");
        orderIDUsed[orderID] = true;
        _claim(
            fromTo,
            nftAddress,
            idAndAmount
        );
        emit Claim(            
            fromTo,
            nftAddress,
            idAndAmount
        );
    }

    function trade(
        uint256 orderID,
        address[2] calldata fromTo,
        address[2] calldata nftAndToken,
        uint256[2] calldata idAndAmount,
        address[] calldata additionalTokenReceivers,
        uint256[] calldata allAmounts,
        uint256 deadline,
        bytes calldata signature
    ) external payable nonReentrant {
        require(
            hasRole(
                SIGNER_ROLE,
                ECDSAUpgradeable.recover(
                    ECDSAUpgradeable.toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                block.chainid,
                                orderID,
                                fromTo,
                                nftAndToken,
                                idAndAmount,
                                additionalTokenReceivers,
                                allAmounts,
                                deadline
                            )
                        )
                    ),
                    signature
                )
            ),
            "Invalid signature"
        );
        require(deadline >= block.timestamp, "Deadline passed");
        require(!orderIDUsed[orderID], "Order ID already used");
        orderIDUsed[orderID] = true;
        _trade(
            fromTo,
            nftAndToken,
            idAndAmount,
            additionalTokenReceivers,
            allAmounts
        );
        emit Trade(
            orderID,
            fromTo,
            nftAndToken,
            idAndAmount,
            additionalTokenReceivers,
            allAmounts
        );
    }

    function forceTradeBatch(
        address[2][] calldata fromTo,
        address[2][] calldata nftAndToken,
        uint256[2][] calldata idAndAmount,
        address[][] calldata additionalTokenReceivers,
        uint256[][] calldata allAmounts
    ) external onlyRole(SIGNER_ROLE) {
        require(
            fromTo.length == nftAndToken.length &&
                fromTo.length == idAndAmount.length &&
                fromTo.length == additionalTokenReceivers.length &&
                fromTo.length == allAmounts.length,
            "Non-matching length"
        );
        for (uint256 i; i < fromTo.length; i++) {
            _trade(
                fromTo[i],
                nftAndToken[i],
                idAndAmount[i],
                additionalTokenReceivers[i],
                allAmounts[i]
            );
        }
    }

    function _sum(uint256[] calldata array) private pure returns (uint256) {
        uint256 sum;
        for (uint256 i; i < array.length; i++) {
            sum += array[i];
        }
        return sum;
    }

    function _trade(
        address[2] calldata fromTo,
        address[2] calldata nftAndToken,
        uint256[2] calldata idAndAmount,
        address[] calldata additionalTokenReceivers,
        uint256[] calldata allAmounts
    ) private {
        require(
            additionalTokenReceivers.length == allAmounts.length - 1,
            "Invalid length"
        );
        require(_msgSender() == fromTo[1], "Wrong sender");
        if (nftAndToken[1] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value == _sum(allAmounts), "Wrong payment amount");
            payable(fromTo[0]).transfer(allAmounts[0]);
            for (uint256 i; i < additionalTokenReceivers.length; i++) {
                payable(additionalTokenReceivers[i]).transfer(
                    allAmounts[i + 1]
                );
            }
        } else {
            require(
                msg.value == 0,
                "Cannot send native currency while paying with token"
            );
            IERC20Upgradeable token = IERC20Upgradeable(nftAndToken[1]);
            token.safeTransferFrom(fromTo[1], fromTo[0], allAmounts[0]);
            for (uint256 i; i < additionalTokenReceivers.length; i++) {
                token.safeTransferFrom(
                    fromTo[1],
                    additionalTokenReceivers[i],
                    allAmounts[i + 1]
                );
            }
        }
        if (idAndAmount[1] == 0) {
            IERC721Upgradeable(nftAndToken[0]).safeTransferFrom(
                fromTo[0],
                fromTo[1],
                idAndAmount[0]
            );
        } else {
            IERC1155Upgradeable(nftAndToken[0]).safeTransferFrom(
                fromTo[0],
                fromTo[1],
                idAndAmount[0],
                idAndAmount[1],
                ""
            );
        }
    }

    function _claim(
        address[2] calldata fromTo,
        address nftAddress,
        uint256[2] calldata idAndAmount
    ) private {
        require(_msgSender() == fromTo[1], "Wrong sender");
        if (idAndAmount[1] == 0) {
            IERC721Upgradeable(nftAddress).safeTransferFrom(
                fromTo[0],
                fromTo[1],
                idAndAmount[0]
            );
        } else {
            IERC1155Upgradeable(nftAddress).safeTransferFrom(
                fromTo[0],
                fromTo[1],
                idAndAmount[0],
                idAndAmount[1],
                ""
            );
        }
    }
}
