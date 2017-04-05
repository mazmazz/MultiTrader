//+------------------------------------------------------------------+
//|                                    MultiTrader Main Settings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MC_Common/MC_Error.mqh"
#include "MC_Common/MC_MultiSettings.mqh"

enum TimeUnits {
    UnitSeconds // Seconds
    , UnitMilliseconds // Milliseconds
    //, UnitMicroseconds // Microseconds
    , UnitTicks // Ticks: Applies only in tick mode
};

enum CycleType {
    CycleTimerSeconds           // Seconds: Run on a second-based interval
    , CycleTimerMilliseconds    // Milliseconds: Run on a millisecond-based interval
    , CycleTimerTicks           // Average ticks: Run on an average tick interval
    , CycleRealTicks            // Real ticks: Run on every tick; applies only in Single Symbol Mode
};

enum TradeMode {
    TradeMarket           // Trade with normal market orders
    , TradeLimitOrders    // Trade with pending limit orders
    , TradeGrid           // Trade with grid orders
};

enum OrderProfitType {
    OrderBothProfitLoss    // All orders
    , OrderOnlyProfitable  // Profitable orders only
    , OrderOnlyLoss        // Losing orders only
};

enum OrderOpType {
    OrderBothLongShort     // All orders
    , OrderOnlyLong        // Long positions only
    , OrderOnlyShort       // Short positions only
};

extern string LblRuntime="********** Runtime Settings **********"; // :
extern int MagicNumber=5001;
extern string ConfigComment=""; // ConfigComment: Comment to display on dashboard

extern string Lbl_ErrorSettings="---- Error Settings ----"; // :
extern ErrorLevelConfig ErrorTerminalLevel=ErrorConfigFatalNormal; // ErrorTerminalLevel: Errors to show in terminal
extern ErrorLevelConfig ErrorFileLevel=ErrorConfigNone; // ErrorFileLevel: Errors to write to log file (Hide=Disable)
extern ErrorLevelConfig ErrorAlertLevel=ErrorConfigFatal; // ErrorAlertLevel: Errors to trigger an alert
extern string ErrorLogFileName=""; // ErrorLogFileName: Leave blank to generate a filename    
//extern int HistoryLevel=1; // HistoryLevel: Number of filter values to keep in memory
int DataHistoryLevel=1; // not convinced this should be a user setting
int SignalHistoryLevel=3;

//
//extern string Lbl_Notification="---- Notification Settings ----";
//extern bool PopupAlert=false;
//extern bool EmailAlert=false;
//extern bool PushAlert=false;

extern string LblDisplay="---- Display Settings ----"; // :
extern bool DisplayShow=true;
extern bool DisplayShowTable=true;
extern bool DisplayColor=true;
//extern bool DisplayShowOrders=true;
//extern string DisplayFont="Lucida Console";
string DisplayFont="Lucida Console"; // Integral font to monospace layout and scaling, should not be user setting
extern int DisplayScale=0; // DisplayScale: 0 = Normal, 1+ = Large
//extern int DisplayFontSize=11;
//extern int DisplaySpacing=13;
//extern DisplayStyleEnum DisplayStyle=ValueAndSignal;

extern string Lbl_CycleSettings="---- Cycle Settings ----"; // :
extern CycleType CycleMode=CycleTimerSeconds;
extern int CycleLength=1; // CycleLength: Length between cycles (seconds or milliseconds)

extern string Lbl_Symbols="********** Symbols & Currencies Settings **********"; // :
extern bool SingleSymbolMode=false; // SingleSymbolMode: Use only the current chart symbol
extern string IncludeSymbols="AUDCADi,AUDCHFi,AUDJPYi,AUDNZDi,AUDUSDi,CADCHFi,CADJPYi,CHFJPYi,EURAUDi,EURCADi,EURJPYi,EURNZDi,EURUSDi,EURGBPi,GBPAUDi,GBPCADi,GBPCHFi,GBPJPYi,GBPNZDi,GBPUSDi,NZDCADi,NZDCHFi,NZDJPYi,NZDUSDi,USDCADi,USDCHFi,USDJPYi";
extern string ExcludeSymbols="";
extern string ExcludeCurrencies="SEK,SGD,DKK,NOK,TRY,HKD,ZAR,MXN,XAG,XAU";

extern string Lbl_Trade="********** Trade Settings **********"; // :
extern bool TradeEntryEnabled=true;
extern bool TradeExitEnabled=true;
extern bool TradeValueEnabled=true;

extern string Lbl_TradeGeneral="---- General Trade Settings ----"; // :
extern TradeMode TradeModeType=TradeMarket; // TradeModeType: Type of trades to enter
extern bool SetStopsOnPendings=true; // SetStopsOnPendings: Set SLTP on pending orders
extern bool BrokerTwoStep=true; // IsTwoStep: Broker is ECN and needs two-step order sending for SL/TP
extern int BrokerPipDecimal = 1; // BrokerPoints: # of pip decimals, e.g. 0 if 4-point broker, 1 if 5-point.
extern string OrderComment_=""; // OrderComment: Comment to attach to orders
extern bool CloseOrderOnOppositeSignal=true; // CloseOrderOnOppositeSignal: Close when entry signal is opposite
extern bool SignalRetraceOpen=true; // SignalRetraceOpen: Enter additional positions on a retrace
extern int MaxTradesPerSymbol=0;
// extern int MaxTradesTimeframe=60;
extern double TradeMinMarginLevel=200; // MinTradeMarginLevel (percent)
extern string MaxSpreadCalc = "4.0";
extern string MaxSlippageCalc = "4.0";
extern string LotSizeCalc = "0.1";

extern string Lbl_TradeDelays="---- Trade Delay Settings ----"; // :
extern TimeUnits TimeSettingUnit=UnitSeconds; // TimeSettingUnit: Unit for values below
extern int EntryStableTime=5;
extern int ExitStableTime=5;
extern int SignalRetraceTime=3600; // SignalRetraceTime: Repeating signal change is seen as retrace
extern int TradeBetweenDelay=0; // TradeBetweenDelay: Wait between trades
extern int ValueBetweenDelay=0; // ValueBetweenDelay: Wait between value changes

//
//extern string LbL_Exit_ExpiryTrade="---- Expiry Trade Exit Settings ----"; // :
//extern bool ExpireTrades=false;
//extern int Exit_expirySeconds=900;
//

extern string LbL_Grid="---- Grid Settings ----"; // Grid settings: Set TradeModeType above to enable grids
extern bool GridHedging=false; // GridHedging: Set pendings in both directions 
extern bool GridOpenMarketInitial=false; // GridOpenMarketInitial: Place market order immediately on signal
extern bool GridSetDualPendings = false; // GridSetDualPendings: Set 1 buy and 1 sell pending on every level
extern bool GridClosePendingOnSignal = false; // GridClosePendingOnSignal: Close pending orders upon signal
extern bool GridCloseMarketOnSignal = true; // GridCloseMarketOnSignal: Close market orders upon signal
extern bool GridOpenIfMarketExists = false; // GridOpenIfMarketExists: Open if market order exists, no pendings
extern int GridCount=5; // GridCount: # of pendings per direction
extern string GridDistanceCalc = "10.0";

extern string LbL_Exit_Basket="---- Basket Exit Settings ----"; // :
extern bool BasketTotalPerDay = false; // BasketTotalPerDay: Add total of all profits during day, not just open orders
// extern int BasketPeriodLengthMinutes = 1440; // BasketPeriodLengthMinutes: Time to limit baskets
//extern bool BasketIncludeFees=false; // BasketIncludeFees: Deduct fees from profit calculation
extern bool BasketEnableStopLoss=false;
extern double BasketStopLossValue=-200.0;
extern int BasketMaxLosingPerDay=2;
// todo: basket filter values. Complicated because we may need to aggregate filters across symbols for a proper basket sltp
extern bool BasketEnableTakeProfit=false;
extern double BasketTakeProfitValue=400.0;
extern int BasketMaxWinningPerDay=1;
extern bool BasketClosePendings=true;

extern string Lbl_StopLoss="---- Stop Loss Settings ----"; // :
extern bool StopLossEnabled=false;
extern bool StopLossInternal=true; // StopLossInternal: Track and fire SL using EA
extern double StopLossBrokerOffset=0.0; // StopLossBrokerOffset: Offset broker SL if Internal enabled
extern string StopLossCalc = "-30.0";

extern string Lbl_TakeProfit="---- Take Profit Settings ----"; // :
extern bool TakeProfitEnabled=false;
extern bool TakeProfitInternal=true; // TakeProfitInternal: Track and fire TP using EA
extern double TakeProfitBrokerOffset=0.0; // TakeProfitBrokerOffset: Offset broker TP if Internal enabled
extern string TakeProfitCalc = "30.0";

extern string Lbl_BreakEven="---- Break Even Settings ----"; // :
extern bool BreakEvenEnabled=false;
extern double BreakEvenProfit=1.5; // BreakEvenProfit: Offset from breakeven to allow a certain profit.
extern string BreakEvenJumpDistanceCalc = "10.0";

extern string Lbl_ITSL="---- Trailing Stop Loss Settings ----"; // :
extern bool TrailingStopEnabled=false;
extern bool TrailAfterBreakEvenOnly=false;
extern string TrailingStopCalc = "10.0";

extern string Lbl_JSL="---- Jumping stop loss settings ----"; // :
extern bool JumpingStopEnabled=false;
extern bool JumpAfterBreakEvenOnly=true;
extern string JumpingStopCalc = "10.0";

extern string Lbl_TradeSched="---- Schedule Settings ----"; // :
extern bool SchedCloseDaily = false; // SchedCloseDaily: Exit trades before day close to prevent swap
extern bool SchedClose3DaySwap = true; // SchedClose3DaySwap: Exit trades before 3-day swap per symbol
extern bool SchedCloseWeekend = true; // SchedCloseWeekend: Exit trades before weekend
extern bool SchedCloseSession = false; // SchedCloseSession: Exit trades before current day session is closed
extern int SchedGapIgnoreMinutes = 15; // SchedGapIgnoreMinutes: Ignore session gaps of X mins
extern OrderProfitType SchedCloseOrderProfit = OrderBothProfitLoss; // SchedCloseOrderProfit: Close only profitable or losing trades
extern OrderOpType SchedCloseOrderOp = OrderBothLongShort; // SchedCloseOrderOp: Close only longs or shorts
extern bool SchedClosePendings = true;
extern int SchedCloseMinutes = 5; // SchedCloseMinutes: Exit X mins before session close
//extern int SchedOpenLastMinutes = 60; // SchedOpenLastMinutes: Open up to X mins before session close
extern int SchedOpenMinutesDaily = 0; 
extern int SchedOpenMinutesSession = 0; 
extern int SchedOpenMinutesWeekend = 180;

//extern string Lbl_TradeSchedSwap="-- Minimum Swap Closing Settings --"; // :
//extern CalcSource SchedMinSwapLongMethod=CalcValue; // SchedMinSwapLong: Minimum swap to close long
//extern double SchedMinSwapLongValue=-5.0; 
//extern string SchedMinSwapLongName="";
//extern double SchedMinSwapLongFactor=1.0;
//extern CalcSource SchedMinSwapShortMethod=CalcValue;  // SchedMinSwapShort: Minimum swap to close short
//extern double SchedMinSwapShortValue=-5.0; 
//extern string SchedMinSwapShortName="";
//extern double SchedMinSwapShortFactor=1.0;
// todo: can we convert points to swap currency?
// todo: close depending on swap value: does order profit exceed current swap value? compare to some filter value like ATR?
    // track separately for longs and shorts -- swap can vary widely