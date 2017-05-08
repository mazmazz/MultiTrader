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
input string ATR_Value_Hidden="*:false";

input string Lbl_ATR_Value_Indi=""; // :
input string ATR_Value_TimeFrame="a:60";
input string ATR_Value_Period="*:20";
input string ATR_Value_Shift="*:0";

//+------------------------------------------------------------------+
//| StdDev
//+------------------------------------------------------------------+

input string Lbl_StdDev="________ StdDev Settings [StdDev] ________"; // :
input string StdDev_Value_Modes="a:1";
input string StdDev_Value_Names="a:H1";
input string StdDev_Value_Hidden="*:false";

input string Lbl_StdDev_Value_Indi=""; // :
input string StdDev_Value_TimeFrame="a:60|b:240|c:1440";
input string StdDev_Value_Period="*:20";
input string StdDev_Value_Shift="*:0";
input string StdDev_Value_Method="*:0";
input string StdDev_Value_AppliedPrice="*:0";
input string StdDev_Value_PeriodShift="*:0";

//+------------------------------------------------------------------+
//| Stoch
//+------------------------------------------------------------------+

input string Lbl_Stoch_1="________ Stoch Settings [Stoch] ________"; // :

input string LbL_Stoch_Entry="---- Stoch Entry Settings ----"; // :
input string Stoch_Entry_Modes="a:1|b:1|c:1";
input string Stoch_Entry_Names="a:M15|b:M30|c:M60";
input string Stoch_Entry_TimeFrame="a:15|b:30|c:60";

input string Lbl_Stoch_Entry_Indi=""; // :
input string Stoch_Entry_KPeriod="*:5";
input string Stoch_Entry_DPeriod="*:3";
input string Stoch_Entry_Slowing="*:3";
input string Stoch_Entry_Method="*:3";
input string Stoch_Entry_PriceField="*:0";
input string Stoch_Entry_Shift="*:0";
input string Stoch_Entry_BuySellZone="*:22.0";

input string LbL_Stoch_Exit="---- Stoch Exit Settings ----"; // :
input string Stoch_Exit_Modes="a:1";
input string Stoch_Exit_Names="a:M15";
input string Stoch_Exit_TimeFrame="a:15";

input string Lbl_Stoch_Exit_Indi=""; // :
input string Stoch_Exit_KPeriod="*:5";
input string Stoch_Exit_DPeriod="*:3";
input string Stoch_Exit_Slowing="*:3";
input string Stoch_Exit_Method="*:3";
input string Stoch_Exit_PriceField="*:0";
input string Stoch_Exit_Shift="*:0";
input string Stoch_Exit_BuySellZone="*:30.0";

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
    Main.addFilter(atr);
        
    FilterStdDev* stdDev = new FilterStdDev();
    stdDev.addSubfilter(StdDev_Value_Modes, StdDev_Value_Names, StdDev_Value_Hidden, SubfilterValue
        , StdDev_Value_TimeFrame, StdDev_Value_Period, StdDev_Value_Shift
        , StdDev_Value_Method, StdDev_Value_AppliedPrice, StdDev_Value_PeriodShift
        );
    Main.addFilter(stdDev);
        
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
    Main.addFilter(stoch);
}