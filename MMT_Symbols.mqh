//+------------------------------------------------------------------+
//|                                              MMT_Helper_Main.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MC_Common/MC_Error.mqh"
#include "MC_Common/MC_Common.mqh"
#include "MMT_Main.mqh"
#include "depends/Symbols.mqh"

//+------------------------------------------------------------------+
// Symbol classes [CLASSES]
//+------------------------------------------------------------------+

class SymbolUnit {
    public:
    SymbolUnit(string formSymName, string bareSymName = "");
    
    string formSymName;
    string bareSymName;
};

class SymbolManager {
    public:
    SymbolManager(string includeSymbols, string excludeSymbols, string excludeCurrencies);
    ~SymbolManager();
    
    SymbolUnit *symbols[]; // array
    string symNames[];
    int symbolCount;
    
    string excludeSym; // not an array
    string excludeCur[]; // array
    
    int addSymbol(string formSymName, string bareSymName = "");
    int getSymbolId(string formSymName);
    void removeSymbol();
    void removeAllSymbols();
    bool isSymbolExcluded(string symName, string excludeSym, string &excludeCur[]);
    void getActiveSymbols(string includeSym, string excludeSym, string excludeCur);
    
    static string getCurrencySuffix(string symName);
    static bool doesSymbolHaveSuffix(string symName, string symSuffix);
    static string formatSymbolName(string symName, string symSuffix, /*string curPrefix*/);
    static string unformatSymbolName(string symName, string symSuffix);
    static int getAllSymbols(string &allSymBuffer[]);
};

//+------------------------------------------------------------------+
// Class methods [METHODS]
//+------------------------------------------------------------------+

void SymbolUnit::SymbolUnit(string formSymNameIn, string bareSymNameIn = "") {
    formSymName = formSymNameIn;
    bareSymName = bareSymNameIn;
}

int SymbolManager::addSymbol(string formSymName, string bareSymName = "") {
    int size = ArraySize(symbols); // assuming 1-based
    ArrayResize(symbols, size+1);
    ArrayResize(symNames, size+1);
    
    symbols[size] = new SymbolUnit(formSymName, bareSymName);
    symNames[size] = formSymName;
    
    return size+1;
}

int SymbolManager::getSymbolId(string formSymName) {
    int size = ArraySize(symNames);
    
    for(int i = 0; i < size; i++) {
        if(StringCompare(symNames[i], formSymName) == 0) { return i; }
    }
    
    return -1;
}

void SymbolManager::removeAllSymbols() {
    int size = ArraySize(symbols); // assuming 1-based
    
    for(int i=0; i < size; i++) {
        delete(symbols[i]);
    }
    
    ArrayFree(symbols);
    ArrayFree(symNames);
    
    return;
}

void SymbolManager::getActiveSymbols(string includeSym, string excludeSymIn, string excludeCurIn) {
    string symSuffix = SymbolManager::getCurrencySuffix(Symbol());
    
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
        
        string formSymName = SymbolManager::formatSymbolName(rawSymName, symSuffix);
        string bareSymName = SymbolManager::unformatSymbolName(rawSymName, symSuffix);
        
        if(!isSymbolExcluded(bareSymName, excludeSym, excludeCur)) { 
            addSymbol(formSymName, bareSymName);
            symbolCount++;
            
            if(DebugLevel >= 2) StringAdd(finalSymString, StringConcatenate(", ", formSymName));
        }
    }
    
    Error::PrintInfo(ErrorInfo, StringConcatenate("Active symbols: ", finalSymString), FunctionTrace);
}

void SymbolManager::SymbolManager(string includeSymbols, string excludeSymbols, string excludeCurrencies) {
    getActiveSymbols(includeSymbols, excludeSymbols, excludeCurrencies);
}

//+------------------------------------------------------------------+
// Runtime methods [RUNTIME]
//+------------------------------------------------------------------+

void SymbolManager::~SymbolManager() {
    removeAllSymbols();
}

//+------------------------------------------------------------------+
// Helpers [HELPERS]
//+------------------------------------------------------------------+

//
//string GetSymbolPrefix(string curName) {
//    string result;
//    
//    return result;
//}

string SymbolManager::getCurrencySuffix(string symName) {
    return StringSubstr(symName, 6);
}
//
//bool DoesSymbolHavePrefix(string curName, string curPrefix) {
//    bool result;
//    
//    return result;
//}

bool SymbolManager::doesSymbolHaveSuffix(string symName, string symSuffix) {
    return (StringLen(symName) > 6 && StringCompare(StringSubstr(symName, 6), symSuffix) == 0);
}

string SymbolManager::formatSymbolName(string symName, string symSuffix, /*string curPrefix*/) {
    if(StringLen(symName) < 6) { 
        Error::ThrowError(ErrorNormal, "symName is not >=6 chars, assuming invalid, passing as is.", FunctionTrace); 
        return symName;
    }
    
    if(StringLen(symSuffix) < 1) { return symName; }
    else if(SymbolManager::doesSymbolHaveSuffix(symName, symSuffix)) { return symName; }
    else if(StringAdd(symName, symSuffix)) { return symName; } 
    else {
        Error::ThrowError(ErrorNormal, "Could not figure out how to format symName, passing as is.", FunctionTrace);
        return symName;
    }
}

string SymbolManager::unformatSymbolName(string symName, string symSuffix) {
    if(StringLen(symName) < 6) { 
        Error::ThrowError(ErrorNormal, "symName is not >=6 chars, assuming invalid, passing as is.", FunctionTrace); 
        return symName;
    }
    
    if(StringLen(symSuffix) < 1) { return symName; }
    else if(!SymbolManager::doesSymbolHaveSuffix(symName, symSuffix)) { return symName; }
    else if(StringReplace(symName, symSuffix, "") > -1) { return symName; } 
    else {
        Error::ThrowError(ErrorNormal, "Could not figure out how to unformat symName, passing as is.", FunctionTrace);
        return symName;
    }
}

bool SymbolManager::isSymbolExcluded(string symName, string excludeSymIn, string &excludeCurIn[]) {
    if(StringFind(excludeSymIn, symName) > -1) { return true; }
    
    int excludeCurCount = ArraySize(excludeCurIn);
    for(int i = 0; i < excludeCurCount; i++) {
        if(StringFind(symName, excludeCurIn[i]) > -1) { return true; }
    }

    return false;
}

int SymbolManager::getAllSymbols(string &allSymBuffer[]) {
    return Symbols(allSymBuffer);
}