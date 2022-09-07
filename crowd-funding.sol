// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

contract CrowdFunding {
    address private _admin;
    uint private  _funding_goal;
    uint public goal;
    uint public deadline;
    uint public _minimumContribution;
    uint public raisedFunding;
    mapping(address => uint) private _fundings;
    uint private _numOfFunders;
    struct Request{
        string desc;
        address payable recipient;
        uint value;
        bool isCompleted;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numberOfRequest;

    constructor(uint _goal, uint _deadline) {
        // The admin is contract creator. (msg.sender)
        _admin = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _deadline;
        // Minimum contribution value is 250 wei;
        _minimumContribution = 250 wei;
    }

    // Modifiers
    modifier onlyAdmin {
        require(_admin == msg.sender, "Only admin can do this action.");
        _;
    }

    // Functions

    //contribute
    function contribute() public payable{
        require(msg.value >= _minimumContribution, "Minimum contribution value is 250 wei.");
        require(block.timestamp <= deadline, "The campaign is dead.");

        // There is not a funding before by msg.sender.
        if(_fundings[msg.sender] == 0){
            _numOfFunders += 1; 
        }

        // Add funding to the _fundings.
        _fundings[msg.sender] += msg.value;
        raisedFunding += msg.value;
    }

    // refund
    function getRefund() public payable {
        require(block.timestamp > deadline && raisedFunding < goal, "You cannot refund. Because the campaing is dead or the goal less than the raised funding");
        require(_fundings[msg.sender] > 0, "You didn't fund anything.");

        // get funding amount from _fundings
        uint amount = _fundings[msg.sender];
        // refund to the msg.sender (recipient)
        address payable recipient = payable(msg.sender);
        // Refund to the recipient.
        recipient.transfer(amount);
        // Remove funder from the _fundings after tranfers process.
        _fundings[msg.sender] = 0;
    }
    
    // if the contract receive value, start to contribute function
    receive() payable external {
        contribute();
    }

    // Get the contract balance 
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function setRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
       // create request by index
        Request storage newReq = requests[numberOfRequest];
        // increase request count
        numberOfRequest++;
        
        // Fill request struct values
        newReq.desc = _description;
        newReq.recipient = _recipient;
        newReq.value = _value;
        // request is not completed because the request is new
        newReq.isCompleted = false;
        // number of voters is zero
        newReq.numberOfVoters = 0;
    }

    // Vote for a request
    function voteForRequest(uint _requestIndex) public{
        require(_fundings[msg.sender] > 0, "You must be a funder to vote.");
        // select the request by index
        Request storage req = requests[_requestIndex];
        require(req.voters[msg.sender] == false, "You have already voted this request.");
        // If msgsender votes let's set bool to true and increase numberOfVoters count.
        req.voters[msg.sender] = true;
        req.numberOfVoters++; 
    }

    // make payment after selecting request by index
    function makePaymentForRequest(uint _requestIndex) public onlyAdmin{
        require(raisedFunding >= goal, "Expected donation must exceed target.");
        Request storage req = requests[_requestIndex];
        require(req.isCompleted == false, "The request has been completed.");
        require(req.numberOfVoters > _numOfFunders / 2, "50% of funders must vote.");

        // Tranfer ETH to the recipient of the request.
        req.recipient.transfer(req.value);
        // The request is completed. (true)
        req.isCompleted = true;
    }

}
