pragma solidity >=0.5.0 <0.6.0;

import "../core/k.sol";
import "../core/library/SafeMath.sol";

import { RelationshipInterfaceNoPayable } from "../defieraInterface/relationship/interface.sol";

contract BankAchievementStorage is KStorage {

    /*
    * @dev
    */
    uint public eachDeep = 14;

    /*
    * @dev
    */
    mapping(address => AchievementInfo) public achievementInfoMapping;
    struct AchievementInfo {

        uint itself;

        uint large;

        uint total;
    }

    /**
     * @dev Constructor.
     */
    constructor(
        RelationshipInterfaceNoPayable _irlts,
        uint _echDeep
    ) public {
        _iRelations = _irlts;
        eachDeep = _echDeep;
    }

    RelationshipInterfaceNoPayable internal _iRelations;
}

contract BankAchievement is BankAchievementStorage(RelationshipInterfaceNoPayable(0x0), 0) {

    using SafeMath for uint;


    function _reconstruction(address recipient) internal {

        (address[] memory recommendedList, ) = _iRelations.RecommendList(recipient);

        AchievementInfo memory newInfo = AchievementInfo(
            achievementInfoMapping[recipient].itself,///itself
            0,///large
            0 ///total
        );

        for ( uint i = 0; i < recommendedList.length; i++ ) {

            uint childValue = achievementInfoMapping[recommendedList[i]].itself;

            newInfo.total = newInfo.total.add(childValue);

            if ( newInfo.large < childValue ) {
                newInfo.large = childValue;
            }
        }


        achievementInfoMapping[recipient] = newInfo;
    }

    function increaseDelegate(address recipient, uint addedValue) external KDelegateMethod returns (bool) {

        address relationRoot = address(0xdead);


        achievementInfoMapping[recipient].itself = achievementInfoMapping[recipient].itself.add(addedValue);


        for (
            (address child, address parent, uint d) = (recipient, _iRelations.GetIntroducer(recipient), 0);
            parent != relationRoot && parent != address(0) && d < eachDeep;
            (d++, child = parent, parent = _iRelations.GetIntroducer(child) )
        ) {

            uint childValue = achievementInfoMapping[child].itself;


            achievementInfoMapping[parent].itself = achievementInfoMapping[parent].itself.add(addedValue);
            achievementInfoMapping[parent].total = achievementInfoMapping[parent].total.add(addedValue);

            if ( childValue > achievementInfoMapping[parent].large ) {
                achievementInfoMapping[parent].large = childValue;
            }
        }

        return true;
    }

    function decreaseDelegate(address recipient, uint subtractedValue) external KDelegateMethod returns (bool) {

        address relationRoot = address(0xdead);


        achievementInfoMapping[recipient].itself = achievementInfoMapping[recipient].itself.sub(subtractedValue);


        for (
            (address child, address parent, uint d) = (recipient, _iRelations.GetIntroducer(recipient), 0);
            parent != relationRoot && parent != address(0) && d < eachDeep;
            (d++, child = parent, parent = _iRelations.GetIntroducer(child) )
        ) {

            if ( achievementInfoMapping[parent].itself >= subtractedValue ) {
                achievementInfoMapping[parent].itself = achievementInfoMapping[parent].itself.sub(subtractedValue);
            } else {
                achievementInfoMapping[parent].itself = 0;
            }
        }

        return true;
    }


    function achievementOf(address recipient) external view returns (uint) {
        AchievementInfo memory info = achievementInfoMapping[recipient];
        if ( info.total < info.large ) {
            return 0;
        }
        return info.total.sub(info.large);
    }


    function largeAchievementOf(address recipient) external view returns (uint) {
        return achievementInfoMapping[recipient].large;
    }
}
