pragma solidity ^0.4.18;
import "./GBxUserContract.sol";
import "./GBxInvestorContract.sol";
import "../GBxTOKEN/RockToken.sol";
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract GBxMasterContract {

    event CreateUserContractEvent(
        address userWalletAddress, 
        address userContractAddress
    );
    
    event CreateInvestorContractEvent(
         address investorWalletAddress, 
         address investorContractAddress
    );

    event FundsTransferEvent(
        address indexed userAddress,
        uint value,
        address indexed userWalletAddress
    );

    // fields
    address public contractOwnerAddress;
    address public coldWalletAddress;
    address public rockTokenAddress;
    address public userContributionCreator;
    uint public icoFunds; //total funds raised
    uint public maxFunds;
    uint public icoCapPerUser;
    uint public icoStartDate;
    uint public icoPhase2StartDate;
    uint public icoEndDate;
    uint public weiRockTokenParity;

    // mappings
    mapping (address => address) private userWalletContractMapping; // maps userWalletAddress with UserContractAddress
    mapping (address => address) private investorWalletContractMapping; // maps investorWalletAddress with InvestorContractAddress

    function GBxMasterContract(address _coldWalletAddress) public {
        contractOwnerAddress = msg.sender; 
        coldWalletAddress = _coldWalletAddress;
    }

    function setRockTokenAddress(address _rockTokenAddress) public onlyOwner {
        rockTokenAddress = _rockTokenAddress;
    }

    function setWeiRockTokenParity(uint _weiRockTokenParity) public onlyOwner {
        weiRockTokenParity = _weiRockTokenParity;
    }

    function createUserContracts(address[] userWallets) public onlyOwnerOrUserContributionCreator {
        // creates the GBxUserContract and saves its address
        for (uint i = 0; i < userWallets.length; i++) {
            address contractInstance = new GBxUserContract(this,userWallets[i]);
            // save in mapping only if it is not already mapped
            // validates if a specific address has a contract already created
            if (userWalletContractMapping[userWallets[i]] == address(0)) {
                userWalletContractMapping[userWallets[i]] = contractInstance;
                CreateUserContractEvent(userWallets[i], contractInstance);
            }        
        }
    }

    function createInvestorContract(address investorWallet, uint icoInvestorCap) public onlyOwnerOrUserContributionCreator {
        // creates the GBxInvestorContract and saves its address
        address contractInstance = new GBxInvestorContract(this,investorWallet, icoInvestorCap);
        // save in mapping
            if (investorWalletContractMapping[investorWallet] == address(0)) {
                investorWalletContractMapping[investorWallet] = contractInstance;
                CreateInvestorContractEvent(investorWallet, contractInstance);
            }
    }

    function reportUserEthTransfer(uint value) public onlyUserOrInvestorContract {
        // increment reported funds
        icoFunds = SafeMath.add(icoFunds,value);
        FundsTransferEvent(tx.origin,value,msg.sender); 
        RockToken(rockTokenAddress).convertTokens(SafeMath.mul(value,weiRockTokenParity), tx.origin);
    }

    function getAcceptedValueForInvestor(address userContractAddress, uint value) public view returns (uint acceptedValue) { 
        GBxInvestorContract investorContract = GBxInvestorContract(userContractAddress);
        // ColdWallet is initialised
        if (coldWalletAddress == address(0)) {
            return 0;
        }
        // ICO isn't over
        if (now < icoStartDate || now > icoEndDate) {
            return 0;
        }

        acceptedValue = 0;

        if (isOverflowed(icoFunds,value)) {
            return 0;
        }

        // investor cap check
        if (icoFunds + value <= investorContract.icoInvestorCap()) {
            acceptedValue = value;    
        }else {
            acceptedValue = investorContract.icoInvestorCap() - icoFunds;
        }

        return acceptedValue;

    }

    function getAcceptedValueForUser(address userContractAddress, uint value) public view returns (uint acceptedValue) { 
        GBxUserContract userContract = GBxUserContract(userContractAddress);
        
        // ColdWallet is initialised
        if (coldWalletAddress == address(0)) {
            return 0;
        }
        // ICO isn't over
        if (now < icoStartDate || now > icoEndDate) {
            return 0;
        }
        // ICO hard cap not reached
        if (icoFunds >= maxFunds) {
            return 0;
        }

        acceptedValue = 0;

        if (isOverflowed(icoFunds,value)) {
            return 0;
        }

        // hard cap check
        if (icoFunds + value <= maxFunds) {
            acceptedValue = value;    
        }else {
            acceptedValue = maxFunds - icoFunds;
        }

        // // user cap check
        if (now < icoPhase2StartDate) {
            if (isOverflowed(userContract.amountPaid(),value)) {
                return 0;
            }
            if (userContract.amountPaid() + value <= icoCapPerUser) {
                acceptedValue = value;
            }else {
                acceptedValue = icoCapPerUser - userContract.amountPaid();
            }            
        }

       return acceptedValue;
    }

    // Check if overflow
    function isOverflowed(uint256 a, uint256 b) public pure returns(bool) {
        uint256 c = a + b;
        return !(c >= a);
    }

    function setMaxFunds(uint _maxFunds) public onlyOwner {
        maxFunds = _maxFunds;
    }
    
    function setICOStartDate(uint _icoStartDate) public onlyOwner {
        icoStartDate = _icoStartDate;
    }

    function changeUserContributionCreator(address _userContributionCreator) public onlyOwner {
        userContributionCreator = _userContributionCreator;
    }

    function setICOPhase2StartDate(uint _icoPhase2StartDate) public onlyOwner {
        icoPhase2StartDate = _icoPhase2StartDate;
    }

    function setICOEndDate(uint _icoEndDate) public onlyOwner {    
        icoEndDate = _icoEndDate;
    }

    function setICOCapPerUser(uint _icoCapPerUser) public onlyOwner {     
        icoCapPerUser = _icoCapPerUser;
    } 

    function getICOStatus() public view returns (address, uint, uint, uint, uint, uint, uint) {
        //returns (cold wallet address,ico max cap, start date, phase 2 start date, end date, cap for phase 1/user, howmuch was raised on entire ico untill now)
        return (coldWalletAddress,maxFunds,icoStartDate,icoPhase2StartDate,icoEndDate, icoCapPerUser,icoFunds);
    }

    function getUserContractForUserWallet(address userWalletAddress) public view returns (address) {
        return userWalletContractMapping[userWalletAddress];
    }

    function getInvestorContractForUserWallet(address investorWalletAddress) public view returns (address) {
        return investorWalletContractMapping[investorWalletAddress];
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwnerAddress); 
        _;        
    }

    modifier onlyOwnerOrUserContributionCreator() {
        require(msg.sender == contractOwnerAddress || msg.sender == userContributionCreator); 
        _;        
    }

    modifier onlyUserOrInvestorContract() {
        // In order to be a valid recorded user eth transfer both must be valid:
        // 1. the tx.origin should be the wallet of the user, 
        //    which is the key from the userWalletContractMapping/investorWalletContractMapping
        // 2. the msg.sender should be the child contract, 
        //    which is the value from the userWalletContractMapping/investorWalletContractMapping

        // Makes sure that the sender of the message 
        // is one of the child contracts.
        require(msg.sender == userWalletContractMapping[tx.origin] || msg.sender == investorWalletContractMapping[tx.origin]);
        _;
    }

    // Makes sure that the ownership is only changed by the owner 
    function transferOwnership(address newOwner) public onlyOwner {
        // Makes sure that the contract will have an owner
        require(newOwner != address(0));
        contractOwnerAddress = newOwner;
    }

    // From solidity FAQ: http://solidity.readthedocs.io/en/develop/frequently-asked-questions.html
    // First, a word of warning: Killing contracts sounds like a good idea, because “cleaning up”
    // is always good, but as seen above, it does not really clean up. Furthermore, if Ether is sent 
    // to removed contracts, the Ether will be forever lost.
    // If you want to deactivate your contracts, it is preferable to disable them by changing 
    // some internal state which causes all functions to throw. This will make it impossible to 
    // use the contract and ether sent to the contract will be returned automatically.
    function kill() public onlyOwner {
       selfdestruct(contractOwnerAddress);
    }
}