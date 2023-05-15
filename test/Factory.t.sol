// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {FactoryEntradas} from "../src/FactoryEntradas.sol";
import {SBT} from "../src/SBT.sol";
import {EntradasEventos} from "../src/EntradasEventos.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FactoryEntradasTest is Test{
    FactoryEntradas public factoryEntradas;
    SBT public sbt;
    EntradasEventos public entradasEventos;
    
    event EntradasEventosCreated(address indexed entryAddress, address indexed creator);

    function setUp() public {
        factoryEntradas = new FactoryEntradas();
        sbt = new SBT("Test","TST");
        entradasEventos = new EntradasEventos();
    }

    function testDeployContract() public {
        
        factoryEntradas.initialize(address(entradasEventos), address(this));
        /* vm.expectEmit(true, false, true, false);
        emit EntradasEventosCreated(address(this), address(this)); */
        factoryEntradas.crearEvento(100, 100, address(sbt), "Evento 1");
        
    }
}