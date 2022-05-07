// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ECDSA.sol";
import "../Ownable.sol";
import "../IERC721.sol";
import "../IERC20.sol";

contract MonaGallery is Ownable {

    mapping(bytes => bool) usedSigs;

    function buyNFT(
        address tokenContract,
        address artistAddr,
        uint tokenId,
        uint price,
        uint percentage,
        uint expirationTimestamp,
        uint nonce,
        bytes calldata sig
    ) external payable {
        require(!usedSigs[sig], "Listing was completed or canceled!");
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            tokenContract,
                            artistAddr,
                            tokenId,
                            price,
                            percentage,
                            expirationTimestamp,
                            nonce   
                        )
                    )

                ), sig
            ) == owner()
        );

        require(expirationTimestamp >= block.timestamp, "Listing expired!");
        require(price == msg.value, "Ether amount incorrect!");

        // split payments
        uint eth = msg.value - ((msg.value * 25) / 1000);
        uint artistAmount = (eth * percentage) / 10_000;
        bool success;

        (success, ) = payable(artistAddr).call{value: artistAmount, gas: 3000}(""); // artist
        require(success, "Failed To Send Ether to artist! User has reverted!");

        eth = (msg.value - artistAmount);
        uint f5 = eth / 4;
        (success, ) = payable(0xAF2992d490E78B94113D44d63E10D1E668b69984).call{value: f5, gas: 3000}(""); // F5
        require(success, "Failed To Send Ether to F5! User has reverted!");
        (success, ) = payable(0x077b813889659Ad54E1538A380584E7a9399ff8F).call{value: eth - f5, gas: 300}(""); // Mona
        require(success, "Failed To Send Ether to Mona! User has reverted!");

        // complete listing and transfer token
        usedSigs[sig] = true;
        IERC721(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // function buyExternalNFT(uint externalOnChainListingId) external payable {
    //     require(!_ExternalOnChainListingsCompleted[externalOnChainListingId], "Listing was completed or canceled!");
    //     OnChainExternalNFTListing memory listing = onChainExternalNFTListings[externalOnChainListingId];
    //     require(listing.expirationTimestamp >= block.timestamp, "Listing expired!");
    //     require(listing.price == msg.value, "Ether amount incorrect!");

    //     // split payments
    //     uint eth = msg.value - ((msg.value * 25) / 1000);
    //     uint artistAmount = (eth * 85) / 100;
    //     bool success;

    //     (success, ) = payable(listing.artistAddr).call{value: artistAmount, gas: 2600}(""); // artist
    //     require(success, "Failed To Send Ether to artist! User has reverted!");

    //     eth = msg.value - artistAmount;
    //     (success, ) = payable(0xAF2992d490E78B94113D44d63E10D1E668b69984).call{value: eth / 4, gas: 2600}(""); // F5
    //     require(success, "Failed To Send Ether to F5! User has reverted!");
    //     (success, ) = payable(0x077b813889659Ad54E1538A380584E7a9399ff8F).call{value: (eth / 4) * 3, gas: 2600}(""); // Mona
    //     require(success, "Failed To Send Ether to Mona! User has reverted!");

    //     // complete listing and transfer token
    //     _ExternalOnChainListingsCompleted[externalOnChainListingId] = true;
    //     activeExternalOnChainListings--;
    //     IERC721(listing.tokenContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);
    // }

    // function hashStruct(Order memory order) private pure returns (bytes32 hash) {
    //     return keccak256(abi.encode(
    //         /* ORDER_TYPEHASH */ keccak256("Order(address tokenContract,uint expirationTimestamp,uint tokenId,uint price)"),
    //         order.tokenContract,
    //         order.expirationTimestamp,
    //         order.tokenId,
    //         order.price
    //     ));
    // }

    function cancelListing(bytes calldata listingSig) external onlyOwner {
        usedSigs[listingSig] = true;
    }

    function transferNFT(address tokenContract, uint id, address to) external onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), to, id);
    }

    function transferERC20(IERC20 tokenContract) external onlyOwner {
        tokenContract.transfer(msg.sender, tokenContract.balanceOf(msg.sender));
    }

/*
    function getMsgOrderHash(Order calldata order) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(order.tokenContract, order.expirationTimestamp, order.tokenId, order.price, order.nonce));
    }
*/

    function withdraw() external onlyOwner {
        uint bal = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: bal, gas: 2600}("");
        require(success, "Failed To Send Ether! User has reverted!");
    }
}