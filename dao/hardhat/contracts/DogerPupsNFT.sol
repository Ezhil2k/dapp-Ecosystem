//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DogerPupsNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string _baseTokenURI;
    IERC20 public DGIToken;

    uint256 public _price = 1000000000000000000; //price is 1 DGI token

    bool public _paused;

    uint256 public maxTokenIds = 10;

    uint256 public tokenIds;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor(string memory baseURI, address _DGIContract) ERC721("Doger Pups NFT", "DGP"){
        _baseTokenURI = baseURI;
        DGIToken = IERC20(_DGIContract);
    }

    function mint(uint256 _tokenID) public onlyWhenNotPaused {
        require(tokenIds < maxTokenIds, "Exceeds maximum Doger pups supply");
        require(_tokenID <= maxTokenIds && _tokenID > 0, "NFT doesn't exist, max 10 pups can be minted");
        require(!_exists(_tokenID), "NFT already exists");
        require(DGIToken.allowance(msg.sender, address(this)) >= _price, "Please approve Doger Inu Token before minting");

        DGIToken.transferFrom(msg.sender, address(this), _price);
        tokenIds += 1;
        _safeMint(msg.sender, _tokenID);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawDGI() public onlyOwner returns (bool success) {
        DGIToken.transfer(owner(), DGIToken.balanceOf(address(this)));
        return true;
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send ether");
    }

    receive() external payable {}
    fallback() external payable {}
}