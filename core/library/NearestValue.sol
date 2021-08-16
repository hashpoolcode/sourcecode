pragma solidity >=0.5.0 <0.6.0;


library NearestValue {

      struct TimeLine {
              uint[] timeList;

              mapping(uint => uint) valueMapping;
    }

    struct Data {
              uint timeInterval_final;
        mapping(address => TimeLine) timeLineMapping;
    }

      function increase(Data storage self, address owner, uint addValue) internal returns(uint) {

              uint t = now / self.timeInterval_final * self.timeInterval_final;

              TimeLine storage line = self.timeLineMapping[owner];

              if ( line.timeList.length == 0 ) {
            line.timeList.push(t);
            line.valueMapping[t] = addValue;
            return line.valueMapping[t];
        }

              uint latestTime = line.timeList[line.timeList.length - 1];

              if (latestTime == t) {
            line.valueMapping[latestTime] += addValue;
            return line.valueMapping[latestTime];
        } else {
            line.timeList.push(t);
            line.valueMapping[t] = (line.valueMapping[latestTime] + addValue);
            return line.valueMapping[t];
        }

    }

      function decrease(Data storage self, address owner, uint subValue) internal returns(uint) {

              uint t = now / self.timeInterval_final * self.timeInterval_final;

              TimeLine storage line = self.timeLineMapping[owner];

              require( line.timeList.length > 0, "DecreaseBeforIncrease");

              uint latestTime = line.timeList.length == 0 ? t : line.timeList[line.timeList.length - 1];

              require(line.valueMapping[latestTime] >= subValue, "InsufficientQuota");

              if (latestTime == t) {
            line.valueMapping[latestTime] -= subValue;
            return line.valueMapping[latestTime];
        } else {
            line.timeList.push(t);
            line.valueMapping[t] = (line.valueMapping[latestTime] - subValue);
            return line.valueMapping[t];
        }

    }

      function forceSet(Data storage self, address owner, uint value) internal {
              uint t = now / self.timeInterval_final * self.timeInterval_final;

              TimeLine storage line = self.timeLineMapping[owner];

              if ( line.timeList.length == 0 ) {
            line.timeList.push(t);
            line.valueMapping[t] = value;
            return ;
        }

              uint latestTime = line.timeList[line.timeList.length - 1];

              if (latestTime == t) {
            line.valueMapping[latestTime] = value;
        } else {
            line.timeList.push(t);
            line.valueMapping[t] = value;
        }
    }

      function nearestLeft(Data storage self, address owner, uint time) internal view returns(uint) {

        uint[] memory s = self.timeLineMapping[owner].timeList;

              if (s.length <= 0) {
            return 0;
        }

              if (time <= s[0]) {
            return self.timeLineMapping[owner].valueMapping[s[0]];
        } else {
            (uint l, ) = binarySearch(s, time);
            return self.timeLineMapping[owner].valueMapping[s[l]];
        }
    }

      function nearestRight(Data storage self, address owner, uint time) internal view returns(uint) {

        uint[] memory s = self.timeLineMapping[owner].timeList;

              if (s.length <= 0) {
            return 0;
        }

              if (time > s[s.length - 1]) {
            return self.timeLineMapping[owner].valueMapping[s[s.length - 1]];
        } else {
            (, uint r) = binarySearch(s, time);
            return self.timeLineMapping[owner].valueMapping[s[r]];
        }
    }

      function binarySearch(uint[] memory s, uint key) internal pure returns(uint l, uint r) {
        if (s.length <= 0) {
            return (0, 0);
        }

        l = 0;
        r = s.length;
        for (uint c = (l + r) / 2; l != c; c = (l + r) / 2) {
                      if (s[c] == key) {
                l = c;
                r = c;
                break;
            }
                      if (s[c] < key) {
                l = c;
            }
                      else {
                r = c;
            }
        }

        if (r > s.length - 1) {
            r = s.length - 1;
        }
    }
}
