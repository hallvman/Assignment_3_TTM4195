// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Ticket is ERC721{
    uint256 public tokenCounter;
    mapping(uint256 => TicketInfo) public tickets;
    
    struct TicketInfo {
        //address owner;
        string title;
        uint256 date;
        uint256 row;
        uint256 s_number;
        uint256 price;
        string link;
    }
    
    constructor () ERC721("Ticket","TCKT"){
        tokenCounter = 0;
    }

    function buy(address _to, string memory _title, uint256 _date, uint256 _row, uint256 _seat_number, uint256 _price, string memory _link) public returns(uint256){
        uint256 newTokenId = tokenCounter;
    
        tickets[newTokenId] = TicketInfo(_title, _date, _row, _seat_number, _price, _link);
        _safeMint(_to, newTokenId);
        
        tokenCounter = tokenCounter + 1;
        return newTokenId;
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
    show_status status = show_status.Scheduled;
    address systems_wallet = address(1);
    string show_title;
    uint256 show_time;
    uint256 n_rows = 3;
    uint256 n_seats_per_row = 20;
    string link = "https://seatplan.com/";
    mapping(bytes32 => Seat) public seats;
    mapping(uint256 => address payable) public tokenOwners;
    mapping(address => uint256) public payback_amount;
    uint256 number_of_tickets_sold = 0;
    
    Ticket myTicket = new Ticket();

    struct Seat {
        address owner;
        string title;
        uint256 date;
        uint256 time;
        uint256 price;
        uint256 s_row;
        uint256 s_number;
        string set_view_link;
    }
    enum show_status {Scheduled, On, Over, Cancelled}

    constructor (string memory _show_title, uint256 date, uint256 _time, uint256 price){
        show_title = _show_title;
        show_time = _time;
        for (uint256 r_nr = 1; r_nr <= n_rows; r_nr++) {
            for (uint256 c_nr = 1; c_nr <= n_seats_per_row; c_nr++) {
                bytes32 mapping_key = keccak256(abi.encodePacked(r_nr, c_nr));
                seats[mapping_key] = Seat(address(0), _show_title, date, time, price, r_nr, c_nr, link);
            }
        }
    }

    /*
    implement a function buy that B and C individually call to get a ticket
    each, which corresponds to a specific show, date and seat. The function generates
    and transfers a unique ticket upon purchase, as an instance of the TICKET token;
    */

    function buy(uint256 row, uint256 seat_number) public {
        require(status == show_status.Scheduled);
        require(row >= 1 && row <= 3 , "Pick row number between 1 and 3");
        require(seat_number >= 1 && seat_number <= 20, "Pick seat number between 1 and 20");
        
        bytes32 mapping_key = keccak256(abi.encodePacked(row, seat_number));
        require(seats[mapping_key].owner == address(0), "This seat is already taken!");
        
        number_of_tickets_sold = myTicket.buy(msg.sender, seats[mapping_key].title, seats[mapping_key].date, row, seat_number, seats[mapping_key].price, seats[mapping_key].set_view_link);
        tokenOwners[number_of_tickets_sold] = payable(msg.sender);
        seats[mapping_key].owner = msg.sender;
    }
    
    /* implement a function verify that allows anyone with the token ID to checkthe validity of the ticket and the address it is supposed to be used by */
    function verify(uint256 tokenID) public view{
        /* Verify that an address owns a token*/
        require(tokenOwners[tokenID] == msg.sender);
    }
    
    function refund() public payable{
        /* Refund funds to ticket owners in caase of cancelled show */
        /* Accumulate refund amount for each of the addresses that own ticket(s)*/
        for (uint256 r_nr = 1; r_nr <= n_rows; r_nr++) {
            for (uint256 c_nr = 1; c_nr <= n_seats_per_row; c_nr++) {
                bytes32 mapping_key = keccak256(abi.encodePacked(r_nr, c_nr));
                Seat memory seat = seats[mapping_key];
                if(seat.owner != address(0)){
                    payback_amount[seat.owner] = payback_amount[seat.owner] + seat.price;
                }
            }
        }
        /* Refund the funds address by address*/
        for (uint256 token_ID = 0;  token_ID <= number_of_tickets_sold; token_ID++) {
            address payable owner_address = tokenOwners[token_ID];
            uint256 amount = payback_amount[owner_address];
            (bool success, ) = owner_address.call{value:amount}("");
            require(success, "Transfer failed.");
        }
    }
}
