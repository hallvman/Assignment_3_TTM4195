// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ticket is ERC721, Ownable {
    address public minterAddress;
    uint256 private tokenId;

    //maps tokenId to ticket information struct
    mapping(uint256 => TicketInfo) public ticketInfoMapping;

    struct TicketInfo {
        string showTitle;
        uint256 showDate;
        uint256 seatRow;
        uint256 seatNumber;
        address mintedBy;
    }

    constructor() ERC721("Ticket", "TKT") {
        minterAddress = msg.sender;
        tokenId = 0;
    }

    //this function mints a new ticket, and saves information about ticket info in ticketInfoMapping
    //against the tokenId
    function mintTicket(
        address receiver,
        string memory _showTitle,
        uint256 _showDate,
        uint256 _seatRow,
        uint256 _seatNumber,
        address _mintedBy
    ) external onlyOwner returns (uint256) {
        ticketInfoMapping[tokenId] = TicketInfo({
            showTitle: _showTitle,
            showDate: _showDate,
            seatRow: _seatRow,
            seatNumber: _seatNumber,
            mintedBy: _mintedBy
        });

        uint256 newTokenId = tokenId;
        _safeMint(receiver, newTokenId);
        tokenId += 1;
        return newTokenId;
    }

    //helper function to get the address who minted the ticket
    function mintedBy(uint256 _tokenId) external view returns (address) {
        return ticketInfoMapping[_tokenId].mintedBy;
    }

    //helper function to get show data from ticket id
    function getShowDateFromTicketId(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return ticketInfoMapping[_tokenId].showDate;
    }

    //check if ticket exists
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    //burn the ticket
    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}

contract Poster is ERC721, Ownable {
    uint256 private posterTokenId;

    constructor() ERC721("Poster", "PSTR") {
        uint256 posterTokenId = 0;
    }

    //mint new poster
    function mintNewPoster(address _to) external onlyOwner returns (uint256) {
        uint256 newTokenId = posterTokenId;
        _safeMint(_to, newTokenId);
        posterTokenId += 1;
        return posterTokenId;
    }
}

contract TicketBookingSystem {
    address payable public salesManager;
    address public ticketBuyer;
    string constant _seatViewLink = "https://seatplan.com/";
    uint256 numberOfSeatsPerRow = 10;
    uint256 numberOfRows = 2;
    uint256 totalNumberOfSeats = numberOfSeatsPerRow * numberOfRows;
    uint256 availableTickets = totalNumberOfSeats;
    uint256 showDate;
    string showTitle;
    uint256 price;
    ShowStatus showStatus;
    Ticket ticketInstance;
    Poster posterInstance;

    //this mapping stores amount to be refunded against each address if show gets cancelled
    mapping(address => uint256) amountToBeRefunded;

    //this mapping stores a Seat struct against each seat index (1-60)
    mapping(uint256 => Seat) public seats;

    //this mapping stores an array of ticketIds bought by each address
    //each address can purchase multiple tickets
    mapping(address => uint256[]) ticketsSold;

    enum ShowStatus {
        Scheduled,
        Over,
        Cancelled
    }

    constructor(
        string memory _showTitle,
        uint256 _showDate,
        uint256 _ticketPrice
    ) payable {
        bytes memory tempEmptyStringTest = bytes(_showTitle);

        //check if show title is empty string
        require(tempEmptyStringTest.length != 0, "Show title can not be empty");

        //check if show date is in past
        require(
            _showDate >= block.timestamp,
            "Show can not be scheduled in past"
        );
        //check if ticket price is > 0
        require(_ticketPrice > 0, "Ticket price must be greater than 0");

        //create new instance of Ticket token
        ticketInstance = new Ticket();
        posterInstance = new Poster();

        //set show date, title and price (assume each ticket is same price)
        showDate = _showDate;
        showTitle = _showTitle;
        price = _ticketPrice;

        //set sales manager account address
        salesManager = payable(msg.sender);

        //for each row and for each seat within row, initialize a seat struct
        for (uint256 row = 1; row <= numberOfRows; row++) {
            for (uint256 seat = 1; seat <= numberOfSeatsPerRow; seat++) {
                seats[seatIndex(row, seat)] = Seat({
                    isTaken: false,
                    showTitle: _showTitle,
                    showDate: _showDate,
                    ticketPrice: _ticketPrice,
                    seatRow: row,
                    seatNumber: seat,
                    seatViewLink: _seatViewLink
                });
            }
        }
    }

    /*
    this function returns the seat index from 1 to rows*seatsPerRow, so in this case
    it will return an index from 1 to 60. e.g., if row is 2 and seat is 13, index will
    be 33 
    */
    function seatIndex(uint256 row, uint256 seat) private returns (uint256) {
        return numberOfSeatsPerRow * (row - 1) + seat;
    }

    struct Seat {
        bool isTaken;
        string showTitle;
        uint256 showDate;
        uint256 ticketPrice;
        uint256 seatRow;
        uint256 seatNumber;
        string seatViewLink;
    }

    //helper function to get status of the show
    function statusOfShow() external view returns (string memory _status) {
        if (showStatus == ShowStatus.Scheduled) _status = "Scheduled";
        if (showStatus == ShowStatus.Over) _status = "Over";
        if (showStatus == ShowStatus.Cancelled) _status = "Cancelled";
    }

    //helper function to get information about the show
    function getShowInformation()
        external
        view
        returns (
            string memory ShowTitle,
            uint256 ShowDate,
            uint256 AvailableTickets
        )
    {
        return (showTitle, showDate, availableTickets);
    }

    //buy function which can be called by anyone to buy a ticket of the show
    function buy(uint256 rowNumber, uint256 seatNumber) public payable {
        ticketBuyer = payable(msg.sender);

        //check if show is scheduled
        require(
            showStatus == ShowStatus.Scheduled,
            "This show is not scheduled"
        );

        //check if row number is valid
        require(rowNumber >= 1 && rowNumber <= numberOfRows, "Invalid row");

        //check if seat number is valid
        require(
            seatNumber >= 1 && seatNumber <= numberOfSeatsPerRow,
            "invalid seat number"
        );

        //check if that seat is free
        require(
            seats[seatIndex(rowNumber, seatNumber)].isTaken == false,
            "This seat is already taken!"
        );

        //check if sender has sent amount equal to price of ticket
        require(msg.value == price, "Incorrect value");

        //mint new ticket
        uint256 tokenId = ticketInstance.mintTicket(
            ticketBuyer,
            showTitle,
            showDate,
            rowNumber,
            seatNumber,
            salesManager
        );

        //add ticketId to buyer's array of ticketIds purchased
        ticketsSold[ticketBuyer].push(tokenId);

        //occupy seat
        seats[seatIndex(rowNumber, seatNumber)].isTaken = true;

        //decrement remaining tickets
        availableTickets -= 1;

        //update amountToBeRefunded

        amountToBeRefunded[ticketBuyer] += price;

        //transfer gwei from buyer's address to salesManager address
        payable(salesManager).transfer(msg.value);
    }

    //verify function to check if ticket is valid, and check owner of ticket
    function verify(uint256 _tokenId)
        public
        view
        returns (bool isTicketValid, address ticketOwner)
    {
        //check if ticket exists
        require(ticketInstance.exists(_tokenId), "ticket does not exist");

        //check if minted by correct address and show date is in future
        address mintedBy = ticketInstance.mintedBy(_tokenId);

        if (
            mintedBy == salesManager &&
            ticketInstance.getShowDateFromTicketId(_tokenId) > block.timestamp
        ) isTicketValid = true;
        else isTicketValid = false;

        //get owner's address
        ticketOwner = ticketInstance.ownerOf(_tokenId);

        return (isTicketValid, ticketOwner);
    }

    // only sales manager should be able to call the function
    modifier onlySalesManager() {
        require(
            msg.sender == salesManager,
            "The calling address is not authorized"
        );
        _;
    }

    //this function cancels the show and refunds all tickets
    function refund() public onlySalesManager {
        //check if show is scheduled
        require(showStatus == ShowStatus.Scheduled, "Show is not scheduled");

        //update status of show
        showStatus = ShowStatus.Cancelled;

        //compute total tickets sold. last tokenId = number of tickets sold
        uint256 numberOfTicketsSold = totalNumberOfSeats - availableTickets;

        //for each tokenId
        for (uint256 i = 0; i < numberOfTicketsSold; i++) {
            //get address of buyer
            address ticketOwner = ticketInstance.ownerOf(i);
            //get amount to be refunded
            uint256 amount = amountToBeRefunded[ticketOwner];
            //refund amount
            payable(ticketOwner).transfer(amount);
            //destroy the ticket
            ticketInstance.burn(i);
        }
    }

    function releasePoster(address _to) internal {
        posterInstance.mintNewPoster(_to);
    }

    //this function validates a ticket before the show starts and releases a poster as unique proof of purchase
    function validate(uint256 _tokenId, address _ticketOwner)
        public
        onlySalesManager
    {
        //check if ticket exists
        require(ticketInstance.exists(_tokenId), "ticket does not exist");

        //check if show is scheduled
        require(showStatus == ShowStatus.Scheduled, "Show is not scheduled");

        //check if show is in future
        require(block.timestamp <= showDate, "Show is in the past");

        //check if current time is <= 1 hr before show starts
        require(
            showDate - block.timestamp <= 3600 seconds,
            "Can not validate ticket until only 1 hour left before the show starts"
        );

        //check if the person presenting the ticket is the owner of ticket
        require(
            ticketInstance.ownerOf(_tokenId) == _ticketOwner,
            "The user does not own this ticket"
        );

        //mint new poster
        releasePoster(_ticketOwner);
        //destroy the ticket
        ticketInstance.burn(_tokenId);
    }
}
