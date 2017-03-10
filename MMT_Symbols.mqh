//+------------------------------------------------------------------+
//|                                              MMT_Helper_Main.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Settings.mqh"
#include "MC_Common/MC_Error.mqh"
#include "MC_Common/MC_Common.mqh"
#include "depends/Symbols.mqh"
#include "MMT_Filters/MMT_Filters.mqh"

//+------------------------------------------------------------------+

class SymbolUnit {
    public:
    // bool enabled;
    string formSymName;
    string bareSymName;
    // string prefix;
    // string suffix;
    // SymbolType type; // Forex, Metals, Indexes, ...
    string baseCurName;
    string quoteCurName;
    
    int digits;
    
    SymbolUnit(string formSymNameIn, string bareSymNameIn = "", string baseCurNameIn = "", string quoteCurNameIn = "");
};

void SymbolUnit::SymbolUnit(string formSymNameIn, string bareSymNameIn = "", string baseCurNameIn = "", string quoteCurNameIn = "") {
    formSymName = formSymNameIn;
    bareSymName = StringLen(bareSymNameIn) <= 0 ? formSymNameIn : bareSymNameIn;
    baseCurName = baseCurNameIn;
    quoteCurName = quoteCurNameIn;
    digits = MarketInfo(formSymName, MODE_DIGITS);
}

//+------------------------------------------------------------------+

class SymbolManager {
    public:
    SymbolUnit *symbols[];
    string symNames[];
    string excludeSym; // not an array, we don't need it for our processing
    string excludeCur[];
    
    int symbolCount() { return ArraySize(symbols); }
    
    SymbolManager(string includeSymbols, string excludeSymbols, string excludeCurrencies);
    ~SymbolManager();
    
    void retrieveActiveSymbols(string includeSym, string excludeSym, string excludeCur);
    
    int addSymbol(string formSymName, string bareSymName = "", string baseCurName = "", string quoteCurName = "");
    int getSymbolId(string symName, bool isFormSymName = false);
    string getFormSymName(string symName);
    int getSymbolDigits(string symName);
    bool isSymbolExcluded(string symName, string excludeSym, string &excludeCur[]);
    void removeAllSymbols();
    
    bool retrieveData();
    
    static int getAllSymbols(string &allSymBuffer[]);
    static bool doesSymbolHaveSuffix(string symName, string symSuffix);
    static string getCurrencySuffix(string symName);
    static string formatSymbolName(string symName, string symSuffix, /*string curPrefix*/);
    static string unformatSymbolName(string symName, string symSuffix);
    static string getSymbolBaseCurrency(string symName);
    static string getSymbolQuoteCurrency(string symName);
};

//+------------------------------------------------------------------+
// Class methods [METHODS]
//+------------------------------------------------------------------+

void SymbolManager::SymbolManager(string includeSymbols, string excludeSymbols, string excludeCurrencies) {
    retrieveActiveSymbols(includeSymbols, excludeSymbols, excludeCurrencies);
}

void SymbolManager::~SymbolManager() {
    removeAllSymbols();
}

void SymbolManager::retrieveActiveSymbols(string includeSym, string excludeSymIn, string excludeCurIn) {
    string symSuffix = getCurrencySuffix(Symbol());
    
    ArrayFree(symNames);
    ArrayFree(excludeCur);
    string finalSymString;
    
    string includeSymSplit[];
    int includeSymCount; int excludeCurCount;
    
    if(SingleSymbolMode) {
        includeSymCount = Common::ArrayPush(includeSymSplit, Symbol());
    } else {
        char delimiter = StringGetCharacter(",", 0);
        includeSymCount = StringSplit(includeSym, delimiter, includeSymSplit);
        excludeCurCount = StringSplit(excludeCurIn, delimiter, excludeCur);
        excludeSym = excludeSymIn; // we can just do a StringFind on this
    }
    
    if(includeSymCount < 1) {
        ArrayFree(includeSymSplit);
        includeSymCount = SymbolManager::getAllSymbols(includeSymSplit);
    }
    
    for(int i = 0; i < includeSymCount; i++) {
        string rawSymName = Common::StringTrim(includeSymSplit[i]);
        int symLength = StringLen(rawSymName);
        if(symLength < 6 || Common::GetStringType(StringSubstr(rawSymName, 0, 1)) == Type_Symbol) {
            if(symLength > 0) { Error::PrintInfo(ErrorInfo, "rawSymName invalid, skipping", FunctionTrace, rawSymName); }
            continue; 
        }
        
        string formSymName = formatSymbolName(rawSymName, symSuffix);
        string bareSymName = unformatSymbolName(rawSymName, symSuffix);
        
        if(SingleSymbolMode || !isSymbolExcluded(bareSymName, excludeSym, excludeCur)) { 
            // todo: exclude non-forex symbols even if SingleSymbolMode
            addSymbol(formSymName, bareSymName, getSymbolBaseCurrency(bareSymName), getSymbolQuoteCurrency(bareSymName));
            
            if(DebugLevel >= 2) StringAdd(finalSymString, StringConcatenate(", ", formSymName));
        }
    }
    
    Error::PrintInfo(ErrorInfo, StringConcatenate("Active symbols: ", finalSymString), FunctionTrace);
}


int SymbolManager::addSymbol(string formSymName, string bareSymName = "", string baseCurName = "", string quoteCurName = "") {
    int size = ArraySize(symbols); // assuming 1-based

    Common::ArrayPush(symbols, new SymbolUnit(formSymName, bareSymName, baseCurName, quoteCurName));
    return Common::ArrayPush(symNames, formSymName);
}

int SymbolManager::getSymbolId(string symName, bool isBareSymName = false) {
    int size = ArraySize(symbols);
    
    for(int i = 0; i < size; i++) {
        if(isBareSymName) {
            if(symbols[i].bareSymName == symName) { return i; }
        } else {
            if(symbols[i].formSymName == symName) { return i; }
        }
    }
    
    return -1;
}

bool SymbolManager::isSymbolExcluded(string symName, string excludeSymIn, string &excludeCurIn[]) {
    if(StringFind(excludeSymIn, symName) > -1) { return true; }
    
    int excludeCurCount = ArraySize(excludeCurIn);
    for(int i = 0; i < excludeCurCount; i++) {
        if(StringFind(symName, excludeCurIn[i]) > -1) { return true; }
    }

    return false;
}

void SymbolManager::removeAllSymbols() {
    int size = ArraySize(symbols); // assuming 1-based
    
    for(int i=0; i < size; i++) {
        delete(symbols[i]);
    }
    
    ArrayFree(symbols);
    ArrayFree(symNames);
}

string SymbolManager::getFormSymName(string symName) {
    int index = getSymbolId(symName);
    
    return symbols[index].formSymName;
}

int SymbolManager::getSymbolDigits(string symName) {
    int index = getSymbolId(symName);
    
    return symbols[index].digits;
}

bool SymbolManager::retrieveData() {
    int size = ArraySize(symbols);
    
    for(int i = 0; i < size; i++) {
        MainFilterMan.calculateFilters(symbols[i].formSymName);
    }
    
    return true;
}

//+------------------------------------------------------------------+
// Helpers [HELPERS]
//+------------------------------------------------------------------+

int SymbolManager::getAllSymbols(string &allSymBuffer[]) {
    return Symbols(allSymBuffer);
}

//bool DoesSymbolHavePrefix(string curName, string curPrefix) {
//    bool result;
//    
//    return result;
//}
//
//string GetSymbolPrefix(string curName) {
//    string result;
//    
//    return result;
//}

bool SymbolManager::doesSymbolHaveSuffix(string symName, string symSuffix) {
    return (StringLen(symName) > 6 && StringCompare(StringSubstr(symName, 6), symSuffix) == 0);
}

string SymbolManager::getCurrencySuffix(string symName) {
    return StringSubstr(symName, 6);
}

string SymbolManager::formatSymbolName(string symName, string symSuffix, /*string curPrefix*/) {
    if(StringLen(symName) < 6) { 
        Error::ThrowError(ErrorNormal, "symName is not >=6 chars, assuming invalid, passing as is.", FunctionTrace); 
        return symName;
    }
    
    if(StringLen(symSuffix) < 1) { return symName; }
    else if(doesSymbolHaveSuffix(symName, symSuffix)) { return symName; }
    else if(StringAdd(symName, symSuffix)) { return symName; } 
    else {
        Error::ThrowError(ErrorNormal, "Could not figure out how to format symName, passing as is.", FunctionTrace);
        return symName;
    }
}

string SymbolManager::unformatSymbolName(string symName, string symSuffix = "") {
    if(StringLen(symName) < 6) { 
        Error::ThrowError(ErrorNormal, "symName is not >=6 chars, assuming invalid, passing as is.", FunctionTrace); 
        return symName;
    }
    
    if(StringLen(symSuffix) <= 0) { symSuffix = getCurrencySuffix(symName); }
    if(StringLen(symSuffix) < 1) { return symName; }
    else if(!doesSymbolHaveSuffix(symName, symSuffix)) { return symName; }
    else if(StringReplace(symName, symSuffix, "") > -1) { return symName; } 
    else {
        Error::ThrowError(ErrorNormal, "Could not figure out how to unformat symName, passing as is.", FunctionTrace);
        return symName;
    }
}

string SymbolManager::getSymbolBaseCurrency(string symName) {
    string bareSymName = unformatSymbolName(symName);
    return StringSubstr(bareSymName, 0, 3);
}

string SymbolManager::getSymbolQuoteCurrency(string symName) {
    string bareSymName = unformatSymbolName(symName);
    return StringSubstr(bareSymName, 3, 3);
}

SymbolManager *MainSymbolMan;