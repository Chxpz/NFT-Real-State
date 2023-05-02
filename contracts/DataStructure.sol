// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// The structs used in the NFTReal State Contract
// We are using encoding the Fractions struct to bytes and storing it in the LandTokenInfo struct as fractionsHash
// This is done to save gas as we are not using any of the Fractions struct variables in the LandTokenInfo struct
// and bytes are cheaper to store in the contract 

struct Fractions {
    address landTokenHolder;
    address fractionToken;
    uint256 totalFractions;
    address[] fractionsRecipients;
    uint256[] fractionsTokenId;
    uint256[] fractionsAmount;
}

struct LandTokenInfo{
    address landToken;
    uint256 landTokenId;
    bytes fractionsHash;
}