// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./IImplementation.sol";

interface IDetectNFT {

    function getImplementation(uint256 standardId) external view returns(IImplementation);

    function getStandardLength() external view returns(uint256);

    function performTransfer(
		address nftAddress,
		address from,
		address to,
		uint256 tokenId,
		uint256 amount
	) 	
		external;

    function isOwnerOf(
		address checkingAddress,
		address nftAddress,
		uint256 tokenId,
		uint256 amount
	) 
		external view returns (bool);
    
    function isApproved(
		address owner,
		address spender,
		address nftAddress,
		uint256 tokenId
	) 
		external view returns (bool);
}