// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//Crea una factory con un proxyU Upgradable para crear contratos de tipo Entrada

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {EntradasEventos} from "./EntradasEventos.sol";

contract FactoryEntradas is UUPSUpgradeable, Ownable, Initializable {
    address public entryImplementation; //TODO: OwnableUpgradeable
    address public proxyAdmin;

    event EntradasEventosCreated(
        address indexed entryAddress,
        address indexed creator
    );

    constructor(address _entryImplementation, address _proxyAdmin) {
        initialize(_entryImplementation, _proxyAdmin);
    }

    function initialize(
        address _entryImplementation,
        address _proxyAdmin
    ) public initializer {
        entryImplementation = _entryImplementation;
        proxyAdmin = _proxyAdmin;
    }

    function crearEvento(
        uint32 _maxTickets,
        uint16 _ticketPrice,
        address _sbtAddress,
        string memory _nameEvent
    ) public onlyOwner {
        EntradasEventos evento = new EntradasEventos(
            _maxTickets,
            _ticketPrice,
            _sbtAddress,
            _nameEvent
        );
        emit EntradasEventosCreated(address(evento), msg.sender);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
