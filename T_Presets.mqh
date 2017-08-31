//+------------------------------------------------------------------+
//|                                                T_LoadFilters.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Comments
//+------------------------------------------------------------------+
//
// How to Add Filters
// 1. Add include to include list - search [INCLUDES]
// 2. Add filter to OnInit() - search [HOOKS]

//+------------------------------------------------------------------+
// 1. Include filter includes here [INCLUDES]
//+------------------------------------------------------------------+

#include "F_Filter/F_ATR.mqh"
#include "F_Filter/F_StdDev.mqh"
#include "F_Filter/F_Spread.mqh"
#include "F_Filter/FG_Genotick/FG_Genotick.mqh"
  
//+------------------------------------------------------------------+

input string Lbl_IndisAndFilters="********** Indicators & Filters **********"; // Filter List
input string Lbl_FilterLegend="0 = Disabled; 1 = Normal; 2 = Opposite; 3 = Not Opposite"; // Legend
input string Lbl_Format="a:1|b:0|c:1"; // Format
input string Lbl_Format2="# of subfilters must be same across a filter's settings."; // Format
input string Lbl_Format3="Do not add a trailing |";

//+------------------------------------------------------------------+
//| ATR
//+------------------------------------------------------------------+

input string Lbl_ATR="________ ATR Settings [ATR] ________"; // :
input string ATR_Modes="a:0";
input string ATR_Types="*:3";
input string ATR_Names="a:H1";
input string ATR_Hidden="*:false";

input string Lbl_ATR_Indi=""; // :
input string ATR_TimeFrame="a:60";
input string ATR_Period="*:20";
input string ATR_Shift="*:0";

//+------------------------------------------------------------------+
//| StdDev
//+------------------------------------------------------------------+

input string Lbl_StdDev="________ StdDev Settings [StdDev] ________"; // :
input string StdDev_Modes="a:0";
input string StdDev_Types="*:3";
input string StdDev_Names="a:H1";
input string StdDev_Hidden="*:false";

input string Lbl_StdDev_Indi=""; // :
input string StdDev_TimeFrame="a:60";
input string StdDev_Period="*:20";
input string StdDev_Shift="*:0";
input string StdDev_Method="*:0";
input string StdDev_AppliedPrice="*:0";
input string StdDev_PeriodShift="*:0";

//+------------------------------------------------------------------+
//| StdDev
//+------------------------------------------------------------------+

input string Lbl_Spread="________ Spread Settings [Spread] ________"; // :
input string Spread_Modes="a:1";
input string Spread_Types="*:3";
input string Spread_Names="a:Cur";
input string Spread_Hidden="*:false";

//+------------------------------------------------------------------+
//| Stoch
//+------------------------------------------------------------------+

input string Lbl_Genotick_1="________ Genotick Settings [Geno] ________"; // :

input string Geno_Modes="a:2|b:2";
input string Geno_Types="a:1|b:2";
input string Geno_Names="a:Open|b:Close";
input string Geno_Hidden="*:false";

input string Geno_Params_Sep = ""; // : 
input string Geno_TimeFrame="*:H2";
input string Geno_LookbackCount="*:256";
input string Geno_IncludeCurrent="*:false";
input string Geno_DataSource="*:oanda";

input string Geno_Params_Sep2 = ""; // : 
input string Geno_UseGMT="*:true"; // UseGMT: Data is in GMT, otherwise use broker current time
input string Geno_ResetOnNewTimePoint="*:false"; // ResetOnNewTimePoint: True, reset trades every period if same signal; False, persist current trades
//string Geno_ResetOnNewTimePoint="*:false"; // todo: we can't support this until we track timeframes separately per api set
input string Geno_CloseOnMissingSignal="*:false"; // CloseOnMissingSignal: Close trades if there is no signal

//+------------------------------------------------------------------+
// 2. Add filters to LoadFilters() below and add settings [HOOKS]
//    ORDER MATTERS BY DEPENDENCY! Any filter that depends on other filters' values
//    must be added after those other filters.
//    Add order also affects display order on dashboard.
//+------------------------------------------------------------------+

void LoadFilters() {
    // Main = new MainManager();
    
    FilterAtr* atr = new FilterAtr();
    atr.addSubfilter(ATR_Modes, ATR_Names, ATR_Hidden, ATR_Types
        , ATR_TimeFrame, ATR_Period, ATR_Shift
        );
    Main.addFilter(atr);
        
    FilterStdDev* stdDev = new FilterStdDev();
    stdDev.addSubfilter(StdDev_Modes, StdDev_Names, StdDev_Hidden, StdDev_Types
        , StdDev_TimeFrame, StdDev_Period, StdDev_Shift
        , StdDev_Method, StdDev_AppliedPrice, StdDev_PeriodShift
        );
    Main.addFilter(stdDev);
        
    FilterSpread* spread = new FilterSpread();
    spread.addSubfilter(Spread_Modes, Spread_Names, Spread_Hidden, Spread_Types);
    Main.addFilter(spread);
        
    FilterGeno* geno = new FilterGeno();
    geno.addSubfilter(Geno_Modes, Geno_Names, Geno_Hidden, Geno_Types
        , Geno_TimeFrame, Geno_LookbackCount, Geno_IncludeCurrent, Geno_DataSource
        , Geno_UseGMT, Geno_ResetOnNewTimePoint, Geno_CloseOnMissingSignal
        );
    Main.addFilter(geno);
}

//+------------------------------------------------------------------+
//| Hardcoded settings here                                          |
//+------------------------------------------------------------------+

// Force retrace behavior: OpenAfterExit because that's the strategy

//input string Lbl_TradeSignal="---- Trade Signal Settings ----"; // :
bool CloseOrderOnOppositeSignal=true; // CloseOrderOnOppositeSignal: Close when entry signal is opposite
bool SignalRetraceOpenAfterExit=true; // SignalRetraceOpenAfterExit: Enter on retrace after exit or SL/TP
bool SignalRetraceOpenAfterDelay=false; // SignalRetraceOpenAfterDelay: Enter on retrace after delay
int SignalRetraceDelay=0; // SignalRetraceDelay: Open position, stated in TimeSettingUnits below
    // If SignalRetraceOpenAfterExit does not work, this should be set to genotick timeframe
    // OpenAfterExit appears to behave as expected, so we don't need this

//+------------------------------------------------------------------+

// Disable grid, since this doesn't apply
//input string LbL_Grid="---- Grid Settings ----";
string GridNote = "Set TradeModeType above to enable grids."; // :
bool GridSetStopOrders = false;
bool GridSetHedgeStopOrders = false;
bool GridSetLimitOrders = false;
bool GridSetHedgeLimitOrders = false;
bool GridOpenMarketInitial=false; // GridOpenMarketInitial: Place market order immediately on signal
int GridCount=0; // GridCount: # of pendings per direction
string GridDistanceCalc = "10.0";

string Lbl_GridReset="---- Grid Reset Settings ----";
bool GridClosePendingOnSignal = false; // GridClosePendingOnSignal: Close pending orders upon signal
bool GridCloseMarketOnSignal = false; // GridCloseMarketOnSignal: Close market orders upon signal
bool GridClosePendingByDistance = false;
string GridCloseDistanceCalc = "-40.0";
bool GridOpenIfPendingsOpen = false; // GridOpenIfPendingsOpen: Open new grids even if pendings exist
int GridStopThreshold = 2; // GridStopThreshold: # of stops to trigger reset per direction
bool GridOpenIfPositionsOpen = false; // GridOpenIfPositionsOpen: Open new grids even if market orders exist
int GridMarketThreshold = 0; // GridMarketThreshold: # of market pos to trigger reset per direction
bool GridResetHedgeOnOpenSignal = false; // GridResetHedgeOnOpenSignal: Force reset hedge if opening new direction

//+------------------------------------------------------------------+

// Disable SL/TP because they hamper the strategy
// Reconsider if an emergency SL is desired
// Basket management may be more appropriate

//string Lbl_Trade_StopLevels="********** Stop Level Settings **********"; // :

//bool MoveStopOnlyIfProgressed = true; // MoveStopOnlyIfProgressed: Moving stops only if they are higher than last stop
bool MoveStopOnlyIfProgressed = true;
double MoveStopThreshold = 0.1; // MoveStopThreshold: Move stops that differ more than this amount

string Lbl_StopLoss="---- Stop Loss Settings ----"; // :
bool StopLossInitialEnabled=false;
bool StopLossInternal=true; // StopLossInternal: Track and fire SL using EA
bool StopLossMinimumAdd=false; // StopLossMinimumAdd: Add broker's minimum to all SL
StopLevelMinAdjust StopLossBelowMinimumAction=MinAdjustDrop;
double StopLossBrokerOffset=0.0; // StopLossBrokerOffset: Offset broker SL if Internal enabled
string StopLossCalc = "-30.0";

string Lbl_TakeProfit="---- Take Profit Settings ----"; // :
bool TakeProfitInitialEnabled=false;
bool TakeProfitInternal=true; // TakeProfitInternal: Track and fire TP using EA
bool TakeProfitMinimumAdd=false; // TakeProfitMinimumAdd: Add broker's minimum to all TP
StopLevelMinAdjust TakeProfitBelowMinimumAction=MinAdjustDrop;
double TakeProfitBrokerOffset=0.0; // TakeProfitBrokerOffset: Offset broker TP if Internal enabled
string TakeProfitCalc = "30.0";

string Lbl_BreakEven="---- Break Even Settings ----"; // :
bool BreakEvenStopEnabled=false;
double BreakEvenProfit=1.5; // BreakEvenProfit: Offset from opening price
string BreakEvenJumpDistanceCalc = "10.0"; // BreakEvenJumpDistanceCalc: Pip distance from opening to trigger

string Lbl_ITSL="---- Trailing Stop Loss Settings ----"; // :
bool TrailingStopEnabled=false;
TrailStopMode TrailByBreakEven=TrailAlways;
string TrailingStopCalc = "10.0";

string Lbl_JSL="---- Jumping stop loss settings ----"; // :
bool JumpingStopEnabled=false;
string JumpingStopCalc = "10.0";
