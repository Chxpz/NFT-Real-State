// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Custom errors saves gas therefore it is recommended to use them
error MissingRole(bytes message);
error CannotRevokeRole(bytes message);
error ZeroAddressesNotAllowed();
