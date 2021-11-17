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
    
    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}

contract Poster is ERC721{
    uint256 public posterTokenCount;
    
    constructor () ERC721("Poster","PSTR"){
        posterTokenCount = 0;
    }
    
    function releasePoster(address _to) public{
        uint256 newTokenId = posterTokenCount;
        
        _safeMint(_to, newTokenId);
    }
}

contract Show {
    address payable public seller;
    address payable public buyer;
    
    show_status status = show_status.Scheduled;
    address systems_wallet = address(1);
    string show_title;
    uint256 n_rows = 3;
    uint256 n_seats_per_row = 20;
    string link = "https://seatplan.com/";
    mapping(bytes32 => Seat) public seats;
    mapping(uint256 => address payable) public tokenOwners;
    mapping(address => uint256) public payback_amount;
    uint256 number_of_tickets_sold = 0;
    
    Ticket myTicket = new Ticket();
    Poster myPoster = new Poster();

    struct Seat {
        address owner;
        string title;
        uint256 date;
        uint256 price;
        uint256 s_row;
        uint256 s_number;
        string set_view_link;
    }
    enum show_status {Scheduled, On, Over, Cancelled}

    constructor (string memory _show_title, uint256 date, uint256 price) payable {
        seller = payable(msg.sender);
        show_title = _show_title;
        for (uint256 r_nr = 1; r_nr <= n_rows; r_nr++) {
            for (uint256 c_nr = 1; c_nr <= n_seats_per_row; c_nr++) {
                bytes32 mapping_key = keccak256(abi.encodePacked(r_nr, c_nr));
                seats[mapping_key] = Seat(address(0), _show_title, date, price, r_nr, c_nr, link);
            }
        }
    }
    
    modifier onlySeller(){
        require(msg.sender == seller, "Only the seller can do this");
        _;
    }

    /*
    implement a function buy that B and C individually call to get a ticket
    each, which corresponds to a specific show, date and seat. The function generates
    and transfers a unique ticket upon purchase, as an instance of the TICKET token;
    */

    function buy(uint256 row, uint256 seat_number) public payable {
        buyer = payable(msg.sender);
        require(status == show_status.Scheduled, "This show is not scheduled");
        require(row >= 1 && row <= 3 , "Pick row number between 1 and 3");
        require(seat_number >= 1 && seat_number <= 20, "Pick seat number between 1 and 20");
        
        bytes32 mapping_key = keccak256(abi.encodePacked(row, seat_number));
        require(seats[mapping_key].owner == address(0), "This seat is already taken!");
        
        number_of_tickets_sold = myTicket.buy(buyer, seats[mapping_key].title, seats[mapping_key].date, row, seat_number, seats[mapping_key].price, seats[mapping_key].set_view_link);
        tokenOwners[number_of_tickets_sold] = buyer;
        seats[mapping_key].owner = buyer;
    }
    
    /* implement a function "verify" that allows anyone with the token ID to checkthe validity of the ticket and the address it is supposed to be used by */
    function verify(uint256 tokenID) public view returns(bool){
        /* Verify that an address owns this token */
        bool is_owner = tokenOwners[tokenID] == msg.sender;
        require(is_owner);
        return is_owner;
    }
    
    /* implement a function "refund" to refund tickets if a show gets cancelled; */
    function refund() onlySeller public payable{
        /* Refund funds to ticket owners in case of cancelled show */
        /* Accumulate refund amount for each of the addresses that own ticket(s)*/
        status = show_status.Cancelled;
        for (uint256 r_nr = 1; r_nr <= n_rows; r_nr++) {
            for (uint256 c_nr = 1; c_nr <= n_seats_per_row; c_nr++) {
                bytes32 mapping_key = keccak256(abi.encodePacked(r_nr, c_nr));
                Seat memory seat = seats[mapping_key];
                if(seat.owner != address(0)){
                    payback_amount[seat.owner] = payback_amount[seat.owner] + seat.price;
                }
            }
        }
        /* Refund the tickets bought by each address*/
        for (uint256 token_ID = 0;  token_ID <= number_of_tickets_sold; token_ID++) {
            address payable owner_address = tokenOwners[token_ID];
            uint256 amount = payback_amount[owner_address];
            (bool success, ) = owner_address.call{value:amount}("");
            require(success, "Transfer failed.");
            myTicket.burn(token_ID);
        }
    }
    
    /*  implement a function "validate"2 to validate a ticket; it can be called onlyin a specific time frame,
    corresponding to a suitable amount of time before thebeginning of the show.
    Upon validation, the ticket is destroyed, and a functionreleasePosterreleases unique proof of purchase (you may consider merging thesetwo functions together).
    This new item must be a unique instance of a POSTERtoken;
    */
    function validate(uint256 tokenID) public{
    /* Exchange a ticket for a poster a short time before the show starts*/
        /* TODO: Add logic to this bool*/
        bool correctTimeFrame = (status == show_status.On);
        require(correctTimeFrame, "The validate function is not available in this time frame");
        require(verify(tokenID),"This user does not own this ticket");
        myPoster.releasePoster(msg.sender);
        myTicket.burn(tokenID);
    }
    //function tradeTicketForEther(address seller, uint256 ticketID, address buyer) public {/* TODO In the case of exchange user1's ticket for ether*/}
    //function tradeTickets(address seller, uint256 ticketID, address buyer) public{/* TODO In the case of two user exchanging tickets*/}
    
    /* TODO implement a function "tradeTicket" that allows users C and D to safely trade (i.e.exchange for another or sell for ether) a ticket directly between each other.*/
    function tradeTicket(address user1_address, uint256 user1_ticketID, address user2_address, uint256 user2_ticketID) public{
    }
}
