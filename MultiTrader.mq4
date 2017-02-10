//+------------------------------------------------------------------+
//|                                                  MultiTrader.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      ""
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

#define ExtLib_Symbols

#ifdef ExtLib_Symbols
    #import "MMT_Library/Symbols.ex4"
    int Symbols(string& sSymbols[]);
    #import
#endif

#include "MMT_Settings.mqh"
#include "MMT_Helper_Error.mqh"

#include "MMT_Filter.mqh"
#include "MMT_Symbols.mqh"
#include "MMT_Data.mqh"

// These are defined in their respective source files
//SymbolManager *MainSymbolManager;
//FilterManager *MainFilterManager;
//DataManager *MainDataManager;

//+------------------------------------------------------------------+
// Runtime functions
//+------------------------------------------------------------------+

int OnInit() {
    MainFilterManager = new FilterManager();
    MainSymbolManager = new SymbolManager(IncludeSymbols, ExcludeSymbols, ExcludeCurrencies);
    MainDataManager = new DataManager(MainSymbolManager.symbolCount, MainFilterManager.filterCount);

    // CalculateHandler();
    // Set timer here

    return INIT_SUCCEEDED;
}

void OnTimer() {

}

void OnDeinit(const int reason) {
    MainDataManager.onDeinit();
    MainSymbolManager.onDeinit();
    MainFilterManager.onDeinit();
    
    delete(MainDataManager);
    delete(MainSymbolManager);
    delete(MainFilterManager);
}