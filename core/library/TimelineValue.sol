pragma solidity >=0.5.0 <0.6.0;


library TimeLineValue {

    struct Data {
              uint timeInterval_final;
              uint[] timeList;
              mapping(uint => uint) valueMapping;
    }

      function init(Data storage self, uint interval, uint t, uint value) internal {
        uint tz = t / interval * interval;

        self.timeInterval_final = interval;
        self.timeList.push(tz);
        self.valueMapping[tz] = value;
    }

      function increase(Data storage self, uint addValue) internal returns(uint) {

              uint t = now / self.timeInterval_final * self.timeInterval_final;


              uint latestTime = self.timeList[self.timeList.length - 1];

              if (latestTime == t) {
            self.valueMapping[latestTime] += addValue;
            return self.valueMapping[latestTime];
        } else {
            self.timeList.push(t);
            self.valueMapping[t] = (self.valueMapping[latestTime] + addValue);
            return self.valueMapping[t];
        }
    }

      function decrease(Data storage self, uint subValue) internal returns(uint) {

              uint t = now / self.timeInterval_final * self.timeInterval_final;


              uint latestTime = self.timeList.length == 0 ? t : self.timeList[self.timeList.length - 1];

              require(self.valueMapping[latestTime] >= subValue, "InsufficientQuota");

              if (latestTime == t) {
            self.valueMapping[latestTime] -= subValue;
            return self.valueMapping[latestTime];
        } else {
            self.timeList.push(t);
            self.valueMapping[t] = (self.valueMapping[latestTime] - subValue);
            return self.valueMapping[t];
        }

    }

      function forceSet(Data storage self, uint value) internal {

              uint t = now / self.timeInterval_final * self.timeInterval_final;


              uint latestTime = self.timeList[self.timeList.length - 1];

              if (latestTime == t) {
            self.valueMapping[latestTime] = value;
        } else {
            self.timeList.push(t);
            self.valueMapping[t] = value;
        }
    }

      function latestValue(Data storage self) internal view returns (uint) {
        uint[] storage s = self.timeList;
        if ( s.length <= 0 ) {
            return 0;
        }
        return self.valueMapping[s[s.length - 1]];
    }

      function bestMatchValue(Data storage self, uint time) internal view returns(uint) {

        uint[] storage s = self.timeList;

              if (s.length <= 0 || time < s[0]) {
            return 0;
        }

              if ( time >= s[s.length - 1] ) {
            return self.valueMapping[s[s.length - 1]];
        }

              uint t = time / self.timeInterval_final * self.timeInterval_final;

              for (uint d = t; d >= t - 7 * self.timeInterval_final; d -= self.timeInterval_final ) {
            if ( self.valueMapping[d] > 0 ) {
                return self.valueMapping[d];
            }
        }

        return 0;
    }
}
