// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title NFT Smart Contract
 * @notice This contract handles minting of ERC721 tokens.
 */
contract NFT is ERC721A, ReentrancyGuard, Ownable {

    using ECDSA for bytes32;
    using Strings for uint256;

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

    // events to handle pause or unpause for NFT Sale 
    event Paused();
    event Unpaused();

    // function to pause NFT Sale
    function pauseSale() public onlyOwner {
      isSaleActive = true;
      emit Paused();
    }

    // function to unpause NFT Sale
    function unpauseSale() public onlyOwner {
      isSaleActive = false;
      emit Unpaused();
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

    /**
     * Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender, uint256 maximumAllowedMints) private pure returns (bytes32) {
        return keccak256(abi.encode(sender, maximumAllowedMints));
    }

    /**
     * @notice Allow for minting of tokens up to the maximum allowed for a given address.
     * The address of the sender and the number of mints allowed are hashed and signed
     * with the server's private key and verified here to prove whitelisting status.
     */
    function mint(bytes32 messageHash,bytes calldata signature,uint256 mintNumber,uint256 maximumAllowedMints) external payable virtual nonReentrant {
        require(isSaleActive == false, "NFT :: Sale is not active!!");
        require(totalSupply() + mintNumber <= maxSupply, "NFT :: Cannot mint beyond max supply!!");
        require(totalMintsPerAddress[msg.sender] + mintNumber <= maximumAllowedMints, "NFT :: Cannot mint beyond maximum allowed mint!!");
        require(msg.value >= (price * mintNumber), "NFT :: Payment is below the price!!");
        require(hashMessage(msg.sender, maximumAllowedMints) == messageHash, "MESSAGE_INVALID");
        require(verifyAddressSigner(messageHash, signature), "SIGNATURE_VALIDATION_FAILED");
        // Imprecise floats are scary. Front-end should utilize BigNumber for safe precision, but adding margin just to be safe to not fail txs
        //require(msg.value >= ((price * mintNumber) - 0.0001 ether) && msg.value <= ((price * mintNumber) + 0.0001 ether), "INVALID_PRICE");
        
        totalMintsPerAddress[msg.sender] += mintNumber;

        _safeMint(msg.sender, mintNumber);

        if (totalSupply() + mintNumber >= maxSupply) {
            isSaleActive = true;
        }
    }

    /**
     * @notice Allow contract owner to withdraw funds to its own account.
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}
