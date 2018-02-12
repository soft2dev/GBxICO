The application is composed of 3 main contracts:

- RockToken (RockToken.sol, StandardToken.sol,Token.sol)
- Master Contract (GBxMasterContract.sol)
- User Contract (GBxUserContract)

External libraries:

- SafeMath (zeppelin-solidity/contracts/math/SafeMath.sol)
- ReentrancyGuard(zeppelin-solidity/contracts/ReentrancyGuard.sol)

A brief definition of the contracts:

- RockToken is a standard ERC20 token, with capabilities to release locked tokens after a period of time. The tokens can be issued only from a call coming from the MasterContract.
After the period expires the claim function can be called and the caller will get the delayed amount allocated to him. 
The coin can start to be transfered after enabling the transfers on the token contract. After doing this the treansfers can not be disabled and the action is ireversible.

- GBxMasterContract is a contract factory that assigns to each user a user contract. It is responsible for controlling the user contract by allowing or denying the payments or by keeping the record of the donated amount. Another capability of the master contract is the conversion of the contribution amount into RockTokens at the donation moment. The conversion rate is set by the wei to rock token parity (a setter in the contract). The master contract also contains other setters for date intervals and amount limits. 
This contract can be disabled by calling the block function that renders the contract in an unusable state (This function is ireversible).

By keeping a mapping of the user contract in the master contract we make sure that any user contract deployed by someone else can not interact with the cold wallet. Also any business decision is taken by the master contract and by doing so the user contract is just a simple payment gate that redirect everything to its master contract.

- GBxUserContract is a small contract dynamically created by the GBxMasterContract and its assigned to each user wallet. It is an one to one relation between users and user contracts. The role of the user contract is to process the payments and keep record of the individual donated amounts by the curent user. It makes sense only if it is dynamically deployed by the MasterContract by using the factory pattern described earlier. Each new contract is beeing registered in the master contract.



# GBxICO
