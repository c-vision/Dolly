//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

/*
    The Migrations contract keeps track of which migrations were done on the current network.

    Inside the migrations folder, you'll see a file called 1_initial_migration.js The 1 in the filename 
    is the reference number of a migration.

    Once you've created a couple of contracts, and want to deploy them using truffle migrate, you can 
    create another migration file called 2_name_of_migration.js. Once the migration is done, Truffle 
    will store that 2 reference number in the Migrations contract

    Migrations are JavaScript files that help you deploy contracts to the Ethereum network. These files 
    are responsible for staging your deployment tasks, and they're written under the assumption that 
    your deployment needs will change over time. As your project evolves, you'll create new migration 
    scripts to further this evolution on the blockchain. A history of previously run migrations is 
    recorded on-chain through a special Migrations contract, detailed below.

    https://www.trufflesuite.com/docs/truffle/getting-started/running-migrations
*/
contract Migrations {
    address public owner;
    uint public lastCompletedMigration;

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setCompleted(uint completed) public restricted {
        lastCompletedMigration = completed;
    }

    function upgrade(address newAddress) public restricted {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(lastCompletedMigration);
    }
}
