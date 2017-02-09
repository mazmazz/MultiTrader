//+------------------------------------------------------------------+
//|                                    MultiTrader Main Settings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

enum FilterMode {
    FilterDisabled,
    FilterNormal,
    FilterOpposite,
    FilterNotOpposite
};

//+------------------------------------------------------------------+
//| Comments
//+------------------------------------------------------------------+
//
// How to Add Filters
// 1. Add filter to toggle list [TOGGLES]
// 2. Add include to include list [INCLUDES]
// 3. Add OnTick indi call to FilterList_OnTick [HOOKS]
//
//+------------------------------------------------------------------+
extern string Lbl_IndisAndFilters="********** Indicators & Filters **********"; // Filter List
extern string Lbl_FilterLegend="0 = Disabled; 1 = Normal; 2 = Opposite; 3 = Not Opposite"; // Legend
extern string Lbl_Format="a=1;b=0;c=1"; // Format
extern string Lbl_Format2="BE CAREFUL of double ;s and trailing ;s - only use with empty values."; // Format single digit

//+------------------------------------------------------------------+
// 1. Add filters to toggle list here [TOGGLES]
//+------------------------------------------------------------------+
extern string Lbl_PossibleEntries="-------- Entry Settings --------";

//extern string HGI_Entry="";
extern string Stoch_Entry="a=1;b=1;c=1";
//extern string MarketHours_CST_Entry="1"; // Use Currency Session Time
//extern string MarketHours_GTH_Entry="1"; // Use General Trading Hours

//+-----------------------------------------+
// 1b. Add exits here [TOGGLES_EXITS]
//+-----------------------------------------+
extern string Lbl_PossibleExits="-------- Exit Settings --------"; // Exit List

extern string Stoch_Exit="1";

//+------------------------------------------------------------------+
// 2. Include filter includes here [INCLUDES]
//+------------------------------------------------------------------+

#include "MMT_Filter_Stoch.mqh"
// #include "MMT_Filter_MarketHours.mqh"

//+-----------------------------------------+
// 2b. Add exit includes here (if not already in the filter includes) [INCLUDES_EXITS]
//+-----------------------------------------+

//#include "MMT_Filter_Stoch_Exit.mqh"

//+------------------------------------------------------------------+
// 3. Add indi call to below methods [HOOKS]
//+------------------------------------------------------------------+

void FilterList_OnInit() {
    Stoch_OnInit();
}
//
//void FilterList_OnTick() {
//    
//}

void FilterList_OnTimer() {
    Stoch_OnTimer();
}

void FilterList_OnDeinit() {

}