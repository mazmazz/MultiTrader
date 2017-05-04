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
    ~FilterStdDev();
    
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif

    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , int periodIn
        , int shiftIn
        , int methodIn
        , int appliedPriceIn
        , int periodShiftIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string timeFrameList
        , string periodList
        , string shiftList
        , string methodList
        , string appliedPriceList
        , string periodShiftList
        , bool addToExisting = false
    );

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterStdDev::~FilterStdDev() {
    deInit();
}

void FilterStdDev::init() {
    if(isInit) { return; }
    
    shortName = "StdDev";
    
#ifdef __MQL5__
    loadIndicatorHandles(iStdDevHandle);
#endif

    isInit = true;
}

#ifdef __MQL4__
void FilterStdDev::deInit() { }
#else
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
#endif

//+------------------------------------------------------------------+

void FilterStdDev::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , int periodIn
    , int shiftIn
    , int methodIn
    , int appliedPriceIn
    , int periodShiftIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(period, periodIn);
    Common::ArrayPush(shift, shiftIn);
    Common::ArrayPush(method, methodIn);
    Common::ArrayPush(appliedPrice, appliedPriceIn);
    Common::ArrayPush(periodShift, periodShiftIn);
}

void FilterStdDev::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string timeFrameList
    , string periodList
    , string shiftList
    , string methodList
    , string appliedPriceList
    , string periodShiftList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(periodList, period, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
        MultiSettings::Parse(methodList, method, count, addToExisting);
        MultiSettings::Parse(appliedPriceList, appliedPrice, count, addToExisting);
        MultiSettings::Parse(periodShiftList, periodShift, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

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
