// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Ticket is ERC721 {
    uint256 public tokenCounter;
    constructor () public ERC721("Ticket", "show"){
        tokenCounter = 0;
    }
}

contract Poster is ERC721 {
    uint256 public tokenCounter;
    constructor () public ERC721("poster", "show"){
        tokenCounter = 0;
    }
}

contract Show {
    string show_title;
    int256 n_rows = 3;
    int256 n_seats_per_row = 20;
    string link = "https://seatplan.com/";
    mapping(bytes32 => Seat) public seats;

    struct Seat {
        address owner;
        string title;
        string date;
        int256 price;
        int256 s_row;
        int256 s_number;
        string set_view_link;
    }

    constructor (string memory _show_title, string memory date, int256 price){
        show_title = _show_title;
        for (int256 r_nr = 0; r_nr < n_rows; r_nr++) {
            for (int256 c_nr = 0; c_nr < n_seats_per_row; c_nr++) {
                bytes32 mapping_key = keccak256(abi.encodePacked(r_nr, c_nr));
                seats[mapping_key] = Seat(address(0), _show_title, date, price, r_nr, c_nr, link);
            }
        }
    }

    /*
    function buy() {

    }
    */
}