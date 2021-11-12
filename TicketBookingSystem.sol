pragma solidity >=0.7.0 <0.9.0;

contract TicketBookingSystem{
    /**
     * For each show, initialize the smart contract with the title of the show, the
     * available seats and any other relevant information. Each seat is an object that
     * contains at least
     * title and date of the show,
     * the price;
     * the seat number and row;
     * a link to the seat view (to realize a service offered, for example, by seatplan.com). It does not need to be working, but set up a field for it;
     */

    //string funker = "funker";

    Show[] public show;
    Member[] public member;
    int256 public showCount = 0;

    struct Show {
        string title;
        int256 availableSeats;
    }

    struct Member {
        // Name is either A, B, C or D
        string name;
    }

    function addMember(string memory name) public {
        member.push(Member(name));
    }

    // Add show to the array
    function addShow(string memory title, int256 availableSeats) public {
        show.push(Show(title, availableSeats));
        incrementCount();
    }

    function incrementCount() internal {
        showCount += 1;
    }

    /**
    * Code to implement
    function buy() {

    }

    function verify() {

    }

    function refund() {

    }

    function validate() {

    }
    */
}