// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Fractions, LandTokenInfo} from "./DataStructure.sol";
import "./RBAC.sol";

//There are other ways to perform contract to contract calls
//This is one of them
//In production those interfaces could be part of an external library/file to be imported here
//As it is a simple project, this simple way is enough

interface ILandToken {
    function safeMint(address to) external;

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IFractionToken {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract NFTRealState is RBAC {
    // Here is a key value pair data structure named mapping in solidity
    // As a dictionary it cannot be iterable, commonly used in solidity due to the gas savings
    // It is not a good practice to use arrays in solidity

    // This first mapping is the "from-to" sort to speaking
    // Mapping from landToken address to the landTokenId to the fractionsHash
    mapping(address => mapping(uint256 => bytes)) private landTokenMap;
    // This second mapping do the opposite way
    // By using these mappings we are able to trace entire lands to fractions of lands and vice versa 
    mapping(address => mapping(uint256 => bytes)) private fractionTokenIdMap;

    // A constructor is a function that is executed when the contract is deployed
    // If changing this contract to implement an upgradeable pattern, this constructor should be replaced by a initialize function
    // We are setting here the contract owner by using the _setupRole method from the RBAC contract
    constructor(address owner) {
        _setupRole(OWNER, owner);
    }

    /**
    **********IMPORTANT**********
    For both functions to work correctly this contract should have a MINTER_ROLE in the both NFT contracts (LandToken and FractionToken)
    The MINTER_ROLE is a role that allows a contract to mint new tokens
    The MINTER_ROLE in the LandToken and The FractionToken should be given by the NFT contract's owner 
    */
    
    // This function is used to mint a new LandToken
    // It is only callable by the AAA role
    // If the caller is not the AAA role, it will revert the transaction
    // This is a simple way to restrict access to a function
    function mintLandToken(address landToken) public onlyRole(AAA) {
        ILandToken(landToken).safeMint(msg.sender);
    }

    // This function is used to mint a new FractionToken
    // It is only callable by the AAA role
    // If the caller is not the AAA role, it will revert the transaction
    // This is a simple way to restrict access to a function
    // @Params LandTokenInfo landTokenInfo imported from DataStructure
    function mintFractionToken(
        LandTokenInfo memory landTokenInfo
    ) public onlyRole(AAA) {

        // For the sake of simplecity we are waiving validations in the LandTokenInfo struct
        // Working with bytes to save gas rather than the full struct
        // Here we use the abi.decode method to convert the bytes back to the struct
        Fractions memory fractions = abi.decode(
            landTokenInfo.fractionsHash,
            (Fractions)
        );

        // Before any external interaction update the state of the contract
        // This is a good practice to avoid reentrancy attacks

        landTokenMap[landTokenInfo.landToken][
            landTokenInfo.landTokenId
        ] = landTokenInfo.fractionsHash;

        fractionTokenIdMap[fractions.fractionToken][
            fractions.fractionsTokenId[0]
        ] = landTokenInfo.fractionsHash;

        // Call the LandToken Contract to transfer NFT tokens to this contract
        // We are calling the transferFrom method, this requires that the landTokenHolder has approved this contract to transfer the NFT token
        ILandToken(landTokenInfo.landToken).transferFrom(
            fractions.landTokenHolder,
            msg.sender,
            landTokenInfo.landTokenId
        );

        // Call the ERC1155 Contract to mint the fraction tokens
        // We are calling the mint method from the ERC1155 contract
        // This requires that this contract has the MINTER_ROLE in the Fraction Contract
        // We are calling the ERC1155 using the internal function mintFractions

        mintFractions(
            fractions.fractionsRecipients,
            fractions.fractionsAmount,
            fractions.fractionsTokenId,
            fractions.fractionToken
        );
    }

    // In this function we are interaction with the ERC1155 contract
    // It is important to mention that we are not passing any data in the bytes parameter as it would not worth the gas in the context of this project

    function mintFractions(
        address[] memory recipients,
        uint256[] memory amounts,
        uint256[] memory id,
        address fractionToken
    ) internal {
        require(
            recipients.length == amounts.length,
            "Amounts and Recipients arrays must be the same length"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            IFractionToken(fractionToken).mint(
                recipients[i],
                id[0],
                amounts[i],
                ""
            );
        }
    }

    // This function is used to get the landTokenInfo by the landToken and landTokenId
    // It is a view function, it means that it does not change the state of the contract
    // It is a public function, it means that it can be called by anyone
    // @Params address landToken, uint256 landTokenId
    // @Returns LandTokenInfo landTokenInfo
    function getFractionInfoByTokenLand(address landToken, uint256 landTokenId)
        public
        view
        returns (Fractions memory fractionsInfo)
    {
        bytes memory fractionsHash = landTokenMap[landToken][landTokenId];
        Fractions memory fractions = abi.decode(
            fractionsHash,
            (Fractions)
        );
        
        return fractions;
    }

    // This function is used to get the fractionsInfo by the fractionToken and fractionTokenId
    // It is a view function, it means that it does not change the state of the contract
    // It is a public function, it means that it can be called by anyone
    // @Params address fractionToken, uint256 fractionTokenId
    // @Returns Fractions fractionsInfo
    function getFrantionInfoByFractionTokenId(address fractionToken, uint256 fractionTokenId)
        public
        view
        returns (Fractions memory fractionsInfo)
    {
        bytes memory fractionsHash = fractionTokenIdMap[fractionToken][fractionTokenId];
        Fractions memory fractions = abi.decode(
            fractionsHash,
            (Fractions)
        );
        
        return fractions;
    }
}
