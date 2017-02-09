//+------------------------------------------------------------------+
//|                                     MMT_Helper_OptionsParser.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Helper_Library.mqh"
#include "MMT_Helper_Error.mqh"

enum DataType {
    DataString,
    DataBool,
    //DataShort,
    DataInt,
    //DataLong,
    //DataUshort,
    //DataUint,
    //DataUlong,
    DataDouble,
    //DataFloat
};

string StringZeroArray[];
bool BoolZeroArray[];
int IntZeroArray[];
double DoubleZeroArray[];

// https://docs.mql4.com/convert/chartostr

// 1. Split string by ;
// 2. Eval units
// 2a. If empty, assume provided default or skip
// 2b. If no =, assume A only
// 2c. If proper a=value, convert AddrAbc to AddrInt and record value

string ParseOptions_GetPairValue(string pair) {
    pair = StringTrim(pair);
    int delimiterPos = StringFind(pair, "=");
    
    if(delimiterPos > 0) { return StringSubstr(pair, delimiterPos+1); }
    else if(delimiterPos < 0) { return pair; } // missing = assumes key a
    else {
        ThrowFatalError(1, ErrorFunctionTrace, StringConcatenate("pair=", pair, " keyLength=", delimiterPos, " not >= 1"));
        return "";
    }
}

string ParseOptions_GetPairKey(string pair) {
    pair = StringTrim(pair);
    int delimiterPos = StringFind(pair, "=");
    
    if(delimiterPos > 0) { return StringSubstr(pair, 0, delimiterPos); }
    else if(delimiterPos < 0) { return "a"; } // missing = assumes key a
    else {
        ThrowFatalError(1, ErrorFunctionTrace, StringConcatenate("pair=", pair, " keyLength=", delimiterPos, " not >= 1"));
        return "";
    }
}

bool ParseOptions_IsPairValid(string pair) {
    pair = StringTrim(pair);
    // If it has at least one equals, it's valid. Todo: check if [key] is a valid ABC addr.
    int delimiterPos = StringFind(pair, "=");
    return (delimiterPos != 0 && StringLen(pair) > 0); // needs to be at least pos 1 or not exist. pair must not be empty
}

int ParseOptions_CountPairs(string &optionPairList[]) {
    int optionPairCount = 0;
    int optionPairListCount = ArraySize(optionPairList);
    
    for(int i = 0; i < optionPairListCount; i++) {
        if(ParseOptions_IsPairValid(optionPairList[i])) { optionPairCount++; }
    }
    
    return optionPairCount;
}

int ParseOptions_CountPairs(string optionPairs) {
    string pairList[];
    int pairListCount = StringSplit(optionPairs, StringGetCharacter(";", 0), pairList);
    
    return ParseOptions_CountPairs(pairList);
}

void ParseOptions_ParseGeneric(string options,
    DataType valueType, 
    string &stringDestArray[], bool &boolDestArray[], 
    /*short &shortDestArray[],*/ int &intDestArray[],/* long &longDestArray[],*/
    /*ushort &ushortDestArray[], uint &uintDestArray[], ulong &ulongDestArray[],*/
    double &doubleDestArray[],/* float &floatDestArray[],*/
    int expectedCount=-1
    ) {
    string pairList[];
    int pairListCount = StringSplit(options, StringGetCharacter(";", 0), pairList);

    int pairValidCount = ParseOptions_CountPairs(pairList);
    
    if(pairValidCount < 1 || (expectedCount > -1 ? pairValidCount != expectedCount : false)) {
        ThrowFatalError(1, ErrorFunctionTrace, 
            pairValidCount < 1 ? StringConcatenate("pairValidCount=", pairValidCount, " not >= 1") : StringConcatenate("pairValidCount=", pairValidCount, " does not match expectedCount=", expectedCount, ". options=", options)
            );
        return;
    }
    
    int destArraySize = 0;
    switch(valueType) {
        case DataString: ArrayFree(stringDestArray); destArraySize = ArrayResize(stringDestArray, pairValidCount); break;
        case DataBool: ArrayFree(boolDestArray); destArraySize = ArrayResize(boolDestArray, pairValidCount); break;
        //case DataShort: ArrayFree(shortDestArray); destArraySize = ArrayResize(shortDestArray, pairValidCount); break;
        case DataInt: ArrayFree(intDestArray); destArraySize = ArrayResize(intDestArray, pairValidCount); break;
        //case DataLong: ArrayFree(longDestArray); destArraySize = ArrayResize(longDestArray, pairValidCount); break;
        //case DataUshort: ArrayFree(ushortDestArray); destArraySize = ArrayResize(ushortDestArray, pairValidCount); break;
        //case DataUint: ArrayFree(uintDestArray); destArraySize = ArrayResize(uintDestArray, pairValidCount); break;
        //case DataUlong: ArrayFree(ulongDestArray); destArraySize = ArrayResize(ulongDestArray, pairValidCount); break;
        case DataDouble: ArrayFree(doubleDestArray); destArraySize = ArrayResize(doubleDestArray, pairValidCount); break;
        //case DataFloat: ArrayFree(floatDestArray); destArraySize = ArrayResize(floatDestArray, pairValidCount); break;
    }
    
    for(int i = 0; i < pairListCount; i++) {
        string key, value; int keyAddrInt;
        
        if(ParseOptions_IsPairValid(pairList[i])) {
            key = ParseOptions_GetPairKey(pairList[i]);
            value = ParseOptions_GetPairValue(pairList[i]);
            keyAddrInt = AddrAbcToInt(key);
            
            if(keyAddrInt < 0 || keyAddrInt >= destArraySize) {
                ThrowFatalError(1, ErrorFunctionTrace, StringConcatenate("key=", key, " keyAddrInt=", keyAddrInt, " is not within destArraySize=", destArraySize));
                return;
            } else {
                switch(valueType) {
                    case DataString: stringDestArray[keyAddrInt] = value; break;
                    case DataBool: boolDestArray[keyAddrInt] = StrToBool(value); break;
                    //case DataShort: shortDestArray[keyAddrInt] = value; break;
                    case DataInt: intDestArray[keyAddrInt] = StrToInteger(value); break;
                    //case DataLong: longDestArray[keyAddrInt] = value; break;
                    //case DataUshort: ushortDestArray[keyAddrInt] = value; break;
                    //case DataUint: uintDestArray[keyAddrInt] = value; break;
                    //case DataUlong: ulongDestArray[keyAddrInt] = value; break;
                    case DataDouble: doubleDestArray[keyAddrInt] = StrToDouble(value); break;
                    //case DataFloat: floatDestArray[keyAddrInt] = value; break;
                }
            }
        }
    }
}

void ParseOptions_String(string options, string &destArray[], int expectedCount=-1) {
    ParseOptions_ParseGeneric(options, DataString, 
        destArray, BoolZeroArray, IntZeroArray, DoubleZeroArray,
        expectedCount
        );
}

void ParseOptions_Bool(string options, bool &destArray[], int expectedCount=-1) {
    ParseOptions_ParseGeneric(options, DataBool, 
        StringZeroArray, destArray, IntZeroArray, DoubleZeroArray,
        expectedCount
        );
}

void ParseOptions_Int(string options, int &destArray[], int expectedCount=-1) {
    ParseOptions_ParseGeneric(options, DataInt, 
        StringZeroArray, BoolZeroArray, destArray, DoubleZeroArray,
        expectedCount
        );
}

void ParseOptions_Double(string options, double &destArray[], int expectedCount=-1) {
    ParseOptions_ParseGeneric(options, DataDouble, 
        StringZeroArray, BoolZeroArray, IntZeroArray, destArray,
        expectedCount
        );
}
