// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Ballot {
    address voter;
    uint voteTime;
    bool affirmed;
}

struct Action {
    uint id;
    address contractAddress;
    address starter;
    uint startTime;
    string functionName;
    bytes parameters;
}

/** @title A contract for voting-action system. */
contract BallotWallet {

    /** @dev Contains all voters. */
    address[] voters;

    /** @dev The minimum number of affirmations that an action can be executed. */
    uint threshold = 1;

    /** @dev Specifies the seconds a voting can last. */
    uint timeout = 300;

    /** @dev Total numbers of actions created. */
    uint total = 0;

    /** @dev Contains all actions created. */
    mapping(uint => Action) actions;

    /** @dev Contains all ballots for an action. */
    mapping(uint => Ballot[]) ballots;

    /** @dev Indicates that a voter has voted for an action or not. */
    mapping(uint => mapping(address => bool)) voted;

    constructor(uint _threshold, uint _timeout, address[] memory _voters) {
        require(_threshold >= 1, "Threshold must be greater than 0");
        require(_timeout >= 300, "Timeout cannot be less than 5 minutes");
        require(_voters.length >= _threshold, "Number of voters cannot be less than its threshold");
        threshold = _threshold;
        timeout = _timeout;
        voters = _voters;
    }

    /** @dev Permits only the voters to execute stuff. */
    modifier onlyVoter() {
        uint totalVoters = voters.length;
        bool canVote = false;
        for (uint index = 0; index < totalVoters; index++) {
            if (voters[index] == msg.sender) {
                canVote = true;
                break;
            }
        }
        require(canVote, "No permission to vote");
        _;
    }

    /** @dev Emitted when a voter starts a voting. */
    event VotingStarted(uint actionId, address starter);

    /** @dev Emitted when a voter votes for an action. */
    event Voted(uint actionId, address voter);

    /** @dev Emitted when an action is executed. */
    event ActionExecuted(uint actionId);

    /** @dev Starts a voting to execute an action. */
    function start(address _contractAddress, string memory _functionName, bytes calldata _parameters) public onlyVoter {
        uint actionId = total;
        actions[actionId] = Action({
            id: actionId,
            contractAddress: _contractAddress,
            starter: msg.sender,
            startTime: block.timestamp,
            functionName: _functionName,
            parameters: _parameters
        });
        emit VotingStarted(actionId, msg.sender);
        total = actionId + 1;
        vote(actionId);
    }

    /** @dev Votes to or not to execute a specific action. */
    function vote(uint _actionId) public onlyVoter returns (bool, bytes memory) {
        require(_actionId < total, "Action not found");
        require(voted[_actionId][msg.sender] != true, "Already voted");
        Action memory action = actions[_actionId];
        require(action.startTime + timeout > block.timestamp, "Action timeout");

        // Add new ballot
        ballots[_actionId].push(Ballot({
            voter: msg.sender,
            voteTime: block.timestamp,
            affirmed: true
        }));
        // Mark that the voter has voted
        voted[_actionId][msg.sender] = true;
        emit Voted(_actionId, msg.sender);

        // Try execute the action
        (bool success, bytes memory result) = execute(action);
        if (success == true) {
            emit ActionExecuted(_actionId);
        }
        return (success, result);
    }

    /** @dev Executes a specific action if it has enough voters. */
    function execute(Action memory _action) private returns (bool, bytes memory) {
        // Count the number of voters that have affirmed the action
        Ballot[] memory currentBallots = ballots[_action.id];
        uint totalBallots = currentBallots.length;
        uint totalAffirmations = 0;
        for (uint index = 0; index < totalBallots; index++) {
            if (currentBallots[index].affirmed == true) {
                totalAffirmations += 1;
            }
        }

        // Only execute the action if there are enough affirmations
        if (totalAffirmations >= threshold) {
            return _action.contractAddress.call(
                abi.encodeWithSignature(_action.functionName, _action.parameters)
            );
        }
        return (false, "");
    }
}