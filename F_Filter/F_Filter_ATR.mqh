//+------------------------------------------------------------------+
//|                                             F_Filter_Stoch.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "F_Filter.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../D_Data/D_DataUnit.mqh"
#include "../S_Symbol.mqh"
#include "../depends/PipFactor.mqh"

class FilterAtr : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int period[];
    int shift[];
    
    public:
    void init();
    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+
// Params
//+------------------------------------------------------------------+

extern string Lbl_ATR="________ ATR Settings [ATR] ________";
extern string ATR_Value_Modes="a=1|b=1|c=1";
extern string ATR_Value_Names="a=H1|b=H4|c=D1";
extern string ATR_Value_Hidden="a=0|b=0|c=0";

extern string Lbl_ATR_Value_Settings="---- ATR Value Settings ----";
extern string ATR_Value_TimeFrame="a=60|b=240|c=1440";
extern string ATR_Value_Period="a=20|b=20|c=20";
extern string ATR_Value_Shift="a=0|b=0|c=0";

//+------------------------------------------------------------------+
// Methods
//+------------------------------------------------------------------+

void FilterAtr::init() {
    if(isInit) { return; }
    
    // 1. Define a shortName -- other settings will refer to this filter using this name (case-insensitive).
    shortName = "ATR";
    
    // 2. Call setupSubfilters for every type offered -- entry, exit, and/or value.
    setupSubfilters(ATR_Value_Modes, ATR_Value_Names, ATR_Value_Hidden, SubfilterValue);
    
    // 3. Set up options per subfilter type.
    int valueSubfilterCount = getSubfilterCount(SubfilterValue);
    if(valueSubfilterCount > 0) {
        MultiSettings::Parse(ATR_Value_TimeFrame, timeFrame, valueSubfilterCount);
        MultiSettings::Parse(ATR_Value_Period, period, valueSubfilterCount);
        MultiSettings::Parse(ATR_Value_Shift, shift, valueSubfilterCount);
    }
    
    isInit = true;
}

bool FilterAtr::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
#ifdef __MQL5__
    int iAtrHandle = iATR(symbol, GetMql5TimeFrame(timeFrame[subfilterId]), period[subfilterId]);
    if(iAtrHandle == INVALID_HANDLE) { return false; }
    double value = NormalizeDouble(
        Common::GetSingleValueFromBuffer(iAtrHandle, shift[subfilterId])
        , MarketInfo(symbol, MODE_DIGITS)
        );
    IndicatorRelease(iAtrHandle);
#else
#ifdef __MQL4__
    double value = NormalizeDouble(
        iATR(symbol, timeFrame[subfilterId], period[subfilterId], shift[subfilterId])
        , MarketInfo(symbol, MODE_DIGITS)
        );
#endif
#endif
    
    double pips = NormalizeDouble(PriceToPips(symbol, value), 2);
    dataOut.setRawValue(pips, SignalNone, DoubleToStr(pips, 1));
    
    return true;
}
