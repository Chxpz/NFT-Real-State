// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {MissingRole, ZeroAddressesNotAllowed, CannotRevokeRole} from "./CustomErrors.sol";

// RBAC - Role Based Access Control
// A contract to manage roles and permissions
// As it is not intended to be deployed, it is marked as abstract

abstract contract RBAC{
    //Roles to be used in the context of this contract
    bytes32 public constant OWNER = keccak256("Owner");
    bytes32 public constant AAA = keccak256("AAA");
    bytes32 public constant CUSTOMER = keccak256("CUSTOMER");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Mapping from address to role to bool
    mapping(address => mapping(bytes32 => bool)) private roles;

    modifier onlyRole(bytes32 role) {
        _verifyRole(role, msg.sender);
        _;
    }

    function _verifyRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert MissingRole(
                bytes(
                    string(
                        abi.encodePacked(
                            "Account ",
                            account,
                            " is missing role ",
                            role
                        )
                    )
                )
            );
        }
    }

    function _setupRole(bytes32 role, address account) internal {
        roles[account][role] = true;
    }

    function grantRole(bytes32 role, address account) public onlyRole(OWNER) {
        if(isZeroAddress(account)){
            revert ZeroAddressesNotAllowed();
        }
        _setupRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(OWNER) {
        if(isZeroAddress(account)){
            revert ZeroAddressesNotAllowed();
        }
        
        if (msg.sender == account)
            revert CannotRevokeRole(
                bytes(
                    string(
                        abi.encodePacked(
                            "Account ",
                            account,
                            " cannot revoke role ",
                            role
                        )
                    )
                )
            );
        roles[account][role] = false;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return roles[account][role];
    }

    function isZeroAddress(address account) internal pure returns (bool) {
        return account == address(0);
    }
}