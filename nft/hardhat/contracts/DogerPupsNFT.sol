// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IERC20.sol";

contract DogerPupsNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string _baseTokenURI;
    IERC20 public DGIToken;

    uint256 public _price = 1000000000000000000; //Price is 1 DGI token

    bool public _paused;

    uint256 public maxTokenIds = 10;

    uint256 public tokenIds;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor (string memory baseURI, address _DGIContract) ERC721("Doger Pups NFT", "DGP") {
        _baseTokenURI = baseURI;
        DGIToken = IERC20(_DGIContract);
    }

    function mint(uint256 _tokenID) public onlyWhenNotPaused {
        require(tokenIds < maxTokenIds, "Exceed maximum Doger pups supply");
        require(_tokenID <= maxTokenIds && _tokenID > 0, "NFT doesn't exist, max 10 pups can be minted");
        require(!_exists(_tokenID), "NFT already minted"); //shouldnt this be first checked?
        require(DGIToken.allowance(msg.sender, address(this)) >= _price, "Please approve Doger Inu Tokens before minting");
        //transfer DGI from msg.sender to address(this)
        DGIToken.transferFrom(msg.sender, address(this), _price);
        tokenIds += 1;
        _safeMint(msg.sender, _tokenID);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        // Here it checks if the length of the baseURI is greater than 0, if it is return the baseURI and attach
        // the tokenId and `.json` to it so that it knows the location of the metadata json file for a given
        // tokenId stored on IPFS
        // If baseURI is empty return an empty string
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawDGI() public onlyOwner returns (bool success){
        DGIToken.transfer(owner(), DGIToken.balanceOf(address(this)));
        return true;
    }

    function withdraw() public onlyOwner  {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    fallback() external payable {}
}