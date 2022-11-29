// SPDX-License-Identifier: MIT
// Version @2021-05
// Source: Pancake Bunny
/*
 █████╗ ██████╗ ███████╗██████╗  ██████╗  ██████╗██╗  ██╗███████╗████████╗
██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝
███████║██████╔╝█████╗  ██████╔╝██║   ██║██║     █████╔╝ █████╗     ██║   
██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗██║   ██║██║     ██╔═██╗ ██╔══╝     ██║   
██║  ██║██║     ███████╗██║  ██║╚██████╔╝╚██████╗██║  ██╗███████╗   ██║   
╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝  
 */
pragma solidity >=0.6.12;

interface IVaultController {
    function minter() external view returns (address);

    function spaceChef() external view returns (address);

    function stakingToken() external view returns (address);
}
