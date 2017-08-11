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
#include "F_Filter/F_Filter_Genotick.mqh"

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
input string ATR_Modes="a:1";
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
input string StdDev_Modes="a:1";
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

input string Geno_Modes="a:1|b:1";
input string Geno_Types="a:1|b:2";
input string Geno_Names="a:Open|b:Close";
input string Geno_Hidden="*:false";

input string Geno_Params_Sep = ""; // : 
input string Geno_FileName="*:Genotick_Data.csv";
input string Geno_ResetOnSameSignal="*:true"; // ResetOnSameSignal: True, reset trades every period if same signal; False, persist current trades
input string Geno_CloseOnMissingSignal="*:true"; // CloseOnMissingSignal: Close trades if there is no signal

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
        , Geno_FileName, Geno_ResetOnSameSignal, Geno_CloseOnMissingSignal
        );
    Main.addFilter(geno);
}