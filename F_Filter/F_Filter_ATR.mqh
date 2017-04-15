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
#ifdef __MQL5__
    ArrayDim<int> iAtrHandle[];
#endif
    
    public:
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif

    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , int periodIn
        , int shiftIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string timeFrameList
        , string periodList
        , string shiftList
        , bool addToExisting = false
    );

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterAtr::init() {
    if(isInit) { return; }
    
    shortName = "ATR";

#ifdef __MQL5__
    loadIndicatorHandles(iAtrHandle);
#endif

    isInit = true;
}

#ifdef __MQL5__
void FilterAtr::deInit() {
    unloadIndicatorHandles(iAtrHandle);

    isInit = false;
}

int FilterAtr::getNewIndicatorHandle(int symIdx, int subIdx) {
    return iATR(MainSymbolMan.symbols[symIdx].name, GetMql5TimeFrame(timeFrame[subIdx]), period[subIdx]);
}
#endif

//+------------------------------------------------------------------+

void FilterAtr::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , int periodIn
    , int shiftIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(period, periodIn);
    Common::ArrayPush(shift, shiftIn);
}

void FilterAtr::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string timeFrameList
    , string periodList
    , string shiftList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(periodList, period, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

bool FilterAtr::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
#ifdef __MQL5__
    if(iAtrHandle[symbolIndex]._[subfilterId] == INVALID_HANDLE) { return false; }
    double value = NormalizeDouble(
        Common::GetSingleValueFromBuffer(iAtrHandle[symbolIndex]._[subfilterId], shift[subfilterId])
        , MarketInfo(symbol, MODE_DIGITS)
        );
#else
#ifdef __MQL4__
    double value = NormalizeDouble(
        iATR(symbol, timeFrame[subfilterId], period[subfilterId], shift[subfilterId])
        , MarketInfo(symbol, MODE_DIGITS)
        );
#endif
#endif
    
    double pips = NormalizeDouble(PriceToPips(symbol, value), 2);
    dataOut.setRawValue(pips, SignalNone, DoubleToString(pips, 1));
    
    return true;
}
