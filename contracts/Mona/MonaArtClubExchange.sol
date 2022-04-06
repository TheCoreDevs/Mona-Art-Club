// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract MonaArtClubExchange is Initializable, OwnableUpgradeable {

    struct Order {
        address tokenContract;
        uint32 expirationTimestamp;
        uint tokenId;
        uint price;
        uint nonce;
    }

    bytes32 public ORDER_TYPEHASH; // = keccak256("Order(address tokenContract,uint32 expirationTimestamp,uint tokenId,uint price)");

    mapping(bytes => bool) usedSigs;

    function initialize(bytes32 orderTypeHash) external initializer {
        ORDER_TYPEHASH = orderTypeHash;
        __Ownable_init();
    }

    function _isMember(address user, bytes memory sig) private view returns(bool, ECDSAUpgradeable.RecoverError) {
        (address result, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(user))), sig);
        return (owner() == result, error);
    }

    function isMember(address user, bytes memory sig) public view returns(bool) {
        (bool result, ) = _isMember(user, sig);
        return result;
    }

    function buyNFT(bytes calldata memberSig, bytes calldata orderSig, Order calldata order) external payable {
        require(isMember(msg.sender, memberSig));
        require(msg.value == order.price);
        require(order.expirationTimestamp >= block.timestamp);
        require(!usedSigs[orderSig]);
        require(owner() == ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(order.tokenContract, order.expirationTimestamp, order.tokenId, order.price, order.nonce))), orderSig));

        

    }

    // function hashStruct(Order memory order) private pure returns (bytes32 hash) {
    //     return keccak256(abi.encode(
    //         /* ORDER_TYPEHASH */ keccak256("Order(address tokenContract,uint32 expirationTimestamp,uint tokenId,uint price)"),
    //         order.tokenContract,
    //         order.expirationTimestamp,
    //         order.tokenId,
    //         order.price
    //     ));
    // }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance, gas: 2600}("");
        require(success, "Failed To Send Ether! User has reverted!");
    }
}