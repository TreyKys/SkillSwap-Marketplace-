// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, CANCELED }

    struct Gig {
        address payable seller;
        address payable buyer;
        uint256 price;
        State state;
    }

    mapping(uint256 => Gig) public gigs;
    uint256 public nextGigId;

    event GigCreated(uint256 gigId, address seller, address buyer, uint256 price);
    event Funded(uint256 gigId);
    event Confirmed(uint256 gigId);
    event Canceled(uint256 gigId);

    function createGig(address payable _seller, uint256 _price) external {
        gigs[nextGigId] = Gig({
            seller: _seller,
            buyer: payable(msg.sender),
            price: _price,
            state: State.AWAITING_PAYMENT
        });
        emit GigCreated(nextGigId, _seller, msg.sender, _price);
        nextGigId++;
    }

    function fundGig(uint256 _gigId) external payable {
        Gig storage gig = gigs[_gigId];
        require(msg.sender == gig.buyer, "Only the buyer can fund.");
        require(msg.value == gig.price, "Must send the exact price.");
        require(gig.state == State.AWAITING_PAYMENT, "Gig is not awaiting payment.");

        gig.state = State.AWAITING_DELIVERY;
        emit Funded(_gigId);
    }

    function confirmDelivery(uint256 _gigId) external {
        Gig storage gig = gigs[_gigId];
        require(msg.sender == gig.buyer, "Only the buyer can confirm.");
        require(gig.state == State.AWAITING_DELIVERY, "Gig is not awaiting delivery.");

        gig.state = State.COMPLETE;
        (bool success, ) = gig.seller.call{value: gig.price}("");
        require(success, "Transfer failed.");
        emit Confirmed(_gigId);
    }

    function cancelGig(uint256 _gigId) external {
        Gig storage gig = gigs[_gigId];
        require(msg.sender == gig.buyer || msg.sender == gig.seller, "Only parties can cancel.");
        require(gig.state != State.COMPLETE, "Cannot cancel a completed gig.");

        if (gig.state == State.AWAITING_DELIVERY) {
            // Refund the buyer if the gig was already funded
            (bool success, ) = gig.buyer.call{value: gig.price}("");
            require(success, "Refund failed.");
        }

        gig.state = State.CANCELED;
        emit Canceled(_gigId);
    }
}
