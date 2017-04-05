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
//#define _X64 IsX64()
#else
#ifdef __MQL4__
//#define _X64 false
#endif
#endif

#include "MMT_Settings.mqh"
#include "MMT_Main.mqh"
//#include "depends/OrderReliable.mqh"

TimePoint LastTickTime;

//+------------------------------------------------------------------+
// 1. Include filter includes here [INCLUDES]
//    Include order affects settings order in config window
//+------------------------------------------------------------------+

#include "MMT_Filter/MMT_Filter_ATR.mqh"
#include "MMT_Filter/MMT_Filter_StdDev.mqh"
#include "MMT_Filter/MMT_Filter_Stoch.mqh"
#ifdef __MQL4__
#include "MMT_Filter/MMT_Filter_HGI.mqh"
//#include "MMT_Filter/MMT_Filter_CSS.mqh"
#endif

//+------------------------------------------------------------------+
// 2. Add filters to OnInit below [HOOKS]
//    ORDER MATTERS BY DEPENDENCY! Any filter that depends on other filters' values
//    must be added after those other filters.
//    Add order also affects display order on dashboard.
//+------------------------------------------------------------------+

int OnInit() {
    Error::ProjectName = _ProjectShortName;
    Error::TerminalLevel = ::ErrorTerminalLevel;
    Error::FileLevel = ::ErrorFileLevel;
    Error::AlertLevel = ::ErrorAlertLevel;
    Error::FilePath = ::ErrorLogFileName;
    
    if(!ValidateSettings()) { return INIT_PARAMETERS_INCORRECT; }
    
#ifdef _OrderReliable
    O_R_Config_use2step(BrokerTwoStep);
    O_R_Config_UseInBacktest(true); // order closes fail without this
    O_R_SetVerbosity(1);
    O_R_Config_FinetuneEntries(true);
#endif

    Main = new MainMultiTrader();
    Main.addFilter(new FilterAtr());
    Main.addFilter(new FilterStdDev());
    Main.addFilter(new FilterStoch());
#ifdef __MQL4__
    Main.addFilter(new FilterHgi());
    //Main.addFilter(new FilterCss());
#endif

    int result = Main.onInit();
    
    Main.doFirstRun();

    if(!SetCycle()) { return INIT_FAILED; }
    else { return result; }
}

void OnDeinit(const int reason) {
    if(!Common::IsInvalidPointer(Main)) {
        Main.onDeinit(reason);
        Common::SafeDelete(Main);
    }
    
    Error::CloseErrorFile();
}

bool ValidateSettings() {
    bool finalResult = true;
    
#ifdef __MQL4__
    if(IsTesting() || IsOptimization()) {
        if(!SingleSymbolMode) {
            Error::ThrowFatalError(ErrorFatal, "Strategy tester requires Single Symbol Mode.");
            finalResult = false;
        }
    }
#endif
    
    if(!SingleSymbolMode && CycleMode == CycleRealTicks) {
        Error::ThrowFatalError(ErrorFatal, "Real tick cycle works only in Single Symbol Mode.");
        finalResult = false;
    }
    
    if(TimeSettingUnit == UnitTicks && CycleMode != CycleRealTicks) {
        Error::ThrowFatalError(ErrorFatal, "Trade delay time must be specified in seconds or milliseconds when not running in real tick cycles.");
        finalResult = false;
    }
    
    if(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) > TradeMinMarginLevel) {
        TradeMinMarginLevel = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
        Error::PrintInfo_v02(ErrorInfo, "Setting TradeMinMarginLevel to account margin call level: " + AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL));
    }
    
    return finalResult;
}

bool SetCycle() {
    bool result = false;
    
    switch(CycleMode) {
        case CycleRealTicks:
            result = true; // we don't set a timer for real ticks, just handle OnTick()
            break;
            
        case CycleTimerTicks: // emulated average ticks, still on timer interval
            result = Main.setAverageTickTimer((IsTesting() || IsOptimization()));
            if(IsTesting() || IsOptimization()) { LastTickTime.update(); }
            break;
            
        case CycleTimerMilliseconds:
            if(IsTesting() || IsOptimization()) { result = true; LastTickTime.update(); } // go by ticks
            else { result = Common::EventSetMillisecondTimerReliable(CycleLength); }
            break;
            
        case CycleTimerSeconds:
        default:
            if(IsTesting() || IsOptimization()) { result = true; LastTickTime.update(); } // go by ticks
            else { result = Common::EventSetTimerReliable(CycleLength); }
            break;
    }
    
    if(!result) {
        Error::ThrowFatalError(ErrorFatal, "Could not set cycle; try to reload the EA.", FunctionTrace);
    }
    
    return result;
}

void OnTimer() {
    Main.onTimer();
}

void OnTick() {
    if(CycleMode == CycleRealTicks) { 
        Main.onTick(); 
    } else if(IsTesting() || IsOptimization()) {
        bool proceed;
        switch(CycleMode) {
            case CycleTimerMilliseconds:
                proceed = (Common::GetTimeDuration(GetTickCount(), LastTickTime.milliseconds) >= CycleLength);
                break;
                
            case CycleTimerSeconds:
            default:
                proceed = (Common::GetTimeDuration(TimeCurrent(), LastTickTime.dateTime) >= CycleLength);
                break;
        }
        
        if(proceed) { 
            Main.onTick(); 
            LastTickTime.update();
        }
    }
}
