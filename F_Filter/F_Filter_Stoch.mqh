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

class FilterStoch : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int kPeriod[];
    int dPeriod[];
    int slowing[];
    int method[];
    int priceField[];
    int shift[];
    double buySellZone[];
#ifdef __MQL5__
    ArrayDim<int> iStochHandle[];
#endif
    
    public:
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif

    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , int kPeriodIn
        , int dPeriodIn
        , int slowingIn
        , int methodIn
        , int priceFieldIn
        , int shiftIn
        , double buySellZoneIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string timeFrameList
        , string kPeriodList
        , string dPeriodList
        , string slowingList
        , string methodList
        , string priceFieldList
        , string shiftList
        , string buySellZoneList
        , bool addToExisting = false
    );

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterStoch::init() {
    if(isInit) { return; }
    
    shortName = "Stoch";
    
#ifdef __MQL5__
    loadIndicatorHandles(iStochHandle);
#endif
    
    isInit = true;
}

#ifdef __MQL4__
void FilterStoch::deInit() { }
#else
#ifdef __MQL5__
void FilterStoch::deInit() {
    unloadIndicatorHandles(iStochHandle);

    isInit = false;
}

int FilterStoch::getNewIndicatorHandle(int symIdx, int subIdx) {
    return iStochastic(
        MainSymbolMan.symbols[symIdx].name
        , GetMql5TimeFrame(timeFrame[subIdx])
        , kPeriod[subIdx]
        , dPeriod[subIdx]
        , slowing[subIdx]
        , (ENUM_MA_METHOD)method[subIdx]
        , (ENUM_STO_PRICE)priceField[subIdx]
        );
}
#endif
#endif

//+------------------------------------------------------------------+

void FilterStoch::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , int kPeriodIn
    , int dPeriodIn
    , int slowingIn
    , int methodIn
    , int priceFieldIn
    , int shiftIn
    , double buySellZoneIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(kPeriod, kPeriodIn);
    Common::ArrayPush(dPeriod, dPeriodIn);
    Common::ArrayPush(slowing, slowingIn);
    Common::ArrayPush(method, methodIn);
    Common::ArrayPush(priceField, priceFieldIn);
    Common::ArrayPush(shift, shiftIn);
    Common::ArrayPush(buySellZone, buySellZoneIn);
}

void FilterStoch::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string timeFrameList
    , string kPeriodList
    , string dPeriodList
    , string slowingList
    , string methodList
    , string priceFieldList
    , string shiftList
    , string buySellZoneList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(kPeriodList, kPeriod, count, addToExisting);
        MultiSettings::Parse(dPeriodList, dPeriod, count, addToExisting);
        MultiSettings::Parse(slowingList, slowing, count, addToExisting);
        MultiSettings::Parse(methodList, method, count, addToExisting);
        MultiSettings::Parse(priceFieldList, priceField, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
        MultiSettings::Parse(buySellZoneList, buySellZone, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

bool FilterStoch::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
#ifdef __MQL5__
    if(iStochHandle[symbolIndex]._[subfilterId] == INVALID_HANDLE) { return false; }
    double value = NormalizeDouble(
        Common::GetSingleValueFromBuffer(iStochHandle[symbolIndex]._[subfilterId], shift[subfilterId], 0)
        , MarketInfo(symbol, MODE_DIGITS)
        );
#else
#ifdef __MQL4__
    double value = iStochastic(
        symbol
        , timeFrame[subfilterId]
        , kPeriod[subfilterId]
        , dPeriod[subfilterId]
        , slowing[subfilterId]
        , method[subfilterId]
        , priceField[subfilterId]
        , 0
        , shift[subfilterId]
        );
#endif
#endif
    
    double lowerZone = buySellZone[subfilterId];
    double upperZone = 100-buySellZone[subfilterId];
    
    SignalType signal = 
        value <= lowerZone ? SignalBuy
        : value >= upperZone ? SignalSell
        : SignalNone
        ;
    
    dataOut.setRawValue(value, signal, DoubleToString(value, 2));
    
    return true;
}
