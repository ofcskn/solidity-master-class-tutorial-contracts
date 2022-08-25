// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery{
    // The lottery manager
    address public owner;
    // The lottery players
    address payable[] public players;

    // THe constructor of the contract
    constructor(){
        owner = msg.sender;
    }

    // The contract need to receive ETH from the lottery players
    receive() payable external{
        // The lottery value condition is 0.1 ETH 
        require(msg.value == 0.1 * 10 **18);
        // If the amount is enough, add the player to the players array.
        players.push(payable(msg.sender));
    }

    function getBalanceOfLottery() public view returns(uint){
       // getBalanceOfLottery() function is only called by the owner (manager)
        require(msg.sender == owner);
        return address(this).balance;
    }

    // Generate random number for selecting winner.
    function randomNumberGenerator() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function selectWinner() payable public {
       // selectWinner() function is only called by the owner (manager)
        require(msg.sender == owner);
        // the lottery game players length > 2
        require(players.length >= 2);

        // Payable winner address
        address payable winner;

        // get the winner by the random number mode
        uint indexOfWinner = randomNumberGenerator() % players.length;
        // select winner in the players array
        winner = players[indexOfWinner];
        // transfer balance of the contract to the winner
        winner.transfer(address(this).balance);
        // remove the players for reseting the game
        players = new address payable[](0);

    }

}
