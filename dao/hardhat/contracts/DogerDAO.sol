// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IDAO {

    //vote type enum against,for,abstain
    //vote state enum notFound, active, success, failed, readyForExecution
    //proposal vote struct againstvote, forvote, abstainvote and voted mapping(shows if voter voted or not)
    //proposal core votestart, voteend and bool executed , bool cancelled, state proposal state

    enum VoteType {
        Against,
        For,
        Abstain
    }

    enum State {
        NotFound,
        Active,
        Success,
        Failed,
        ReadyForExecution
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) voted;
    }

    struct ProposalCore {
        uint voteStart /* block number to start vote */;
        uint voteEnd /* block number that ends vote */;
        bool executed;
        bool cancelled;
        State proposalState;
    }

    event ProposalCreated(
        uint256 indexed proposalId,
        address proposer,
        address[] targetContracts,
        uint[] values,
        string[] targetsLength,
        bytes[] calldatas,
        uint startBlock,
        uint endBlock,
        string description
    );

    event ProposalExecuted(uint256 indexed proposalId);
    event proposalCancelled(uint256 indexed proposalId);

    event Voted(uint256 indexed proposalId,address indexed voter, VoteType support);

    function propose(
        address[] memory targets,
        uint[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function execute(
        uint256 proposalId,
        address[] memory targets,
        uint[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external returns (bool);

    function vote(uint256 proposalId, uint8 support) external;

    function hasVoted(uint proposalId, address voter) external view returns (bool);

    function state(uint proposalId) external view returns (State);
    
}

interface INFTCollection {
    function balanceOf(address owner) external view returns(uint);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint);
}

contract DogerDAO is IDAO {
    mapping(uint256 => ProposalVote) public _proposalVotes;
    mapping(uint256 => ProposalCore) public _proposals;
    uint256 public numProposals;
    uint256 public votingDuration; /* duration of a proposal in number of blocks, 300 blocks ~= 5 minutes */
    INFTCollection public DogerPupsNFTCollection;
    IERC20 public DogerInuToken;

    constructor (address _DogerPupsNFTCollection, address _DogerInuToken, uint256 _votingDuration) {
        DogerPupsNFTCollection = INFTCollection(_DogerPupsNFTCollection);
        DogerInuToken = IERC20(_DogerInuToken);
        votingDuration = _votingDuration;
    } 

    function hashProposal(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    function state(uint proposalId) public view returns (State proposalState) {
        uint currentBlock = block.number;
        ProposalCore storage proposal = _proposals[proposalId];
        
        if(proposal.proposalState == State.NotFound){
            return State.NotFound;
        }

        if(currentBlock < proposal.voteEnd && proposal.proposalState == State.Active){
            return State.Active;
        }

        if(proposal.voteEnd <= currentBlock && proposal.executed == true){
            return State.Success;
        }

        if(proposal.voteEnd <= currentBlock && proposal.cancelled == true){
            return State.Failed;
        }

        if(currentBlock > proposal.voteEnd  && proposal.executed == false && proposal.cancelled == false){
            //deadline passed but not yet executed
            return State.ReadyForExecution;
        }
    }

    function hasVoted(
        uint256 proposalId,
        address voter
    ) public view returns (bool) {
        return _proposalVotes[proposalId].voted[voter];
    }

    function propose(
        address[] memory targets,
        uint[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        require(DogerPupsNFTCollection.balanceOf(msg.sender) > 0, "You need Doger Pups NFT to create proposal");
        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length,"Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");

        uint256 proposalId = hashProposal(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        ProposalCore storage proposal = _proposals[proposalId];
        require(
            proposal.proposalState != State.Active,
            "Governor: Duplicate proposal"
        );

        uint startBlock = block.number;
        uint endBlock = block.number + votingDuration;

        proposal.voteStart = startBlock;
        proposal.voteEnd = endBlock;
        proposal.proposalState = State.Active;

        numProposals += 1;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            startBlock,
            endBlock,
            description
        );

        return proposalId;
    }

    function vote(uint256 proposalId, uint8 support) external {
        require(DogerInuToken.balanceOf(msg.sender) > 0, "Governor: You need Doger Inu in your wallet to vote");
        require(hasVoted(proposalId, msg.sender) == false, "Governor: You have already voted");
        require(state(proposalId) == State.Active, "Governor: Proposal is not active to vote");

        _proposalVotes[proposalId].voted[msg.sender] = true;
        if(support == 0){
            _proposalVotes[proposalId].againstVotes += 1;
        }

        if(support == 1){
            _proposalVotes[proposalId].forVotes += 1;
        }

        if(support == 2){
            _proposalVotes[proposalId].abstainVotes += 1;
        }

        emit Voted(proposalId, msg.sender, VoteType(support));
    }

    
    function execute(
        uint256 proposalId,
        address[] memory targets,
        uint[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public returns (bool execution) {
        uint256 GeneratedproposalId = hashProposal(targets, values, calldatas, descriptionHash);
        require(proposalId == GeneratedproposalId, "Governor: proposal ID doesn't match");
        require(state(proposalId) == State.ReadyForExecution, "Governor: proposal must be in ready for execution state");
        //count the vote
        ProposalVote storage votes = _proposalVotes[proposalId];
    
        if(votes.forVotes < votes.againstVotes || (votes.forVotes == 0 && votes.againstVotes == 0)){
            _proposals[proposalId].cancelled = true;
            emit proposalCancelled(proposalId);
            return true;
        } else {
            _proposals[proposalId].executed = true;

            emit ProposalExecuted(proposalId);

            for (uint256 i = 0; i < targets.length; ++i) {
                (bool success, ) = targets[i].call{value: values[i]}(calldatas[i]);

                if (success) {
                    return true;
                } else {
                    revert("Governor: call reverted without message");
                }
            }
        }
    }
}