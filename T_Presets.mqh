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
#include "F_Filter/F_Filter_NVIPVI.mqh"
#include "F_Filter/F_Filter_VPCI.mqh"
#include "F_Filter/F_Filter_EMI.mqh"

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
//| NVI-PVI
//+------------------------------------------------------------------+

input string Lbl_NVIPVI_1="________ NVI-PVI Settings [NVIPVI] ________"; // :

input string NVIPVI_Modes="a:1";
input string NVIPVI_Types="a:1";
input string NVIPVI_Names="a:M60";
input string NVIPVI_TimeFrame="a:60";

input string Lbl_NVIPVI_Indi=""; // :
input string NVIPVI_Trigger="*:0"; // Trigger 0:Competing 1:Agree
input string NVIPVI_CalcNvi="*:true";
input string NVIPVI_NviShortMaPeriod="*:9";
input string NVIPVI_NviLongMaPeriod="*:0";
input string NVIPVI_CalcPvi="*:true";
input string NVIPVI_PviShortMaPeriod="*:9";
input string NVIPVI_PviLongMaPeriod="*:0";

input string Lbl_NVIPVI_Options=""; // :
input string NVIPVI_CalcCurrentIndex="*:true";
input string NVIPVI_SuppressAllBelowThreshold="*:true";
input string NVIPVI_Shift="*:1";
input string NVIPVI_Limit="*:1";
input string NVIPVI_SlopeThreshold="*:0.4"; // SlopeThreshold: In pips
input string NVIPVI_SlopeSource="*:2"; // SlopeSource: 0-IndexType 1-Real 2-ShortMA 3-LongMA

//+------------------------------------------------------------------+
//| Ease of Movement
//+------------------------------------------------------------------+

input string Lbl_EMI_1="________ Ease of Movement Settings [EMI] ________"; // :

input string EMI_Modes="a:0";
input string EMI_Types="a:1";
input string EMI_Names="a:M60";
input string EMI_TimeFrame="a:60";

input string Lbl_EMI_Indi=""; // :
input string EMI_Trigger="*:0"; // Trigger 0:Slope
input string EMI_EmiPeriod="*:14";
input string EMI_EmiMaPeriod="*:9";

input string Lbl_EMI_Options=""; // :
input string EMI_Shift="*:1";
input string EMI_Limit="*:1";
input string EMI_SlopeThreshold="*:0.02";
input string EMI_SlopeSource="*:1"; // Slope source 0:EMI 1:EMIMA

//+------------------------------------------------------------------+
//| VPCI
//+------------------------------------------------------------------+

input string Lbl_VPCI_1="________ Volume Price Confirmation Settings [VPCI] ________"; // :

input string VPCI_Modes="a:0";
input string VPCI_Types="a:1";
input string VPCI_Names="a:M60";
input string VPCI_TimeFrame="a:60";

input string Lbl_VPCI_Indi=""; // :
input string VPCI_Trigger="*:0"; // Trigger 0:Slope
input string VPCI_ShortPeriod="*:14";
input string VPCI_LongPeriod="*:9";

input string Lbl_VPCI_Options=""; // :
input string VPCI_Shift="*:1";
input string VPCI_Limit="*:1";
input string VPCI_SlopeThreshold="*:0.4"; // SlopeThreshold: In pips
input string VPCI_SlopeSource="*:0"; // Slope source 0:VPCI 1:VPCIS

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
        
    FilterNVIPVI* nvipvi = new FilterNVIPVI();
    nvipvi.addSubfilter(NVIPVI_Modes, NVIPVI_Names, NULL, NVIPVI_Types
        , NVIPVI_TimeFrame, NVIPVI_Trigger
        , NVIPVI_CalcNvi, NVIPVI_NviShortMaPeriod, NVIPVI_NviLongMaPeriod
        , NVIPVI_CalcPvi, NVIPVI_PviShortMaPeriod, NVIPVI_PviLongMaPeriod
        , NVIPVI_CalcCurrentIndex, NVIPVI_SuppressAllBelowThreshold
        , NVIPVI_Shift, NVIPVI_Limit, NVIPVI_SlopeThreshold, NVIPVI_SlopeSource
        );
    Main.addFilter(nvipvi);
    
    FilterEMI* emi = new FilterEMI();
    emi.addSubfilter(EMI_Modes, EMI_Names, NULL, EMI_Types
        , EMI_TimeFrame, EMI_Trigger
        , EMI_EmiPeriod, EMI_EmiMaPeriod
        , EMI_Shift, EMI_Limit, EMI_SlopeThreshold, EMI_SlopeSource
        );
    Main.addFilter(emi);
    
    FilterVPCI* vpci = new FilterVPCI();
    vpci.addSubfilter(VPCI_Modes, VPCI_Names, NULL, VPCI_Types
        , VPCI_TimeFrame, VPCI_Trigger
        , VPCI_ShortPeriod, VPCI_LongPeriod
        , VPCI_Shift, VPCI_Limit, VPCI_SlopeThreshold, VPCI_SlopeSource
        );
    Main.addFilter(vpci);
}