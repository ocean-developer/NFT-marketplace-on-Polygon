//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    //auto-increment field for each token
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; 

    address contractAddress;

    constructor(address marketplaceAddress) ERC721("Diamondverse Tokens", "DVT"){
      contractAddress = marketplaceAddress;  
    }

   
    /// @notice create a new token
    /// @param tokenURI : token URI
    function createToken(string memory tokenURI) public returns(uint) {
        //sets a new token id for the token to be minted
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

    //Change contract on approval for all
        _mint(msg.sender, newItemId); //mints the token
        _setTokenURI(newItemId, tokenURI); //generates the URI
        setApprovalForAll(contractAddress, true); //grants transaction permission to marketplace 
 
       //retun token iD
        return newItemId;

    }
}
