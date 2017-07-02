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
//| NVI-PVI
//+------------------------------------------------------------------+

input string Lbl_NVIPVI_1="________ NVI-PVI Settings [NVIPVI] ________"; // :

input string LbL_NVIPVI_Entry="---- NVI-PVI Entry Settings ----"; // :
input string NVIPVI_Entry_Modes="a:1";
input string NVIPVI_Entry_Names="a:M60";
input string NVIPVI_Entry_TimeFrame="a:60";

input string Lbl_NVIPVI_Entry_Indi=""; // :
input string NVIPVI_Entry_Trigger="*:0"; // Trigger 0:Competing 1:Agree
input string NVIPVI_Entry_CalcNvi="*:true";
input string NVIPVI_Entry_NviShortMaPeriod="*:9";
input string NVIPVI_Entry_NviLongMaPeriod="*:0";
input string NVIPVI_Entry_CalcPvi="*:true";
input string NVIPVI_Entry_PviShortMaPeriod="*:9";
input string NVIPVI_Entry_PviLongMaPeriod="*:0";

input string Lbl_NVIPVI_Entry_Options=""; // :
input string NVIPVI_Entry_CalcCurrentIndex="*:true";
input string NVIPVI_Entry_SuppressAllBelowThreshold="*:true";
input string NVIPVI_Entry_Shift="*:1";
input string NVIPVI_Entry_Limit="*:1";
input string NVIPVI_Entry_SlopeThreshold="*:0.4"; // SlopeThreshold: In pips
input string NVIPVI_Entry_SlopeSource="*:2"; // SlopeSource: 0-IndexType 1-Real 2-ShortMA 3-LongMA

input string LbL_NVIPVI_Exit="---- NVI-PVI Exit Settings ----"; // :
input string NVIPVI_Exit_Modes="a:0";
input string NVIPVI_Exit_Names="a:M60";
input string NVIPVI_Exit_TimeFrame="a:60";

input string Lbl_NVIPVI_Exit_Indi=""; // :
input string NVIPVI_Exit_Trigger="*:0"; // Trigger 0:Competing 1:Agree
input string NVIPVI_Exit_CalcNvi="*:true";
input string NVIPVI_Exit_NviShortMaPeriod="*:9";
input string NVIPVI_Exit_NviLongMaPeriod="*:0";
input string NVIPVI_Exit_CalcPvi="*:true";
input string NVIPVI_Exit_PviShortMaPeriod="*:9";
input string NVIPVI_Exit_PviLongMaPeriod="*:0";

input string Lbl_NVIPVI_Exit_Options=""; // :
input string NVIPVI_Exit_CalcCurrentIndex="*:true";
input string NVIPVI_Exit_SuppressAllBelowThreshold="*:true";
input string NVIPVI_Exit_Shift="*:1";
input string NVIPVI_Exit_Limit="*:1";
input string NVIPVI_Exit_SlopeThreshold="*:0.4"; // SlopeThreshold: In pips
input string NVIPVI_Exit_SlopeSource="*:2"; // SlopeSource: 0-IndexType 1-Real 2-ShortMA 3-LongMA

//+------------------------------------------------------------------+
//| Ease of Movement
//+------------------------------------------------------------------+

input string Lbl_EMI_1="________ Ease of Movement Settings [EMI] ________"; // :

input string LbL_EMI_Entry="---- Ease of Movement Entry Settings ----"; // :
input string EMI_Entry_Modes="a:0";
input string EMI_Entry_Names="a:M60";
input string EMI_Entry_TimeFrame="a:60";

input string Lbl_EMI_Entry_Indi=""; // :
input string EMI_Entry_Trigger="*:0"; // Trigger 0:Slope
input string EMI_Entry_EmiPeriod="*:14";
input string EMI_Entry_EmiMaPeriod="*:9";

input string Lbl_EMI_Entry_Options=""; // :
input string EMI_Entry_Shift="*:1";
input string EMI_Entry_Limit="*:1";
input string EMI_Entry_SlopeThreshold="*:0.02";
input string EMI_Entry_SlopeSource="*:1"; // Slope source 0:EMI 1:EMIMA

input string LbL_EMI_Exit="---- Ease of Movement Exit Settings ----"; // :
input string EMI_Exit_Modes="a:0";
input string EMI_Exit_Names="a:M60";
input string EMI_Exit_TimeFrame="a:60";

input string Lbl_EMI_Exit_Indi=""; // :
input string EMI_Exit_Trigger="*:0"; // Trigger 0:Slope
input string EMI_Exit_EmiPeriod="*:14";
input string EMI_Exit_EmiMaPeriod="*:9";

input string Lbl_EMI_Exit_Options=""; // :
input string EMI_Exit_Shift="*:1";
input string EMI_Exit_Limit="*:1";
input string EMI_Exit_SlopeThreshold="*:0.02";
input string EMI_Exit_SlopeSource="*:1"; // Slope source 0:EMI 1:EMIMA

//+------------------------------------------------------------------+
//| VPCI
//+------------------------------------------------------------------+

input string Lbl_VPCI_1="________ Volume Price Confirmation Settings [VPCI] ________"; // :

input string LbL_VPCI_Entry="---- Volume Price Confirmation Entry Settings ----"; // :
input string VPCI_Entry_Modes="a:0";
input string VPCI_Entry_Names="a:M60";
input string VPCI_Entry_TimeFrame="a:60";

input string Lbl_VPCI_Entry_Indi=""; // :
input string VPCI_Entry_Trigger="*:0"; // Trigger 0:Slope
input string VPCI_Entry_ShortPeriod="*:14";
input string VPCI_Entry_LongPeriod="*:9";

input string Lbl_VPCI_Entry_Options=""; // :
input string VPCI_Entry_Shift="*:1";
input string VPCI_Entry_Limit="*:1";
input string VPCI_Entry_SlopeThreshold="*:0.4"; // SlopeThreshold: In pips
input string VPCI_Entry_SlopeSource="*:0"; // Slope source 0:VPCI 1:VPCIS

input string LbL_VPCI_Exit="---- Volume Price Confirmation Exit Settings ----"; // :
input string VPCI_Exit_Modes="a:0";
input string VPCI_Exit_Names="a:M60";
input string VPCI_Exit_TimeFrame="a:60";

input string Lbl_VPCI_Exit_Indi=""; // :
input string VPCI_Exit_Trigger="*:0"; // Trigger 0:Slope
input string VPCI_Exit_ShortPeriod="*:14";
input string VPCI_Exit_LongPeriod="*:9";

input string Lbl_VPCI_Exit_Options=""; // :
input string VPCI_Exit_Shift="*:1";
input string VPCI_Exit_Limit="*:1";
input string VPCI_Exit_SlopeThreshold="*:0.4"; // SlopeThreshold: In pips
input string VPCI_Exit_SlopeSource="*:0"; // Slope source 0:VPCI 1:VPCIS

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
        
    FilterNVIPVI* nvipvi = new FilterNVIPVI();
    nvipvi.addSubfilter(NVIPVI_Entry_Modes, NVIPVI_Entry_Names, NULL, SubfilterEntry
        , NVIPVI_Entry_TimeFrame, NVIPVI_Entry_Trigger
        , NVIPVI_Entry_CalcNvi, NVIPVI_Entry_NviShortMaPeriod, NVIPVI_Entry_NviLongMaPeriod
        , NVIPVI_Entry_CalcPvi, NVIPVI_Entry_PviShortMaPeriod, NVIPVI_Entry_PviLongMaPeriod
        , NVIPVI_Entry_CalcCurrentIndex, NVIPVI_Entry_SuppressAllBelowThreshold
        , NVIPVI_Entry_Shift, NVIPVI_Entry_Limit, NVIPVI_Entry_SlopeThreshold, NVIPVI_Entry_SlopeSource
        );
    nvipvi.addSubfilter(NVIPVI_Exit_Modes, NVIPVI_Exit_Names, NULL, SubfilterExit
        , NVIPVI_Exit_TimeFrame, NVIPVI_Exit_Trigger
        , NVIPVI_Exit_CalcNvi, NVIPVI_Exit_NviShortMaPeriod, NVIPVI_Exit_NviLongMaPeriod
        , NVIPVI_Exit_CalcPvi, NVIPVI_Exit_PviShortMaPeriod, NVIPVI_Exit_PviLongMaPeriod
        , NVIPVI_Exit_CalcCurrentIndex, NVIPVI_Exit_SuppressAllBelowThreshold
        , NVIPVI_Exit_Shift, NVIPVI_Exit_Limit, NVIPVI_Exit_SlopeThreshold, NVIPVI_Entry_SlopeSource
        , true
        );
    Main.addFilter(nvipvi);
    
    FilterEMI* emi = new FilterEMI();
    emi.addSubfilter(EMI_Entry_Modes, EMI_Entry_Names, NULL, SubfilterEntry
        , EMI_Entry_TimeFrame, EMI_Entry_Trigger
        , EMI_Entry_EmiPeriod, EMI_Entry_EmiMaPeriod
        , EMI_Entry_Shift, EMI_Entry_Limit, EMI_Entry_SlopeThreshold, EMI_Entry_SlopeSource
        );
    emi.addSubfilter(EMI_Exit_Modes, EMI_Exit_Names, NULL, SubfilterExit
        , EMI_Exit_TimeFrame, EMI_Exit_Trigger
        , EMI_Exit_EmiPeriod, EMI_Exit_EmiMaPeriod
        , EMI_Exit_Shift, EMI_Exit_Limit, EMI_Exit_SlopeThreshold, EMI_Exit_SlopeSource
        , true
        );
    Main.addFilter(emi);
    
    FilterVPCI* vpci = new FilterVPCI();
    vpci.addSubfilter(VPCI_Entry_Modes, VPCI_Entry_Names, NULL, SubfilterEntry
        , VPCI_Entry_TimeFrame, VPCI_Entry_Trigger
        , VPCI_Entry_ShortPeriod, VPCI_Entry_LongPeriod
        , VPCI_Entry_Shift, VPCI_Entry_Limit, VPCI_Entry_SlopeThreshold, VPCI_Entry_SlopeSource
        );
    vpci.addSubfilter(VPCI_Exit_Modes, VPCI_Exit_Names, NULL, SubfilterExit
        , VPCI_Exit_TimeFrame, VPCI_Exit_Trigger
        , VPCI_Exit_ShortPeriod, VPCI_Exit_LongPeriod
        , VPCI_Exit_Shift, VPCI_Exit_Limit, VPCI_Exit_SlopeThreshold, VPCI_Exit_SlopeSource
        , true
        );
    Main.addFilter(vpci);
}