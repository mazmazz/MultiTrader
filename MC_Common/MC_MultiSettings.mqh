//+------------------------------------------------------------------+
//|                                     MMT_Helper_MultiSettings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MC_Common.mqh"
#include "MC_Error.mqh"

enum CalcSource {
    CalcValue // Use exact value below
    , CalcFilter // Use value from filter
};

enum CalcOperation {
    CalcExact // Use exact value from filter
    , CalcOffset // Add to filter
    , CalcSubtract // Subtract from filter (positive = subtract)
    , CalcFactor // Multiply from filter
    , CalcDivide // Divide from filter
};

class ValueLocation {
    public:
    CalcSource source;
    CalcOperation operation;
    string filterName;
    int filterIdx;
    int subIdx;
    double setVal;
    double operand;
    
    ValueLocation() {
        filterName = "";
        filterIdx = -1;
        subIdx = -1;
        setVal = -1;
        operand = -1;
    }
};

enum ScheduleTimeType {
    TimeTypeGmt // GMT time
    , TimeTypeBroker // Broker time
    , TimeTypeLocal // Local time
};

enum ScheduleType {
    ScheduleExactDatetime,
    ScheduleDayOfWeek,
    ScheduleDaily
};

class ScheduleUnit {
    public:
    bool definedAsClose;
    ScheduleType type;
    int dayOfWeek;
    //datetime open;
    //datetime close;
    datetime value;
    
    ScheduleUnit() {
        definedAsClose = false;
        type = ScheduleExactDatetime;
        dayOfWeek = -1;
        //open = -1;
        //close = -1;
        value = -1;
    }
    
    datetime getFullDatetime(ScheduleTimeType currentTimeType = TimeTypeBroker) {
        datetime currentDatetime = -1;
        switch(currentTimeType) {
            case TimeTypeGmt: currentDatetime = TimeGMT(); break;
            case TimeTypeLocal: currentDatetime = TimeLocal(); break;
            case TimeTypeBroker:
            default: currentDatetime = TimeCurrent(); break;
        }
        
        switch(type) {
            case ScheduleDaily:
            case ScheduleDayOfWeek: return Common::StripTimeFromDatetime(currentDatetime) + value;
            case ScheduleExactDatetime:
            default: return value;
        }
    }
    
    datetime getDate() {
        return Common::StripTimeFromDatetime(value);
    }
    
    datetime getTime() {
        return Common::StripDateFromDatetime(value);
    }
};

class MultiSettings {
    public:
    template<typename T>
    static void Parse(string options, T &destArray[], int expectedCount=-1, bool addToArray = true, bool fillDefaultVal = true);
    template<typename T>
    static void Parse(string options, T &destArray[], int &idArray[], int expectedCount=-1, bool addToArray = true, bool fillDefaultVal = true);
    template<typename T>
    static void Parse(string options, T defaultVal, T &destArray[], int &idArray[], int expectedCount=-1, bool addToArray = true, bool fillDefaultVal = true, bool paramDefaultValUndefined = false);
    
    template<typename T>
    static void FillDestArrayByValue(T &destArray[],int keyAddrInt,bool valueNumResult, double valueNum, string value);
    static void FillDestArrayByValue(bool &destArray[],int index,bool valueNumResult, double valueNum, string value);
    
    template<typename T>
    static void GetDefaultUndefinedValue(T &out);
    static void GetDefaultUndefinedValue(string &out);
    
    static int CountPairs(string optionPairs);
    static int CountPairs(string optionPairs, bool &defaultValSetOut);
    static int CountPairs(string &optionPairList[]);
    static int CountPairs(string &optionPairList[], bool &defaultValSetOut);
    static bool IsPairValid(string pair);
    
    static string GetPairValue(string pair);
    static string GetPairKey(string pair);

    static bool ParseLocation(string location, ValueLocation *locOut);
    static CalcSource GetLocationSource(string location);
    static double GetLocationValue(string location);
    static string GetLocationFilterName(string location);
    static CalcOperation GetLocationOperation(string location);
    static double GetLocationOperand(string location, CalcOperation operation);
    
    static void PrepareRedirects(int size);
    static void LoadRedirect(int index, double value);
    static double ParseValueRedirect(string value);
    static bool ParseValueRedirect(string value, double &valueOut);
    
    static bool ParseScheduleList(string schedule, ScheduleUnit* &scheduleList[]);
    static bool ParseDatetime(string datetimeStr, datetime &datetimeOut, ScheduleType &typeOut, int &dayOfWeekOut);

    private:
    static double Redirects[];
    
    static string KeyValDelimiter;
    static string PairDelimiter;
    
    static string DefaultDelimiter;
    
    static string RedirectDelimiter;
    static string OptimizeParamDelimiter;
    
    static string DateOpenDelimiter;
    static string DateCloseDelimiter;
    static string DateSegmentDelimiter;
    static string DateDayDelimiter;
    static string DateTimeDelimiter;
};

double MultiSettings::Redirects[];

string MultiSettings::KeyValDelimiter = ":"; // = does not import into MT4 ea settings
string MultiSettings::PairDelimiter = "|";

string MultiSettings::DefaultDelimiter = "*";

string MultiSettings::RedirectDelimiter = "@";
string MultiSettings::OptimizeParamDelimiter = ",";

string MultiSettings::DateOpenDelimiter = "+";
string MultiSettings::DateCloseDelimiter = "-";
string MultiSettings::DateSegmentDelimiter = " "; // space
string MultiSettings::DateDayDelimiter = ".";
string MultiSettings::DateTimeDelimiter = ":";

// https://docs.mql4.com/convert/chartostr

// 1. Split string by ;
// 2. Eval units
// 2a. If empty, assume provided default or skip
// 2b. If no =, assume A only
// 2c. If proper a=value, convert AddrAbc to AddrInt and record value

template<typename T>
void MultiSettings::Parse(string options, T &destArray[], int expectedCount=-1, bool addToArray = true, bool fillDefaultVal = true) {
    T defaultVal; GetDefaultUndefinedValue(defaultVal);
    Parse(options, defaultVal, destArray, IntZeroArray, expectedCount, addToArray, fillDefaultVal, true);
}

template<typename T>
void MultiSettings::Parse(string options, T &destArray[], int &idArray[], int expectedCount=-1, bool addToArray = true, bool fillDefaultVal = true) {
    T defaultVal; GetDefaultUndefinedValue(defaultVal);
    Parse(options, defaultVal, destArray, idArray, expectedCount, addToArray, fillDefaultVal, true);
}

template<typename T>
void MultiSettings::Parse(string options, T defaultVal, T &destArray[], int &idArray[], int expectedCount=-1, bool addToArray = true, bool fillDefaultVal = true, bool paramDefaultValUndefined = false) {
    string pairList[];
    int pairListCount = StringSplit(options, StringGetCharacter(PairDelimiter, 0), pairList);
    bool defaultValSet = false;
    int pairValidCount = CountPairs(pairList, defaultValSet);
    
    if(pairValidCount < 1 && !defaultValSet && expectedCount < 0) {
        Error::ThrowFatal("No valid key=val pairs found.", NULL, options);
        return;
    }
    
    bool fillIdArray = ArrayIsDynamic(idArray);
    if(fillIdArray) { 
        if(!addToArray) { ArrayFree(idArray); } 
        Common::ArrayReserve(idArray, ArraySize(idArray) + (expectedCount >= 0 ? expectedCount : pairValidCount)); 
    }
    
    int destArraySize = 0;
    int oldArraySize = 0;
    if(!addToArray) { ArrayFree(destArray); }
    else { oldArraySize = ArraySize(destArray); }
    destArraySize = ArrayResize(destArray, oldArraySize + (expectedCount >= 0 ? expectedCount : pairValidCount));
    
    int filledAddr[];
    string valueDefault = NULL; double valueNumDefault = NULL; bool valueNumResultDefault = false;
    for(int i = 0; i < pairValidCount+(defaultValSet?1:0); i++) { // defaults are not counted, add them here so the loop crosses them
        string key = NULL, value = NULL; int keyAddrInt = 0; double valueNum = 0; bool valueNumResult = false;
        
        if(IsPairValid(pairList[i])) {
            key = GetPairKey(pairList[i]);
            value = GetPairValue(pairList[i]);
            valueNumResult = ParseValueRedirect(value, valueNum);
            
            if(key == DefaultDelimiter) {
                valueDefault = value;
                valueNumDefault = valueNum;
                valueNumResultDefault = valueNumResult;
                defaultValSet = true;
                continue;
            }
            
            keyAddrInt = StringLen(key) <= 0 ? i : Common::AddrAbcToInt(key);
            if(addToArray) { keyAddrInt += oldArraySize; }

            if(keyAddrInt < 0 || keyAddrInt >= destArraySize) {
                Error::ThrowFatal("key=" + key + " (sub " + (keyAddrInt+1) + ") is not within expected count " + destArraySize, NULL, options);
                return;
            } else {
                FillDestArrayByValue(destArray, keyAddrInt, valueNumResult, valueNum, value);
                Common::ArrayPush(idArray, keyAddrInt); // fails silently if fixed array
                Common::ArrayPush(filledAddr, keyAddrInt);
            }
        }
    }
    
    if(!fillDefaultVal || ArraySize(filledAddr) >= expectedCount) { return; }
    
    if(!defaultValSet) {
        if(!paramDefaultValUndefined) {
            if(typename(T) == "string") {
                valueDefault = defaultVal;
                valueNumDefault = 0;
                valueNumResultDefault = false;
            } else {
                valueDefault = NULL;
                valueNumDefault = defaultVal;
                valueNumResultDefault = true;
            }
        } else {
            Error::ThrowFatal("Pairs are missing (" + pairValidCount + " specified, expected up to " + expectedCount + ") and default value not found. Default value must be specified", NULL, options);
            return;
        }
    }    
    
    // pass 2: fill non-filled values with default, if it exists
    for(int i = oldArraySize; i < destArraySize; i++) {
        if(Common::ArrayFind(filledAddr, i) >= 0) { continue; }
        
        FillDestArrayByValue(destArray, i, valueNumResultDefault, valueNumDefault, valueDefault);
    }
}

template<typename T>
void MultiSettings::FillDestArrayByValue(T &destArray[],int keyAddrInt,bool valueNumResult, double valueNum, string value) {
    if(typename(T) == "int") { destArray[keyAddrInt] = valueNumResult ? valueNum : StringToInteger(value); }
    else if(typename(T) == "double") { destArray[keyAddrInt] = valueNumResult ? valueNum : StringToDouble(value); }
    else { destArray[keyAddrInt] = value; }
}

// workaround for bool because template errors out with destArray[i] = value, says string can't convert to bool
void MultiSettings::FillDestArrayByValue(bool &destArray[],int keyAddrInt,bool valueNumResult, double valueNum, string value) {
    destArray[keyAddrInt] = valueNumResult ? valueNum : Common::StrToBool(value);
}

template<typename T>
void MultiSettings::GetDefaultUndefinedValue(T &out) {
    out = 0;
}

// workaround for string because 0 does not convert implicitly
void MultiSettings::GetDefaultUndefinedValue(string &out) {
    out = NULL;
}

//+------------------------------------------------------------------+

int MultiSettings::CountPairs(string optionPairs) {
    bool defaultValSet = false;
    return CountPairs(optionPairs, defaultValSet);
}

int MultiSettings::CountPairs(string optionPairs, bool &defaultValSetOut) {
    string pairList[];
    int pairListCount = StringSplit(optionPairs, StringGetCharacter(PairDelimiter, 0), pairList);
    
    return CountPairs(pairList, defaultValSetOut);
}

int MultiSettings::CountPairs(string &optionPairList[]) {
    bool defaultValSet = false;
    return CountPairs(optionPairList, defaultValSet);
}

int MultiSettings::CountPairs(string &optionPairList[], bool &defaultValSetOut) {
    int optionPairCount = 0;
    int optionPairListCount = ArraySize(optionPairList);
    
    int numPairsWithoutEquals = 0;
    for(int i = 0; i < optionPairListCount; i++) {
        if(IsPairValid(optionPairList[i])) { 
            if(GetPairKey(optionPairList[i]) == DefaultDelimiter) { 
                defaultValSetOut = true; // do not count in tally
            } else {
                optionPairCount++;
            }
        }
        else { return 0; }
    }
    
    return optionPairCount;
}

bool MultiSettings::IsPairValid(string pair) {
    // We support key=value (a=25). 
    // Empty values are also supported: key=
    
    pair = Common::StringTrim(pair);
    
    int delimiterPos = StringFind(pair, KeyValDelimiter);
    int pairLen = StringLen(pair);
    if(delimiterPos > 0) { return true; }
    else { 
        Error::ThrowFatal("Option pair found without key=. All options pairs must specify key=val", NULL, pair); 
        return false;
    } // todo: check if key is abc valid
        // Add this if empty values should not be supported: && pairLen > 0 && pairLen != delimiterPos
}

//+------------------------------------------------------------------+

string MultiSettings::GetPairKey(string pair) {
    pair = Common::StringTrim(pair);
    int delimiterPos = StringFind(pair, KeyValDelimiter);
    
    if(delimiterPos > 0) { return Common::StringTrim(StringSubstr(pair, 0, delimiterPos)); }
    else {
        Error::ThrowFatal("Option pair found without key=. All options pairs must specify key=[val]", NULL, pair); 
        return "";
    }
}

string MultiSettings::GetPairValue(string pair) {
    pair = Common::StringTrim(pair);
    int delimiterPos = StringFind(pair, KeyValDelimiter);
    
    if(delimiterPos > 0) { return Common::StringTrim(StringSubstr(pair, delimiterPos+1)); }
    else {
        Error::ThrowFatal("Option pair found without key=. All options pairs must specify key=[val]", NULL, pair); 
        return "";
    }
}

//+------------------------------------------------------------------+

bool MultiSettings::ParseLocation(string location, ValueLocation *locOut) {
    CalcSource source = GetLocationSource(location);
    
    switch(source) {
        case CalcValue:
            if(Common::IsInvalidPointer(locOut)) { locOut = new ValueLocation(); }
            locOut.source = source;
            locOut.operation = CalcExact;
            locOut.setVal = GetLocationValue(location);
            return true;
            
        case CalcFilter:
            if(Common::IsInvalidPointer(locOut)) { locOut = new ValueLocation(); }
            locOut.source = source;
            locOut.filterName = GetLocationFilterName(location);
            locOut.operation = GetLocationOperation(location);
            locOut.operand = GetLocationOperand(location, locOut.operation);
            return true;
            
        default:
            return false;
    }
    
    return true;
}

CalcSource MultiSettings::GetLocationSource(string location) {
    int delimPos = StringFind(location, PairDelimiter);
    
    if(delimPos < 0) {
        if(Common::GetStringType(location) == Type_Numeric) { return CalcValue; }
        else { return CalcFilter; }
    } else {
        return CalcFilter;
    }
}

double MultiSettings::GetLocationValue(string location) {
    int delimPos = StringFind(location, PairDelimiter);
    
    if(delimPos >= 0) { location = StringSubstr(location, 0, delimPos); }
    
    if(Common::GetStringType(location) == Type_Numeric) { return ParseValueRedirect(location); }
    else { return 0; }
}

string MultiSettings::GetLocationFilterName(string location) {
    int delimPos = StringFind(location, PairDelimiter);
    
    if(delimPos >= 0) { location = StringSubstr(location, 0, delimPos); }
    
    return location;
}

CalcOperation MultiSettings::GetLocationOperation(string location) {
    string unitList[];
    int unitListCount = StringSplit(location, StringGetCharacter(PairDelimiter, 0), unitList);
    
    if(unitListCount >= 2) {
        string compare = Common::StringTrim(unitList[1]);
        StringToLower(compare);
        if(compare == "offset") { return CalcOffset; }
        else if(compare == "factor") { return CalcFactor; }
        else if(compare == "divide") { return CalcDivide; }
        else if(compare == "add") { return CalcOffset; }
        else if(compare == "subtract") { return CalcSubtract; }
        else if(compare == "multiply") { return CalcFactor; }
        //else if(compare == "exact") { return CalcExact; }
        else { return CalcExact; }
    } else { return CalcExact; }
}

double MultiSettings::GetLocationOperand(string location, CalcOperation operation) {
    if(operation == CalcExact) { return 0; }

    string unitList[];
    int unitListCount = StringSplit(location, StringGetCharacter(PairDelimiter, 0), unitList);
    
    if(unitListCount >= 2) {
        string compare = Common::StringTrim(unitList[2]);
        if(Common::GetStringType(compare) == Type_Numeric) { return ParseValueRedirect(compare); }
    }
    
    switch(operation) {
        case CalcExact:
        case CalcOffset:
            return 0;
            
        case CalcFactor:
        case CalcDivide:
            return 1;
            
        default:
            return 0;
    }
}

//+------------------------------------------------------------------+

void MultiSettings::PrepareRedirects(int size) {
    if(ArraySize(Redirects) <= size) { Common::ArrayReserve(Redirects, size); }
}

void MultiSettings::LoadRedirect(int index, double value) {
    if(ArraySize(Redirects) <= index) { ArrayResize(Redirects, index+1); }
    
    Redirects[index] = value;
}

double MultiSettings::ParseValueRedirect(string value) {
    double result = 0;
    ParseValueRedirect(value, result);
    
    return result;
}

bool MultiSettings::ParseValueRedirect(string value, double &valueOut) {
    value = Common::StringTrim(value);
    if(StringFind(value, RedirectDelimiter) < 0) {
        valueOut = StringToDouble(value); 
        return false;
    }
    
    string valRed[];
    if(StringSplit(value, StringGetCharacter(RedirectDelimiter, 0), valRed) < 2) { 
        valueOut = StringToDouble(value); 
        return false;
    }
    
    valRed[1] = Common::StringTrim(valRed[1]);
    if(StringLen(valRed[1]) <= 0 || Common::GetStringType(valRed[1]) != Type_Numeric) {
        Error::ThrowFatal("Value redirect " + valRed[1] + " is not valid");
        valueOut = StringToDouble(value);
        return false;
    }
    int index = StringToInteger(valRed[1]);
    
    if(index < 0 || ArraySize(Redirects) <= index) {
        Error::ThrowFatal("Value redirect " + index + " does not exist");
        valueOut = StringToDouble(value);
        return false;
    }

    if(ArraySize(Redirects) > index) { 
        valueOut = Redirects[index]; 
        return true;
    } else if(StringLen(valRed[0]) > 0) { 
        valueOut = StringToDouble(valRed[0]); 
        return true;
    } else { return false; }
}

//+------------------------------------------------------------------+

bool MultiSettings::ParseScheduleList(string schedule, ScheduleUnit* &scheduleList[]) {
    string unitList[];
    int unitListCount = StringSplit(schedule, StringGetCharacter(PairDelimiter, 0), unitList);
    
    if(unitListCount > 0) {
        Common::SafeDeletePointerArray(scheduleList);
        ArrayFree(scheduleList);
    }
    
    for(int i = 0; i < unitListCount; i++) {
        string unitStr = Common::StringTrim(unitList[i]);
        string cmd = StringSubstr(unitStr, 0, 1);
        
        if(cmd != DateOpenDelimiter && cmd != DateCloseDelimiter) { continue; }
        
        datetime dt = -1; ScheduleType type = ScheduleExactDatetime; int dayOfWeek = -1;
        if(!ParseDatetime(StringSubstr(unitStr, 1), dt, type, dayOfWeek)) { continue; }
        
        ScheduleUnit *unit = new ScheduleUnit();
        unit.type = type;
        unit.dayOfWeek = dayOfWeek;
        
        unit.definedAsClose = (cmd == DateCloseDelimiter);
        unit.value = dt;
        //if(cmd == DateCloseDelimiter) { unit.close = dt; }
        //else { unit.open = dt; }
        Common::ArrayPush(scheduleList, unit);
    }
    
    return true;
}

bool MultiSettings::ParseDatetime(string datetimeStr, datetime &datetimeOut, ScheduleType &typeOut, int &dayOfWeekOut) {
    if(StringFind(datetimeStr, DateSegmentDelimiter) < 0) { // is daily
        datetimeOut = Common::StripDateFromDatetime(StringToTime(datetimeStr));
        typeOut = ScheduleDaily;
        dayOfWeekOut = -1;
        return true; // no way to tell if parse succeeded; it returns 00:00 of the current day
    } else {
        string datetimeSegment[];
        int segCount = StringSplit(datetimeStr, StringGetCharacter(DateSegmentDelimiter, 0), datetimeSegment);
        if(segCount != 2) { return false; }
        
        if(StringLen(datetimeSegment[0]) == 1 && Common::GetStringType(datetimeSegment[0]) == Type_Numeric && datetimeSegment[0] >= SUNDAY && datetimeSegment[0] <= SATURDAY) { // is weekday
            datetimeOut = Common::StripDateFromDatetime(StringToTime(datetimeSegment[1]));
            typeOut = ScheduleDayOfWeek;
            dayOfWeekOut = datetimeSegment[0];
        } else if(StringLen(datetimeSegment[0]) > 0) { // is exact date
            datetimeOut = StringToTime(datetimeStr); // partial dates follow MQL rules: yyyy.mm.dd OR dd.mm OR dd.mm.yyyy (NOT mm.dd)
            typeOut = ScheduleExactDatetime;
            dayOfWeekOut = -1;
        } else { return false; }
        
        return true;
    }
}