import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert, expect } from "chai";
import { utils, Contract } from "ethers";
import { ethers } from "hardhat";
require("chai").use(require("chai-as-promised")).should();

describe("Tests for Fluent Protocol Contracts", function () {
	let NFTRealState: Contract;
	let LandToken: Contract;
	let FractionNFT: Contract;

	let deployer: SignerWithAddress;
	let owner: SignerWithAddress;
	let AAA: SignerWithAddress;
	let user1: SignerWithAddress;
	let user2: SignerWithAddress;

	this.beforeAll(async () => {
		[
			deployer,
			owner,
			AAA,
			user1,
			user2,
		] = await ethers.getSigners();

		const _nftRealState = await ethers.getContractFactory(
			"NFTRealState"
		);
		NFTRealState = await _nftRealState.deploy(owner.address);
		await NFTRealState.deployed();

		const _tokenLand = await ethers.getContractFactory(
			"LandToken"
		);
		LandToken = await _tokenLand.deploy(owner.address);
		await LandToken.deployed();

		const _fractionNFT = await ethers.getContractFactory(
			"LandFractions"
		);

		FractionNFT = await _fractionNFT.deploy(owner.address);
		await FractionNFT.deployed();

	});

	describe("Tests for NFT Real State", () => {
		describe("#Testing Roles", () => {
			it("It should assign the contract owner role to the NFTReal State Contract", async () => {
				expect(await NFTRealState.hasRole(NFTRealState.OWNER(), owner.address)).to.be.true;
			});

			it("It should assign the contract owner role to the LandToken Contract", async () => {
				expect(await NFTRealState.hasRole(LandToken.OWNER(), owner.address)).to.be.true;
			});

			it("It should assign the contract owner role to the LandFraction Contract", async () => {
				expect(await NFTRealState.hasRole(FractionNFT.OWNER(), owner.address)).to.be.true;
			});

			it("It should assign the contract AAA role to the NFTReal State Contract", async () => {
				await NFTRealState.connect(owner).grantRole(NFTRealState.AAA(), AAA.address);
				expect(await NFTRealState.hasRole(NFTRealState.AAA(), AAA.address)).to.be.true;
			});

			it("It should assign the contract CUSTOMER role to the NFTReal State Contract", async () => {
				await NFTRealState.connect(owner).grantRole(NFTRealState.CUSTOMER(), user1.address);
				expect(await NFTRealState.hasRole(NFTRealState.CUSTOMER(), user1.address)).to.be.true;
			});

			it("It should revoke roles in the NFTReal State Contract", async () => {
				await NFTRealState.connect(owner).revokeRole(NFTRealState.AAA(), AAA.address);
				expect(await NFTRealState.hasRole(NFTRealState.AAA(), AAA.address)).to.be.false;

				await NFTRealState.connect(owner).revokeRole(NFTRealState.CUSTOMER(), user1.address);
				expect(await NFTRealState.hasRole(NFTRealState.CUSTOMER(), user1.address)).to.be.false;

				await NFTRealState.connect(owner).grantRole(NFTRealState.AAA(), AAA.address);
				expect(await NFTRealState.hasRole(NFTRealState.AAA(), AAA.address)).to.be.true;

				await NFTRealState.connect(owner).grantRole(NFTRealState.CUSTOMER(), user1.address);
				expect(await NFTRealState.hasRole(NFTRealState.CUSTOMER(), user1.address)).to.be.true;
			});

			it("It should not be possible for the owner to revoke its own role without prior assignment to other address", async () => {
				await expect(NFTRealState.connect(owner).revokeRole(NFTRealState.OWNER(), owner.address))
					.to.be.rejectedWith("VM Exception while processing transaction:");
			});

			it("It should grant the NFTReal State Contract the Minter Roles in the LandToken and Fraction Token Contracts", async () => {
				await LandToken.connect(owner).grantRole(LandToken.MINTER_ROLE(), NFTRealState.address);
				expect(await LandToken.hasRole(LandToken.MINTER_ROLE(), NFTRealState.address)).to.be.true;

				await FractionNFT.connect(owner).grantRole(FractionNFT.MINTER_ROLE(), NFTRealState.address);
				expect(await FractionNFT.hasRole(FractionNFT.MINTER_ROLE(), NFTRealState.address)).to.be.true;
			});
		});
		describe("#Minting LandTokens and Fraction Tokens", () => {
			it("It should mint a LandTokens", async () => {
				await NFTRealState.connect(AAA).mintLandToken(LandToken.address);
				expect(+(await LandToken.balanceOf(AAA.address))).to.equal(1);
			});

			it("It should not mint a LandTokens if the caller is not AAA", async () => {
				await expect(NFTRealState.connect(user1).mintLandToken(LandToken.address))
					.to.be.rejectedWith("VM Exception while processing transaction:");
			});

			it("It should mint Fraction Tokens", async () => {

				const fractions = {
					landTokenHolder: AAA.address,
					fractionToken: FractionNFT.address,
					totalFractions: 100,
					fractionsRecipients: [user1.address, user2.address],
					fractionsTokenId: [0],
					fractionsAmount: [50, 50],
				};

				const fractionsHash: string = ethers.utils.defaultAbiCoder.encode(
					[
						"tuple(address landTokenHolder,address fractionToken,uint256 totalFractions,address[] fractionsRecipients,uint256[] fractionsTokenId, uint256[] fractionsAmount)",
					],
					[fractions]
				);

				const landTokenInfo = {
					landToken: LandToken.address,
					landTokenId: 0,
					fractionsHash: fractionsHash,
				};

				await LandToken.connect(AAA).approve(NFTRealState.address, 0);

				await NFTRealState.connect(AAA).mintFractionToken(landTokenInfo);

				expect(+(await LandToken.balanceOf(AAA.address))).to.equal(1);
				expect(await LandToken.ownerOf(0)).to.equal(AAA.address);

				expect(+(await FractionNFT.balanceOf(user1.address,0))).to.equal(50);
				expect(+(await FractionNFT.balanceOf(user2.address,0))).to.equal(50);

				const result = await NFTRealState.connect(AAA).getFractionInfoByTokenLand(
					LandToken.address,
					0
				);
				expect(result.landTokenHolder).to.equal(AAA.address);
				expect(result.fractionToken).to.equal(FractionNFT.address);
				expect(+result.totalFractions).to.equal(100);
				expect(result.fractionsRecipients[0]).to.equal(user1.address);
				expect(result.fractionsRecipients[1]).to.equal(user2.address);
				expect(+result.fractionsTokenId[0]).to.equal(0);
				expect(+result.fractionsAmount[0]).to.equal(50);
				expect(+result.fractionsAmount[1]).to.equal(50);

				const resultFraction = await NFTRealState.connect(AAA).getFrantionInfoByFractionTokenId(
					FractionNFT.address,
					0
				);
				expect(resultFraction.landTokenHolder).to.equal(AAA.address);
				expect(resultFraction.fractionToken).to.equal(FractionNFT.address);
				expect(+resultFraction.totalFractions).to.equal(100);
				expect(resultFraction.fractionsRecipients[0]).to.equal(user1.address);
				expect(resultFraction.fractionsRecipients[1]).to.equal(user2.address);
				expect(+resultFraction.fractionsTokenId[0]).to.equal(0);
				expect(+resultFraction.fractionsAmount[0]).to.equal(50);
				expect(+resultFraction.fractionsAmount[1]).to.equal(50);
			});
		});
	});
});
