pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

struct Charity {
    string name;
    string description;
    address owner;
    uint256 totalDonations;
    uint256 programCount;
}

struct Program {
    string name;
    string description;
    uint256 fundingGoal;
    uint256 currentFunding;
    bool isActive;
}

contract CharityPlatform is Ownable {
        struct Donor {
        uint256 id;
        string name;
        uint256 totalDonations;
        address walletAddress;
        // Add more fields for donor information as needed
    }
    
    // Mapping of donor addresses to their respective information
    mapping(address => Donor) public donors;
    
    // Events to log important contract actions
    event DonorAdded(address indexed donorAddress, uint256 id, string name);
    event DonationReceived(address indexed donorAddress, uint256 amount);
    

    
    // Function to add a new donor to the system
    function addDonor(string memory _name) public {
        require(donors[msg.sender].walletAddress == address(0), "Donor already exists");
        
        // Generate a unique donor ID (You may implement your own logic for uniqueness)
        uint256 donorId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        
        // Create a new donor instance and add it to the mapping
        donors[msg.sender] = Donor(donorId, _name, 0, msg.sender);
        
        // Emit an event to log the donor addition
        emit DonorAdded(msg.sender, donorId, _name);
    }
    
    // Function to receive donations and update donor information
    function receiveDonation() public payable {
        require(donors[msg.sender].walletAddress != address(0), "Donor does not exist");
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        // Update the donor's total donations
        donors[msg.sender].totalDonations += msg.value;
        
        // Emit an event to log the donation
        emit DonationReceived(msg.sender, msg.value);
    }
    
    // Function to get a donor's information
    function getDonorInfo(address _donorAddress) public view returns (uint256, string memory, uint256) {
        Donor memory donor = donors[_donorAddress];
        require(donor.walletAddress != address(0), "Donor does not exist");
        return (donor.id, donor.name, donor.totalDonations);
    }
    
    mapping(address => Charity) public charities;
    mapping(address => mapping(uint256 => Program)) public charityPrograms;
    mapping(address => uint256[]) public donorContributions;

    event CharityRegistered(address indexed charityAddress, string name);
    event ProgramAdded(address indexed charityAddress, uint256 programId, string name);
    event DonationMade(address indexed donor, address indexed charityAddress, uint256 programId, uint256 amount);

    modifier onlyRegisteredCharity() {
        require(charities[msg.sender].owner == msg.sender, "Only registered charities can perform this action");
        _;
    }

    function registerCharity(string memory _name, string memory _description) external {
        require(charities[msg.sender].owner == address(0), "Charity already registered");

        Charity storage newCharity = charities[msg.sender];
        newCharity.name = _name;
        newCharity.description = _description;
        newCharity.owner = msg.sender;

        emit CharityRegistered(msg.sender, _name);
    }

    function addProgram(string memory _name, string memory _description, uint256 _fundingGoal) external onlyRegisteredCharity {
        Charity storage charity = charities[msg.sender];
        uint256 programId = charity.programCount;

        Program storage newProgram = charityPrograms[msg.sender][programId];
        newProgram.name = _name;
        newProgram.description = _description;
        newProgram.fundingGoal = _fundingGoal;
        newProgram.currentFunding = 0;
        newProgram.isActive = true;
        charity.programCount++;
        emit ProgramAdded(msg.sender, programId, _name);
    }

    function makeDonation(address _charityAddress, uint256 _programId) external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        Charity storage charity = charities[_charityAddress];
        Program storage program = charityPrograms[_charityAddress][_programId];

        require(charity.owner != address(0), "Charity not found");
        require(program.isActive, "Program is not active");
        require(msg.value <= (program.fundingGoal - program.currentFunding), "Donation exceeds funding goal");

        program.currentFunding += msg.value;
        charity.totalDonations += msg.value;
        donorContributions[msg.sender].push(msg.value);

        emit DonationMade(msg.sender, _charityAddress, _programId, msg.value);
    }

    function withdrawFunds(address _charityAddress, uint256 _programId) external onlyRegisteredCharity {
        Charity storage charity = charities[_charityAddress];
        Program storage program = charityPrograms[_charityAddress][_programId];

        require(program.isActive, "Program is not active");
        require(charity.owner == msg.sender, "You can only withdraw funds for your own charity");
        require(program.currentFunding >= program.fundingGoal, "Funding goal not reached yet");

        uint256 balanceToWithdraw = program.currentFunding;
        program.currentFunding = 0;

        payable(charity.owner).transfer(balanceToWithdraw);
    }

    function getDonorContributions(address _donor) external view returns (uint256[] memory) {
        return donorContributions[_donor];
    }
}
