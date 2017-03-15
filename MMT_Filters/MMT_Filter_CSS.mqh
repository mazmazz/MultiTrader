//+------------------------------------------------------------------+
//|                                                            MMT_Filter_Stoch.mqh |
//|                                                        Copyright 2017, Marco Z |
//|                                                            https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link        "https://www.mql5.com"
#property strict

#include "MMT_Filters.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../MMT_Data/MMT_DataUnit.mqh"
#include "../depends/PipFactor.mqh"
#include "depends/LibCSS.mqh"

class FilterCss : public Filter {
     private:
     bool isInit;
     int timeFrame[];
     int shift[];
     int maPeriod[];
     int atrPeriod[];
     int calcMethod[];
     
     public:
     void init();
     bool calculate(int subfilterIndex, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+
// Params
//+------------------------------------------------------------------+

extern string Lbl_CSS="________ CSS Settings [CSS] ________";
extern string CSS_Entry_Modes="a=1|b=1";
extern string CSS_Entry_Names="a=H1|b=H1SS";
extern string CSS_Exit_Modes="a=1|b=1";
extern string CSS_Exit_Names="a=H1x|b=H1SSx";

extern string Lbl_CSS_General_Settings="---- CSS General Settings ----";
extern string CSS_SymbolsToWeigh = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURJPY,EURNZD,EURUSD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,GBPUSD,NZDCHF,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY";
extern bool   CSS_AddSundayToMonday = true;

extern string Lbl_CSS_Entry_Settings="---- CSS Entry Settings ----";
extern string CSS_Entry_TimeFrame="a=60|b=60";
extern string CSS_Entry_Shift="a=0|b=0";
extern string CSS_Entry_MaPeriod="a=21|b=7";
extern string CSS_Entry_AtrPeriod="a=100|b=50";
extern string CSS_Entry_CalcMethod="a=0|b=2";

extern string Lbl_CSS_Exit_Settings="---- CSS Exit Settings ----";
extern string CSS_Exit_TimeFrame="a=60|b=60";
extern string CSS_Exit_Shift="a=0|b=0";
extern string CSS_Exit_MaPeriod="a=21|b=7";
extern string CSS_Exit_AtrPeriod="a=100|b=50";
extern string CSS_Exit_CalcMethod="a=0|b=2";


//+------------------------------------------------------------------+
// Methods
//+------------------------------------------------------------------+

void FilterCss::init() {
     if(isInit) { return; }
     
     // 1. Define a shortName -- other settings will refer to this filter using this name (case-insensitive).
     shortName = "CSS";
     
     // 2. Call setupSubfilters for every type offered -- entry, exit, and/or value.
     setupSubfilters(CSS_Entry_Modes, CSS_Entry_Names, SubfilterEntry);
     setupSubfilters(CSS_Exit_Modes, CSS_Exit_Names, SubfilterExit);
     
     // 3. Set up options per subfilter type.
     int entrySubfilterCount = subfilterCount(SubfilterEntry);
     int exitSubfilterCount = subfilterCount(SubfilterExit);
     if(entrySubfilterCount > 0) {
          MultiSettings::Parse(CSS_Entry_TimeFrame, timeFrame, entrySubfilterCount);
          MultiSettings::Parse(CSS_Entry_Shift, shift, entrySubfilterCount);
          MultiSettings::Parse(CSS_Entry_MaPeriod, maPeriod, entrySubfilterCount);
          MultiSettings::Parse(CSS_Entry_AtrPeriod, atrPeriod, entrySubfilterCount);
          MultiSettings::Parse(CSS_Entry_CalcMethod, calcMethod, entrySubfilterCount);
     }
     
     if(exitSubfilterCount > 0) {
          MultiSettings::Parse(CSS_Exit_TimeFrame, timeFrame, exitSubfilterCount);
          MultiSettings::Parse(CSS_Exit_Shift, shift, exitSubfilterCount);
          MultiSettings::Parse(CSS_Exit_MaPeriod, maPeriod, exitSubfilterCount);
          MultiSettings::Parse(CSS_Exit_AtrPeriod, atrPeriod, exitSubfilterCount);
          MultiSettings::Parse(CSS_Exit_CalcMethod, calcMethod, exitSubfilterCount);
     }
     
     // CSS global settings
     libCSS_symbolsToWeigh = CSS_SymbolsToWeigh;
     libCSS_addSundayToMonday = CSS_AddSundayToMonday;
     libCSS_init();
          
     isInit = true;
}

bool FilterCss::calculate(int subfilterIndex, int symbolIndex, DataUnit *dataOut) {
     if(!checkSafe(subfilterIndex)) { return false; }
     string symbol = MainSymbolMan.symbols[symbolIndex].formSymName;
     
     libCSS_useCalcMethod = calcMethod[subfilterIndex];
     double value = libCSS_getCSSCurrency(
        symbol
        , MainSymbolMan.symbols[symbolIndex].baseCurName
        , timeFrame[subfilterIndex]
        , maPeriod[subfilterIndex]
        , atrPeriod[subfilterIndex]
        , shift[subfilterIndex]
        );
     
     dataOut.setRawValue(value, 0, DoubleToString(value, 2));
     
     return true;
}
