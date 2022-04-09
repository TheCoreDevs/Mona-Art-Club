// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721.sol";

contract MonaArtClubGallery is Initializable, OwnableUpgradeable {

    struct OnChainListing {
        // uint32 expirationTimestamp;
        uint artistId;
        uint tokenId;
        uint price;
        // uint nonce;
    }

    struct Artist {
        address tokenContract;
        address addr;
        uint percnetage;
    }

    bytes32 public ORDER_TYPEHASH; // = keccak256("Order(address tokenContract,uint32 expirationTimestamp,uint tokenId,uint price)");

    mapping(bytes => bool) usedSigs;
    mapping(uint => bool) _onChainListingsCompleted;

    Artist[] public artists;
    OnChainListing[] public onChainListings;


    event NewArtist(Artist indexed artist, uint id);
    event NewOnChainListing(OnChainListing listing, uint id);

    function initialize(bytes32 orderTypeHash) external initializer {
        ORDER_TYPEHASH = orderTypeHash;
        __Ownable_init();
    }

/*
    function _isMember(address user, bytes memory sig) private view returns(bool, ECDSAUpgradeable.RecoverError) {
        (address result, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(user))), sig);
        return (owner() == result, error);
    }

    function isMember(address user, bytes memory sig) public view returns(bool) {
        (bool result, ) = _isMember(user, sig);
        return result;
    }
*/

/*
    function buyNFT(bytes calldata memberSig, bytes calldata orderSig, Order calldata order) external payable {
        require(isMember(msg.sender, memberSig));
        require(msg.value == order.price, "incorect eth amount payed!");
        require(order.expirationTimestamp >= block.timestamp, "order expired!");
        require(!usedSigs[orderSig], "order sig already used!");
        require(owner() == ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked([order.artistId], order.expirationTimestamp, order.tokenId, order.price, order.nonce))), orderSig));

        usedSigs[orderSig] = true;
        IERC721(order.tokenContract).safeTransferFrom(address(this), msg.sender, order.tokenId);

    }
*/

    function buyNFT(uint onChainListingId) external payable {
        require(!_onChainListingsCompleted[onChainListingId], "Listing was completed or canceled!");
        OnChainListing memory listing = onChainListings[onChainListingId];
        require(listing.price == msg.value, "Ether amount incorrect!");

        Artist memory artist = artists[listing.artistId];

        // split payments
        uint eth = msg.value - ((msg.value * 25) / 1000);
        bool success;

        (success, ) = payable(msg.sender).call{value: (eth * artist.percnetage) / 10_000, gas: 2600}("");
        require(success, "Failed To Send Ether! User has reverted!");

        // complete listing and transfer token
        _onChainListingsCompleted[onChainListingId] = true;
        IERC721(artist.tokenContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);
    }

    function cancelOnChainListing(uint onChainListingId) external onlyOwner {
        require(onChainListingId < onChainListings.length, "On chain listing does not exist!");
        _onChainListingsCompleted[onChainListingId] = true;
    }

    function onChainListNFT(OnChainListing calldata newListing) external onlyOwner {
        onChainListings.push(newListing);
        emit NewOnChainListing(newListing, onChainListings.length - 1);
    }

    function addArtist(Artist calldata artist) external onlyOwner {
        artists.push(artist);
        emit NewArtist(artist, artists.length - 1);
    }

    function getArtist(uint id) external view returns (Artist memory) {
        return artists[id];
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

    function transferNFT(address tokenContract, uint id, address to) external onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), to, id);
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