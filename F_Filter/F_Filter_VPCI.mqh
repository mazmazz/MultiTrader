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

enum ENUM_VPCI_TRIGGER {
    TRIGGER_VPCI_SLOPE
};

enum ENUM_VPCI_BUFFER {
    BUFFER_VPCI
    , BUFFER_VPCI_SMOOTHED
};

class FilterVPCI : public Filter {
    private:
    bool isInit;
    int bufferSize;
    
    int timeFrame[];
    ENUM_VPCI_TRIGGER trigger[];
    
    int shortPeriod[];
    int longPeriod[];
    
    int shift[];
    int limit[];
    double slopeThreshold[];
    ENUM_VPCI_BUFFER slopeSource[];
    
#ifdef __MQL5__
    ArrayDim<int> iVPCIHandle[];
#endif
    
    double calcSlope(int subIdx, int symIdx, int shift, int limit, /*int interval, */ ENUM_VPCI_BUFFER buffer);
    
    double calcSlopeByPoints(double pointAy, double pointBy, double pointAx = 0, double pointBx = 1) ;
    
    public:
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif

    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , ENUM_VPCI_TRIGGER triggerIn
        , int shortPeriodIn
        , int longPeriodIn
        , int shiftIn
        , int limitIn
        , double slopeThresholdIn
        , ENUM_VPCI_BUFFER slopeSourceIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string timeFrameList
        , string triggerList
        , string shortPeriodList
        , string longPeriodList
        , string shiftList
        , string limitList
        , string slopeThresholdList
        , string slopeSourceList
        , bool addToExisting = false
    );
    
    int iVPCI(
        string symbol
        , ENUM_TIMEFRAMES tf
        , int shortPeriodIn = 10
        , int longPeriodIn = 50
        , ENUM_APPLIED_PRICE basePriceTypeIn = PRICE_CLOSE
        , ENUM_APPLIED_VOLUME volumeTypeIn = VOLUME_TICK
    );
    
    bool isSubfilterMatching(int compareIdx, int subIdx);

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterVPCI::init() {
    if(isInit) { return; }
    
    bufferSize = 3;
    shortName = "VPCI";
    consolidateHandles = true;
    
#ifdef __MQL5__
    loadIndicatorHandles(iVPCIHandle);
#endif
    
    isInit = true;
}

void FilterVPCI::deInit() {
#ifdef __MQL5__
    unloadIndicatorHandles(iVPCIHandle);
#endif
    isInit = false;
}

#ifdef __MQL5__
int FilterVPCI::getNewIndicatorHandle(int symIdx, int subIdx) {
    return iVPCI(
        MainSymbolMan.symbols[symIdx].name
        , GetMql5TimeFrame(timeFrame[subIdx])
        , shortPeriod[symIdx]
        , longPeriod[symIdx]
        // , priceType[symIdx]
        // , volumeType[symIdx]
        );
}
#endif

//+------------------------------------------------------------------+

int FilterVPCI::iVPCI(
    string symbol
    , ENUM_TIMEFRAMES tf
    , int shortPeriodIn = 10
    , int longPeriodIn = 50
    , ENUM_APPLIED_PRICE basePriceTypeIn = PRICE_CLOSE
    , ENUM_APPLIED_VOLUME volumeTypeIn = VOLUME_TICK
) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    MqlParam params[];
    ArrayResize(params, 5);
    params[0].type = TYPE_STRING; 
    params[0].string_value = "VolumeTools/VPCI";
    params[1].type = TYPE_INT; //input int ShortPeriod = 10;
    params[1].integer_value = shortPeriodIn;
    params[2].type = TYPE_INT; //input int LongPeriod = 50;
    params[2].integer_value = longPeriodIn;
    params[3].type = TYPE_INT; //input ENUM_APPLIED_PRICE BasePriceType = PRICE_CLOSE;
    params[3].integer_value = (int)basePriceTypeIn;
    params[4].type = TYPE_INT; //input ENUM_APPLIED_VOLUME BaseVolumeType = VOLUME_TICK;
    params[4].integer_value = (int)volumeTypeIn;
    
    return IndicatorCreate(symbol, tf, IND_CUSTOM, ArraySize(params), params);
#endif
#endif
}

//+------------------------------------------------------------------+

void FilterVPCI::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , ENUM_VPCI_TRIGGER triggerIn
    , int shortPeriodIn
    , int longPeriodIn
    , int shiftIn
    , int limitIn
    , double slopeThresholdIn
    , ENUM_VPCI_BUFFER slopeSourceIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(trigger, (ENUM_VPCI_TRIGGER)triggerIn);
    Common::ArrayPush(shortPeriod, shortPeriodIn);
    Common::ArrayPush(longPeriod, longPeriodIn);
    Common::ArrayPush(shift, shiftIn);
    Common::ArrayPush(limit, limitIn);
    Common::ArrayPush(slopeThreshold, slopeThresholdIn);
    Common::ArrayPush(slopeSource, (ENUM_VPCI_BUFFER)slopeSourceIn);
}

void FilterVPCI::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string timeFrameList
    , string triggerList
    , string shortPeriodList
    , string longPeriodList
    , string shiftList
    , string limitList
    , string slopeThresholdList
    , string slopeSourceList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(triggerList, trigger, count, addToExisting);
        MultiSettings::Parse(shortPeriodList, shortPeriod, count, addToExisting);
        MultiSettings::Parse(longPeriodList, longPeriod, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
        MultiSettings::Parse(limitList, limit, count, addToExisting);
        MultiSettings::Parse(slopeThresholdList, slopeThreshold, count, addToExisting);
        MultiSettings::Parse(slopeSourceList, slopeSource, count, addToExisting);
    }
}

bool FilterVPCI::isSubfilterMatching(int compareIdx, int subIdx) {
    return timeFrame[compareIdx] == timeFrame[subIdx]
        && shortPeriod[compareIdx] == shortPeriod[subIdx]
        && longPeriod[compareIdx] == longPeriod[subIdx]
        ;
}

//+------------------------------------------------------------------+

bool FilterVPCI::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
    SignalType signal = SignalNone;
    string statusText = "";
    
    switch(trigger[subfilterId]) {
        case TRIGGER_VPCI_SLOPE: {
            double slope = calcSlope(subfilterId, symbolIndex, shift[subfilterId], limit[subfilterId], slopeSource[subfilterId]);
            double threshold = PipsToPrice(symbol, slopeThreshold[subfilterId]);
            
            if(slope < threshold*-1) {
                signal = SignalSell;
            } else if(slope > threshold) {
                signal = SignalBuy;
            } else {
                signal = SignalNone;
            }
            
            statusText = DoubleToString(PriceToPips(symbol, slope), 2);
            break;
        }
    }
    
    dataOut.setRawValue(statusText, signal);
    
    return true;
}

double FilterVPCI::calcSlope(int subIdx, int symIdx, int shift, int limit, /*int interval, */ ENUM_VPCI_BUFFER bufferIdx) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    double read[]; ArraySetAsSeries(read, true);
    if(CopyBuffer(iVPCIHandle[symIdx]._[subIdx], (int)bufferIdx, 0+shift, limit+1, read) < limit+1) { return 0; }
    else { return calcSlopeByPoints(read[ArraySize(read)-1], read[0]); }
#endif
#endif
}

double FilterVPCI::calcSlopeByPoints(double pointAy, double pointBy, double pointAx = 0, double pointBx = 1) {
    return (pointBy-pointAy)/(pointBx-pointAx);
}