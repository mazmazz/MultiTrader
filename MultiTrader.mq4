//+------------------------------------------------------------------+
//|                                                  MultiTrader.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#define _ProjectName "MultiOp"
#define _ProjectShortName "MMO"
#define _ProjectVersion "v0.1 04/2017"

datetime ProjectExpiration = D'2017.06.04';

#define _NoExpiration
//#define _EmulatedTicks
//#define _Benchmark

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

#ifdef __MQL5__
#include "MC_Common/Mql4Shim.mqh"
//#define _X64 true
#else
#ifdef __MQL4__
//#define _X64 false
#endif
#endif

#include "T_Settings.mqh"
#include "T_Presets.mqh"
#include "T_Optimization.mqh"
#include "T_Validation.mqh"
#include "M_Main.mqh"

//#include "depends/OrderReliable.mqh"

TimePoint LastTickTime;

int OnInit() {
    Error::ProjectName = _ProjectShortName;
    Error::TerminalLevel = ::ErrorTerminalLevel;
    Error::FileLevel = ::ErrorFileLevel;
    Error::AlertLevel = ::ErrorAlertLevel;
    Error::FilePath = ::ErrorLogFileName;
    
    if(!ValidateSession(true)) { return INIT_FAILED; }
    
    if(!ValidateSettings()) { return INIT_PARAMETERS_INCORRECT; }
    
#ifdef _OrderReliable
    O_R_Config_use2step(BrokerTwoStep);
    O_R_Config_UseInBacktest(true); // order closes fail without this
    O_R_SetVerbosity(1);
    O_R_Config_FinetuneEntries(true);
#endif

#ifdef _Benchmark
    uint setupMilCounter = GetTickCount();
    Error::PrintMinor(TimeCurrent() + " | Setup started");
#endif

    Main = new MainMultiTrader();
    LoadFilters();

    int result = Main.onInit();
    
#ifdef _Benchmark
    Error::PrintMinor(TimeCurrent() + " | Setup finished: " + (GetTickCount() - setupMilCounter));
#endif
    
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
    
    if(AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL) > TradeMinMarginLevel) {
        //TradeMinMarginLevel = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
        //Error::PrintInfo_v02(ErrorInfo, "Setting TradeMinMarginLevel to account margin call level: " + AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL));
        Error::ThrowFatal("TradeMinMarginLevel must be set greater than broker's stopout level: " + AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL));
        finalResult = false;
    }
    
    return finalResult;
}

bool SetCycle() {
    bool result = false;
    
    switch(CycleMode) {
        case CycleRealTicks:
            result = true; // we don't set a timer for real ticks, just handle OnTick()
            break;

#ifdef __MQL4__
#ifdef _EmulatedTicks
        case CycleTimerTicks: // emulated average ticks, still on timer interval
            result = Main.setAverageTickTimer((IsTesting() || IsOptimization()));
            if(IsTesting() || IsOptimization()) { LastTickTime.update(); }
            break;
#endif
            
        case CycleTimerMilliseconds:
            if(IsTesting() || IsOptimization()) { result = true; LastTickTime.update(); } // go by ticks
            else { result = Common::EventSetMillisecondTimerReliable(CycleLength); }
            break;
            
        case CycleTimerSeconds:
        default:
            if(IsTesting() || IsOptimization()) { result = true; LastTickTime.update(); } // go by ticks
            else { result = Common::EventSetTimerReliable(CycleLength); }
            break;
#else
#ifdef __MQL5__
#ifdef _EmulatedTicks
        case CycleTimerTicks: // emulated average ticks, still on timer interval
            result = Main.setAverageTickTimer((IsTesting() || IsOptimization()));
            break;
#endif
            
        case CycleTimerMilliseconds:
            result = Common::EventSetMillisecondTimerReliable(CycleLength);
            break;
            
        case CycleTimerSeconds:
        default:
            result = Common::EventSetTimerReliable(CycleLength);
            break;
#endif
#endif
    }
    
    if(!result) {
        Error::ThrowFatalError(ErrorFatal, "Could not set cycle; try to reload the EA.", FunctionTrace);
    }
    
    return result;
}

void OnTimer() {
    if(!ValidateSession()) { return; }

    Main.onTimer();
}

void OnTick() {
    if(!ValidateSession()) { return; }

#ifdef __MQL4__
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
#else
#ifdef __MQL5__
    Main.onTick(); 
#endif
#endif
}
