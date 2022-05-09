// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../ECDSA.sol";
import "../Ownable.sol";
import "../IERC721.sol";
import "../IERC20.sol";

contract MonaGallery is Ownable {

    mapping(bytes => bool) usedSigs;

    event NftSold(address to, address tokenContract, uint tokenId, uint price);

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
        address contractOwner = owner();
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
            ) == contractOwner
        );

        require(expirationTimestamp >= block.timestamp, "Listing expired!");
        require(price == msg.value, "Ether amount incorrect!");

        usedSigs[sig] = true;

        // split payments
        uint eth = msg.value - (msg.value / 40); // 2.5%
        uint artistAmount = (eth * percentage) / 10_000;
        bool success;

        (success, ) = payable(artistAddr).call{value: artistAmount, gas: 3000}(""); // artist
        require(success, "Failed To Send Ether to artist! User has reverted!");

        eth = (msg.value - artistAmount);
        uint f5 = eth / 4;
        (success, ) = payable(0xAF2992d490E78B94113D44d63E10D1E668b69984).call{value: f5, gas: 2300}(""); // F5
        require(success, "Failed To Send Ether to F5! User has reverted!");
        (success, ) = payable(0x077b813889659Ad54E1538A380584E7a9399ff8F).call{value: eth - f5, gas: 2300}(""); // Mona
        require(success, "Failed To Send Ether to Mona! User has reverted!");

        // send NFT
        IERC721(tokenContract).safeTransferFrom(contractOwner, msg.sender, tokenId);

        emit NftSold(msg.sender, tokenContract, tokenId, price);
    }

    function cancelListing(bytes calldata listingSig) external onlyOwner {
        usedSigs[listingSig] = true;
    }

    /**
     * @dev to be used to save nfts that were sent to this address
     */
    function transferNFT(address tokenContract, uint id, address to) external onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), to, id);
    }

    /**
     * @dev to be used to save erc20 tokens that were sent to this address
     */
    function transferERC20(IERC20 tokenContract) external onlyOwner {
        require(tokenContract.transfer(msg.sender, tokenContract.balanceOf(msg.sender)), "Transfer Failed!");
    }

    /**
     * @dev in case eth gets locked in the contract
     */
    function withdraw() external onlyOwner {
        uint bal = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: bal, gas: 3000}("");
        require(success, "Failed To Send Ether! User has reverted!");
    }

    function getMsg(
        address tokenContract,
        address artistAddr,
        uint tokenId,
        uint price,
        uint percentage,
        uint expirationTimestamp,
        uint nonce
    ) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            tokenContract,
            artistAddr,
            tokenId,
            price,
            percentage,
            expirationTimestamp,
            nonce
        ));
    }
}
