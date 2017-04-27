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

enum StopLevelMinAdjust {
    MinAdjustDrop          // Drop new order / Do not modify existing order
    , MinAdjustDoNotSet    // Do not set stop level for new order
    , MinAdjustSetEqual    // Set stop level equal to minimum
};

enum TrailStopMode {
    TrailAlways            // Always trail
    , TrailBeforeBreakEven // Trail only before break even
    , TrailAfterBreakEven  // Trail only after break even
};

enum BasketStopMode {
    BasketStopDisable      // Disabled
    , BasketStopExactValue // Use exact value below
    //, BasketStopSumActiveSymbols // Sum stop levels from open symbols
    //, BasketStopSumAllSymbols // Sum stop levels from all symbols
};

input int MagicNumber=5001;
input string ConfigComment=""; // ConfigComment: Comment to display on dashboard

input string Lbl_Symbols="********** Instrument Settings **********"; // :
input bool SingleSymbolMode=false; // SingleSymbolMode: Use only the current chart symbol
input string IncludeSymbols="AUDCAD,AUDJPY,AUDNZD,AUDUSD,CADJPY,EURAUD,EURCAD,EURJPY,EURNZD,EURUSD,EURGBP,GBPAUD,GBPCAD,GBPJPY,GBPNZD,GBPUSD,NZDCAD,NZDJPY,NZDUSD,USDCAD,USDJPY";
input string ExcludeSymbols="";
input string ExcludeCurrencies="SEK,CHF,DKK,NOK,TRY,HKD,ZAR,MXN,XAG,XAU";

input string Lbl_Trade="********** Trade Settings **********"; // :
input bool TradeEntryEnabled=true;
input bool TradeExitEnabled=true; // TradeExitEnabled: Follow signals; does not affect basket and SLTP
input bool TradeValueEnabled=true;

input string Lbl_TradeGeneral="---- General Trade Settings ----"; // :
input TradeMode TradeModeType=TradeMarket; // TradeModeType: Type of trades to enter
input bool SetStopsOnPendings=true; // SetStopsOnPendings: Set SLTP on pending orders
input bool BrokerTwoStep=true; // IsTwoStep: Broker is ECN and needs two-step order sending for SL/TP
input int BrokerPipDecimal = 1; // BrokerPoints: # of pip decimals, e.g. 0 if 4-point broker, 1 if 5-point.
input string OrderComment_=""; // OrderComment: Comment to attach to orders

input string Lbl_TradeParams="---- Trade Parameters ----"; // :
input int MaxTradesPerSymbol=0;
// input int MaxTradesTimeframe=60;
input double TradeMinMarginLevel=200; // MinTradeMarginLevel (percent)
input string MaxSpreadCalc = "4.0";
input string MaxSlippageCalc = "4.0";
input string LotSizeCalc = "0.01";

input string Lbl_TradeSignal="---- Trade Signal Settings ----"; // :
input bool CloseOrderOnOppositeSignal=true; // CloseOrderOnOppositeSignal: Close when entry signal is opposite
input bool SignalRetraceOpenAfterExit=true; // SignalRetraceOpenAfterExit: Enter on retrace after exit or SL/TP
input bool SignalRetraceOpenAfterDelay=false; // SignalRetraceOpenAfterDelay: Enter on retrace after delay
input int SignalRetraceDelay=1800; // SignalRetraceDelay: Open position, stated in TimeSettingUnits below

input string Lbl_TradeDelays="---- Trade Delay Settings ----"; // :
input TimeUnits TimeSettingUnit=UnitSeconds; // TimeSettingUnit: Unit for values below
input int EntryStableTime=5;
input int ExitStableTime=5;
input int TradeBetweenDelay=0; // TradeBetweenDelay: Wait between trades
input int ValueBetweenDelay=0; // ValueBetweenDelay: Wait between value changes

//
//input string LbL_Exit_ExpiryTrade="---- Expiry Trade Exit Settings ----"; // :
//input bool ExpireTrades=false;
//input int Exit_expirySeconds=900;
//
input string Lbl_Trade_Grid="********** Grid Settings **********"; // :

//input string LbL_Grid="---- Grid Settings ----";
input string GridNote = "Set TradeModeType above to enable grids."; // :
input bool GridSetStopOrders = true;
input bool GridSetHedgeStopOrders = false;
input bool GridSetLimitOrders = false;
input bool GridSetHedgeLimitOrders = true;
input bool GridOpenMarketInitial=false; // GridOpenMarketInitial: Place market order immediately on signal
input int GridCount=5; // GridCount: # of pendings per direction
input string GridDistanceCalc = "10.0";

input string Lbl_GridReset="---- Grid Reset Settings ----";
input bool GridClosePendingOnSignal = false; // GridClosePendingOnSignal: Close pending orders upon signal
input bool GridCloseMarketOnSignal = false; // GridCloseMarketOnSignal: Close market orders upon signal
input bool GridClosePendingByDistance = false;
input string GridCloseDistanceCalc = "-40.0";
input bool GridOpenIfPendingsOpen = false; // GridOpenIfPendingsOpen: Open new grids even if pendings exist
input int GridStopThreshold = 2; // GridStopThreshold: # of stops to trigger reset per direction
input bool GridOpenIfPositionsOpen = false; // GridOpenIfPositionsOpen: Open new grids even if market orders exist
input int GridMarketThreshold = 0; // GridMarketThreshold: # of market pos to trigger reset per direction
input bool GridResetHedgeOnOpenSignal = false; // GridResetHedgeOnOpenSignal: Force reset hedge if opening new direction

input string Lbl_Trade_StopLevels="********** Stop Level Settings **********"; // :

input string Lbl_StopLoss="---- Stop Loss Settings ----"; // :
input bool StopLossInitialEnabled=false;
input bool StopLossInternal=true; // StopLossInternal: Track and fire SL using EA
input bool StopLossMinimumAdd=false; // StopLossMinimumAdd: Add broker's minimum to all SL
input StopLevelMinAdjust StopLossBelowMinimumAction=MinAdjustDrop;
input double StopLossBrokerOffset=0.0; // StopLossBrokerOffset: Offset broker SL if Internal enabled
input string StopLossCalc = "-30.0";

input string Lbl_TakeProfit="---- Take Profit Settings ----"; // :
input bool TakeProfitInitialEnabled=false;
input bool TakeProfitInternal=true; // TakeProfitInternal: Track and fire TP using EA
input bool TakeProfitMinimumAdd=false; // TakeProfitMinimumAdd: Add broker's minimum to all TP
input StopLevelMinAdjust TakeProfitBelowMinimumAction=MinAdjustDrop;
input double TakeProfitBrokerOffset=0.0; // TakeProfitBrokerOffset: Offset broker TP if Internal enabled
input string TakeProfitCalc = "30.0";

input string Lbl_BreakEven="---- Break Even Settings ----"; // :
input bool BreakEvenStopEnabled=false;
input double BreakEvenProfit=1.5; // BreakEvenProfit: Offset from opening price
input string BreakEvenJumpDistanceCalc = "10.0"; // BreakEvenJumpDistanceCalc: Pip distance from opening to trigger

input string Lbl_ITSL="---- Trailing Stop Loss Settings ----"; // :
input bool TrailingStopEnabled=false;
input TrailStopMode TrailByBreakEven=TrailAlways;
input string TrailingStopCalc = "10.0";

input string Lbl_JSL="---- Jumping stop loss settings ----"; // :
input bool JumpingStopEnabled=false;
input string JumpingStopCalc = "10.0";

input string Lbl_Trade_Basket="********** Basket Settings **********"; // :

//input bool BasketTotalPerDay = false; // BasketTotalPerDay: Add total of all profits during day, not just open orders
bool BasketTotalPerDay = false; // dummied out for now
// input int BasketPeriodLengthMinutes = 1440; // BasketPeriodLengthMinutes: Time to limit baskets
// input bool BasketPeriodStartType = From execution, From start time; // ???
// input datetime BasketPeriodStartTime = Monday 12:00am; // ???

input bool BasketClosePendings=true;

input string Lbl_Basket_Master_Stop="________ Master Basket Stop Levels ________"; // :

input BasketStopMode BasketMasterInitialStopLossMode=BasketStopDisable;
input double BasketStopLossValue=-200.0;
input double BasketStopLossFactor=1;
input int BasketMaxLosingPerDay=2;

input string Lbl_Basket_Master_Stop_Gap=""; // :

input BasketStopMode BasketMasterInitialTakeProfitMode=BasketStopDisable;
input double BasketTakeProfitValue=400.0;
input double BasketTakeProfitFactor=1;
input int BasketMaxWinningPerDay=1;

input string Lbl_Basket_Master_Stop_Breakeven="---- Master Break Even Stop ----"; // :
input bool BasketMasterBreakEvenStopEnabled=false;
input double BasketMasterBreakEvenProfit=1.5;
input double BasketMasterBreakEvenJumpDistance = 10;

input string Lbl_Basket_Master_Stop_Trailing="---- Master Trailing Stop ----"; // :
input bool BasketMasterTrailingStopEnabled=false;
input TrailStopMode BasketMasterTrailByBreakEven=TrailAlways;
input double BasketMasterTrailingStop = 10.0;

input string Lbl_Basket_Master_Stop_Jumping="---- Master Jumping Stop ----"; // :
input bool BasketMasterJumpingStopEnabled=false;
input double BasketMasterJumpingStop = 10.0;

input string Lbl_Basket_Symbol_Stop="________ Symbol Basket Stop Levels ________"; // :
input bool BasketSymbolInitialStopLossEnabled = false;
input string BasketSymbolStopLossCalc="-50.0";
//input bool BasketSymbolStopLossReUpdate = false;
input int BasketSymbolMaxLosingPerDay=2;

input string Lbl_Basket_Symbol_Stop_Gap=""; // :

input bool BasketSymbolInitialTakeProfitEnabled = false;
input string BasketSymbolTakeProfitCalc="75.0";
//input bool BasketSymbolTakeProfitReUpdate = false;
input int BasketSymbolMaxWinningPerDay=2;

input string Lbl_Basket_Symbol_Stop_Breakeven="---- Symbol Break Even Stop ----"; // :
input bool BasketSymbolBreakEvenStopEnabled=false;
input double BasketSymbolBreakEvenProfit=1.5;
input string BasketSymbolBreakEvenJumpDistanceCalc = "10.0";

input string Lbl_Basket_Symbol_Stop_Trailing="---- Symbol Trailing Stop ----"; // :
input bool BasketSymbolTrailingStopEnabled=false;
input TrailStopMode BasketSymbolTrailByBreakEven=TrailAlways;
input string BasketSymbolTrailingStopCalc = "10.0";

input string Lbl_Basket_Symbol_Stop_Jumping="---- Symbol Jumping Stop ----"; // :
input bool BasketSymbolJumpingStopEnabled=false;
input string BasketSymbolJumpingStopCalc = "10.0";

input string Lbl_Schedule="********** Schedule Settings **********"; // :
input string SchedCustom = "-23:00|-00:00|+01:00"; // SchedCustom: Specify times daily, weekday, or exact date
input ScheduleTimeType SchedCustomType = TimeTypeGmt; // SchedCustomType: Is SchedCustom in GMT, broker, or local time?
input bool SchedCloseCustom = false; // SchedCloseCustom: Exit trades following custom schedule
input bool SchedCloseDaily = false; // SchedCloseDaily: Exit trades before day close to prevent swap
input bool SchedClose3DaySwap = true; // SchedClose3DaySwap: Exit trades before 3-day swap per symbol
input bool SchedCloseWeekend = true; // SchedCloseWeekend: Exit trades before weekend
input bool SchedCloseSession = false; // SchedCloseSession: Exit trades before current day session is closed
input int SchedGapIgnoreMinutes = 15; // SchedGapIgnoreMinutes: Ignore session gaps of X mins

input string Lbl_Schedule_Closing="---- Schedule order closing settings ----"; // :
input OrderProfitType SchedCloseOrderProfit = OrderBothProfitLoss; // SchedCloseOrderProfit: Close only profitable or losing trades
input OrderOpType SchedCloseOrderOp = OrderBothLongShort; // SchedCloseOrderOp: Close only longs or shorts
input bool SchedClosePendings = true;
input bool SchedCloseBySwapDaily = false; // SchedCloseBySwapDaily: Only close if swap exceeds threshold
input bool SchedCloseBySwap3DaySwap = false; // SchedCloseBySwap3DaySwap: Only close if swap exceeds threshold
input string SchedSwapThresholdCalc = "-0.5"; // SchedSwapThresholdCalc: Swap threshold to close trades

input string Lbl_Schedule_Delay="---- Schedule delay settings ----"; // :
input int SchedCloseMinutes = 5; // SchedCloseMinutes: Exit X mins before session close
//input int SchedOpenLastMinutes = 60; // SchedOpenLastMinutes: Open up to X mins before session close
input int SchedOpenMinutesDaily = 0; 
input int SchedOpenMinutesSession = 0; 
input int SchedOpenMinutesWeekend = 180;

//input string Lbl_TradeSchedSwap="-- Minimum Swap Closing Settings --"; // :
//input CalcSource SchedMinSwapLongMethod=CalcValue; // SchedMinSwapLong: Minimum swap to close long
//input double SchedMinSwapLongValue=-5.0; 
//input string SchedMinSwapLongName="";
//input double SchedMinSwapLongFactor=1.0;
//input CalcSource SchedMinSwapShortMethod=CalcValue;  // SchedMinSwapShort: Minimum swap to close short
//input double SchedMinSwapShortValue=-5.0; 
//input string SchedMinSwapShortName="";
//input double SchedMinSwapShortFactor=1.0;
// todo: can we convert points to swap currency?
// todo: close depending on swap value: does order profit exceed current swap value? compare to some filter value like ATR?
    // track separately for longs and shorts -- swap can vary widely
