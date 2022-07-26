// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title NFT Smart Contract
 * @notice This contract handles minting of ERC721 tokens.
 */
contract NFT is ERC721A, ReentrancyGuard, Ownable, Pausable {

    using ECDSA for bytes32;
    using Strings for uint256;

    // Internal vars
    address account1;
    address account2;

    // Public vars
    string public baseTokenURI;
    uint256 public price = 0.125 ether;

    // Immutable vars
    uint256 public immutable maxSupply;

    // Used to validate authorized mint addresses
    address private signerAddress;

    mapping (address => uint256) public totalMintsPerAddress;

    bool public isSaleActive = false;

    /**
     * @notice Construct a NFT instance
     * @param name Token name
     * @param symbol Token symbol
     * @param baseTokenURI_ Base URI for all tokens
     * @param maxSupply_ Max Supply of tokens
     */
    constructor(string memory name, string memory symbol, string memory baseTokenURI_, uint256 maxSupply_) ERC721A(name, symbol) {
        require(maxSupply_ > 0, "INVALID_SUPPLY");
        baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * To be updated by contract owner to allow updating the mint price
     */
    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        require(price != _newMintPrice, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        price = _newMintPrice;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }
}
