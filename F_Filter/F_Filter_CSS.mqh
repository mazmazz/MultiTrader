//+------------------------------------------------------------------+
//|                                                            F_Filter_Stoch.mqh |
//|                                                        Copyright 2017, Marco Z |
//|                                                            https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link        "https://www.mql5.com"
#property strict

#include "F_Filter.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../D_Data/D_DataUnit.mqh"
#include "../S_Symbol.mqh"
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
     bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+
// Params
//+------------------------------------------------------------------+

input string Lbl_CSS="________ CSS Settings [CSS] ________";
input string CSS_Entry_Modes="a=1|b=1";
input string CSS_Entry_Names="a=H1|b=H1SS";
input string CSS_Exit_Modes="a=1|b=1";
input string CSS_Exit_Names="a=H1x|b=H1SSx";

input string Lbl_CSS_General_Settings="---- CSS General Settings ----";
input string CSS_SymbolsToWeigh = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURJPY,EURNZD,EURUSD,GBPAUD,GBPCAD,GBPCHF,GBPJPY,GBPNZD,GBPUSD,NZDCHF,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY"; // CSS_SymbolsToWeigh: Leave blank to weigh all symbols

input string Lbl_CSS_Entry_Settings="---- CSS Entry Settings ----";
input string CSS_Entry_TimeFrame="a=60|b=60";
input string CSS_Entry_Shift="a=0|b=0";
input string CSS_Entry_MaPeriod="a=21|b=7";
input string CSS_Entry_AtrPeriod="a=100|b=50";
input string CSS_Entry_CalcMethod="a=0|b=2";

input string Lbl_CSS_Exit_Settings="---- CSS Exit Settings ----";
input string CSS_Exit_TimeFrame="a=60|b=60";
input string CSS_Exit_Shift="a=0|b=0";
input string CSS_Exit_MaPeriod="a=21|b=7";
input string CSS_Exit_AtrPeriod="a=100|b=50";
input string CSS_Exit_CalcMethod="a=0|b=2";


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
     int entrySubfilterCount = getSubfilterCount(SubfilterEntry);
     int exitSubfilterCount = getSubfilterCount(SubfilterExit);
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
     libCSS_init();
          
     isInit = true;
}

bool FilterCss::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
     if(!checkSafe(subfilterId)) { return false; }
     string symbol = MainSymbolMan.symbols[symbolIndex].name;
     
     libCSS_useCalcMethod = calcMethod[subfilterId];
     double value = libCSS_getCSSCurrency(
        symbol
        , MainSymbolMan.symbols[symbolIndex].baseCurName
        , timeFrame[subfilterId]
        , maPeriod[subfilterId]
        , atrPeriod[subfilterId]
        , shift[subfilterId]
        );
     
     dataOut.setRawValue(value, 0, DoubleToString(value, 2));
     
     return true;
}
