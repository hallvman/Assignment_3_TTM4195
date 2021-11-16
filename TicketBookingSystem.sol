// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Ticket is ERC721{
    uint256 public tokenCounter;
    mapping(uint256 => TicketInfo) public tickets;
    
    struct TicketInfo {
        //address owner;
        string title;
        int256 date;
        uint256 row;
        uint256 s_number;
        int256 price;
        string link;
    }
    
    constructor () ERC721("Ticket","TCKT"){
        tokenCounter = 0;
    }

    function buy(address _to, string memory _title, int256 _date, uint256 _row, uint256 _seat_number, int256 _price, string memory _link) public {
        uint256 newTokenId = tokenCounter;
    
        tickets[newTokenId] = TicketInfo(_title, _date, _row, _seat_number, _price, _link);
        _safeMint(_to, newTokenId);
        
        tokenCounter = tokenCounter + 1;
    }
    
    function refund(uint256 tokenId) public {
        _burn(tokenId);
    }
}

contract Poster is ERC721{
    uint256 public posterTokenCount;
    
    constructor () ERC721("Poster","PSTR"){
        posterTokenCount = 0;
    }
    
    function buy(address _to) public{
        uint256 newTokenId = posterTokenCount;
        
        _safeMint(_to, newTokenId);
    }
}

contract Show {
    string show_title;
    int256 n_rows = 3;
    int256 n_seats_per_row = 20;
    string link = "https://seatplan.com/";
    mapping(bytes32 => Seat) public seats;
    
    Ticket myTicket = new Ticket();

    struct Seat {
        address owner;
        string title;
        int256 date;
        int256 price;
        int256 s_row;
        int256 s_number;
        string set_view_link;
    }

    constructor (string memory _show_title, int256 date, int256 price){
        show_title = _show_title;
        for (int256 r_nr = 1; r_nr <= n_rows; r_nr++) {
            for (int256 c_nr = 1; c_nr <= n_seats_per_row; c_nr++) {
                bytes32 mapping_key = keccak256(abi.encodePacked(r_nr, c_nr));
                seats[mapping_key] = Seat(address(0), _show_title, date, price, r_nr, c_nr, link);
            }
        }
    }

    /*
    implement a function buy that B and C individually call to get a ticket
    each, which corresponds to a specific show, date and seat. The function generates
    and transfers a unique ticket upon purchase, as an instance of the TICKET token;
    */

    function buy(uint256 row, uint256 seat_number) public {
        require(row <= 3, "Only 3 rows");
        require(seat_number <= 20, "Only 20 seats per row");
        
        bytes32 mapping_key = keccak256(abi.encodePacked(row, seat_number));
        require(seats[mapping_key].owner == address(0), "This seat is already taken!");
        
        myTicket.buy(msg.sender, seats[mapping_key].title, seats[mapping_key].date, row, seat_number, seats[mapping_key].price, seats[mapping_key].set_view_link);
        seats[mapping_key].owner = msg.sender;
    }

    /*

    implement a function verify that allows anyone with the token ID to check
    the validity of the ticket and the address it is supposed to be used by;

    */

    function verify() public {
        
    }

    /*

    implement a function refund to refund tickets if a show gets cancelled;

    */

    function refund(uint256 row, uint256 seat_number, uint256 tokenId) public {
        require(row <= 3, "Only 3 rows");
        require(seat_number <= 20, "Only 20 seats per row");
        
        bytes32 mapping_key = keccak256(abi.encodePacked(row, seat_number));
        require(seats[mapping_key].owner == msg.sender, "There is not any ticket on this address!");
        
        myTicket.refund(tokenId);
        seats[mapping_key].owner = address(0);
    }

    /*

    implement a function validate to validate a ticket; it can be called only
    in a specific time frame, corresponding to a suitable amount of time before the
    beginning of the show. Upon validation, the ticket is destroyed, and a function
    releasePoster releases unique proof of purchase (you may consider merging these
    two functions together). This new item must be a unique instance of a POSTER
    token;

    */

    function validate() public {

    }

    /*

    implement a function tradeTicket that allows C and D to safely trade (i.e.
    exchange for another or sell for ether) a ticket directly between each other.

    */

    function tradeTicket() public {

    }


}