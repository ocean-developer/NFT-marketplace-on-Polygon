//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//prevents re-entry attacks
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard  {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold; //Keeps track of number of items sold

    address payable owner;  //owner of SContract 
    //artists have to pay to put their NFT on this Marketplace
    //listingprice is per nft 
    uint256 listingPrice = 0.25 ether; 

    constructor(){
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;       
    }

    //a way to access values of the MarketItem struct above by passing an integer ID
    mapping(uint256 => MarketItem) private idMarketItem;

    //log message (when Item is sold)
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    /// @notice function to get listing price 
    function getListingPrice() public view returns (uint256){
        return listingPrice; 
    }

    function setListingPrice(uint _price) public returns(uint){
        if(msg.sender == address(this) ){
            listingPrice = _price;
        }
        return listingPrice;
        
    }

    /// @notice function to create market item
    function createMarketItem(
        address nftContract, 
        uint256 tokenId, 
        uint price) public payable nonReentrant{
        require(price > 0, "Price must be above zero");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idMarketItem[itemId] = MarketItem(
            itemId, 
            nftContract, 
            tokenId, 
            payable(msg.sender), //seller putting the nft up for sale 
            payable(address(0)), //no owner yet (set owner to empty address)
            price,
            false
        );

        //transfer ownership of the nft to the contract itself
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); 

        //log this transaction
        emit MarketItemCreated(
         itemId, 
         nftContract, 
         tokenId, 
         msg.sender, 
         address(0), 
         price, 
         false);

    }


    /// @notice function to create a sale 
        function createMarketSale(
            address nftContract, 
            uint256 itemId) public payable nonReentrant{
                uint price = idMarketItem[itemId].price;
                uint tokenId = idMarketItem[itemId].tokenId;
                
                require(msg.value == price, "Please Submit the askingg price in order to complete purchase");

            //pays the seller the amount
            idMarketItem[itemId].seller.transfer(msg.value);

            //transfers ownership of the nft from the contract itself to the buyer
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);   

            idMarketItem[itemId].owner = payable(msg.sender); //mark that buyer is new owner
            idMarketItem[itemId].sold = true; //mark that nft as been sold 
            _itemsSold.increment(); //increase the total number of items sold by 1
            payable(owner).transfer(listingPrice); //pay owner of the contract the listing price
            
        }

        ///@notice total number of items unsold on our platform
        function fetchMarketItems() public view returns (MarketItem[] memory){
            uint itemCount = _itemIds.current(); //total number of items ever created on platform
            //total number of items are unsold = total items ever created 
            uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
            uint currentIndex = 0;

            MarketItem[] memory items = new MarketItem[](unsoldItemCount);

            //loop through all items ever created 
            for(uint i =0; i < itemCount; i++){
                
                //check if the item has not been sold
                //by checking if the owner field is empty
                if(idMarketItem[i+1].owner == address(0)){
                    //means item has never been sold
                    uint currentId = idMarketItem[i+1].itemId;
                    MarketItem storage currentItem = idMarketItem[currentId];
                    items[currentIndex] = currentItem; 
                    currentIndex += 1;

                }

            }
            return items; //retun array of all unsold items functions cut because memory error
        }

        ///@notice fetch list of NFTS owned by this user 
        function fetchMyNFTs() public view returns (MarketItem[] memory){
            //get total number of items ever created 
            uint totalItemCount = _itemIds.current();

            uint itemCount = 0; 
            uint currentIndex = 0; 

            for(uint i = 0; i < totalItemCount; i++){
                //get only the items that this user has bought/is the owner
                if(idMarketItem[i+1].owner == msg.sender){
                     itemCount += 1; //total length
                }
           } 

           MarketItem[] memory items = new MarketItem[](itemCount);
           for(uint i = 0; i < totalItemCount; i++){
               if(idMarketItem[1+1].owner ==msg.sender){
                   uint currentId = idMarketItem[i+1].itemId; 
                   MarketItem storage currentItem = idMarketItem[currentId];
                   items[currentIndex] = currentItem; 
                   currentIndex += 1; 
               }
           }
           return items; 

        }

        ///@notice fetch list of NFTS owned by this user 
        function fetchItemsCreated() public view returns (MarketItem[] memory){
            //get total number of items ever created 
            uint totalItemCount = _itemIds.current();

            uint itemCount = 0; 
            uint currentIndex = 0; 

            for(uint i = 0; i < totalItemCount; i++){
                //get only the items that this user has bought/is the owner
                if(idMarketItem[i+1].seller == msg.sender){
                     itemCount += 1; //total length
                }
           } 

           MarketItem[] memory items = new MarketItem[](itemCount);
           for(uint i = 0; i < totalItemCount; i++){
               if(idMarketItem[1+1].seller ==msg.sender){
                   uint currentId = idMarketItem[i+1].itemId; 
                   MarketItem storage currentItem = idMarketItem[currentId];
                   items[currentIndex] = currentItem; 
                   currentIndex += 1; 
               }
           }
           return items; 

        }

        

}