//+------------------------------------------------------------------+
//|                                                  MultiTrader.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#define _ProjectName "MultiTrader"
#define _ProjectShortName "MMT"
#define _ProjectVersion "v0.1 04/2017"

//+------------------------------------------------------------------+
//| Comments
//+------------------------------------------------------------------+
//
// How to Add Filters
// 1. Add include to include list - search [INCLUDES]
// 2. Add filter to OnInit() - search [HOOKS]
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
// 1. Include filter includes here [INCLUDES]
//    Include order affects settings order in config window
//+------------------------------------------------------------------+

#include "MMT_Filters/MMT_Filter_ATR.mqh"
#include "MMT_Filters/MMT_Filter_StdDev.mqh"
#include "MMT_Filters/MMT_Filter_Stoch.mqh"
#ifdef __MQL4__
#include "MMT_Filters/MMT_Filter_HGI.mqh"
#include "MMT_Filters/MMT_Filter_CSS.mqh"
#endif

//+------------------------------------------------------------------+
// 2. Add filters to OnInit below [HOOKS]
//    ORDER MATTERS BY DEPENDENCY! Any filter that depends on other filters' values
//    must be added after those other filters.
//    Add order also affects display order on dashboard.
//+------------------------------------------------------------------+

int OnInit() {
    Error::TerminalLevel = ::ErrorTerminalLevel;
    Error::FileLevel = ::ErrorFileLevel;
    Error::AlertLevel = ::ErrorAlertLevel;
    Error::FilePath = ::ErrorLogFileName;
    
    if(!ValidateSettings()) { return INIT_PARAMETERS_INCORRECT; }

    Main = new MainMultiTrader();
    Main.addFilter(new FilterAtr());
    Main.addFilter(new FilterStdDev());
    Main.addFilter(new FilterStoch());
#ifdef __MQL4__
    Main.addFilter(new FilterHgi());
    Main.addFilter(new FilterCss());
#endif

    if(!SetCycle()) { return INIT_FAILED; }

    return Main.onInit();
}

bool SetCycle() {
    bool result = false;
    
    switch(CycleMode) {
        case CycleRealTicks:
            result = true; // we don't set a timer for real ticks, just handle OnTick()
            break;
            
        case CycleTimerTicks: // emulated average ticks, still on timer interval
            result = Main.setAverageTickTimer();
            break;
            
        case CycleTimerMilliseconds:
            result = Common::EventSetMillisecondTimerReliable(CycleLength);
            break;
            
        case CycleTimerSeconds:
        default:
            result = Common::EventSetTimerReliable(CycleLength);
            break;
    }
    
    if(!result) {
        Error::ThrowFatalError(ErrorFatal, "Could not set cycle; try to reload the EA.", FunctionTrace);
    }
    
    return result;
}

void OnTimer() {
    //EventKillTimer(); 
        // undecided on this: timer events don't wait until the previous OnTimer call finishes. 
        // Are there issues to simultaneous OnTimer calls?
    Main.onTimer();
    //SetCycle();
}

void OnTick() {
    if(CycleMode == CycleRealTicks) { Main.onTick(); }
}

void OnDeinit(const int reason) {
    if(!Common::IsInvalidPointer(Main)) {
        Main.onDeinit(reason);
        Common::SafeDelete(Main);
    }
}
