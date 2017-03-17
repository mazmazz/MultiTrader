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
#include "MMT_Filters/MMT_Filters.mqh"

//+------------------------------------------------------------------+

class SymbolUnit {
    public:
    // bool enabled;
    string name;
    string bareName;
    //string prefix;
    //string suffix;
    // SymbolType type; // Forex, Metals, Indexes, ...
    string baseCurName;
    string quoteCurName;
    
    int digits;
    
    SymbolUnit(string nameIn, string bareNameIn = "", string baseCurNameIn = "", string quoteCurNameIn = "");
};

void SymbolUnit::SymbolUnit(string nameIn, string bareNameIn = "", string baseCurNameIn = "", string quoteCurNameIn = "") {
    name = nameIn;
    bareName = StringLen(bareNameIn) <= 0 ? nameIn : bareNameIn;
    baseCurName = baseCurNameIn;
    quoteCurName = quoteCurNameIn;
    digits = MarketInfo(name, MODE_DIGITS);
}

//+------------------------------------------------------------------+

class SymbolManager {
    public:
    SymbolUnit *symbols[];
    string excludeSym; // not an array, we don't need it for our processing
    string excludeCur[];
    
    SymbolManager(string includeSymbols, string excludeSymbols, string excludeCurrencies);
    ~SymbolManager();
    
    void retrieveActiveSymbols(string includeSym, string excludeSym, string excludeCur);
    
    int addSymbol(string name, string bareName = "", string baseCurName = "", string quoteCurName = "");
    int getSymbolId(string symName, bool isFormSymName = false);
    int getSymbolCount();
    bool isSymbolTradable(string symName);
    bool isSymbolExcluded(string symName, string excludeSym, string &excludeCur[]);
    void removeAllSymbols();
    
    bool retrieveData();
    
    static int getAllSymbols(string &allSymBuffer[]);
    static string getCompareSymbol(int symType = 0);
    static string getSymbolPrefix(string symName);
    static string getSymbolSuffix(string symName);
    static string fixSymbolName(string symName, string compareName = NULL);
    static string stripSymbolName(string symName);
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
        string rawName = Common::StringTrim(includeSymSplit[i]);
        string name = fixSymbolName(rawName);
        string bareName = stripSymbolName(rawName);
        
        if(isSymbolTradable(name) && (SingleSymbolMode || !isSymbolExcluded(bareName, excludeSym, excludeCur))) { 
            addSymbol(name, bareName, getSymbolBaseCurrency(name), getSymbolQuoteCurrency(name));
            
            if(ErrorTerminalLevel >= ErrorInfo || ErrorFileLevel >= ErrorInfo || ErrorAlertLevel >= ErrorInfo) { 
                finalSymString += ", " + name; 
            }
        }
    }
    
    Error::PrintInfo(ErrorInfo, "Active symbols: " + finalSymString, FunctionTrace);
}


int SymbolManager::addSymbol(string name, string bareName = "", string baseCurName = "", string quoteCurName = "") {
    int size = ArraySize(symbols); // assuming 1-based

    return Common::ArrayPush(symbols, new SymbolUnit(name, bareName, baseCurName, quoteCurName));
}

int SymbolManager::getSymbolCount() {
    return ArraySize(symbols);
}

int SymbolManager::getSymbolId(string symName, bool isBareSymName = false) {
    int size = ArraySize(symbols);
    
    for(int i = 0; i < size; i++) {
        if(isBareSymName) {
            if(symbols[i].bareName == symName) { return i; }
        } else {
            if(symbols[i].name == symName) { return i; }
        }
    }
    
    return -1;
}

bool SymbolManager::isSymbolTradable(string symName) {
    // todo: allow non-forex types to be traded?
    return (
        SymbolInfoInteger(symName, SYMBOL_TRADE_CALC_MODE) == 0 // forex type
        && SymbolInfoInteger(symName, SYMBOL_TRADE_MODE) > 0 // not disabled for trading
        );
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
        Common::SafeDelete(symbols[i]);
    }
    
    ArrayFree(symbols);
}

bool SymbolManager::retrieveData() {
    int size = ArraySize(symbols);
    
    for(int i = 0; i < size; i++) {
        MainFilterMan.calculateFilters(i);
    }
    
    return true;
}

//+------------------------------------------------------------------+
// Helpers [HELPERS]
//+------------------------------------------------------------------+

int SymbolManager::getAllSymbols(string &allSymBuffer[]) {
    int count = SymbolsTotal(false);
    Common::ArrayReserve(allSymBuffer, count);
    
    for(int i = 0; i < count; i++) {
        string symName = SymbolName(i, false);
        Common::ArrayPush(allSymBuffer, symName);
    }
    
    return ArraySize(allSymBuffer);
}

string SymbolManager::getCompareSymbol(int symType=0) {
    int count = SymbolsTotal(false);
    
    for(int i = 0; i < count; i++) {
        string symName = SymbolName(i, false);
        if(SymbolInfoInteger(symName, SYMBOL_TRADE_CALC_MODE) == symType) { return symName; }
    }
    
    return "";
}

string SymbolManager::getSymbolPrefix(string symName) {
    string baseCur = getSymbolBaseCurrency(symName);
    string quoteCur = getSymbolQuoteCurrency(symName);
    
    if(StringLen(symName) > StringLen(baseCur) + StringLen(quoteCur)) {
        int basePos = StringFind(symName, baseCur);
        if(basePos > 0) {
            return StringSubstr(symName, 0, basePos);
        }
    }
    
    return "";
}

string SymbolManager::getSymbolSuffix(string symName) {
    string baseCur = getSymbolBaseCurrency(symName);
    string quoteCur = getSymbolQuoteCurrency(symName);
    
    if(StringLen(symName) > StringLen(baseCur) + StringLen(quoteCur)) {
        int quotePos = StringFind(symName, quoteCur);
        if(quotePos >= StringLen(baseCur)) {
            return StringSubstr(symName, quotePos+StringLen(quoteCur));
        }
    }
    
    return "";
}

string SymbolManager::fixSymbolName(string symName, string compareName = NULL) {
    // todo: remove nonexistant -fixes if necessary

    // we need to compare given symName to a market-provided symName, and add prefix and suffix if necessary
    if(StringLen(compareName) <= 0) { compareName = getCompareSymbol(); }
    
    string prefix = getSymbolPrefix(compareName);
    string suffix = getSymbolSuffix(compareName);
    
    if(StringLen(suffix) > 0 && StringFind(symName, suffix) != StringLen(symName)-StringLen(suffix)) { symName = symName + suffix; }
    if(StringLen(prefix) > 0 && StringFind(symName, prefix) != 0) { symName = prefix + symName; }
    
    return symName;
}

string SymbolManager::stripSymbolName(string symName) {
    string prefix = getSymbolPrefix(symName);
    string suffix = getSymbolSuffix(symName);

    if(StringLen(prefix) > 0) { StringReplace(symName, prefix, ""); }
    if(StringLen(suffix) > 0) { StringReplace(symName, suffix, ""); }
    
    return symName;    
}

string SymbolManager::getSymbolBaseCurrency(string symName) {
    string result;
    SymbolInfoString(symName, SYMBOL_CURRENCY_BASE, result);
    return result;
}

string SymbolManager::getSymbolQuoteCurrency(string symName) {
    string result;
    SymbolInfoString(symName, SYMBOL_CURRENCY_PROFIT, result);
    return result;
}

SymbolManager *MainSymbolMan;