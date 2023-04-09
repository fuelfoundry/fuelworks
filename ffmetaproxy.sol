// SPDX-License-Identifier: Apache-2.0
//
// ((((((((((((((((((((((((((((((((((((       ((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((       ((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((       ((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((       ((((((((((((((((((((((((((((((((((((
//
//
//
// ((((((((((((((((((((((((((((                       ((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((               ((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((           ((((((((((((((((((((((((((((((((((
// (((((((((((((((((((((((((((((((((((         (((((((((((((((((((((((((((((((((((
//                      (((((((((((((((       (((((((((((((((
//                         ((((((((((((       ((((((((((((
//                          (((((((((((       (((((((((((
//                          (((((((((((       (((((((((((
//                          (((((((((((       (((((((((((
//                          (((((((((((       (((((((((((
//                          (((((((((((       (((((((((((
//                          (((((((((((       (((((((((((
//
// Fuel Foundry Metadata Proxy Smart Contract
// Generated by: FuelFoundry
// More info at: https://fuelfoundry.io
// Code Release: 0.875alpha
// All rights reserved
//
// Use at your own risk, no warranties unless specified in service agreement.
//   
// ------------------------------------------------------------------------
//
// Additional Configuration(s):
//
// - Name:     FF721MetaProxy
// - Guardian: 1 (Multi-Sig Lite)
// - Oracle:   0
//
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract FF721MetaProxy is Ownable, Pausable {

    address private _owner;
    address private _guardian;

    bool    private _ownerCanTransfer;
    bool    private _guardianCanTransfer;

    string  private _baseTokenURI;
    string  private _tokenURISuffix;
    bool    private _useCustomTokenURI;

    IERC721Metadata public sourceContract;

    mapping (uint256 => string) private _customTokenURIs;

    event GuardianUpdated(address indexed previousGuardian, address indexed newGuardian);
    event OwnerTransferabilityChanged(address indexed guardian, bool canTransfer);
    event GuardianTransferabilityChanged(address indexed owner, bool canTransfer);

    modifier onlyGuardian() {

        require(msg.sender == _guardian, "Only guardian may call this function");
        _;
    }


    constructor(address owner_, address guardian_, address _sourceContract, string memory _initialBaseTokenURI, string memory _initialTokenURISuffix) {

        if (owner_ == address(0)) { _owner = msg.sender; } 
        else { _owner = owner_; }

        _guardian = guardian_;

        sourceContract  = IERC721Metadata(_sourceContract);
        _baseTokenURI   = _initialBaseTokenURI;
        _tokenURISuffix = _initialTokenURISuffix;

        _ownerCanTransfer = true;

        emit OwnershipTransferred(address(0), _owner);
        emit GuardianUpdated(address(0), _guardian);
    }


    function setBaseTokenURI(string memory newBaseTokenURI) external onlyOwner {

        _baseTokenURI = newBaseTokenURI;
    }


    function setTokenURISuffix(string memory newTokenURISuffix) external onlyOwner {

        _tokenURISuffix = newTokenURISuffix;
    }


    function setCustomTokenURI(uint256 tokenId, string memory customTokenURI) external onlyOwner {

        _customTokenURIs[tokenId] = customTokenURI;
    }


    function toggleCustomTokenURI(bool useCustomTokenURI) external onlyOwner {

        _useCustomTokenURI = useCustomTokenURI;
    }


    function pause() external onlyOwner {

        _pause();
    }


    function unpause() external onlyOwner {

        _unpause();
    }


    function balanceOf(address owner) external view whenNotPaused returns (uint256) {

        return sourceContract.balanceOf(owner);
    }


    function tokenURI(uint256 tokenId) external view whenNotPaused returns (string memory) {

        if (_useCustomTokenURI) {

            if (bytes(_customTokenURIs[tokenId]).length > 0) {

                return _customTokenURIs[tokenId];
            }

            return string(abi.encodePacked(_baseTokenURI, sourceContract.tokenURI(tokenId), _tokenURISuffix));
        } else {

            return sourceContract.tokenURI(tokenId);
        }
    }


    function ownerOf(uint256 tokenId) external view whenNotPaused returns (address) {

        return sourceContract.ownerOf(tokenId);
    }


    function withdraw() external onlyOwner {

        uint256 balance = address(this).balance;

        require(balance > 0, "FF721MetaProxy: zero balance");

        payable(msg.sender).transfer(balance);
    }


    function setGuardianTransferability(bool canTransfer) public onlyOwner {

        _guardianCanTransfer = canTransfer;

        emit GuardianTransferabilityChanged(_owner, canTransfer);
    }


    function setOwnerTransferability(bool canTransfer) public onlyGuardian {

        _ownerCanTransfer = canTransfer;

        emit OwnerTransferabilityChanged(_guardian, canTransfer);
    }


    function updateGuardian(address newGuardian) public onlyGuardian {

        require(_guardianCanTransfer, "Guardian role transfer prohibited");
        require(newGuardian != address(0), "New Guardian cannot equal address(0)");

        _guardian = newGuardian;

        emit GuardianUpdated(_guardian, newGuardian);
    }
 

    function transferOwnership(address newOwner) public override onlyOwner {

        require(_ownerCanTransfer, "Owner role transfer prohibited");
        require(newOwner != address(0), "New owner cannot equal address(0)");

        _owner = newOwner;

        emit OwnershipTransferred(_owner, newOwner);
    }

    function renounceOwnership() public override onlyOwner {

        require(_ownerCanTransfer, "Transfer to account(0) prohibited");

        address previousOwner = owner();
        _transferOwnership(address(0));

        emit OwnershipTransferred(previousOwner, address(0));
    }

    function burn() external payable {

        require(msg.value == 420 ether, "420 fuel required to burn contract");
    }
}
