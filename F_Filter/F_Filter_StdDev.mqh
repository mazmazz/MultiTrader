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

class FilterStdDev : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int period[];
    int shift[];
    int method[];
    int appliedPrice[];
    int periodShift[];
#ifdef __MQL5__
    ArrayDim<int> iStdDevHandle[];
#endif

    public:
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif
    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+
// Params
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
// Methods
//+------------------------------------------------------------------+

void FilterStdDev::init() {
    if(isInit) { return; }
    
    // 1. Define a shortName -- other settings will refer to this filter using this name (case-insensitive).
    shortName = "StdDev";
    
    // 2. Call setupSubfilters for every type offered -- entry, exit, and/or value.
    setupSubfilters(StdDev_Value_Modes, StdDev_Value_Names, StdDev_Value_Hidden, SubfilterValue);
    
    // 3. Set up options per subfilter type.
    int valueSubfilterCount = getSubfilterCount(SubfilterValue);
    if(valueSubfilterCount > 0) {
        MultiSettings::Parse(StdDev_Value_TimeFrame, timeFrame, valueSubfilterCount);
        MultiSettings::Parse(StdDev_Value_Period, period, valueSubfilterCount);
        MultiSettings::Parse(StdDev_Value_Shift, shift, valueSubfilterCount);
        MultiSettings::Parse(StdDev_Value_Method, method, valueSubfilterCount);
        MultiSettings::Parse(StdDev_Value_AppliedPrice, appliedPrice, valueSubfilterCount);
        MultiSettings::Parse(StdDev_Value_PeriodShift, periodShift, valueSubfilterCount);
    }
    
#ifdef __MQL5__
    loadIndicatorHandles(iStdDevHandle);
#endif

    isInit = true;
}

#ifdef __MQL5__
void FilterStdDev::deInit() {
    unloadIndicatorHandles(iStdDevHandle);

    isInit = false;
}

int FilterStdDev::getNewIndicatorHandle(int symIdx, int subIdx) {
    return iStdDev(
        MainSymbolMan.symbols[symIdx].name
        , GetMql5TimeFrame(timeFrame[subIdx])
        , period[subIdx]
        , shift[subIdx]
        , (ENUM_MA_METHOD)method[subIdx]
        , appliedPrice[subIdx]
        );
}
#endif

bool FilterStdDev::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
#ifdef __MQL5__
    if(iStdDevHandle[symbolIndex]._[subfilterId] == INVALID_HANDLE) { return false; }
    double value = NormalizeDouble(
        Common::GetSingleValueFromBuffer(iStdDevHandle[symbolIndex]._[subfilterId], periodShift[subfilterId])
        , MarketInfo(symbol, MODE_DIGITS)
        );
#else
#ifdef __MQL4__
    double value = NormalizeDouble(
        iStdDev(
            symbol
            , timeFrame[subfilterId]
            , period[subfilterId]
            , shift[subfilterId]
            , method[subfilterId]
            , appliedPrice[subfilterId]
            , periodShift[subfilterId]
            )
        , MarketInfo(symbol, MODE_DIGITS)
        );
#endif
#endif
    
    double pips = NormalizeDouble(PriceToPips(symbol, value), 2);
    dataOut.setRawValue(pips, SignalNone, DoubleToString(pips, 1));
    
    return true;
}
