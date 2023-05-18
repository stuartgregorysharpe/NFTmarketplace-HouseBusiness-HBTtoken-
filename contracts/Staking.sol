// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './interfaces/IHouseBusiness.sol';
pragma solidity ^0.8.7;

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
        uint256 houseID;
        uint256 startedDate;
        uint256 endDate;
        uint256 claimDate;
        uint256 stakingType;
        uint256 perSecRewards;
        bool stakingStatus;
    }

    event APYConfigSet(uint256 indexed _type, uint256 apy, uint256 timestamp);
    event NFTStaked(address indexed staker, uint256 houseID, uint256 stakingType, uint256 stakedAt);
    event NFTUnstaked(address indexed staker, uint256 houseID, uint256 stakedAt);
    event APYConfigUpdated(uint256 indexed _type, uint256 newApy, address indexed updatedBy, uint256 timestamp);
    event RewardsClaimed(address indexed stakedNFTowner, uint256 claimedRewards, uint256 timestamp);
    event PenaltySet(address indexed updatedBy, uint256 newPenalty, uint256 timestamp);

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

    function setAPYConfig(uint256 _type, uint256 Apy) external {
        APYConfig[_type] = Apy;
        APYtypes.push(_type);

        emit APYConfigSet(_type, Apy, block.timestamp);
    }

    // stake House Nft
    function stake(uint256 _houseID, uint256 _stakingType, address _owner) external {
        IERC721 houseNFT = IERC721(houseNFTAddress);
        IHouseBusiness houseBusiness = IHouseBusiness(houseNFTAddress);

        require(houseNFT.ownerOf(_houseID) != address(this), 'You have already staked this House Nft');
        require(APYConfig[_stakingType] > 0, 'Staking type should be specify.');

        houseNFT.transferFrom(_owner, address(this), _houseID);

        uint256 price = houseBusiness.getTokenPrice(_houseID);

        stakedNfts[_owner].push(
            StakedNft(
                _owner,
                _houseID,
                block.timestamp,
                block.timestamp + (APYConfig[_stakingType] * 31536000) / 12,
                block.timestamp,
                _stakingType,
                this.calcDiv(price, 31536000),
                true
            )
        );
        
        houseBusiness.setHouseStakedStatus(_houseID, true);
        stakedCounter++;

        emit NFTStaked(_owner, _houseID, _stakingType, block.timestamp);
    }

    // Unstake House Nft
    function unstake(uint256 _houseID, address _owner) external {
        require(_houseID > 0, 'Invalid Token ID');
        StakedNft memory unstakingNft;
        uint256 counter;
        for (uint256 i = 0; i < stakedNfts[_owner].length; i++) {
            if (stakedNfts[_owner][i].houseID == _houseID) {
                unstakingNft = stakedNfts[_owner][i];
                delete stakedNfts[_owner][i];
                counter = i;
                break;
            }
        }
        require(unstakingNft.owner == _owner, 'OCUT');

        // conditional execution
        if (stakingFinished(_houseID, _owner) == false) {
            IERC20(tokenAddress).transfer(_owner, (totalRewards(_owner) * (100 - penalty)) / 100);
        } else {
            claimRewards(_owner);
        }

        IERC721(houseNFTAddress).transferFrom(address(this), _owner, _houseID);

        IHouseBusiness(houseNFTAddress).setHouseStakedStatus(_houseID, false);
        stakedCounter--;

        emit NFTUnstaked(_owner, _houseID, unstakingNft.startedDate);
    }

    function updateAPYConfig(uint _type, uint APY, address _owner) external {
        require(IHouseBusiness(houseNFTAddress).member(_owner), 'member');
        for (uint i = 0; i < APYtypes.length; i++) {
            if (APYtypes[i] == _type) {
                APYConfig[_type] = APY;

                emit APYConfigUpdated(_type, APY, _owner, block.timestamp);
            }
        }
    }

    // Claim Rewards
    function claimRewards(address _stakedNFTowner) public {
        StakedNft[] storage allmyStakingNfts = stakedNfts[_stakedNFTowner];
        IHouseBusiness houseBusiness = IHouseBusiness(houseNFTAddress);
        uint256 allRewardAmount = 0;

        for (uint256 i = 0; i < allmyStakingNfts.length; i++) {
            StakedNft storage stakingNft = allmyStakingNfts[i];
            if (stakingNft.stakingStatus == true) {
                uint256 stakingType = stakingNft.stakingType;
                uint256 expireDate = stakingNft.startedDate + 2592000 * stakingType;

                uint256 _timestamp = (block.timestamp <= expireDate) ? block.timestamp : expireDate;
                uint256 price = houseBusiness.getTokenPrice(stakingNft.houseID);

                uint256 stakedReward = this.calcDiv(
                    (price * APYConfig[stakingType] * (_timestamp - stakingNft.claimDate)) / 100,
                    (365 * 24 * 60 * 60)
                );
                allRewardAmount += stakedReward;
                stakingNft.claimDate = _timestamp;
            }
        }

        if (allRewardAmount != 0) {
            IERC20(tokenAddress).transfer(_stakedNFTowner, allRewardAmount);
            emit RewardsClaimed(_stakedNFTowner, allRewardAmount, block.timestamp);
        }
    }

    function setPenalty(uint256 _penalty, address _user) external {
        require(IHouseBusiness(houseNFTAddress).member(_user), 'member');
        penalty = _penalty;

        emit PenaltySet(_user, _penalty, block.timestamp);
    }

    function calcDiv(uint256 a, uint256 b) public pure returns (uint256) {
        return (a - (a % b)) / b;
    }

    function getStakedCounter() external view returns (uint256) {
        return stakedCounter;
    }

    function getAllAPYTypes() external view returns (uint256[] memory) {
        return APYtypes;
    }

    function stakingFinished(uint256 _houseID, address _owner) public view returns (bool) {
        StakedNft memory stakingNft;
        for (uint256 i = 0; i < stakedNfts[_owner].length; i++) {
            if (stakedNfts[_owner][i].houseID == _houseID) {
                stakingNft = stakedNfts[_owner][i];
            }
        }
        return block.timestamp < stakingNft.endDate;
    }

    // Claim Rewards
    function totalRewards(address _rewardOwner) public view returns (uint256) {
        StakedNft[] memory allmyStakingNfts = stakedNfts[_rewardOwner];
        IHouseBusiness houseBusiness = IHouseBusiness(houseNFTAddress);
        uint256 allRewardAmount = 0;

        for (uint256 i = 0; i < allmyStakingNfts.length; i++) {
            StakedNft memory stakingNft = allmyStakingNfts[i];
            if (stakingNft.stakingStatus == true) {
                uint256 stakingType = stakingNft.stakingType;
                uint256 expireDate = stakingNft.startedDate + 2592000 * stakingType;

                uint256 _timestamp = (block.timestamp <= expireDate) ? block.timestamp : expireDate;
                uint256 price = houseBusiness.getTokenPrice(stakingNft.houseID);

                allRewardAmount += this.calcDiv(
                    (price * APYConfig[stakingType] * (_timestamp - stakingNft.claimDate)) / 100,
                    (365 * 24 * 60 * 60)
                );
            }
        }

        return allRewardAmount;
    }

    // Gaddress _rewardOwneret All staked Nfts
    function getAllMyStakedNFTs(address _owner) external view returns (StakedNft[] memory) {
        return stakedNfts[_owner];
    }

    // Get All APYs
    function getAllAPYs() external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory apyCon = new uint256[](APYtypes.length);
        uint256[] memory apys = new uint256[](APYtypes.length);
        for (uint256 i = 0; i < APYtypes.length; i++) {
            apys[i] = APYtypes[i];
            apyCon[i] = APYConfig[APYtypes[i]];
        }
        return (apys, apyCon);
    }
}
