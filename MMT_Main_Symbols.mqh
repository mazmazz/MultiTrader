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
//string GetSymbolPrefix(string curName) {
//    string result;
//    
//    return result;
//}

string GetCurrencySuffix(string symName) {
    return StringSubstr(symName, 6);
}
//
//bool DoesSymbolHavePrefix(string curName, string curPrefix) {
//    bool result;
//    
//    return result;
//}

bool DoesSymbolHaveSuffix(string symName, string symSuffix) {
    return (StringLen(symName) > 6 && StringCompare(StringSubstr(symName, 6), symSuffix) == 0);
}

string FormatSymbolName(string symName, string symSuffix, /*string curPrefix*/) {
    if(StringLen(symName) < 6) { 
        ThrowError(1, ErrorFunctionTrace, "symName is not >=6 chars, assuming invalid, passing as is."); 
        return symName;
    }
    
    if(StringLen(symSuffix) < 1) { return symName; }
    else if(DoesSymbolHaveSuffix(symName, symSuffix)) { return symName; }
    else if(StringAdd(symName, symSuffix)) { return symName; } 
    else {
        ThrowError(1, ErrorFunctionTrace, "Could not figure out how to format symName, passing as is.");
        return symName;
    }
}

string UnformatSymbolName(string symName, string symSuffix) {
    if(StringLen(symName) < 6) { 
        ThrowError(1, ErrorFunctionTrace, "symName is not >=6 chars, assuming invalid, passing as is."); 
        return symName;
    }
    
    if(StringLen(symSuffix) < 1) { return symName; }
    else if(!DoesSymbolHaveSuffix(symName, symSuffix)) { return symName; }
    else if(StringReplace(symName, symSuffix, "") > -1) { return symName; } 
    else {
        ThrowError(1, ErrorFunctionTrace, "Could not figure out how to unformat symName, passing as is.");
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

#ifdef ExtLib_Symbols
int GetAllSymbols(string &allSymBuffer[]) {
    return Symbols(allSymBuffer);
}
#else
int GetAllSymbols(string &allSymBuffer[]) {
    int count;
    
    // https://www.mql5.com/en/forum/146736
    ThrowError(1, ErrorFunctionTrace, "Get all symbols not implemented");
    
    return count;
}
#endif

void GetActiveSymbols(string &curBuffer[], string includeSym, string excludeSym, string excludeCur) {
    string symSuffix = GetCurrencySuffix(Symbol());
    
    string finalSym[];
    string finalSymString;
    
    string includeSymSplit[];
    string excludeCurSplit[];
    int includeSymCount; int excludeCurCount;
    if(SingleSymbolMode) {
        includeSymCount = ArrayPushString(includeSymSplit, Symbol());
    } else {
        char delimiter = StringGetCharacter(",", 0);
        includeSymCount = StringSplit(includeSym, delimiter, includeSymSplit);
        excludeCurCount = StringSplit(excludeCur, delimiter, excludeCurSplit);
        //string excludeSymSplit[]; // we can just do a StringFind on this
    }
    
    if(includeSymCount < 1) {
        ArrayFree(includeSymSplit);
        includeSymCount = GetAllSymbols(includeSymSplit);
    }
    
    for(int i = 0; i < includeSymCount; i++) {
        string rawSymName = StringTrim(includeSymSplit[i]);
        int symLength = StringLen(rawSymName);
        if(symLength < 6 || GetStringType(StringSubstr(rawSymName, 0, 1)) == Type_Symbol) {
            if(symLength > 0) { PrintInfo(0, ErrorFunctionTrace, "rawSymName invalid, skipping", rawSymName); }
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