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
    static void Parse(string options, T &destArray[], int expectedCount=-1, bool addToArray = true);
    template<typename T>
    static void Parse(string options, T &destArray[], int &idArray[], int expectedCount=-1, bool addToArray = true);
    
    static int CountPairs(string &optionPairList[]);
    static int CountPairs(string optionPairs);
    static bool IsPairValid(string pair);
    
    static string GetPairValue(string pair);
    static string GetPairKey(string pair, int indexNum = -1);

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
    
    static string RedirectDelimiter;
    static string OptimizeParamDelimiter;
    
    static string DateOpenDelimiter;
    static string DateCloseDelimiter;
    static string DateSegmentDelimiter;
    static string DateDayDelimiter;
    static string DateTimeDelimiter;
};

double MultiSettings::Redirects[];

string MultiSettings::KeyValDelimiter = "=";
string MultiSettings::PairDelimiter = "|";

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
void MultiSettings::Parse(string options, T &destArray[], int expectedCount=-1, bool addToArray = true) {
    Parse(options, destArray, IntZeroArray, expectedCount, addToArray);
}

template<typename T>
void MultiSettings::Parse(string options, T &destArray[], int &idArray[], int expectedCount=-1, bool addToArray = true) {
    string pairList[];
    int pairListCount = StringSplit(options, StringGetCharacter(PairDelimiter, 0), pairList);

    int pairValidCount = CountPairs(pairList);
    
    if(pairValidCount < 1 || (expectedCount > -1 ? pairValidCount != expectedCount : false)) {
        Error::ThrowFatalError(ErrorFatal
            , pairValidCount < 1 ? 
                ("pairValidCount=" + pairValidCount + " not >= 1") 
                : ("pairValidCount=" + pairValidCount + " does not match expectedCount=" + expectedCount + ". options=" + options)
            , FunctionTrace    
            );
        return;
    }
    
    bool fillIdArray = ArrayIsDynamic(idArray);
    if(fillIdArray) { 
        if(!addToArray) { ArrayFree(idArray); } 
        Common::ArrayReserve(idArray, ArraySize(idArray) + pairValidCount); 
    }
    
    int destArraySize = 0;
    int oldArraySize = 0;
    if(!addToArray) { ArrayFree(destArray); }
    else { oldArraySize = ArraySize(destArray); }
    destArraySize = ArrayResize(destArray, oldArraySize+pairValidCount);
    
    for(int i = 0; i < pairValidCount; i++) {
        string key = NULL, value = NULL; int keyAddrInt = 0; double valueNum = 0; bool valueNumResult = false;
        
        if(IsPairValid(pairList[i])) {
            key = GetPairKey(pairList[i], i);
            value = GetPairValue(pairList[i]);
            valueNumResult = ParseValueRedirect(value, valueNum);
            
            keyAddrInt = StringLen(key) <= 0 ? i : Common::AddrAbcToInt(key);
            if(addToArray) { keyAddrInt += oldArraySize; }

            if(keyAddrInt < 0 || keyAddrInt >= destArraySize) {
                Error::ThrowFatalError(ErrorFatal, "key=" + key + " keyAddrInt=" + keyAddrInt + " is not within destArraySize=" + destArraySize, FunctionTrace, pairList[i]);
                return;
            } else {
                if(typename(T) == "bool") { destArray[keyAddrInt] = valueNumResult ? valueNum : Common::StrToBool(value); }
                else if(typename(T) == "int") { destArray[keyAddrInt] = valueNumResult ? valueNum : StringToInteger(value); }
                else if(typename(T) == "double") { destArray[keyAddrInt] = valueNumResult ? valueNum : StringToDouble(value); }
                else { destArray[keyAddrInt] = value; }
                
                Common::ArrayPush(idArray, keyAddrInt);
            }
        }
    }
}

//+------------------------------------------------------------------+

int MultiSettings::CountPairs(string optionPairs) {
    string pairList[];
    int pairListCount = StringSplit(optionPairs, StringGetCharacter(PairDelimiter, 0), pairList);
    
    return CountPairs(pairList);
}

int MultiSettings::CountPairs(string &optionPairList[]) {
    int optionPairCount = 0;
    int optionPairListCount = ArraySize(optionPairList);
    
    bool groupHasEquals = false;
    int numPairsWithoutEquals = 0;
    for(int i = 0; i < optionPairListCount; i++) {
        if(IsPairValid(optionPairList[i])) { optionPairCount++; }
        if(StringFind(optionPairList[i], KeyValDelimiter) > -1) { groupHasEquals = true; }
        else { numPairsWithoutEquals++; }
    }
    
    if(groupHasEquals && numPairsWithoutEquals > 0) {
        optionPairCount = 0;
        Error::ThrowFatalError(ErrorFatal, "All option pairs must be key=val when at least one key=val is present.", FunctionTrace, Common::ConcatStringFromArray(optionPairList));
    }
    
    return optionPairCount;
}

bool MultiSettings::IsPairValid(string pair) {
    // We support value-only (25) and key=value (a=25). 
    // Empty values are also supported but I'm undecided on this: key=blank (a=), or blank ().
    // Only invalid pair is =value (=25) or = (=), no key provided.
    // If one pair uses =, all of them must use =.
    
    pair = Common::StringTrim(pair);
    
    int delimiterPos = StringFind(pair, KeyValDelimiter);
    int pairLen = StringLen(pair);
    return (delimiterPos != 0); // todo: check if key is abc valid
        // Add this if empty values should not be supported: && pairLen > 0 && pairLen != delimiterPos
}

//+------------------------------------------------------------------+

string MultiSettings::GetPairKey(string pair, int indexNum = -1) {
    pair = Common::StringTrim(pair);
    int delimiterPos = StringFind(pair, KeyValDelimiter);
    
    if(delimiterPos > 0) { return StringSubstr(pair, 0, delimiterPos); }
    else if(delimiterPos < 0) {
        if(indexNum < 0) { return ""; } // -1 means to return no key; calling procedure should know how to handle this case.
        else { return Common::AddrIntToAbc(indexNum, true); }
    }
    else {
        Error::ThrowFatalError(ErrorFatal, "Invalid key=val pair", FunctionTrace, pair);
        return "";
    }
}

string MultiSettings::GetPairValue(string pair) {
    pair = Common::StringTrim(pair);
    int delimiterPos = StringFind(pair, KeyValDelimiter);
    
    if(delimiterPos > 0) { return StringSubstr(pair, delimiterPos+1); }
    else if(delimiterPos < 0) { return pair; }
    else {
        Error::ThrowFatalError(ErrorFatal, "Invalid key=val pair", FunctionTrace, pair);
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
        return true;
    }
    
    string valRed[];
    if(StringSplit(value, RedirectDelimiter, valRed) < 2) { 
        valueOut = StringToDouble(value); 
        return true;
    }
    
    valRed[0] = Common::StringTrim(valRed[0]);
    if(!IsOptimization() && StringLen(valRed[0]) > 0) { 
        valueOut = StringToDouble(valRed[0]); 
        return true;
    }
    
    // if there's redirect notation ([value]@[redirectIndex])
    valRed[1] = Common::StringTrim(valRed[1]);
    if(StringLen(valRed[1]) > 0) {
        string indexStr = NULL;
        
        if(StringFind(valRed[1], OptimizeParamDelimiter) < 0) {
            indexStr = valRed[1];
        } else {
            string optParams[];
            StringSplit(value, OptimizeParamDelimiter, optParams);
            indexStr = Common::StringTrim(optParams[0]);
        }
        
        int index = StringToInteger(indexStr);
        
        if(ArraySize(Redirects) > index) { 
            valueOut = Redirects[index]; 
            return true;
        } else if(StringLen(valRed[0]) > 0) { 
            valueOut = StringToDouble(valRed[0]); 
            return true;
        }
    }
    
    return false;
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