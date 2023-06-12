// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SBT.sol";

contract EntradasEventos is Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    SBT public sbt;

    string public nameEvent;

    uint32 public maxTickets;
    uint32 public ticketsAvailable; //How many tickets are available for sale
    uint16 public ticketPrice;
    uint64 public globalScore; //How has been sold
    uint256 public totalEarned; //How much money has been earned

    mapping(address => mapping(uint256 =>SBT.Soul)) private soldTickets; //address => tickets SBT
    
    mapping(uint256 => SBT.Soul) public canceledTickets; //Tickets that have been canceled
    mapping(address => uint256) private allowedToBuyTicket;

    event SoldTicket(address indexed buyer, uint256 score);
    event ResellTicket(address indexed oldOwner, address indexed buyer, uint256 score);
    event CanceledTicket(address indexed buyer, uint256 score);

    constructor(
        uint32 _maxTickets,
        uint16 _ticketPrice,
        address _sbtAddress,
        string memory _nameEvent
    ){
        maxTickets = _maxTickets;
        ticketPrice = _ticketPrice;
        ticketsAvailable = _maxTickets;
        globalScore = 0;
        nameEvent = _nameEvent;        
        sbt = SBT(_sbtAddress);
    }
     
    function buyTickets(address buyer, uint256 quantity) public payable nonReentrant {
        require(quantity > 0, "Quantity must be greater than zero");
        require(allowedToBuyTicket[buyer] >= quantity, "You have to pay the previous ticket first");
        require(ticketsAvailable >= quantity, "Not enough tickets available");
        
        for (uint256 i = 0; i < quantity;) {
            buyTicket(buyer);
            unchecked {
                i++;
            }
        }
    }

    function buyTicket(address _buyer) public payable nonReentrant {
        require(msg.sender == _buyer, "You can only buy tickets for yourself");
        require(allowedToBuyTicket[_buyer] != 0, "You have to pay the previous ticket first");
        require( ticketsAvailable != 0, "Not enough tickets available");

        sbt.mint(_buyer, SBT.Soul({
            id: nameEvent,
            url: "",
            score: ++globalScore, //Contador de entradas
            timestamp: block.timestamp,
            owner: _buyer,
            available: false // If a ticket its put on resall mode, it will be available again
        }));

        soldTickets[_buyer][globalScore] = SBT.Soul({
            id: nameEvent,
            url: "",
            score: globalScore, //Contador de entradas
            timestamp: block.timestamp,
            owner: _buyer,
            available: false // If a ticket its put on resall mode, it will be available again
        });

        --allowedToBuyTicket[_buyer];
        --ticketsAvailable;

        emit SoldTicket(_buyer, globalScore);
    }
   

    //You can get refund if you cancel your tickets X time before the eventq
    function cancelTickets(uint256[] memory _scores) external nonReentrant {
        require(_scores.length > 0, "Not enough tickets to cancel");
        
        for(uint256 i = 0; i < _scores.length; i++) {
            _cancelTicket(_scores[i], msg.sender);
        }
    }

    function _cancelTicket(uint256 _score, address _buyer) internal onlyOwner{
        ///@dev: Is checked that the ticket with that score exists?
        require(soldTickets[_buyer][_score].owner == _buyer, "You are not the owner of this ticket");
        require(soldTickets[_buyer][_score].available == false, "The ticket is not on resell mode");
        
        canceledTickets[_score] = soldTickets[_buyer][_score];
        delete soldTickets[_buyer][_score];

        sbt.burn(msg.sender); //burn se debería hacer solo por contratos autorizados

        emit CanceledTicket(msg.sender, _score);
        
    }

    function resellTicket(uint256 _score, address _buyer, address newOwner) internal onlyOwner{
        ///@dev: Is checked that the ticket with that score exists?
        require(soldTickets[_buyer][_score].owner == _buyer, "You are not the owner of this ticket");
        require(soldTickets[_buyer][_score].available == false, "The ticket is not on resell mode");
        require(newOwner != address(0), "You can't sell a ticket to address 0");

        canceledTickets[_score] = soldTickets[_buyer][_score];
        delete soldTickets[_buyer][_score];

        sbt.burn(msg.sender); //burn se debería hacer solo por contratos autorizados

        sbt.mint(newOwner, SBT.Soul({
            id: nameEvent,
            url: "",
            score: _score, //Contador de entradas
            timestamp: block.timestamp,
            owner: newOwner,
            available: false // If a ticket its put on resall mode, it will be available again
        }));

        emit ResellTicket(msg.sender, newOwner, _score);
        
    }

    ///@dev when user pays for a ticket, he can mint the tickets
    function allowToBuyTickets(address _buyer, uint256 _quantity) external payable onlyOwner {
        require(_quantity != 0, "Quantity must be greater than zero");
        require(ticketsAvailable >= _quantity, "Not enough tickets available");
        require(msg.value == ticketPrice *_quantity, "No se ha enviado suficiente ETH");

        totalEarned += msg.value;
        allowedToBuyTicket[_buyer] = _quantity;
    }

    ///@dev called by frontend to get the price of the ticket
    function automaticTicketPrice() public view returns(uint256) {
        require(maxTickets != 0 &&
                ticketsAvailable != 0, "Theres no tickets available");

        uint256 initialPrice = ticketPrice;
        uint256 maxPrice = initialPrice * 3;
        uint256 soldPercentage = (globalScore * 100) / maxTickets;
        uint256 priceIncrement = (soldPercentage * (maxPrice - initialPrice)) / 100;

        return initialPrice + priceIncrement;
    }
}
