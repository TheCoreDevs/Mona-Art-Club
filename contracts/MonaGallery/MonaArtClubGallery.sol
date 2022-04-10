// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721.sol";

contract MonaArtClubGallery is Initializable, OwnableUpgradeable {

    struct OnChainListing {
        uint32 expirationTimestamp;
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

    struct OnChainExternalNFTListing {
        address tokenContract;
        address artistAddr;
        uint tokenId;
        uint price;
        uint expirationTimestamp;
    }

    bytes32 public ORDER_TYPEHASH; // = keccak256("Order(address tokenContract,uint32 expirationTimestamp,uint tokenId,uint price)");

    mapping(bytes => bool) usedSigs;
    mapping(uint => bool) _onChainListingsCompleted;
    mapping(uint => bool) _ExternalOnChainListingsCompleted;


    Artist[] public artists;
    OnChainListing[] public onChainListings;
    OnChainExternalNFTListing[] public onChainExternalNFTListings;

    uint public activeOnChainListings;
    uint public activeExternalOnChainListings;


    event NewArtist(address tokenContract, address addr, uint percnetage, uint artistId);
    event NewOnChainListing(uint32 expirationTimestamp, uint artistId, uint tokenId, uint price, uint listingId);
    event NewExternalOnChainListing(address tokenContract, address artistAddr, uint tokenId, uint price, uint expirationTimestamp, uint externalListingId);

    function initialize(uint8 version) external reinitializer(version) {
        // ORDER_TYPEHASH = orderTypeHash;
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
        require(listing.expirationTimestamp >= block.timestamp, "Listing expired!");
        require(listing.price == msg.value, "Ether amount incorrect!");

        Artist memory artist = artists[listing.artistId];

        // split payments
        uint eth = msg.value - ((msg.value * 25) / 1000);
        uint artistAmount = (eth * artist.percnetage) / 10_000;
        bool success;

        (success, ) = payable(artist.addr).call{value: artistAmount, gas: 2600}(""); // artist
        require(success, "Failed To Send Ether to artist! User has reverted!");

        eth = msg.value - artistAmount;
        (success, ) = payable(0xAF2992d490E78B94113D44d63E10D1E668b69984).call{value: eth / 4, gas: 2600}(""); // F5
        require(success, "Failed To Send Ether to F5! User has reverted!");
        (success, ) = payable(0x077b813889659Ad54E1538A380584E7a9399ff8F).call{value: (eth / 4) * 3, gas: 2600}(""); // Mona
        require(success, "Failed To Send Ether to Mona! User has reverted!");

        // complete listing and transfer token
        _onChainListingsCompleted[onChainListingId] = true;
        activeOnChainListings--;
        IERC721(artist.tokenContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);
    }

    function buyExternalNFT(uint externalOnChainListingId) external payable {
        require(!_ExternalOnChainListingsCompleted[externalOnChainListingId], "Listing was completed or canceled!");
        OnChainExternalNFTListing memory listing = onChainExternalNFTListings[externalOnChainListingId];
        require(listing.expirationTimestamp >= block.timestamp, "Listing expired!");
        require(listing.price == msg.value, "Ether amount incorrect!");

        

        // split payments
        uint eth = msg.value - ((msg.value * 25) / 1000);
        uint artistAmount = (eth * 85) / 100;
        bool success;

        (success, ) = payable(listing.artistAddr).call{value: artistAmount, gas: 2600}(""); // artist
        require(success, "Failed To Send Ether to artist! User has reverted!");

        eth = msg.value - artistAmount;
        (success, ) = payable(0xAF2992d490E78B94113D44d63E10D1E668b69984).call{value: eth / 4, gas: 2600}(""); // F5
        require(success, "Failed To Send Ether to F5! User has reverted!");
        (success, ) = payable(0x077b813889659Ad54E1538A380584E7a9399ff8F).call{value: (eth / 4) * 3, gas: 2600}(""); // Mona
        require(success, "Failed To Send Ether to Mona! User has reverted!");

        // complete listing and transfer token
        _ExternalOnChainListingsCompleted[externalOnChainListingId] = true;
        activeExternalOnChainListings--;
        IERC721(listing.tokenContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);
    }

    function cancelOnChainListing(uint onChainListingId) external onlyOwner {
        require(onChainListingId < onChainListings.length, "On chain listing does not exist!");
        require(!_onChainListingsCompleted[onChainListingId], "Already Completed Or Canceled!");
        _onChainListingsCompleted[onChainListingId] = true;
        activeOnChainListings--;
    }

    function cancelOnChainExternalListing(uint onChainExternalListingId) external onlyOwner {
        require(onChainExternalListingId < onChainListings.length, "On chain listing does not exist!");
        require(!_ExternalOnChainListingsCompleted[onChainExternalListingId], "Already Completed Or Canceled!");
        _ExternalOnChainListingsCompleted[onChainExternalListingId] = true;
        activeExternalOnChainListings--;

    }

    function onChainListNFT(uint32 expirationTimestamp, uint artistId, uint tokenId, uint price) external onlyOwner {
        onChainListings.push(OnChainListing(expirationTimestamp, artistId, tokenId, price));
        activeOnChainListings++;
        emit NewOnChainListing(expirationTimestamp, artistId, tokenId, price, onChainListings.length - 1);
    }

    function onChainListExternalNFT(address tokenContract, address artistAddr, uint tokenId, uint price, uint expirationTimestamp) external onlyOwner {
        onChainExternalNFTListings.push(OnChainExternalNFTListing(tokenContract, artistAddr, tokenId, price, expirationTimestamp));
        activeExternalOnChainListings++;
        emit NewExternalOnChainListing(tokenContract, artistAddr, tokenId, price, expirationTimestamp, onChainExternalNFTListings.length - 1);
    }

    function addArtist(address tokenContract, address addr, uint percnetage) external onlyOwner {
        artists.push(Artist(tokenContract, addr, percnetage));
        emit NewArtist(tokenContract, addr, percnetage, artists.length - 1);
    }

    function getArtist(uint id) external view returns (address tokenContract, address addr, uint percnetage) {
        Artist memory artist = artists[id];
        return (artist.tokenContract, artist.addr, artist.percnetage);
    }

    function getOnChainListing(uint id) external view returns(uint32 expirationTimestamp, uint artistId, uint tokenId, uint price) {
        OnChainListing memory listing = onChainListings[id];
        return (listing.expirationTimestamp, listing.artistId, listing.tokenId, listing.price);
    }

    function getOnChainExternalNFTListing(uint id) external view returns(address tokenContract, address artistAddr, uint tokenId, uint price, uint expirationTimestamp) {
        OnChainExternalNFTListing memory listing = onChainExternalNFTListings[id];
        return (listing.tokenContract, listing.artistAddr, listing.tokenId, listing.price, listing.expirationTimestamp);
    }

    function getAllActiveOnChainListingIds() external view returns(uint[] memory) {
        uint[] memory listings = new uint[](activeOnChainListings);
        uint x;

        for (uint i; i < onChainListings.length; i++) {
            if (!_onChainListingsCompleted[i]) {
                listings[x] = i;
                x++;
            }
        }
        return listings;
    }

    function getAllActiveOnChainExternalListingIds() external view returns(uint[] memory) {
        uint[] memory listings = new uint[](activeExternalOnChainListings);
        uint x;

        for (uint i; i < onChainExternalNFTListings.length; i++) {
            if (!_ExternalOnChainListingsCompleted[i]) {
                listings[x] = i;
                x++;
            }
        }
        return listings;
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