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

#include "F_Filter/F_Filter_ATR.mqh"
#include "F_Filter/F_Filter_StdDev.mqh"
#include "F_Filter/F_Filter_Stoch.mqh"
//#include "F_Filter/F_Filter_CSS.mqh"
#ifdef __MQL4__
//#include "F_Filter/F_Filter_HGI.mqh"
#endif

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
<<<<<<< HEAD
input string ATR_Value_Modes="a:1|b:1|c:1";
input string ATR_Value_Names="a:H1|b:H4|c:D1";
input string ATR_Value_Hidden="a:0|b:0|c:0";
=======
input string ATR_Value_Modes="a:1";
input string ATR_Value_Names="a:H1";
input string ATR_Value_Hidden="a:false";
>>>>>>> 4d8ae81... Setting bool fixes

input string Lbl_ATR_Value_Indi=""; // :
input string ATR_Value_TimeFrame="a:60|b:240|c:1440";
input string ATR_Value_Period="a:20|b:20|c:20";
input string ATR_Value_Shift="a:0|b:0|c:0";

//+------------------------------------------------------------------+
//| StdDev
//+------------------------------------------------------------------+

input string Lbl_StdDev="________ StdDev Settings [StdDev] ________"; // :
<<<<<<< HEAD
input string StdDev_Value_Modes="a:1|b:1|c:1";
input string StdDev_Value_Names="a:H1|b:H4|c:D1";
input string StdDev_Value_Hidden="a:0|b:0|c:0";

input string Lbl_StdDev_Value_Indi=""; // :
input string StdDev_Value_TimeFrame="a:60|b:240|c:1440";
input string StdDev_Value_Period="a:20|b:20|c:20";
input string StdDev_Value_Shift="a:0|b:0|c:0";
input string StdDev_Value_Method="a:0|b:0|c:0";
input string StdDev_Value_AppliedPrice="a:0|b:0|c:0";
input string StdDev_Value_PeriodShift="a:0|b:0|c:0";

//+------------------------------------------------------------------+
//| Stoch
//+------------------------------------------------------------------+

input string Lbl_Stoch_1="________ Stoch Settings [Stoch] ________"; // :

input string LbL_Stoch_Entry="---- Stoch Entry Settings ----"; // :
input string Stoch_Entry_Modes="a:1|b:1|c:1";
input string Stoch_Entry_Names="a:M15|b:M30|c:M60";
input string Stoch_Entry_TimeFrame="a:15|b:30|c:60";

input string Lbl_Stoch_Entry_Indi=""; // :
input string Stoch_Entry_KPeriod="a:5|b:5|c:5";
input string Stoch_Entry_DPeriod="a:3|b:3|c:3";
input string Stoch_Entry_Slowing="a:3|b:3|c:3";
input string Stoch_Entry_Method="a:3|b:3|c:3";
input string Stoch_Entry_PriceField="a:0|b:0|c:0";
input string Stoch_Entry_Shift="a:0|b:0|c:0";
input string Stoch_Entry_BuySellZone="a:22.0|b:22.0|c:22.0";

input string LbL_Stoch_Exit="---- Stoch Exit Settings ----"; // :
input string Stoch_Exit_Modes="a:1";
input string Stoch_Exit_Names="a:M15";
input string Stoch_Exit_TimeFrame="a:15";

input string Lbl_Stoch_Exit_Indi=""; // :
input string Stoch_Exit_KPeriod="a:5";
input string Stoch_Exit_DPeriod="a:3";
input string Stoch_Exit_Slowing="a:3";
input string Stoch_Exit_Method="a:3";
input string Stoch_Exit_PriceField="a:0";
input string Stoch_Exit_Shift="a:0";
input string Stoch_Exit_BuySellZone="a:30.0";

//+------------------------------------------------------------------+
//| HGI
//+------------------------------------------------------------------+

//input string Lbl_Hgi_1="________ HGI Settings [HGI] ________"; // :
//input string LbL_Hgi_Entry="---- HGI Entry Settings ----"; // :
//input string Hgi_Entry_Modes="a:1";
//input string Hgi_Entry_Names="a:M60";

//input string Lbl_Hgi_Entry_Indi=""; // :
//input string Hgi_Entry_TimeFrame="a:60";
//input string Hgi_Entry_Shift="a:0";
//input string Hgi_Entry_OnTrend="a:1";
//input string Hgi_Entry_OnRange="a:1";
//input string Hgi_Entry_OnRad="a:0";
//input string Hgi_Entry_OnSignal="a:1";
//input string Hgi_Entry_OnSlope="a:0";
//
//input string LbL_Hgi_Exit="---- HGI Exit Settings ----"; // :
//input string Hgi_Exit_Modes="a:1";
//input string Hgi_Exit_Names="a:M60";
=======
input string StdDev_Value_Modes="a:0";
input string StdDev_Value_Names="a:H1";
input string StdDev_Value_Hidden="a:false";
>>>>>>> 4d8ae81... Setting bool fixes

//input string Lbl_Hgi_Exit_Indi=""; // :
//input string Hgi_Exit_TimeFrame="a:60";
//input string Hgi_Exit_Shift="a:0";
//input string Hgi_Exit_OnTrend="a:1";
//input string Hgi_Exit_OnRange="a:1";
//input string Hgi_Exit_OnRad="a:0";
//input string Hgi_Exit_OnSignal="a:1";
//input string Hgi_Exit_OnSlope="a:0";

//+------------------------------------------------------------------+
//| CSS
//+------------------------------------------------------------------+

<<<<<<< HEAD
//input string Lbl_CSS="________ CSS Settings [CSS] ________";
//input string Lbl_CSS_General_Settings="---- CSS General Settings ----";
//input string CSS_SymbolsToWeigh = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURJPY,EURNZD,EURUSD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,GBPUSD,NZDCHF,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY"; // CSS_SymbolsToWeigh: Leave blank to weigh all symbols
//
//input string Lbl_CSS_Entry_Settings="---- CSS Entry Settings ----";
//input string CSS_Entry_Modes="a:1|b:1";
//input string CSS_Entry_Names="a:H1|b:H1SS";

//input string Lbl_CSS_Entry_Indi=""; // :
//input string CSS_Entry_TimeFrame="a:60|b:60";
//input string CSS_Entry_Shift="a:0|b:0";
//input string CSS_Entry_MaPeriod="a:21|b:7";
//input string CSS_Entry_AtrPeriod="a:100|b:50";
//input string CSS_Entry_CalcMethod="a:0|b:2";
//
//input string Lbl_CSS_Exit_Settings="---- CSS Exit Settings ----";
//input string CSS_Exit_Modes="a:1|b:1";
//input string CSS_Exit_Names="a:H1x|b:H1SSx"; 

//input string Lbl_CSS_Exit_Indi=""; // :
//input string CSS_Exit_TimeFrame="a:60|b:60";
//input string CSS_Exit_Shift="a:0|b:0";
//input string CSS_Exit_MaPeriod="a:21|b:7";
//input string CSS_Exit_AtrPeriod="a:100|b:50";
//input string CSS_Exit_CalcMethod="a:0|b:2";
=======
input string Lbl_CSS="________ CSS Settings [CSS] ________";
input string Lbl_CSS_General_Settings="---- CSS General Settings ----";
input string CSS_SymbolsToWeigh = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURJPY,EURNZD,EURUSD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,GBPUSD,NZDCHF,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY"; // CSS_SymbolsToWeigh: Leave blank to weigh all symbols

input string Lbl_CSS_Entry_Settings="---- CSS Entry Settings ----";
input string CSS_Entry_Modes="a:0|b:1";
input string CSS_Entry_Names="a:D1|b:D1SS";

input string Lbl_CSS_Entry_Indi="-- Parameters --"; // :
input string CSS_Entry_ResultType="a:3|b:3"; // ResultType: 1=Diff 2=Delta 3=Cross 4=Direction 5=GMT 6=GMT Delta
input string CSS_Entry_CalcMethod="a:1|b:3"; // CalcMethod: 1=CSS 3=SuperSlope
input string CSS_Entry_TimeFrame="a:1440|b:1440";
input string CSS_Entry_MaPeriod="a:21|b:7";
input string CSS_Entry_AtrPeriod="a:100|b:50";
input string CSS_Entry_Shift="*:0";

input string Lbl_CSS_Entry_Specific="-- Result Settings --"; // :
input string CSS_Entry_Candles="*:0"; // CSS_Entry_Candles: Delta/Cross/GMT Delta
input string CSS_Entry_Absolute="*:false"; // CSS_Entry_Absolute: Diff/Delta
input string CSS_Entry_Min="*:0.1"; // CSS_Entry_Min: Diff/Delta/GMT/GMT Delta
input string CSS_Entry_Max="*:99.0"; // CSS_Entry_Max: Diff/Delta/GMT/GMT Delta
input string CSS_Entry_TradeLevel="a:0.2|b:2.0"; // CSS_Entry_TradeLevel: Cross, 0 to disable check
input string CSS_Entry_DifferenceThreshold="*:0"; // CSS_Entry_DifferenceThreshold: Direction

input string Lbl_CSS_Exit_Settings="---- CSS Exit Settings ----";
input string CSS_Exit_Modes="a:0|b:1";
input string CSS_Exit_Names="a:D1|b:D1SS";

input string Lbl_CSS_Exit_Indi="-- Parameters --"; // :
input string CSS_Exit_ResultType="a:3|b:3"; // ResultType: 1=Diff 2=Delta 3=Cross 4=Direction 5=GMT 6=GMT Delta
input string CSS_Exit_CalcMethod="a:1|b:3"; // CalcMethod: 1=CSS 3=SuperSlope
input string CSS_Exit_TimeFrame="a:1440|b:1440";
input string CSS_Exit_MaPeriod="a:21|b:7";
input string CSS_Exit_AtrPeriod="a:100|b:50";
input string CSS_Exit_Shift="*:0";

input string Lbl_CSS_Exit_Specific="-- Result Settings --"; // :
input string CSS_Exit_Candles="*:0"; // CSS_Exit_Candles: Delta/Cross/GMT Delta
input string CSS_Exit_Absolute="*:false"; // CSS_Exit_Absolute: Diff/Delta
input string CSS_Exit_Min="*:0.1"; // CSS_Exit_Min: Diff/Delta/GMT/GMT Delta
input string CSS_Exit_Max="*:99.0"; // CSS_Exit_Max: Diff/Delta/GMT/GMT Delta
input string CSS_Exit_TradeLevel="a:0.2|b:2.0"; // CSS_Exit_TradeLevel: Cross - 0 to disable check
input string CSS_Exit_DifferenceThreshold="*:0"; // CSS_Exit_DifferenceThreshold: Direction

//+------------------------------------------------------------------+
//| Flying Buddha
//+------------------------------------------------------------------+

input string Lbl_Fb="________ Flying Buddha Settings [FB] ________";

input string Lbl_FB_Entry_Settings="---- FB Entry Settings ----";
input string FB_Entry_Modes="a:1";
input string FB_Entry_Names="a:M1";

input string Lbl_FB_Entry_Indi="-- Parameters --"; // :
input string FB_Entry_TimeFrame="a:1";
input string FB_Entry_Shift="a:1";
input string FB_Entry_CompareMaFastSlow="a:false";
input string FB_Entry_SignalDirectionless="a:false";

input string Lbl_FB_Entry_Fast="-- Fast MA --"; // :
input string FB_Entry_MaPeriodFast="a:5";
input string FB_Entry_MaAvgModeFast="a:1"; // AvgModeFast: 0=Simple 1=Exponential 2=Smoothed 3=Linear-Weight
input string FB_Entry_MaPriceFast="a:0"; // MaPriceFast: 0=Close 1=Open 2=High 3=Low 4=Median 5=Typical 6=Weighted

input string Lbl_FB_Entry_Slow="-- Slow MA --"; // :
input string FB_Entry_MaEnableSlow="a:1";
input string FB_Entry_MaPeriodSlow="a:10";
input string FB_Entry_MaAvgModeSlow="a:1"; // AvgModeSlow: 0=Simple 1=Exponential 2=Smoothed 3=Linear-Weight
input string FB_Entry_MaPriceSlow="a:0"; // MaPriceSlow: 0=Close 1=Open 2=High 3=Low 4=Median 5=Typical 6=Weighted

input string Lbl_FB_Exit_Settings="---- FB Exit Settings ----";
input string FB_Exit_Modes="a:1";
input string FB_Exit_Names="a:M1";

input string Lbl_FB_Exit_Indi="-- Parameters --"; // :
input string FB_Exit_TimeFrame="a:1";
input string FB_Exit_Shift="a:1";
input string FB_Exit_CompareMaFastSlow="a:false";
input string FB_Exit_SignalDirectionless="a:false";

input string Lbl_FB_Exit_Fast="-- Fast MA --"; // :
input string FB_Exit_MaPeriodFast="a:5";
input string FB_Exit_MaAvgModeFast="a:1"; // AvgModeFast: 0=Simple 1=Exponential 2=Smoothed 3=Linear-Weight
input string FB_Exit_MaPriceFast="a:0"; // MaPriceFast: 0=Close 1=Open 2=High 3=Low 4=Median 5=Typical 6=Weighted

input string Lbl_FB_Exit_Slow="-- Slow MA --"; // :
input string FB_Exit_MaEnableSlow="a:true";
input string FB_Exit_MaPeriodSlow="a:10";
input string FB_Exit_MaAvgModeSlow="a:1"; // AvgModeSlow: 0=Simple 1=Exponential 2=Smoothed 3=Linear-Weight
input string FB_Exit_MaPriceSlow="a:0"; // MaPriceSlow: 0=Close 1=Open 2=High 3=Low 4=Median 5=Typical 6=Weighted
>>>>>>> 4d8ae81... Setting bool fixes

//+------------------------------------------------------------------+
// 2. Add filters to LoadFilters() below and add settings [HOOKS]
//    ORDER MATTERS BY DEPENDENCY! Any filter that depends on other filters' values
//    must be added after those other filters.
//    Add order also affects display order on dashboard.
//+------------------------------------------------------------------+

void LoadFilters() {
    // Main = new MainManager();
    
    FilterAtr* atr = new FilterAtr();
    atr.addSubfilter(ATR_Value_Modes, ATR_Value_Names, ATR_Value_Hidden, SubfilterValue
        , ATR_Value_TimeFrame, ATR_Value_Period, ATR_Value_Shift
        );
        
    FilterStdDev* stdDev = new FilterStdDev();
    stdDev.addSubfilter(StdDev_Value_Modes, StdDev_Value_Names, StdDev_Value_Hidden, SubfilterValue
        , StdDev_Value_TimeFrame, StdDev_Value_Period, StdDev_Value_Shift
        , StdDev_Value_Method, StdDev_Value_AppliedPrice, StdDev_Value_PeriodShift
        );
        
    FilterStoch* stoch = new FilterStoch();
    stoch.addSubfilter(Stoch_Entry_Modes, Stoch_Entry_Names, NULL, SubfilterEntry
        , Stoch_Entry_TimeFrame, Stoch_Entry_KPeriod, Stoch_Entry_DPeriod
        , Stoch_Entry_Slowing, Stoch_Entry_Method, Stoch_Entry_PriceField
        , Stoch_Entry_Shift, Stoch_Entry_BuySellZone
        );
    stoch.addSubfilter(Stoch_Exit_Modes, Stoch_Exit_Names, NULL, SubfilterExit
        , Stoch_Exit_TimeFrame, Stoch_Exit_KPeriod, Stoch_Exit_DPeriod
        , Stoch_Exit_Slowing, Stoch_Exit_Method, Stoch_Exit_PriceField
        , Stoch_Exit_Shift, Stoch_Exit_BuySellZone
        , true
        );
        
    //FilterCss* css = new FilterCss();
    //css.addSubfilter(CSS_Entry_Modes, CSS_Entry_Names, NULL, SubfilterEntry
    //    , CSS_Entry_TimeFrame, CSS_Entry_Shift, CSS_Entry_MaPeriod
    //    , CSS_Entry_AtrPeriod, CSS_Entry_CalcMethod
    //    );
    //css.addSubfilter(CSS_Exit_Modes, CSS_Exit_Names, NULL, SubfilterExit
    //    , CSS_Exit_TimeFrame, CSS_Exit_Shift, CSS_Exit_MaPeriod
    //    , CSS_Exit_AtrPeriod, CSS_Exit_CalcMethod
    //    , true
    //    );
    
    Main.addFilter(atr);
    Main.addFilter(stdDev);
    Main.addFilter(stoch);
    //Main.addFilter(css);
    
#ifdef __MQL4__
    //FilterHgi* hgi = new FilterHgi();
    //hgi.addSubfilter(Hgi_Entry_Modes, Hgi_Entry_Names, NULL, SubfilterEntry
    //    , Hgi_Entry_TimeFrame, Hgi_Entry_Shift, Hgi_Entry_OnTrend
    //    , Hgi_Entry_OnRange, Hgi_Entry_OnRad, Hgi_Entry_OnSignal
    //    , Hgi_Entry_OnSlope
    //    );
    //hgi.addSubfilter(Hgi_Exit_Modes, Hgi_Exit_Names, NULL, SubfilterExit
    //    , Hgi_Exit_TimeFrame, Hgi_Exit_Shift, Hgi_Exit_OnTrend
    //    , Hgi_Exit_OnRange, Hgi_Exit_OnRad, Hgi_Exit_OnSignal
    //    , Hgi_Exit_OnSlope
    //    , true
    //    );
    
    //Main.addFilter(hgi);
#endif
}