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
#include "F_Filter/F_Filter_Spread.mqh"
#include "F_Filter/F_Filter_Sentiment.mqh"

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
input string StdDev_Value_TimeFrame="a:60";
input string StdDev_Value_Period="*:20";
input string StdDev_Value_Shift="*:0";
input string StdDev_Value_Method="*:0";
input string StdDev_Value_AppliedPrice="*:0";
input string StdDev_Value_PeriodShift="*:0";

//+------------------------------------------------------------------+
//| StdDev
//+------------------------------------------------------------------+

input string Lbl_Spread="________ Spread Settings [Spread] ________"; // :
input string Spread_Value_Modes="a:1";
input string Spread_Value_Names="a:Cur";
input string Spread_Value_Hidden="*:false";

//+------------------------------------------------------------------+
//| Sentiment
//+------------------------------------------------------------------+

input string Lbl_Sentiment_1="________ Sentiment Zone Oscillator Settings [Sentiment] ________"; // :

input string LbL_Sentiment_Entry="---- Sentiment Entry Settings ----"; // :
input string Sentiment_Entry_Modes="a:1";
input string Sentiment_Entry_Names="a:H1";
input string Sentiment_Entry_TimeFrame="a:60";

input string Lbl_Sentiment_Entry_Indi=""; // :
input string Sentiment_Entry_Trigger="a:1";
input string Sentiment_Entry_SzoPeriod="*:14";
input string Sentiment_Entry_FilterPeriod="*:14";
input string Sentiment_Entry_LevelPeriod="*:25";
input string Sentiment_Entry_Shift="*:1";

input string LbL_Sentiment_Exit="---- Sentiment Exit Settings ----"; // :
input string Sentiment_Exit_Modes="a:1";
input string Sentiment_Exit_Names="a:H1";
input string Sentiment_Exit_TimeFrame="a:60";

input string Lbl_Sentiment_Exit_Indi=""; // :
input string Sentiment_Exit_Trigger="a:1";
input string Sentiment_Exit_SzoPeriod="*:14";
input string Sentiment_Exit_FilterPeriod="*:14";
input string Sentiment_Exit_LevelPeriod="*:25";
input string Sentiment_Exit_Shift="*:1";

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
        
    FilterSpread* spread = new FilterSpread();
    spread.addSubfilter(Spread_Value_Modes, Spread_Value_Names, Spread_Value_Hidden, SubfilterValue);
    Main.addFilter(spread);
        
    FilterSentiment* sentiment = new FilterSentiment();
    sentiment.addSubfilter(Sentiment_Entry_Modes, Sentiment_Entry_Names, NULL, SubfilterEntry
        , Sentiment_Entry_TimeFrame
        , Sentiment_Entry_Trigger
        , Sentiment_Entry_SzoPeriod
        , Sentiment_Entry_FilterPeriod
        , Sentiment_Entry_LevelPeriod
        , Sentiment_Entry_Shift
        );
    sentiment.addSubfilter(Sentiment_Exit_Modes, Sentiment_Exit_Names, NULL, SubfilterExit
        , Sentiment_Exit_TimeFrame
        , Sentiment_Exit_Trigger
        , Sentiment_Exit_SzoPeriod
        , Sentiment_Exit_FilterPeriod
        , Sentiment_Exit_LevelPeriod
        , Sentiment_Exit_Shift
        , true
        );
    Main.addFilter(sentiment);
}