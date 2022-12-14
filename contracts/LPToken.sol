// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LPToken is ERC20 {

	constructor() ERC20("XMC-USDT-LP", "XMC-USDT-LP") {
		_mint(msg.sender, 1_000_000 * 1E18);
	}
}