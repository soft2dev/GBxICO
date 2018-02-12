pragma solidity ^0.4.18;

import "./GBxMasterContract.sol";
import 'zeppelin-solidity/contracts/ReentrancyGuard.sol';

contract GBxInvestorContract is ReentrancyGuard {

    // instantiated from constructor 
    uint public icoInvestorCap;    
    // instantiated from constructor 
    address public investorWalletAddress;
    // instantiated from constructor 
    GBxMasterContract public masterContract;
    // gets updated from the payable function
    uint public amountPaid;

    function GBxInvestorContract(address _masterContractAddress, address _investorWalletAddress, uint _icoInvestorCap) public {
        // references to user wallet and master contract address
        investorWalletAddress = _investorWalletAddress;
        icoInvestorCap = _icoInvestorCap;        
        masterContract = GBxMasterContract(_masterContractAddress);
    }

    // 
    // Actual payment method that. 
    function() public payable nonReentrant {
        
        // VALIDATE

        // payable function should only be accessed by the userWalletAddress
        // that can only be a person not a contract (tx.origin use).


        require (tx.origin == investorWalletAddress && msg.sender == investorWalletAddress);

        // ask the master if the transfer should be allowed
        // the master should be the only decision maker and expose the answer 
        // through this method. 
        uint acceptedValue = masterContract.getAcceptedValueForInvestor(this, msg.value);
        address coldWallet = masterContract.coldWalletAddress();
        require (acceptedValue != 0);
        require (coldWallet != address(0));

        // MODIFY STATE

        // transfer amount to cold wallet
        // and return money to user back.
        
        amountPaid += acceptedValue;        
        // report transaction to master.
        masterContract.reportUserEthTransfer(acceptedValue);

        // DO ACTUAL TRANSFER

        coldWallet.transfer(acceptedValue);
        uint returnValue = msg.value - acceptedValue;
        if (returnValue != 0) {
            tx.origin.transfer(returnValue);
        }

    }



}