//+------------------------------------------------------------------+
//|                                    MultiTrader Main Settings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

enum DisplayStyleEnum {
    ValueAndMode,
    ValueOnly,
    ModeOnly
};

extern string MADDY_CSS_HGI_Trader_5="///// MultiTrader v1 /////"; // MultiTrader v1
extern string Lbl_SymbolsSettings="***** Symbols & Currencies Settings *****";
extern bool SingleSymbolMode=false; // Current symbol only
extern string IncludeSymbols="AUDCADi,AUDCHFi,AUDJPYi,AUDNZDi,AUDUSDi,CADCHFi,CADJPYi,CHFJPYi,EURAUDi,EURCADi,EURJPYi,EURNZDi,EURUSDi,EURGBPi,GBPAUDi,GBPCADi,GBPCHFi,GBPJPYi,GBPNZDi,GBPUSDi,NZDCADi,NZDCHFi,NZDJPYi,NZDUSDi,USDCADi,USDCHFi,USDJPYi";
extern string ExcludeSymbols="";
extern string ExcludeCurrencies="SEK,SGD,DKK,NOK,TRY,HKD,ZAR,MXN,XAG,XAU";

extern string Lbl_TradeSettings="***** Trade Settings *****";
extern bool DoTrade=true;
extern bool DoExit=true;
extern string ConfigComment="StochDTestFDJ";
extern int MagicNumber=1245;
extern string MyOrderComment="MCH Stochs 15 30 60";
extern double MaxSpread=4.0;
extern double MinTradeMarginLevel=100;

extern string Lbl_MultipleTradesSettings="-- Multiple Trades Settings --";
extern int MaxSymbolTrades=3;
extern int MultiTrades_TimeFrame=60;
//
//extern string LbL_Exit_Basket="--- Basket Exit Settings ---";
//extern bool UseBaskets=false;
//extern int ProfitCalcMethod=3; //ProfitCalcMethod //enum
//extern double BasketTP=1.0;
//extern double BasketSL=-100.0;
//extern int MaxBasketsPerDay=10;
//extern int MaxLossBasketsPerDay=0;

extern string Lbl_TradeDelaysSettings="-- Trade Delay Settings --";
extern int CycleTimeSeconds=5;
extern int Entry_StableSeconds=2;
extern int Exit_StableSeconds=10;
extern int ExitCheckDelay=10;
extern int TimeBetweenTrades=2;
//
//extern string LbL_Exit_ExpiryTrade="--- Expiry Trade Exit Settings ---";
//extern bool ExpireTrades=false;
//extern int Exit_expirySeconds=900;

extern string Lbl_ATR_Settings="--- ATR (AverageTrueRange) Settings ---";
extern int ATR_TimeFrame=60;
extern int ATR_Period=20;

extern string Lbl_Lotsize_Settings="-- LotSize Settings --";
extern int LotCalcMethod=0; //LotCalcMethod //enum
extern double LotSize=0.1;
extern double LotFactor=0.5;

extern string Lbl_TPSL_Settings="-- TP/SL Settings --";
extern bool UseTPSL=true;
extern int SLTPCalcMethod=1; //SLTPCalcMethod //enum
extern double SL=-175.0;
extern double TP=150.0;

extern string Lbl_BESettings="-- Break Even Settings --";
extern bool UseBreakEven=false;
extern int BreakEvenCalcMethod=0; //BreakEvenCalcMethod //enum
extern double BreakEven=25.0;
extern double BreakEvenProfit=5.0;
//
//extern string Lbl_ITSLSettings="-- Instant Trailing Stop Loss Settings --";
//extern bool UseInstantTrailingStop=false;
//extern int TrailStopCalcMethod=0; //TrailStopCalcMethod //enum
//extern double InstantTrailingStop=30.0;
//extern double PipIncrement=5;
//
//extern string Lbl_TSFSettings="-- Tightening stop feature Settings --";
//extern bool UseTigheningStop=false;
//extern int TighteningCalcMethod=0; //TighteningCalcMethod //enum
//extern double TrailAt20Percent=25.0;
//extern double TrailAt40Percent=25.0;
//extern double TrailAt60Percent=25.0;
//extern double TrailAt80Percent=15.0;

extern string Lbl_JSLSettings="-- Jumping stop loss settings --";
extern bool UseJumpingStop=false;
extern int JumpingStopCalcMethod=0; //JumpingStopCalcMethod //enum
extern double JumpingStop=10.0;
extern bool JumpAfterBreakevenOnly=true;
extern double PipsAwayFromVisualJS=100.0;
//
//extern string Lbl_NotificationSettings="***** Notification Settings *****";
//extern bool PopupAlert=false;
//extern bool EmailAlert=false;
//extern bool PushAlert=false;

extern string LblDisplay="***** Display Settings *****";
extern bool DisplayShowSettings=true;
extern bool DisplayShowTable=true;
extern bool DisplayShowOrdersInTable=true;
extern string DisplayFont="Courier";
extern int DisplayFontSize=7;
extern int DisplaySpacing=13;
extern DisplayStyleEnum DisplayStyle=ValueAndMode;

extern string LblRuntime="***** Runtime Settings *****";
extern string LblDebug="DebugLevel 0 = Regular messages, 1 = Print errors, 2 = Print info";
extern int DebugLevel=2;
extern string LblHistory="# of historical data readings to keep per filter per symbol.";
extern string LblHistory2="Decrease only if memory use is an issue.";
extern string LblHistory3="Filters can override this # per filter.";
extern int HistoryLevel=10;
