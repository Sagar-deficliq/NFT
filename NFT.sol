// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFT is ERC721A, Ownable {

    using Strings for uint256;

    uint256 public constant SALE_MAX_HEADQUARTER = 500;
    uint256 public constant SALE_MAX_WARFACTORY = 1500;
    uint256 public constant SALE_MAX_WORKER = 3000;
    uint256 public constant SALE_MAX_PEACEMAKER = 5500;

    uint256 public constant PER_MINT_HEADQUARTER = 1;
    uint256 public constant PER_MINT_WARFACTORY = 1;
    uint256 public constant PER_MINT_WORKER = 1;
    uint256 public constant PER_MINT_PEACEMAKER = 1;

    uint256 public constant NFT_PRICE_HEADQUARTER = 0.5 ether;
    uint256 public constant NFT_PRICE_WARFACTORY = 0.5 ether;
    uint256 public constant NFT_PRICE_WORKER = 0.5 ether;
    uint256 public constant NFT_PRICE_PEACEMAKER = 0.5 ether;

    enum nftType {HEADQUARTER, WARFACTORY, WORKER, PEACEMAKER}

    mapping (uint256 => nftType) private _currentNftType;

    mapping (address => uint256) public totalMintsPerAddress;
    
    bool public isSaleActive = false;

    address private _signerAddress;
    address public payoutAddress;

    string private _tokenBaseURI;
    string private signPrefix = "This is DystoWorld NFT";

    uint256 public maxSupply;

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

    constructor() ERC721A("NFT", "NFT") {
        payoutAddress = msg.sender;
        _signerAddress = msg.sender;
    }

    function setSignerAddress(address signaddress) external onlyOwner {
        require(_signerAddress != address(0));
        _signerAddress = signaddress;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Kanji: Cannot query non-existent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function verifyTransaction(address sender,uint256 amount,bytes calldata signature, string memory metadata) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(signPrefix, sender, amount, metadata));
        address recoveredAddress = ECDSA.recover(hash, signature);
        return _signerAddress == recoveredAddress;
    }

    function purchase(uint256 mintNumber,bytes calldata signature, string memory metadata) external payable {
      require(isSaleActive == false, "NFT :: Sale is not active!!");

        if(keccak256(abi.encodePacked(metadata)) == "HEADQUARTER") {
            require(maxSupply + mintNumber <= SALE_MAX_HEADQUARTER, "NFT :: Cannot mint beyond max supply!!");
            require(totalMintsPerAddress[msg.sender] + mintNumber <= PER_MINT_HEADQUARTER, "NFT :: Cannot mint beyond maximum allowed mint!!");
            require(msg.value >= (NFT_PRICE_HEADQUARTER * mintNumber), "NFT :: Payment is below the price!!");
            require(verifyTransaction(msg.sender, mintNumber, signature, metadata),"NFT: Contract Mint Not Allowed");
            _safeMint(msg.sender, mintNumber);
            maxSupply += mintNumber;
            totalMintsPerAddress[msg.sender] += mintNumber;
            _currentNftType[mintNumber] = nftType.HEADQUARTER;
        } else if(keccak256(abi.encodePacked(metadata)) == "WARFACTORY"){
            require(maxSupply + mintNumber <= SALE_MAX_WARFACTORY, "NFT :: Cannot mint beyond max supply!!");
            require(totalMintsPerAddress[msg.sender] + mintNumber <= PER_MINT_WARFACTORY, "NFT :: Cannot mint beyond maximum allowed mint!!");
            require(msg.value >= (NFT_PRICE_WARFACTORY * mintNumber), "NFT :: Payment is below the price!!");
            require(verifyTransaction(msg.sender, mintNumber, signature, metadata),"NFT: Contract Mint Not Allowed");
            _safeMint(msg.sender, mintNumber);
            maxSupply += mintNumber;
            totalMintsPerAddress[msg.sender] += mintNumber;
            _currentNftType[mintNumber] = nftType.WARFACTORY;
        } else if(keccak256(abi.encodePacked(metadata)) == "PEACEMAKER"){
            require(maxSupply + mintNumber <= SALE_MAX_PEACEMAKER, "NFT :: Cannot mint beyond max supply!!");
            require(totalMintsPerAddress[msg.sender] + mintNumber <= PER_MINT_PEACEMAKER, "NFT :: Cannot mint beyond maximum allowed mint!!");
            require(msg.value >= (NFT_PRICE_PEACEMAKER * mintNumber), "NFT :: Payment is below the price!!");
            require(verifyTransaction(msg.sender, mintNumber, signature, metadata),"NFT: Contract Mint Not Allowed");
            _safeMint(msg.sender, mintNumber);
            maxSupply += mintNumber;
            totalMintsPerAddress[msg.sender] += mintNumber;
            _currentNftType[mintNumber] = nftType.PEACEMAKER;

        } else if(keccak256(abi.encodePacked(metadata)) == "WORKER"){
            require(maxSupply + mintNumber <= SALE_MAX_WORKER, "NFT :: Cannot mint beyond max supply!!");
            require(totalMintsPerAddress[msg.sender] + mintNumber <= PER_MINT_WORKER, "NFT :: Cannot mint beyond maximum allowed mint!!");
            require(msg.value >= (NFT_PRICE_WORKER * mintNumber), "NFT :: Payment is below the price!!");
            require(verifyTransaction(msg.sender, mintNumber, signature, metadata),"NFT: Contract Mint Not Allowed");
            _safeMint(msg.sender, mintNumber);
            maxSupply += mintNumber;
            totalMintsPerAddress[msg.sender] += mintNumber;
            _currentNftType[mintNumber] = nftType.WORKER;
        }
        
    }

    function withdraw() external onlyOwner {
        payable(payoutAddress).transfer(address(this).balance);
    }

 
}
