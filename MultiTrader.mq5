//+------------------------------------------------------------------+
//|                                                  MultiTrader.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
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

#ifdef __MQL5__
#include "MC_Common/Mql4Shim.mqh"
#define _X64 IsX64()
#else
#ifdef __MQL4__
#define _X64 false
#endif
#endif

#include "MMT_Settings.mqh"
#include "MMT_Main.mqh"

//+------------------------------------------------------------------+
// 1. Include filter and risk includes here [INCLUDES]
//    Include order affects settings order in config window
//+------------------------------------------------------------------+

#include "MMT_Filters/MMT_Filter_ATR.mqh"
#include "MMT_Filters/MMT_Filter_StdDev.mqh"
#include "MMT_Filters/MMT_Filter_Stoch.mqh"
#ifdef __MQL4__
#include "MMT_Filters/MMT_Filter_HGI.mqh"
#endif

//+------------------------------------------------------------------+
// 2. Add filters to OnInit below [HOOKS]
//    ORDER MATTERS BY DEPENDENCY! Any filter that depends on other filters' values
//    must be added after those other filters.
//    Add order also affects display order on dashboard.
//+------------------------------------------------------------------+

int OnInit() {
    Main = new MainMultiTrader();
    Main.addFilter(new FilterAtr());
    Main.addFilter(new FilterStdDev());
    Main.addFilter(new FilterStoch());
#ifdef __MQL4__
    Main.addFilter(new FilterHgi());
#endif

    SetTimer();

    return Main.onInit();
}

bool SetTimer() {
    bool result = false;
    
    //if(firstRun) {
    //    if(DelayedEntrySeconds > 0) { result = Common::EventSetTimerReliable(DelayedEntrySeconds); }
    //    else { result = Common::EventSetMillisecondTimerReliable(255); }
    //} else {
        result = Common::EventSetTimerReliable(1);
    //}
    
    if(!result) {
        Error::ThrowFatalError(ErrorFatal, "Could not set run timer; try to reload the EA.", FunctionTrace);
    }
    
    return result;
}

void OnTimer() {
    Main.onTimer();
}

void OnDeinit(const int reason) {
    Main.onDeinit(reason);
    delete(Main);
}
