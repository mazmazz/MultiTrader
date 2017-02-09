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

#include "MMT_Main_Settings.mqh"
#include "MMT_Filter.mqh"
#include "MMT_Helper_Error.mqh"
#include "MMT_Main_Symbols.mqh"

string ActiveSymbols[];

//+------------------------------------------------------------------+
// Runtime functions
//+------------------------------------------------------------------+

#include "MMT_Helper_OptionsParser.mqh"

int OnInit() {
    GetActiveSymbols(ActiveSymbols, IncludeSymbols, ExcludeSymbols, ExcludeCurrencies);
    FilterList_OnInit();

    // CalculateHandler();
    // Set timer here

    return INIT_SUCCEEDED;
}

void OnTimer() {

}

void OnDeinit(const int reason) {
    
}