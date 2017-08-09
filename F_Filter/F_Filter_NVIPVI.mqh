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

enum ENUM_NVIPVI_TRIGGER {
    TRIGGER_COMPETE_SLOPE
    , TRIGGER_AGREE_SLOPE
    , TRIGGER_SELF_SLOPE
};

enum ENUM_NVIPVI_BUFFER {
    BUFFER_INDEXMODE
    , BUFFER_NVI
    , BUFFER_NVI_SHORTMA
    , BUFFER_NVI_LONGMA
    , BUFFER_PVI
    , BUFFER_PVI_SHORTMA
    , BUFFER_PVI_LONGMA
};

enum ENUM_NVIPVI_BUFFER_TYPE {
    BUFFER_TYPE_INDEXMODE
    , BUFFER_TYPE_REAL
    , BUFFER_TYPE_SHORTMA
    , BUFFER_TYPE_LONGMA
};

class FilterNVIPVI : public Filter {
    private:
    int timeFrame[];
    ENUM_NVIPVI_TRIGGER trigger[];
    bool calcNvi[];
    int nviShortMaPeriod[];
    int nviLongMaPeriod[];
    bool calcPvi[];
    int pviShortMaPeriod[];
    int pviLongMaPeriod[];
    
    bool calcCurrentIndex[];
    bool suppressAllBelowThreshold[];
    
    int shift[];
    int limit[];
    double slopeThreshold[];
    ENUM_NVIPVI_BUFFER_TYPE slopeSource[];
    
    public:
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , ENUM_NVIPVI_TRIGGER triggerIn
        , bool calcNviIn
        , int nviShortMaPeriodIn
        , int nviLongMaPeriodIn
        , bool calcPviIn
        , int pviShortMaPeriodIn
        , int pviLongMaPeriodIn
        , bool calcCurrentIndexIn
        , bool suppressAllBelowThresholdIn
        , int shiftIn
        , int limitIn
        , double slopeThresholdIn
        , ENUM_NVIPVI_BUFFER_TYPE slopeSourceIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, string typeList
        , string timeFrameList
        , string triggerList
        , string calcNviList
        , string nviShortMaPeriodList
        , string nviLongMaPeriodList
        , string calcPviList
        , string pviShortMaPeriodList
        , string pviLongMaPeriodList
        , string calcCurrentIndexList
        , string suppressAllBelowThresholdList
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
    ArrayDim<int> iNVIPVIHandle[];
#endif
    
    double calcSlope(int subIdx, int symIdx, int shift, int limit, /*int interval, */ ENUM_NVIPVI_BUFFER buffer);
    double calcSlopeByPoints(double pointAy, double pointBy, double pointAx = 0, double pointBx = 1) ;
    ENUM_NVIPVI_BUFFER getBufferIndexFromType(ENUM_NVIPVI_BUFFER_TYPE bufferType, bool isPvi = false);
    
    public:
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif
    
    int iNVIPVI(
        string symbol
        , ENUM_TIMEFRAMES tf
        , bool calcNviIn = true
        , int nviShortMaPeriodIn = 9
        , int nviLongMaPeriodIn = 255
        , bool calcPviIn = true
        , int pviShortMaPeriodIn = 9
        , int pviLongMaPeriodIn = 255
        , bool calcCurrentIndexIn = true
        , bool normalizeVolumeIn = false
        , int normalPeriodIn = 20
        , double lowVolumeThresholdIn = 0.4
        , ENUM_APPLIED_VOLUME volumeTypeIn = VOLUME_TICK
    );
    
    bool isSubfilterMatching(int compareIdx, int subIdx);

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterNVIPVI::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , ENUM_NVIPVI_TRIGGER triggerIn
    , bool calcNviIn
    , int nviShortMaPeriodIn
    , int nviLongMaPeriodIn
    , bool calcPviIn
    , int pviShortMaPeriodIn
    , int pviLongMaPeriodIn
    , bool calcCurrentIndexIn
    , bool suppressAllBelowThresholdIn
    , int shiftIn
    , int limitIn
    , double slopeThresholdIn
    , ENUM_NVIPVI_BUFFER_TYPE slopeSourceIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(trigger, (ENUM_NVIPVI_TRIGGER)triggerIn);
    Common::ArrayPush(calcNvi, calcNviIn);
    Common::ArrayPush(nviShortMaPeriod, nviShortMaPeriodIn);
    Common::ArrayPush(nviLongMaPeriod, nviLongMaPeriodIn);
    Common::ArrayPush(calcPvi, calcPviIn);
    Common::ArrayPush(pviShortMaPeriod, pviShortMaPeriodIn);
    Common::ArrayPush(pviLongMaPeriod, pviLongMaPeriodIn);
    Common::ArrayPush(calcCurrentIndex, calcCurrentIndexIn);
    Common::ArrayPush(suppressAllBelowThreshold, suppressAllBelowThresholdIn);
    Common::ArrayPush(shift, shiftIn);
    Common::ArrayPush(limit, limitIn);
    Common::ArrayPush(slopeThreshold, slopeThresholdIn);
    Common::ArrayPush(slopeSource, (ENUM_NVIPVI_BUFFER_TYPE)slopeSourceIn);
}

void FilterNVIPVI::addSubfilter(string modeList, string nameList, string hiddenList, string typeList
    , string timeFrameList
    , string triggerList
    , string calcNviList
    , string nviShortMaPeriodList
    , string nviLongMaPeriodList
    , string calcPviList
    , string pviShortMaPeriodList
    , string pviLongMaPeriodList
    , string calcCurrentIndexList
    , string suppressAllBelowThresholdList
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
        MultiSettings::Parse(calcNviList, calcNvi, count, addToExisting);
        MultiSettings::Parse(nviShortMaPeriodList, nviShortMaPeriod, count, addToExisting);
        MultiSettings::Parse(nviLongMaPeriodList, nviLongMaPeriod, count, addToExisting);
        MultiSettings::Parse(calcPviList, calcPvi, count, addToExisting);
        MultiSettings::Parse(pviShortMaPeriodList, pviShortMaPeriod, count, addToExisting);
        MultiSettings::Parse(pviLongMaPeriodList, pviLongMaPeriod, count, addToExisting);
        MultiSettings::Parse(calcCurrentIndexList, calcCurrentIndex, count, addToExisting);
        MultiSettings::Parse(suppressAllBelowThresholdList, suppressAllBelowThreshold, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
        MultiSettings::Parse(limitList, limit, count, addToExisting);
        MultiSettings::Parse(slopeThresholdList, slopeThreshold, count, addToExisting);
        MultiSettings::Parse(slopeSourceList, slopeSource, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

void FilterNVIPVI::init() {
    if(isInit) { return; }
    
    bufferSize = 3;
    shortName = "NVIPVI";
    consolidateHandles = true;
    
#ifdef __MQL5__
    loadIndicatorHandles(iNVIPVIHandle);
#endif
    
    isInit = true;
}

void FilterNVIPVI::deInit() {
#ifdef __MQL5__
    unloadIndicatorHandles(iNVIPVIHandle);
#endif
    isInit = false;
}

#ifdef __MQL5__
int FilterNVIPVI::getNewIndicatorHandle(int symIdx, int subIdx) {
    return iNVIPVI(
        MainSymbolMan.symbols[symIdx].name
        , GetMql5TimeFrame(timeFrame[subIdx])
        , calcNvi[subIdx]
        , nviShortMaPeriod[subIdx]
        , nviLongMaPeriod[subIdx]
        , calcPvi[subIdx]
        , pviShortMaPeriod[subIdx]
        , pviLongMaPeriod[subIdx]
        , calcCurrentIndex[subIdx]
        // , normalizeVolume[subIdx]
        // , normalPeriod[subIdx]
        // , lowVolumeThreshold[subIdx]
        // , volumeType[subIdx]
        );
}
#endif

//+------------------------------------------------------------------+

int FilterNVIPVI::iNVIPVI(
    string symbol
    , ENUM_TIMEFRAMES tf
    , bool calcNviIn = true
    , int nviShortMaPeriodIn = 9
    , int nviLongMaPeriodIn = 255
    , bool calcPviIn = true
    , int pviShortMaPeriodIn = 9
    , int pviLongMaPeriodIn = 255
    , bool calcCurrentIndexIn = true
    , bool normalizeVolumeIn = false
    , int normalPeriodIn = 20
    , double lowVolumeThresholdIn = 0.4
    , ENUM_APPLIED_VOLUME volumeTypeIn = VOLUME_TICK
) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    MqlParam params[];
    ArrayResize(params, 18);
    params[0].type = TYPE_STRING; 
    params[0].string_value = "VolumeTools/NVI-PVI";
    params[1].type = TYPE_INT; //input bool CalcNVI=true;
    params[1].integer_value = calcNviIn;
    params[2].type = TYPE_INT; //input int NVIShortMAPeriod=9;
    params[2].integer_value = nviShortMaPeriodIn;
    params[3].type = TYPE_INT; //input int NVILongMAPeriod=255;
    params[3].integer_value = nviLongMaPeriodIn;
    params[4].type = TYPE_STRING; //input string PVILabel = NULL; // :
    params[4].string_value = NULL;
    params[5].type = TYPE_INT; //input bool CalcPVI=false;
    params[5].integer_value = calcPviIn;
    params[6].type = TYPE_INT; //input int PVIShortMAPeriod=9;
    params[6].integer_value = pviShortMaPeriodIn;
    params[7].type = TYPE_INT; //input int PVILongMAPeriod=255;
    params[7].integer_value = pviLongMaPeriodIn;
    params[8].type = TYPE_STRING; //input string NormalLabel = NULL; // :
    params[8].string_value = NULL;
    params[9].type = TYPE_INT; //input bool CalcByNormalizedVolume = false; // CalcByNormalizedVolume: Normalize volume and compare to threshold
    params[9].integer_value = normalizeVolumeIn;
    params[10].type = TYPE_INT; //input int NormalPeriod = 20;
    params[10].integer_value = normalPeriodIn;
    params[11].type = TYPE_DOUBLE; //input double LowVolumeThreshold = 0.4; // LowVolumeThreshold: Boundary between low and high volume conditions
    params[11].double_value = lowVolumeThresholdIn;
    params[12].type = TYPE_STRING; //input string ParamsLabel = NULL; // :
    params[12].string_value = NULL;
    params[13].type = TYPE_INT; //input bool CalcCurrentBarIndex = true; // CalcCurrentBarIndex: Select NVI or PVI from volume level for the current duration
    params[13].integer_value = calcCurrentIndexIn;
    params[14].type = TYPE_INT; //input bool ShowIndexType = false;
    params[14].integer_value = false;
    params[15].type = TYPE_INT; //input bool ShowIndexTypeNegative = true;
    params[15].integer_value = true;
    params[16].type = TYPE_INT; //input bool ShowIndexTypePositive = true;
    params[16].integer_value = true;
    params[17].type = TYPE_INT; //input ENUM_APPLIED_VOLUME VolumeType = VOLUME_TICK;
    params[17].integer_value = volumeTypeIn;
    
    return IndicatorCreate(symbol, tf, IND_CUSTOM, ArraySize(params), params);
#endif
#endif
}

//+------------------------------------------------------------------+

bool FilterNVIPVI::isSubfilterMatching(int compareIdx, int subIdx) {
    return timeFrame[compareIdx] == timeFrame[subIdx]
        && calcNvi[compareIdx] == calcNvi[subIdx]
        && nviShortMaPeriod[compareIdx] == nviShortMaPeriod[subIdx]
        && nviLongMaPeriod[compareIdx] == nviLongMaPeriod[subIdx]
        && calcPvi[compareIdx] == calcPvi[subIdx]
        && pviShortMaPeriod[compareIdx] == pviShortMaPeriod[subIdx]
        && pviLongMaPeriod[compareIdx] == pviLongMaPeriod[subIdx]
        && calcCurrentIndex[compareIdx] == calcCurrentIndex[subIdx]
        ;
}

//+------------------------------------------------------------------+

bool FilterNVIPVI::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
    SignalType signal = SignalNone;
    string statusText = "";
    
    switch(trigger[subfilterId]) {
        case TRIGGER_COMPETE_SLOPE: {
            double nviSlope = calcSlope(subfilterId, symbolIndex, shift[subfilterId], limit[subfilterId], getBufferIndexFromType(slopeSource[subfilterId], false));
            double pviSlope = calcSlope(subfilterId, symbolIndex, shift[subfilterId], limit[subfilterId], getBufferIndexFromType(slopeSource[subfilterId], true));
            double strongSlope = MathAbs(nviSlope) >= MathAbs(pviSlope) ? nviSlope : pviSlope;
            
            double slopeThresholdPrice = PipsToPrice(symbol, slopeThreshold[subfilterId]);
            
            if(suppressAllBelowThreshold[subfilterId]
                && ((nviSlope >= slopeThresholdPrice*-1 && nviSlope <= slopeThresholdPrice)
                    || (pviSlope >= slopeThresholdPrice*-1 && pviSlope <= slopeThresholdPrice)
                    )
            ) {
                signal = SignalNone;
            } else if(strongSlope < slopeThresholdPrice*-1) {
                signal = SignalSell;
            } else if(strongSlope > slopeThresholdPrice) {
                signal = SignalBuy;
            } else {
                signal = SignalNone;
            }
            
            statusText = DoubleToString(PriceToPips(symbol, nviSlope), 1) + "/" + DoubleToString(PriceToPips(symbol, pviSlope), 1);
            break;
        }
        
        case TRIGGER_AGREE_SLOPE: {
            double nviSlope = calcSlope(subfilterId, symbolIndex, shift[subfilterId], limit[subfilterId], getBufferIndexFromType(slopeSource[subfilterId], false));
            double pviSlope = calcSlope(subfilterId, symbolIndex, shift[subfilterId], limit[subfilterId], getBufferIndexFromType(slopeSource[subfilterId], true));
            //double strongSlope = MathAbs(nviSlope) >= MathAbs(pviSlope) ? nviSlope : pviSlope;
            
            double slopeThresholdPrice = PipsToPrice(symbol, slopeThreshold[subfilterId]);
            
            if(suppressAllBelowThreshold[subfilterId]
                && ((nviSlope >= slopeThresholdPrice*-1 && nviSlope <= slopeThresholdPrice)
                    || (pviSlope >= slopeThresholdPrice*-1 && pviSlope <= slopeThresholdPrice)
                    )
            ) {
                signal = SignalNone;
            } if(nviSlope < slopeThresholdPrice*-1 && pviSlope < slopeThresholdPrice*-1) {
                signal = SignalSell;
            } else if(nviSlope > slopeThresholdPrice && pviSlope > slopeThresholdPrice) {
                signal = SignalBuy;
            } else {
                signal = SignalNone;
            }
            
            statusText = DoubleToString(PriceToPips(symbol, nviSlope), 1) + "/" + DoubleToString(PriceToPips(symbol, pviSlope), 1);
            break;
        }
        
        case TRIGGER_SELF_SLOPE: {
            double slope = 0;
            if(calcNvi[subfilterId] == calcPvi[subfilterId]) {
                signal = SignalNone;
                break;
            } else if(calcNvi[subfilterId]) {
                slope = calcSlope(subfilterId, symbolIndex, shift[subfilterId], limit[subfilterId], getBufferIndexFromType(slopeSource[subfilterId], false));
            } else {
                slope = calcSlope(subfilterId, symbolIndex, shift[subfilterId], limit[subfilterId], getBufferIndexFromType(slopeSource[subfilterId], true));
            }
            
            double slopeThresholdPrice = PipsToPrice(symbol, slopeThreshold[subfilterId]);
                
            if(suppressAllBelowThreshold[subfilterId]
                && ((slope >= slopeThresholdPrice*-1 && slope <= slopeThresholdPrice))
            ) {
                signal = SignalNone;
            } else if(slope < slopeThresholdPrice*-1) {
                signal = SignalSell;
            } else if(slope > slopeThresholdPrice) {
                signal = SignalBuy;
            } else {
                signal = SignalNone;
            }
            
            statusText = DoubleToString(PriceToPips(symbol, slope), 1);
            break;
        }
    }
    
    dataOut.setRawValue(statusText, signal);
    
    return true;
}

double FilterNVIPVI::calcSlope(int subIdx, int symIdx, int shift, int limit, /*int interval, */ ENUM_NVIPVI_BUFFER bufferIdx) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    double read[]; ArraySetAsSeries(read, true);
    if(CopyBuffer(iNVIPVIHandle[symIdx]._[subIdx], (int)bufferIdx, 0+shift, limit+1, read) < limit+1) { return 0; }
    else { return calcSlopeByPoints(read[ArraySize(read)-1], read[0]); }
#endif
#endif
}

double FilterNVIPVI::calcSlopeByPoints(double pointAy, double pointBy, double pointAx = 0, double pointBx = 1) {
    return (pointBy-pointAy)/(pointBx-pointAx);
}

ENUM_NVIPVI_BUFFER FilterNVIPVI::getBufferIndexFromType(ENUM_NVIPVI_BUFFER_TYPE bufferType, bool isPvi = false) {
    switch(bufferType) {
        case BUFFER_TYPE_REAL: return isPvi ? BUFFER_PVI : BUFFER_NVI;
        case BUFFER_TYPE_SHORTMA: return isPvi ? BUFFER_PVI_SHORTMA : BUFFER_NVI_SHORTMA;
        case BUFFER_TYPE_LONGMA: return isPvi ? BUFFER_PVI_LONGMA : BUFFER_NVI_LONGMA;
        case BUFFER_TYPE_INDEXMODE: default: return BUFFER_INDEXMODE;
    }
}