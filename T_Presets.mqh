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
#include "F_Filter/F_Filter_CSS.mqh"
#include "F_Filter/F_Filter_FB.mqh"

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
input string ATR_Value_Modes="a:1";
input string ATR_Value_Names="a:H1";
input string ATR_Value_Hidden="a:0";

input string Lbl_ATR_Value_Indi="-- Parameters --"; // :
input string ATR_Value_TimeFrame="a:60";
input string ATR_Value_Period="*:20";
input string ATR_Value_Shift="*:0";

//+------------------------------------------------------------------+
//| StdDev
//+------------------------------------------------------------------+

input string Lbl_StdDev="________ StdDev Settings [StdDev] ________"; // :
input string StdDev_Value_Modes="a:0";
input string StdDev_Value_Names="a:H1";
input string StdDev_Value_Hidden="a:0";

input string Lbl_StdDev_Value_Indi="-- Parameters --"; // :
input string StdDev_Value_TimeFrame="a:60";
input string StdDev_Value_Period="*:20";
input string StdDev_Value_Shift="*:0";
input string StdDev_Value_Method="*:0";
input string StdDev_Value_AppliedPrice="*:0";
input string StdDev_Value_PeriodShift="*:0";

//+------------------------------------------------------------------+
//| CSS
//+------------------------------------------------------------------+

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
input string FB_Entry_CompareMaFastSlow="a:false";
input string FB_Entry_Shift="a:1";

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
input string FB_Exit_CompareMaFastSlow="a:false";
input string FB_Exit_Shift="a:1";

input string Lbl_FB_Exit_Fast="-- Fast MA --"; // :
input string FB_Exit_MaPeriodFast="a:5";
input string FB_Exit_MaAvgModeFast="a:1"; // AvgModeFast: 0=Simple 1=Exponential 2=Smoothed 3=Linear-Weight
input string FB_Exit_MaPriceFast="a:0"; // MaPriceFast: 0=Close 1=Open 2=High 3=Low 4=Median 5=Typical 6=Weighted

input string Lbl_FB_Exit_Slow="-- Slow MA --"; // :
input string FB_Exit_MaEnableSlow="a:1";
input string FB_Exit_MaPeriodSlow="a:10";
input string FB_Exit_MaAvgModeSlow="a:1"; // AvgModeSlow: 0=Simple 1=Exponential 2=Smoothed 3=Linear-Weight
input string FB_Exit_MaPriceSlow="a:0"; // MaPriceSlow: 0=Close 1=Open 2=High 3=Low 4=Median 5=Typical 6=Weighted

//+------------------------------------------------------------------+
// 2. Add filters to LoadFilters() below and add settings [HOOKS]
//    ORDER MATTERS BY DEPENDENCY! Any filter that depends on other filters' values
//    must be added after those other filters.
//    Add order also affects display order on dashboard.
//+------------------------------------------------------------------+

void LoadFilters() {
    FilterAtr* atr = new FilterAtr();
    atr.addSubfilter(ATR_Value_Modes, ATR_Value_Names, ATR_Value_Hidden, SubfilterValue
        , ATR_Value_TimeFrame, ATR_Value_Period, ATR_Value_Shift
        );
    Main.addFilter(atr);
    
    FilterStdDev* stdDev = new FilterStdDev();
    stdDev.addSubfilter(StdDev_Value_Modes, StdDev_Value_Names, StdDev_Value_Hidden, SubfilterValue
        , StdDev_Value_TimeFrame, StdDev_Value_Period, StdDev_Value_Shift
        , StdDev_Value_Method, StdDev_Value_AppliedPrice, StdDev_Value_PeriodShift
        );
    Main.addFilter(stdDev);
        
    FilterCss* css = new FilterCss();
    css.addSubfilter(CSS_Entry_Modes, CSS_Entry_Names, NULL, SubfilterEntry
       , CSS_Entry_ResultType, CSS_Entry_CalcMethod
       , CSS_Entry_TimeFrame, CSS_Entry_MaPeriod, CSS_Entry_AtrPeriod, CSS_Entry_Shift
       , CSS_Entry_Candles, CSS_Entry_Absolute, CSS_Entry_Min, CSS_Entry_Max, CSS_Entry_TradeLevel, CSS_Entry_DifferenceThreshold
       );
    css.addSubfilter(CSS_Exit_Modes, CSS_Exit_Names, NULL, SubfilterExit
       , CSS_Exit_ResultType, CSS_Exit_CalcMethod
       , CSS_Exit_TimeFrame, CSS_Exit_MaPeriod, CSS_Exit_AtrPeriod, CSS_Exit_Shift
       , CSS_Exit_Candles, CSS_Exit_Absolute, CSS_Exit_Min, CSS_Exit_Max, CSS_Exit_TradeLevel, CSS_Exit_DifferenceThreshold
       , true
       );
    Main.addFilter(css);
    
    FilterFb *fb = new FilterFb();
    fb.addSubfilter(FB_Entry_Modes, FB_Entry_Names, NULL, SubfilterEntry
        , FB_Entry_TimeFrame, FB_Entry_MaPeriodFast, FB_Entry_MaAvgModeFast, FB_Entry_MaPriceFast
        , FB_Entry_MaEnableSlow, FB_Entry_MaPeriodSlow, FB_Entry_MaAvgModeSlow, FB_Entry_MaPriceSlow
        , FB_Entry_CompareMaFastSlow, FB_Entry_Shift
        );

    fb.addSubfilter(FB_Exit_Modes, FB_Exit_Names, NULL, SubfilterExit
        , FB_Exit_TimeFrame, FB_Exit_MaPeriodFast, FB_Exit_MaAvgModeFast, FB_Exit_MaPriceFast
        , FB_Exit_MaEnableSlow, FB_Exit_MaPeriodSlow, FB_Exit_MaAvgModeSlow, FB_Exit_MaPriceSlow
        , FB_Exit_CompareMaFastSlow, FB_Exit_Shift
        , true
    );
    Main.addFilter(fb);
}
