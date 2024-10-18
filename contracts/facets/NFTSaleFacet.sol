// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {MerkleProof} from "../libraries/MerkleProof.sol";
import "./ERC721Facet.sol";

contract NFTPresaleMint {
    event NFTMinted(
        address indexed nftContract,
        address indexed buyer,
        uint256 indexed tokenId
    );

    uint256 public constant TOKEN_PRICE = 0.01 ether;
    uint256 public constant TOKENS_PER_ETHER = 30;

    function _diamondStorage()
        internal
        pure
        returns (LibDiamond.DiamondStorage storage)
    {
        return LibDiamond.diamondStorage();
    }

    function mintDuringPresale(bytes32[] calldata proof) external payable {
        LibDiamond.DiamondStorage storage ds = _diamondStorage();

        // Check if the user has already minted
        require(!ds.hasMinted[msg.sender], "Presale: You have already minted");

        // Ensure sufficient ETH is sent
        require(msg.value >= TOKEN_PRICE, "Presale: Insufficient ETH sent");

        // Verify if the provided Merkle proof is valid
        require(_validateProof(proof, msg.sender), "Presale: Invalid proof");

        // Calculate how many NFTs the user can mint based on the ETH sent
        uint256 numTokens = (msg.value * TOKENS_PER_ETHER) / 1 ether;
        address nftContract = ds.token;

        // Mark the user as having minted
        ds.hasMinted[msg.sender] = true;

        // Mint the calculated number of NFTs
        for (uint256 i = 0; i < numTokens; i++) {
            ds.tokenIds++;
            ERC721Facet(nftContract).mint(msg.sender, ds.tokenIds + i);
            emit NFTMinted(nftContract, msg.sender, ds.tokenIds + i);
        }
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external {
        LibDiamond.enforceIsContractOwner();
        _diamondStorage().merkleRoot = newMerkleRoot;
    }

    function _validateProof(
        bytes32[] memory proof,
        address user
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, _diamondStorage().merkleRoot, leaf);
    }
}
