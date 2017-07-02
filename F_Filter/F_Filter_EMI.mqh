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

enum ENUM_EMI_TRIGGER {
    TRIGGER_SLOPE
};

enum ENUM_EMI_BUFFER {
    BUFFER_EMI
    , BUFFER_EMI_MA
};

class FilterEMI : public Filter {
    private:
    int timeFrame[];
    ENUM_EMI_TRIGGER trigger[];
    int emiPeriod[];
    int emiMaPeriod[];
    int shift[];
    int limit[];
    double slopeThreshold[];
    ENUM_EMI_BUFFER slopeSource[];
    
    public:
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , ENUM_EMI_TRIGGER triggerIn
        , int emiPeriodIn
        , int emiMaPeriodIn
        , int shiftIn
        , int limitIn
        , double slopeThresholdIn
        , ENUM_EMI_BUFFER slopeSourceIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, string typeList
        , string timeFrameList
        , string triggerList
        , string emiPeriodList
        , string emiMaPeriodList
        , string shiftList
        , string limitList
        , string slopeThresholdList
        , string slopeSourceList
        , bool addToExisting = false
    );
    
    private:
    bool isInit;
    int bufferSize;
    
#ifdef __MQL5__
    ArrayDim<int> iEMIHandle[];
#endif
    
    double calcSlope(int subIdx, int symIdx, int shift, int limit, /*int interval, */ ENUM_EMI_BUFFER buffer);
    
    double calcSlopeByPoints(double pointAy, double pointBy, double pointAx = 0, double pointBx = 1) ;
    
    public:
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif
    
    int iEMI(
        string symbol
        , ENUM_TIMEFRAMES tf
        , int emiPeriodIn = 14
        , int emiMaPeriodIn = 9
        //, ENUM_APPLIED_VOLUME volumeTypeIn = VOLUME_TICK
    );
    
    bool isSubfilterMatching(int compareIdx, int subIdx);

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterEMI::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , ENUM_EMI_TRIGGER triggerIn
    , int emiPeriodIn
    , int emiMaPeriodIn
    , int shiftIn
    , int limitIn
    , double slopeThresholdIn
    , ENUM_EMI_BUFFER slopeSourceIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(trigger, (ENUM_EMI_TRIGGER)triggerIn);
    Common::ArrayPush(emiPeriod, emiPeriodIn);
    Common::ArrayPush(emiMaPeriod, emiMaPeriodIn);
    Common::ArrayPush(shift, shiftIn);
    Common::ArrayPush(limit, limitIn);
    Common::ArrayPush(slopeThreshold, slopeThresholdIn);
    Common::ArrayPush(slopeSource, (ENUM_EMI_BUFFER)slopeSourceIn);
}

void FilterEMI::addSubfilter(string modeList, string nameList, string hiddenList, string typeList
    , string timeFrameList
    , string triggerList
    , string emiPeriodList
    , string emiMaPeriodList
    , string shiftList
    , string limitList
    , string slopeThresholdList
    , string slopeSourceList
    , bool addToExisting = false
) {
    int count = setupSubfilters(modeList, nameList, hiddenList, typeList);
    
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(triggerList, trigger, count, addToExisting);
        MultiSettings::Parse(emiPeriodList, emiPeriod, count, addToExisting);
        MultiSettings::Parse(emiMaPeriodList, emiMaPeriod, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
        MultiSettings::Parse(limitList, limit, count, addToExisting);
        MultiSettings::Parse(slopeThresholdList, slopeThreshold, count, addToExisting);
        MultiSettings::Parse(slopeSourceList, slopeSource, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

void FilterEMI::init() {
    if(isInit) { return; }
    
    bufferSize = 3;
    shortName = "EMI";
    consolidateHandles = true;
    
#ifdef __MQL5__
    loadIndicatorHandles(iEMIHandle);
#endif
    
    isInit = true;
}

void FilterEMI::deInit() {
#ifdef __MQL5__
    unloadIndicatorHandles(iEMIHandle);
#endif
    isInit = false;
}

#ifdef __MQL5__
int FilterEMI::getNewIndicatorHandle(int symIdx, int subIdx) {
    return iEMI(
        MainSymbolMan.symbols[symIdx].name
        , GetMql5TimeFrame(timeFrame[subIdx])
        , emiPeriod[symIdx]
        , emiMaPeriod[symIdx]
        // , volumeType[symIdx]
        );
}
#endif

//+------------------------------------------------------------------+

int FilterEMI::iEMI(
    string symbol
    , ENUM_TIMEFRAMES tf
    , int emiPeriodIn = 14
    , int emiMaPeriodIn = 9
    //, ENUM_APPLIED_VOLUME volumeTypeIn = VOLUME_TICK
) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    MqlParam params[];
    ArrayResize(params, 3);
    params[0].type = TYPE_STRING; 
    params[0].string_value = "VolumeTools/EMI";
    params[1].type = TYPE_INT; //input int EMIPeriod=14;
    params[1].integer_value = emiPeriodIn;
    params[2].type = TYPE_INT; //input int EMIMAPeriod=9;
    params[2].integer_value = emiMaPeriodIn;
    
    return IndicatorCreate(symbol, tf, IND_CUSTOM, ArraySize(params), params);
#endif
#endif
}

//+------------------------------------------------------------------+

bool FilterEMI::isSubfilterMatching(int compareIdx, int subIdx) {
    return timeFrame[compareIdx] == timeFrame[subIdx]
        && emiPeriod[compareIdx] == emiPeriod[subIdx]
        && emiMaPeriod[compareIdx] == emiMaPeriod[subIdx]
        ;
}

//+------------------------------------------------------------------+

bool FilterEMI::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
    SignalType signal = SignalNone;
    string statusText = "";
    
    switch(trigger[subfilterId]) {
        case TRIGGER_SLOPE: {
            double slope = calcSlope(subfilterId, symbolIndex, shift[subfilterId], limit[subfilterId], slopeSource[subfilterId]);
            
            if(slope < slopeThreshold[subfilterId]*-1) {
                signal = SignalSell;
            } else if(slope > slopeThreshold[subfilterId]) {
                signal = SignalBuy;
            } else {
                signal = SignalNone;
            }
            
            statusText = DoubleToString(slope, 2);
            break;
        }
    }
    
    dataOut.setRawValue(statusText, signal);
    
    return true;
}

double FilterEMI::calcSlope(int subIdx, int symIdx, int shift, int limit, /*int interval, */ ENUM_EMI_BUFFER bufferIdx) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    double read[]; ArraySetAsSeries(read, true);
    if(CopyBuffer(iEMIHandle[symIdx]._[subIdx], (int)bufferIdx, 0+shift, limit+1, read) < limit+1) { return 0; }
    else { return calcSlopeByPoints(read[ArraySize(read)-1], read[0]); }
#endif
#endif
}

double FilterEMI::calcSlopeByPoints(double pointAy, double pointBy, double pointAx = 0, double pointBx = 1) {
    return (pointBy-pointAy)/(pointBx-pointAx);
}