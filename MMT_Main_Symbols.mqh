//+------------------------------------------------------------------+
//|                                              MMT_Helper_Main.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Helper_Error.mqh"
#include "MMT_Helper_Library.mqh"

//+------------------------------------------------------------------+
// Symbol names
//+------------------------------------------------------------------+

//
//string GetCurrencyPrefix(string curName) {
//    string result;
//    
//    return result;
//}

string GetCurrencySuffix(string symName) {
    return StringSubstr(symName, 6);
}
//
//bool DoesCurrencyHavePrefix(string curName, string curPrefix) {
//    bool result;
//    
//    return result;
//}

bool DoesSymbolHaveSuffix(string symName, string symSuffix) {
    return (StringLen(symName) > 6 && StringCompare(StringSubstr(symName, 6), symSuffix) == 0);
}

string FormatSymbolName(string symName, string symSuffix, /*string curPrefix*/) {
    if(StringLen(symName) < 6) { 
        ThrowError(1, "Helper_Main FormatSymbolName", "symName is not >=6 chars, assuming invalid, passing as is."); 
        return symName;
    }
    
    if(StringLen(symSuffix) < 1) { return symName; }
    else if(DoesSymbolHaveSuffix(symName, symSuffix)) { return symName; }
    else if(StringAdd(symName, symSuffix)) { return symName; } 
    else {
        ThrowError(1, "Helper_Main FormatSymbolName", "Could not figure out how to format symName, passing as is.");
        return symName;
    }
}

string UnformatSymbolName(string symName, string symSuffix) {
    if(StringLen(symName) < 6) { 
        ThrowError(1, "Helper_Main FormatSymbolName", "symName is not >=6 chars, assuming invalid, passing as is."); 
        return symName;
    }
    
    if(StringLen(symSuffix) < 1) { return symName; }
    else if(!DoesSymbolHaveSuffix(symName, symSuffix)) { return symName; }
    else if(StringReplace(symName, symSuffix, "") > -1) { return symName; } 
    else {
        ThrowError(1, "Helper_Main UnformatSymbolName", "Could not figure out how to unformat symName, passing as is.");
        return symName;
    }
}

bool IsSymbolExcluded(string symName, string excludeSym, string &excludeCur[]) {
    if(StringFind(excludeSym, symName) > -1) { return true; }
    
    int excludeCurCount = ArraySize(excludeCur);
    for(int i = 0; i < excludeCurCount; i++) {
        if(StringFind(symName, excludeCur[i]) > -1) { return true; }
    }

    return false;
}

int GetAllSymbols(string &allSymBuffer[]) {
    int count;
    
    // https://www.mql5.com/en/forum/146736
    ThrowError(1, "Helper_Main GetAllSymbols", "Get all symbols not implemented");
    
    return count;
}

void GetActiveSymbols(string &curBuffer[], string includeSym, string excludeSym, string excludeCur) {
    string symSuffix = GetCurrencySuffix(Symbol());
    
    string finalSym[];
    string finalSymString;
    
    char delimiter = StringGetCharacter(",", 0);
    string includeSymSplit[];
    string excludeCurSplit[];
    int includeSymCount = StringSplit(includeSym, delimiter, includeSymSplit);
    int excludeCurCount = StringSplit(excludeCur, delimiter, excludeCurSplit);
    //string excludeSymSplit[]; // we can just do a StringFind on this
    
    if(includeSymCount < 1) {
        ArrayFree(includeSymSplit);
        includeSymCount = GetAllSymbols(includeSymSplit);
    }
    
    for(int i = 0; i < includeSymCount; i++) {
        string rawSymName = StringTrim(includeSymSplit[i]);
        int symLength = StringLen(rawSymName);
        if(symLength < 6) {
            if(symLength > 0) { ThrowError(1, "Helper_Main GetActiveSymbols", "rawSymName length is not >= 6, assuming invalid and skipping"); }
            continue; 
        }
        
        string formattedSymName = FormatSymbolName(rawSymName, symSuffix);
        string bareSymName = UnformatSymbolName(rawSymName, symSuffix);
        
        if(!IsSymbolExcluded(bareSymName, excludeSym, excludeCurSplit)) { 
            ArrayPushString(finalSym, formattedSymName); 
            if(DebugLevel >= 2) StringAdd(finalSymString, StringConcatenate(", ", formattedSymName));
        }
    }
    
    ArrayFree(curBuffer);
    ArrayCopy(curBuffer, finalSym);
    
    PrintInfo(2, "Helper_Main GetActiveCurrencies", StringConcatenate("Active symbols: ", finalSymString));
}