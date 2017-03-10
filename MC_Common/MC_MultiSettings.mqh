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

class MultiSettings {
    private:
    static string KeyValDelimiter;
    static string PairDelimiter;

    public:
    static string GetPairValue(string pair);
    static string GetPairKey(string pair, int indexNum = -1);
    static bool IsPairValid(string pair);
    static int CountPairs(string &optionPairList[]);
    static int CountPairs(string optionPairs);
    
    template<typename T>
    static void Parse(string options, T &destArray[], int expectedCount=-1, bool addToArray = true);
    
    template<typename T>
    static void Parse(string options, T &destArray[], int &idArray[], int expectedCount=-1, bool addToArray = true);
};

string MultiSettings::KeyValDelimiter = "=";
string MultiSettings::PairDelimiter = "|";

// https://docs.mql4.com/convert/chartostr

// 1. Split string by ;
// 2. Eval units
// 2a. If empty, assume provided default or skip
// 2b. If no =, assume A only
// 2c. If proper a=value, convert AddrAbc to AddrInt and record value

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

int MultiSettings::CountPairs(string optionPairs) {
    string pairList[];
    int pairListCount = StringSplit(optionPairs, StringGetCharacter(PairDelimiter, 0), pairList);
    
    return MultiSettings::CountPairs(pairList);
}

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
        string key, value; int keyAddrInt;
        
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
