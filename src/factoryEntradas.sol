// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//Crea una factory con un proxyU Upgradable para crear contratos de tipo Entrada

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EntryFactory is UUPSUpgradeable, Ownable {
    address public entryImplementation;
    address public proxyAdmin;

    event EntryCreated(address indexed entryAddress, address indexed creator);

    function initialize(address _entryImplementation, address _proxyAdmin) public initializer {
        entryImplementation = _entryImplementation;
        proxyAdmin = _proxyAdmin;
    }

    function createEntry(uint256 _initialAmount) public onlyOwner {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(entryImplementation, proxyAdmin, "");

        IEntry(entryImplementation).initialize(_initialAmount);

        emit EntryCreated(address(proxy), msg.sender);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
