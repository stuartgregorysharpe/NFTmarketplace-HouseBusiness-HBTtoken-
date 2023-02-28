pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './interfaces/IHouseBusiness.sol';

contract HouseStaking {
    // total number of staked nft
    uint256 public stakedCounter;
    // token panalty
    uint256 public penalty;
    // All APY types
    uint256[] APYtypes;

    // APY
    mapping(uint256 => uint256) APYConfig;
    mapping(address => StakedNft[]) stakedNfts;

    address tokenAddress;
    address houseNFTAddress;

    // Staking NFT struct
    struct StakedNft {
        address owner;
        uint256 tokenId;
        uint256 startedDate;
        uint256 endDate;
        uint256 claimDate;
        uint256 stakingType;
        uint256 perSecRewards;
        bool stakingStatus;
    }

    constructor(address _houseNFTAddress, address _tokenAddress) {
        APYtypes.push(1);
        APYConfig[1] = 6;
        APYtypes.push(6);
        APYConfig[6] = 8;
        APYtypes.push(12);
        APYConfig[12] = 10;
        APYtypes.push(24);
        APYConfig[24] = 12;
        tokenAddress = _tokenAddress;
        houseNFTAddress = _houseNFTAddress;
    }

    // Devide number
    function calcDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return (a - (a % b)) / b;
    }

    function setAPYConfig(uint256 _type, uint256 Apy) external {
        APYConfig[_type] = Apy;
        APYtypes.push(_type);
    }

    function getAllAPYTypes() public view returns (uint256[] memory) {
        return APYtypes;
    }

    // stake House Nft
    function stake(uint256 _tokenId, uint256 _stakingType) external {
        require(IERC721(houseNFTAddress).ownerOf(_tokenId) != address(this), 'You have already staked this House Nft');

        // _stakingType should be one, six, twelve, twentytwo
        require(APYConfig[_stakingType] > 0, 'Staking type should be specify.');
        // transfer the token from owner to the caller of the function (buyer)
        IERC721(houseNFTAddress).transferFrom(msg.sender, address(this), _tokenId);

        StakedNft memory simpleStakedNft;
        simpleStakedNft.owner = msg.sender;
        simpleStakedNft.tokenId = _tokenId;
        simpleStakedNft.startedDate = block.timestamp;

        simpleStakedNft.endDate = block.timestamp + (24 * 3600 * 366 * APYConfig[_stakingType]) / 12;
        simpleStakedNft.claimDate = block.timestamp;
        simpleStakedNft.stakingType = _stakingType;
        uint256 dayToSec = 365 * 24 * 60 * 60;
        uint256 price = IHouseBusiness(houseNFTAddress).getTokenPrice(_tokenId);
        simpleStakedNft.perSecRewards = this.calcDiv(price, dayToSec);
        simpleStakedNft.stakingStatus = true;
        stakedCounter++;
        stakedNfts[msg.sender].push(simpleStakedNft);

        IHouseBusiness(houseNFTAddress).setHouseStakedStatus(_tokenId, true);
    }

    // Unstake House Nft
    function unstake(uint256 _tokenId) external {
        StakedNft[] memory cStakedNfts = stakedNfts[msg.sender];
        bool status = true;
        for (uint256 i = 0; i < cStakedNfts.length; i++) {
            if (cStakedNfts[i].tokenId == _tokenId) {
                status = false;
            }
        }
        require(status == false, 'NS');
        StakedNft memory unstakingNft;
        uint256 counter;
        for (uint256 i = 0; i < stakedNfts[msg.sender].length; i++) {
            if (stakedNfts[msg.sender][i].tokenId == _tokenId) {
                unstakingNft = stakedNfts[msg.sender][i];
                counter = i;
            }
        }
        if (stakingFinished(_tokenId) == false) {
            uint256 claimAmount = totalRewards(msg.sender);
            IERC20(tokenAddress).transfer(msg.sender, (claimAmount * (100 - penalty)) / 100);
        } else {
            claimRewards(msg.sender);
        }
        // check if owner call this request
        require(unstakingNft.owner == msg.sender, 'OCUT');
        // transfer the token from owner to the caller of the function (buyer)
        IERC721(houseNFTAddress).transferFrom(address(this), msg.sender, _tokenId);
        // commit ustaked
        IHouseBusiness(houseNFTAddress).setHouseStakedStatus(_tokenId, false);
        stakedCounter--;
        delete stakedNfts[msg.sender][counter];
    }

    function stakingFinished(uint256 _tokenId) public view returns (bool) {
        StakedNft memory stakingNft;
        for (uint256 i = 0; i < stakedNfts[msg.sender].length; i++) {
            if (stakedNfts[msg.sender][i].tokenId == _tokenId) {
                stakingNft = stakedNfts[msg.sender][i];
            }
        }
        return block.timestamp < stakingNft.endDate;
    }

    // Claim Rewards
    function totalRewards(address _rewardOwner) public view returns (uint256) {
        StakedNft[] memory allmyStakingNfts = stakedNfts[_rewardOwner];
        uint256 allRewardAmount = 0;
        for (uint256 i = 0; i < allmyStakingNfts.length; i++) {
            if (allmyStakingNfts[i].stakingStatus == true) {
                uint256 stakingType = allmyStakingNfts[i].stakingType;
                uint256 expireDate = allmyStakingNfts[i].startedDate + 60 * 60 * 24 * 30 * stakingType;
                uint256 _timestamp;
                uint256 price = IHouseBusiness(houseNFTAddress).getTokenPrice(allmyStakingNfts[i].tokenId);
                if (block.timestamp <= expireDate) {
                    _timestamp = block.timestamp;
                } else {
                    _timestamp = expireDate;
                }
                allRewardAmount += this.calcDiv(
                    (price * APYConfig[stakingType] * (_timestamp - allmyStakingNfts[i].claimDate)) / 100,
                    (365 * 24 * 60 * 60)
                );
            }
        }
        return allRewardAmount;
    }

    // Claim Rewards
    function claimRewards(address _stakedNFTowner) public {
        StakedNft[] memory allmyStakingNfts = stakedNfts[_stakedNFTowner];
        uint256 allRewardAmount = 0;
        for (uint256 i = 0; i < allmyStakingNfts.length; i++) {
            if (allmyStakingNfts[i].stakingStatus == true) {
                uint256 stakingType = allmyStakingNfts[i].stakingType;
                uint256 expireDate = allmyStakingNfts[i].startedDate + 60 * 60 * 24 * 30 * stakingType;
                uint256 _timestamp;
                uint256 price = IHouseBusiness(houseNFTAddress).getTokenPrice(allmyStakingNfts[i].tokenId);
                if (block.timestamp <= expireDate) {
                    _timestamp = block.timestamp;
                } else {
                    _timestamp = expireDate;
                }
                allRewardAmount += this.calcDiv(
                    (price * APYConfig[stakingType] * (_timestamp - allmyStakingNfts[i].claimDate)) / 100,
                    (365 * 24 * 60 * 60)
                );
                stakedNfts[_stakedNFTowner][i].claimDate = _timestamp;
            }
        }
        if (allRewardAmount != 0) {
            IERC20(tokenAddress).transfer(_stakedNFTowner, allRewardAmount);
        }
    }

    // Gaddress _rewardOwneret All staked Nfts
    function getAllMyStakedNFTs() public view returns (StakedNft[] memory) {
        return stakedNfts[msg.sender];
    }

    // Get All APYs
    function getAllAPYs() public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory apyCon = new uint256[](APYtypes.length);
        uint256[] memory apys = new uint256[](APYtypes.length);
        for (uint256 i = 0; i < APYtypes.length; i++) {
            apys[i] = APYtypes[i];
            apyCon[i] = APYConfig[APYtypes[i]];
        }
        return (apys, apyCon);
    }

    // Penalty
    function getPenalty() public view returns (uint256) {
        return penalty;
    }

    function setPenalty(uint256 _penalty) public {
        require(IHouseBusiness(houseNFTAddress).allMembers(msg.sender), 'member');
        penalty = _penalty;
    }
}
