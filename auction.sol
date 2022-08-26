// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;

    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        /*Anladığım kadarıyla bu endBlock, startblock
        başladıktan sonra en son kaç tane blok olacağını belirtiyor */
        endBlock = startBlock + 3;
        ipfsHash = "";
        bidIncrement = 1000000000000000000;
    }

    //teklif artışı
    uint bidIncrement;

    //Not owner require function
    modifier _notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier _afterStart(){
        require(block.number > startBlock);
        _;
    }

    modifier _beforeEnd(){
        require(block.number < endBlock);
        _;
    }

    modifier _onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function cancelAuction() public _onlyOwner{
        auctionState = State.Canceled;
    }

    function min(uint a, uint b) public pure returns(uint){
        if(a > b){
            return b;
        }
        else{
            return a;
        }
    }

    function finalizeAuction() public{
        //must be canceled or reached to latest block number.
        require(auctionState == State.Canceled || block.number > endBlock);
        //The sender must be owner or sended bid.
        require(msg.sender == owner || bids[msg.sender] > 0);

        //define recipent address
        address payable recipent;
        //define to how many price will be got?
        uint value;

        //Auction was canceled
        if(auctionState == State.Canceled){
            recipent = payable(msg.sender);
            value = bids[msg.sender];
        }else{//auction was ended (not canceled)
            if(msg.sender == owner){
                recipent = owner;
                value = highestBindingBid;
            }
            else{
                if(msg.sender == highestBidder){
                    recipent = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }
                else{
                    recipent = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        //Reset
        bids[recipent] = 0;
        recipent.transfer(value);
    }

    function placeBid() public payable _notOwner _afterStart _beforeEnd{
        require(auctionState == State.Running);
        require(msg.value >= 100);
        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }
        else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }
}
