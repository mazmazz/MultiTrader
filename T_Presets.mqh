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
input string Lbl_Format="a=1|b=0|c=1"; // Format
input string Lbl_Format2="# of subfilters must be same across a filter's settings."; // Format
input string Lbl_Format3="Do not add a trailing |";

//+------------------------------------------------------------------+
//| ATR
//+------------------------------------------------------------------+

input string Lbl_ATR="________ ATR Settings [ATR] ________";
input string ATR_Value_Modes="a=1|b=1|c=1";
input string ATR_Value_Names="a=H1|b=H4|c=D1";
input string ATR_Value_Hidden="a=0|b=0|c=0";

input string Lbl_ATR_Value_Settings="---- ATR Value Settings ----";
input string ATR_Value_TimeFrame="a=60|b=240|c=1440";
input string ATR_Value_Period="a=20|b=20|c=20";
input string ATR_Value_Shift="a=0|b=0|c=0";

//+------------------------------------------------------------------+
//| StdDev
//+------------------------------------------------------------------+

input string Lbl_StdDev="________ StdDev Settings [StdDev] ________";
input string StdDev_Value_Modes="a=1|b=1|c=1";
input string StdDev_Value_Names="a=H1|b=H4|c=D1";
input string StdDev_Value_Hidden="a=0|b=0|c=0";

input string Lbl_StdDev_Value_Settings="---- StdDev Value Settings ----";
input string StdDev_Value_TimeFrame="a=60|b=240|c=1440";
input string StdDev_Value_Period="a=20|b=20|c=20";
input string StdDev_Value_Shift="a=0|b=0|c=0";
input string StdDev_Value_Method="a=0|b=0|c=0";
input string StdDev_Value_AppliedPrice="a=0|b=0|c=0";
input string StdDev_Value_PeriodShift="a=0|b=0|c=0";

//+------------------------------------------------------------------+
//| Stoch
//+------------------------------------------------------------------+

input string Lbl_Stoch_1="________ Stoch Settings [Stoch] ________";
input string Stoch_Entry_Modes="a=1|b=1|c=1";
input string Stoch_Entry_Names="a=M15|b=M30|c=M60";
input string Stoch_Exit_Modes="a=1";
input string Stoch_Exit_Names="a=M15";

input string LbL_Stoch_Entry="---- Stoch Entry Settings ----";
input string Stoch_Entry_TimeFrame="a=15|b=30|c=60";
input string Stoch_Entry_KPeriod="a=5|b=5|c=5";
input string Stoch_Entry_DPeriod="a=3|b=3|c=3";
input string Stoch_Entry_Slowing="a=3|b=3|c=3";
input string Stoch_Entry_Method="a=3|b=3|c=3";
input string Stoch_Entry_PriceField="a=0|b=0|c=0";
input string Stoch_Entry_Shift="a=0|b=0|c=0";
input string Stoch_Entry_BuySellZone="a=22.0|b=22.0|c=22.0";

input string LbL_Stoch_Exit="---- Stoch Exit Settings ----";
input string Stoch_Exit_TimeFrame="a=15";
input string Stoch_Exit_KPeriod="a=5";
input string Stoch_Exit_DPeriod="a=3";
input string Stoch_Exit_Slowing="a=3";
input string Stoch_Exit_Method="a=3";
input string Stoch_Exit_PriceField="a=0";
input string Stoch_Exit_Shift="a=0";
input string Stoch_Exit_BuySellZone="a=30.0";

//+------------------------------------------------------------------+
//| HGI
//+------------------------------------------------------------------+

//input string Lbl_Hgi_1="________ HGI Settings [HGI] ________";
//input string Hgi_Entry_Modes="a=1";
//input string Hgi_Entry_Names="a=M60";
//input string Hgi_Exit_Modes="a=1";
//input string Hgi_Exit_Names="a=M60";
//
//input string LbL_Hgi_Entry="---- HGI Entry Settings ----";
//input string Hgi_Entry_TimeFrame="a=60";
//input string Hgi_Entry_Shift="a=0";
//input string Hgi_Entry_OnTrend="a=1";
//input string Hgi_Entry_OnRange="a=1";
//input string Hgi_Entry_OnRad="a=0";
//input string Hgi_Entry_OnSignal="a=1";
//input string Hgi_Entry_OnSlope="a=0";
//
//input string LbL_Hgi_Exit="---- HGI Exit Settings ----";
//input string Hgi_Exit_TimeFrame="a=60";
//input string Hgi_Exit_Shift="a=0";
//input string Hgi_Exit_OnTrend="a=1";
//input string Hgi_Exit_OnRange="a=1";
//input string Hgi_Exit_OnRad="a=0";
//input string Hgi_Exit_OnSignal="a=1";
//input string Hgi_Exit_OnSlope="a=0";

//+------------------------------------------------------------------+
//| CSS
//+------------------------------------------------------------------+

//input string Lbl_CSS="________ CSS Settings [CSS] ________";
//input string CSS_Entry_Modes="a=1|b=1";
//input string CSS_Entry_Names="a=H1|b=H1SS";
//input string CSS_Exit_Modes="a=1|b=1";
//input string CSS_Exit_Names="a=H1x|b=H1SSx"; 
//
//input string Lbl_CSS_General_Settings="---- CSS General Settings ----";
//input string CSS_SymbolsToWeigh = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURJPY,EURNZD,EURUSD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,GBPUSD,NZDCHF,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY"; // CSS_SymbolsToWeigh: Leave blank to weigh all symbols
//
//input string Lbl_CSS_Entry_Settings="---- CSS Entry Settings ----";
//input string CSS_Entry_TimeFrame="a=60|b=60";
//input string CSS_Entry_Shift="a=0|b=0";
//input string CSS_Entry_MaPeriod="a=21|b=7";
//input string CSS_Entry_AtrPeriod="a=100|b=50";
//input string CSS_Entry_CalcMethod="a=0|b=2";
//
//input string Lbl_CSS_Exit_Settings="---- CSS Exit Settings ----";
//input string CSS_Exit_TimeFrame="a=60|b=60";
//input string CSS_Exit_Shift="a=0|b=0";
//input string CSS_Exit_MaPeriod="a=21|b=7";
//input string CSS_Exit_AtrPeriod="a=100|b=50";
//input string CSS_Exit_CalcMethod="a=0|b=2";

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
        );
        
    //FilterCss* css = new FilterCss();
    //css.addSubfilter(CSS_Entry_Modes, CSS_Entry_Names, NULL, SubfilterEntry
    //    , CSS_Entry_TimeFrame, CSS_Entry_Shift, CSS_Entry_MaPeriod
    //    , CSS_Entry_AtrPeriod, CSS_Entry_CalcMethod
    //    );
    //css.addSubfilter(CSS_Exit_Modes, CSS_Exit_Names, NULL, SubfilterExit
    //    , CSS_Exit_TimeFrame, CSS_Exit_Shift, CSS_Exit_MaPeriod
    //    , CSS_Exit_AtrPeriod, CSS_Exit_CalcMethod
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
    //    );
    
    //Main.addFilter(hgi);
#endif
}