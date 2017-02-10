//+------------------------------------------------------------------+
//|                                                  MultiTrader.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      ""
#property strict
//+------------------------------------------------------------------+
//| Comments
//+------------------------------------------------------------------+
//
// How to Add Filters and Risks
// 1. Add include to include list - search [INCLUDES]
// 2. Add filter or risk to OnInit() - search [HOOKS]
//
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
const string MMT_EaName = "MultiTrader";
const string MMT_EaShortName = "MMT";
const string MMT_Version = "v0.1 02/2017";

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
#include "MMT_Dashboard.mqh"

// These are defined in their respective source files
//FilterManager *MainFilterManager;
//RiskManager *MainRiskManager;
//SymbolManager *MainSymbolManager;
//DataManager *MainDataManager;
//OrderManager *MainOrderManager;
//DashboardManager *MainDashboardManager;

//+------------------------------------------------------------------+
// 1. Include filter and risk includes here [INCLUDES]
//    Include order affects settings order in config window
//+------------------------------------------------------------------+

#include "MMT_Filter_Stoch.mqh"

//+------------------------------------------------------------------+
// 2. Add filters and risks to OnInit below [HOOKS]
//+------------------------------------------------------------------+

int OnInit() {
    MainFilterManager = new FilterManager();
    MainFilterManager.addFilter(new FilterStoch());
    
    // MainRiskManager = new RiskManager();
    // MainRiskManager.addRisk(new RiskAtr());
    
    MainSymbolManager = new SymbolManager(IncludeSymbols, ExcludeSymbols, ExcludeCurrencies);
    MainDataManager = new DataManager(MainSymbolManager.symbolCount, MainFilterManager.filterCount);
    // MainOrderManager = new OrderManager();

    // MainRiskManager.calculateAll();
    // MainFilterManager.calculateAll();
    // MainOrderManager.doAllTrades();
    
    MainDashboardManager = new DashboardManager();

    return INIT_SUCCEEDED;
}

//void OnTick() {
    // Toggle to do OnTimer or OnTick
    // Per order update, risk calc, or filter calc
    // Per tick or per cycle time (whichever method is picked)
    
    // Procedure to calculate risk goes here
    // Procedure to update existing trades goes here
    
    // Procedure to check cycle time goes here
    // If cycle time, then calculate filters
    
    // Dashboard is updated within MainOrderManager, MainRiskManager, and MainFilterManager
    // No need to update here.
//}

void OnDeinit(const int reason) {
    delete(MainDashboardManager);
    // delete(MainOrderManager);
    delete(MainDataManager);
    delete(MainSymbolManager);
    // delete(MainRiskManager);
    delete(MainFilterManager);
}