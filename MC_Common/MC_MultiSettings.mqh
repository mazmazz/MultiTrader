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

    private:
    static string KeyValDelimiter;
    static string PairDelimiter;
    static string OptimizeDelimiter;
    static string OptimizeParamDelimiter;
};

string MultiSettings::KeyValDelimiter = "=";
string MultiSettings::PairDelimiter = "|";
string MultiSettings::OptimizeDelimiter = "#";
string MultiSettings::OptimizeParamDelimiter = ",";

// https://docs.mql4.com/convert/chartostr

// 1. Split string by ;
// 2. Eval units
// 2a. If empty, assume provided default or skip
// 2b. If no =, assume A only
// 2c. If proper a=value, convert AddrAbc to AddrInt and record value

template<typename T>
void MultiSettings::Parse(string options, T &destArray[], int expectedCount=-1, bool addToArray = true) {
    MultiSettings::Parse(options, destArray, IntZeroArray, expectedCount, addToArray);
}

template<typename T>
void MultiSettings::Parse(string options, T &destArray[], int &idArray[], int expectedCount=-1, bool addToArray = true) {
    string pairList[];
    int pairListCount = StringSplit(options, StringGetCharacter(PairDelimiter, 0), pairList);

    int pairValidCount = MultiSettings::CountPairs(pairList);
    
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
        string key = NULL, value = NULL; int keyAddrInt = 0;
        
        if(MultiSettings::IsPairValid(pairList[i])) {
            key = MultiSettings::GetPairKey(pairList[i], i);
            value = MultiSettings::GetPairValue(pairList[i]);
            keyAddrInt = StringLen(key) <= 0 ? i : Common::AddrAbcToInt(key);
            if(addToArray) { keyAddrInt += oldArraySize; }

            if(keyAddrInt < 0 || keyAddrInt >= destArraySize) {
                Error::ThrowFatalError(ErrorFatal, "key=" + key + " keyAddrInt=" + keyAddrInt + " is not within destArraySize=" + destArraySize, FunctionTrace, pairList[i]);
                return;
            } else {
                if(typename(T) == "bool") { destArray[keyAddrInt] = Common::StrToBool(value); }
                else if(typename(T) == "int") { destArray[keyAddrInt] = StringToInteger(value); }
                else if(typename(T) == "double") { destArray[keyAddrInt] = StringToDouble(value); }
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
    
    return MultiSettings::CountPairs(pairList);
}

int MultiSettings::CountPairs(string &optionPairList[]) {
    int optionPairCount = 0;
    int optionPairListCount = ArraySize(optionPairList);
    
    bool groupHasEquals = false;
    int numPairsWithoutEquals = 0;
    for(int i = 0; i < optionPairListCount; i++) {
        if(MultiSettings::IsPairValid(optionPairList[i])) { optionPairCount++; }
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
    
    if(Common::GetStringType(location) == Type_Numeric) { return StringToDouble(location); }
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
        if(Common::GetStringType(compare) == Type_Numeric) { return StringToDouble(compare); }
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
