pragma solidity ^0.4.18;

import "./StandardToken.sol";

// After instantiation make sure to call 
// allocateDelayedTokens on every partners/advisors you want 
// after allocating all (or part) of additional supply make sure
// to call the stopDelayedTokenAllocation() to close the allocation 
// of delayed supplies window
contract RockToken is StandardToken {

    // Holds delayed token allocation data
    struct DelayedToken {
        address receiver;
        uint256 amount;
        uint256 timestamp;
    }

    // UM
    uint256 public million = 1000000;
    uint8 public constant decimals = 18;
    string public constant symbol = "RKT";
    string public constant name = "Rock Token";
    bool public canAllocateDelayedTokens;
    bool public canConvertTokens;
    address public delayedTokenCreator;
    
    // Inited in constructor
    address public contractOwner; // Can stop the allocation of delayed tokens and can allocate delayed tokens.
    address public masterContractAddress; // The ICO contract to issue tokens.

    // Delayed token allocation fields
    mapping (address => DelayedToken) private delayedTokenMapping;

    // Constructor 
    // Sets the contractOwner for the onlyOwner modifier
    // Sets the public values in the ERC20 standard token
    // Opens the delayed allocation window.
    function RockToken(address _masterContractAddress) public {
        
        contractOwner = msg.sender;
        masterContractAddress = _masterContractAddress;

        totalSupply = 0; 

        // Owner can allocate tokens 
        // after creating the contract
        canAllocateDelayedTokens = true;
        canConvertTokens = true;
    }

    // Use this after instantiation how many times needed but make 
    // sure after initialisation to call stopDelayedTokenAllocation()
    // delayedTokenCreator can also call this function
    function allocateDelayedTokens(address _receiver, uint256 _amount, uint256 _timestamp) onlyOwnerOrDelayedTokenCreator public {
        require(canAllocateDelayedTokens);
        delayedTokenMapping[_receiver] = DelayedToken(_receiver, _amount, _timestamp);
    }

    // Use this to close the delayed token allocation window
    function stopDelayedTokenAllocation() onlyOwner public {
        canAllocateDelayedTokens = false;
    }

    // Called by anyone that is includded in the delayedTokenMapping
    function claim() public {
        require(delayedTokenMapping[msg.sender].receiver != address(0));
        require(delayedTokenMapping[msg.sender].amount > 0);
        require(now >= delayedTokenMapping[msg.sender].timestamp);
        // transfer and delete
        balances[msg.sender] += delayedTokenMapping[msg.sender].amount;
        // increase totalSupply due to delayed allocation
        totalSupply += delayedTokenMapping[msg.sender].amount;
        // fire Transfer event for ERC-20 compliance
        Transfer(address(0), msg.sender, delayedTokenMapping[msg.sender].amount);
        delete delayedTokenMapping[msg.sender];
    }

    // Called by the master contract to set balance coins
    function convertTokens(uint256 _amount, address tokenReceiver) onlyMasterContract public {
        if (canConvertTokens && _amount > 0) {
            balances[tokenReceiver] += _amount;
            // fire Transfer event for ERC-20 compliance
            Transfer(address(0), tokenReceiver, _amount);
            totalSupply += _amount; 
        }        
    }

    function stopConvertTokens() onlyOwner public {
        canConvertTokens = false;
    }

    // Called by the token owner to block or unblock transfers
    function enableTransfers() onlyOwner public {
        transferEnabled = true;
    }

    function changeDelayedTokenCreator(address _delayedTokenCreator) onlyOwner public {
        delayedTokenCreator = _delayedTokenCreator;
    }

    function getDelayedAmountForAddress(address _address) public view returns ( address, uint256, uint256) {
      DelayedToken storage delayedToken = delayedTokenMapping[_address];
      return (delayedToken.receiver, delayedToken.amount, delayedToken.timestamp) ;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    modifier onlyOwnerOrDelayedTokenCreator() {
        require(msg.sender == contractOwner || msg.sender == delayedTokenCreator);
        _;
    }

    modifier onlyMasterContract() {
        require(msg.sender == masterContractAddress);
        _;
    }

}