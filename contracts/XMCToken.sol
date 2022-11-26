// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract XMCToken is ERC20 {

	constructor() ERC20("XMC", "XMC") {
		_mint(msg.sender, 1_000_000 * 1E18);
	}
}