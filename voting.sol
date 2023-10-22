// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Voting {
    struct Proposal {
        address target;
        bytes data;
        uint yesCount;
        uint noCount;
    }

    Proposal[] public proposals;

    mapping(uint => mapping(address => bool)) public votes;
    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public isAllowed;

    event ProposalCreated(uint proposalId);
    event VoteCast(uint proposalId, address voter);

    constructor(address[] memory allowedAddresses) {
        isAllowed[msg.sender] = true; // Allow the deployer to create proposals and vote

        for (uint i = 0; i < allowedAddresses.length; i++) {
            isAllowed[allowedAddresses[i]] = true; // Allow the provided addresses to create proposals and vote
        }
    }

    function newProposal(address _target, bytes memory _data) external {
        require(isAllowed[msg.sender], "Not allowed to create a proposal");

        proposals.push(Proposal({
            target: _target,
            data: _data,
            yesCount: 0,
            noCount: 0
        }));

        emit ProposalCreated(proposals.length - 1);
    }

    function castVote(uint proposalId, bool vote) external {
        require(isAllowed[msg.sender], "Not allowed to vote");

        Proposal storage proposal = proposals[proposalId];

        if (hasVoted[proposalId][msg.sender]) {
            if (votes[proposalId][msg.sender]) {
                proposal.yesCount--;
            } else {
                proposal.noCount--;
            }
        }

        if (vote) {
            proposal.yesCount++;
            if (proposal.yesCount == 10) {
                // If the proposal has received 10 yes votes, execute it
                (bool success,) = proposal.target.call(proposal.data);
                require(success, "Execution failed");
            }
        } else {
            proposal.noCount++;
        }

        votes[proposalId][msg.sender] = vote;
        hasVoted[proposalId][msg.sender] = true;

        emit VoteCast(proposalId, msg.sender);
    }
}