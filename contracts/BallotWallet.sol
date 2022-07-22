// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/** @dev Represents a vote. */
struct Ballot {
    address voter;
    uint voteTime;
    bool affirmed;
}

/** @dev An action need executing. */
struct Action {
    uint id;
    address starter;
    uint startTime;
    uint executionTime;
    uint cancellationTime;
    bytes data;
    bool executed;
    bool cancelled;
}

/** @title A contract for voting-action system. */
contract BallotWallet {

    /** @dev The address of execution contract. */
    address execution;

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

    /** @dev Receives ethers. */
    receive() external payable {}

    /** @dev Starts a voting to execute an action. */
    fallback() external payable {
        require(isVoter(msg.sender), "No permission to start a voting");
        uint actionId = total;
        actions[actionId] = Action({
            id: actionId,
            starter: msg.sender,
            startTime: block.timestamp,
            executionTime: 0,
            cancellationTime: 0,
            data: msg.data,
            executed: false,
            cancelled: false
        });
        emit VotingStarted(actionId, msg.sender);
        total = actionId + 1;
    }

    constructor(
        address _execution,
        uint _threshold,
        uint _timeout,
        address[] memory _voters
    ) {
        require(_threshold >= 1, "Threshold must be greater than 0");
        require(_timeout >= 300, "Timeout cannot be less than 5 minutes");
        require(_voters.length >= _threshold, "Number of voters cannot be less than its threshold");
        execution = _execution;
        threshold = _threshold;
        timeout = _timeout;
        voters = _voters;
    }

    /** @dev Checks if an address is belong to a voter or not. */
    function isVoter(address _address) public view returns (bool) {
        uint totalVoters = voters.length;
        for (uint index = 0; index < totalVoters; index++) {
            if (voters[index] == _address) {
                return true;
            }
        }
        return false;
    }

    /** @dev Permits only the voters to execute stuff. */
    modifier onlyVoter() {
        require(isVoter(msg.sender), "No permission to vote");
        _;
    }

    /** @dev Emitted when a voter starts a voting. */
    event VotingStarted(uint indexed actionId, address indexed starter);

    /** @dev Emitted when a voter votes for an action. */
    event Voted(uint indexed actionId, address indexed voter);

    /** @dev Emitted when an action is executed. */
    event ActionExecuted(uint indexed actionId);

    /** @dev Emitted when an action is cancelled. */
    event ActionCancelled(uint indexed actionId);

    /** @dev Views a specific action. */
    function peek(uint _actionId) public view onlyVoter returns (Action memory) {
        require(_actionId < total, "Action not found");
        return actions[_actionId];
    }

    /** @dev Votes to or not to execute a specific action. */
    function vote(uint _actionId, bool _affirmed) public onlyVoter returns (bool, bytes memory) {
        require(_actionId < total, "Action not found");
        require(voted[_actionId][msg.sender] != true, "Already voted");
        Action storage action = actions[_actionId];
        require(action.executed == false, "Action executed");
        require(action.cancelled == false, "Action cancelled");
        require(action.startTime + timeout > block.timestamp, "Action timeout");

        // Add new ballot
        ballots[_actionId].push(Ballot({
            voter: msg.sender,
            voteTime: block.timestamp,
            affirmed: _affirmed
        }));
        // Mark that the voter has voted
        voted[_actionId][msg.sender] = true;
        emit Voted(_actionId, msg.sender);

        // Try execute the action
        return execute(action);
    }

    /** @dev Executes a specific action if it has enough voters. */
    function execute(Action storage _action) private returns (bool, bytes memory) {
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
            (bool success, bytes memory result) = address(execution).call(_action.data);
            if (success) {
                _action.executionTime = block.timestamp;
                _action.executed = true;
                emit ActionExecuted(_action.id);
                return (success, result);
            }
        } else if (totalBallots - totalAffirmations >= threshold) {
            _action.cancellationTime = block.timestamp;
            _action.cancelled = true;
            emit ActionCancelled(_action.id);
        }
        return (false, "");
    }
}