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
#include <LibVolume.mqh>

class FilterVwap : public Filter {
    private:
    int timeFrame[];
    int period[];
    
    ENUM_APPLIED_PRICE priceType[];
    ENUM_APPLIED_VOLUME volumeType[];
    
    double threshold[];
    
    int shift[];
    
    public:
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , int periodIn
        , ENUM_APPLIED_PRICE priceTypeIn
        , ENUM_APPLIED_VOLUME volumeTypeIn
        , double thresholdIn
        , int shiftIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, string typeName
        , string timeFrameList
        , string periodList
        , string priceTypeList
        , string volumeTypeList
        , string thresholdList
        , string shiftList
        , bool addToExisting = false
    );
    
    private:
    bool isInit;
#ifdef __MQL5__
    ArrayDim<int> iVwapHandle[];
#endif
    
    public:
    ~FilterVwap();
    
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif

    int iVWAP(
        string symbol
        , ENUM_TIMEFRAMES tf
        , int periodIn = 10
        , ENUM_APPLIED_PRICE basePriceTypeIn = PRICE_TYPICAL
        , ENUM_APPLIED_VOLUME volumeTypeIn = VOLUME_TICK
    );
    bool isSubfilterMatching(int compareIdx, int subIdx);

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
    bool calcVwap(int subIdx, int symIdx, double &vwapOut);
};

//+------------------------------------------------------------------+

void FilterVwap::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , int periodIn
    , ENUM_APPLIED_PRICE priceTypeIn
    , ENUM_APPLIED_VOLUME volumeTypeIn
    , double thresholdIn
    , int shiftIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(period, periodIn);
    Common::ArrayPush(priceType, (ENUM_APPLIED_PRICE)priceTypeIn);
    Common::ArrayPush(volumeType, (ENUM_APPLIED_VOLUME)volumeTypeIn);
    Common::ArrayPush(threshold, thresholdIn);
    Common::ArrayPush(shift, shiftIn);
}

void FilterVwap::addSubfilter(string modeList, string nameList, string hiddenList, string typeName
    , string timeFrameList
    , string periodList
    , string priceTypeList
    , string volumeTypeList
    , string thresholdList
    , string shiftList
    , bool addToExisting = false
) {
    int count = setupSubfilters(modeList, nameList, hiddenList, typeName);

    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(periodList, period, count, addToExisting);
        MultiSettings::Parse(priceTypeList, priceType, count, addToExisting);
        MultiSettings::Parse(volumeTypeList, volumeType, count, addToExisting);
        MultiSettings::Parse(thresholdList, threshold, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

void FilterVwap::~FilterVwap() {
    deInit();
}

void FilterVwap::init() {
    if(isInit) { return; }
    
    shortName = "VWAP";
    consolidateHandles = true;

#ifdef __MQL5__
    loadIndicatorHandles(iVwapHandle);
#endif

    isInit = true;
}

#ifdef __MQL4__
void FilterVwap::deInit() { }
#else
#ifdef __MQL5__
void FilterVwap::deInit() {
    unloadIndicatorHandles(iVwapHandle);

    isInit = false;
}

int FilterVwap::getNewIndicatorHandle(int symIdx, int subIdx) {
    return iVWAP(MainSymbolMan.symbols[symIdx].name, GetMql5TimeFrame(timeFrame[subIdx]), period[subIdx]);
}
#endif
#endif

int FilterVwap::iVWAP(
    string symbol
    , ENUM_TIMEFRAMES tf
    , int periodIn = 10
    , ENUM_APPLIED_PRICE basePriceTypeIn = PRICE_TYPICAL
    , ENUM_APPLIED_VOLUME volumeTypeIn = VOLUME_TICK
) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    MqlParam params[];
    ArrayResize(params, 4);
    params[0].type = TYPE_STRING; 
    params[0].string_value = "VolumeTools/VWAP";
    params[1].type = TYPE_INT; //input int VwapPeriod = 10;
    params[1].integer_value = periodIn;
    params[2].type = TYPE_INT; //input ENUM_APPLIED_PRICE BasePriceType = PRICE_TYPICAL;
    params[2].integer_value = (int)basePriceTypeIn;
    params[3].type = TYPE_INT; //input ENUM_APPLIED_VOLUME BaseVolumeType = VOLUME_TICK;
    params[3].integer_value = (int)volumeTypeIn;
    
    return IndicatorCreate(symbol, tf, IND_CUSTOM, ArraySize(params), params);
#endif
#endif
}

bool FilterVwap::isSubfilterMatching(int compareIdx, int subIdx) {
    return timeFrame[compareIdx] == timeFrame[subIdx]
        && period[compareIdx] == period[subIdx]
        && priceType[compareIdx] == priceType[subIdx]
        && volumeType[compareIdx] == volumeType[subIdx]
        ;
}

//+------------------------------------------------------------------+

bool FilterVwap::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
    SignalType signalVal = SignalNone;
    double pips = 0;
    double thresholdVal = PipsToPrice(symbol, threshold[subfilterId]);
    double vwapVal = 0;
    if(!calcVwap(subfilterId, symbolIndex, vwapVal)) { return false; }
    
    if(SymbolInfoDouble(symbol, SYMBOL_ASK) <= vwapVal) {
        signalVal = SignalBuy;
        pips = PriceToPips(symbol, vwapVal - SymbolInfoDouble(symbol, SYMBOL_ASK));
    } else if(SymbolInfoDouble(symbol, SYMBOL_BID) >= vwapVal) {
        signalVal = SignalSell;
        pips = PriceToPips(symbol, SymbolInfoDouble(symbol, SYMBOL_BID) - vwapVal);
    } else {
        signalVal = SignalNone;
        pips = 0;
    }
        
    dataOut.setRawValue(pips, signalVal, DoubleToString(pips, 1));
    
    return true;
}

bool FilterVwap::calcVwap(int subIdx, int symIdx, double &vwapOut) {
    string symbol = MainSymbolMan.symbols[symIdx].name;
    
#ifdef __MQL4__
    vwapOut = 0;
    return false;
#else
#ifdef __MQL5__
    if(iVwapHandle[symIdx]._[subIdx] == INVALID_HANDLE) { return false; }
    vwapOut = NormalizeDouble(
        Common::GetSingleValueFromBuffer(iVwapHandle[symIdx]._[subIdx], shift[subIdx])
        , SymbolInfoInteger(symbol, SYMBOL_DIGITS)
        );
    return vwapOut != 0; //true;
#endif
}