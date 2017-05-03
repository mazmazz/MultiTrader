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

class FilterFb : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int maPeriodFast[];
    int maAvgModeFast[];
    int maPriceFast[];
    bool maEnableSlow[]; // should be bool
    int maPeriodSlow[];
    int maAvgModeSlow[];
    int maPriceSlow[];
    bool compareMaFastSlow[]; // should be bool
    int shift[];
#ifdef __MQL5__
    ArrayDim<int> iMaFastHandle[];
    ArrayDim<int> iMaSlowHandle[];
#endif
    
    public:
    void init();
    void deInit();
#ifdef __MQL5__
    bool getFastHandle;
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif

    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , int maPeriodFastIn
        , int maAvgModeFastIn
        , int maPriceFastIn
        , bool maEnableSlowIn
        , int maPeriodSlowIn
        , int maAvgModeSlowIn
        , int maPriceSlowIn
        , bool compareMaFastSlowIn
        , int shiftIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string timeFrameList
        , string maPeriodFastList
        , string maAvgModeFastList
        , string maPriceFastList
        , string maEnableSlowList
        , string maPeriodSlowList
        , string maAvgModeSlowList
        , string maPriceSlowList
        , string compareMaFastSlowList
        , string shiftList
        , bool addToExisting = false
    );

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
    double getMaValue(int symIdx, int subIdx, bool isFast);
    double getBarLow(int symIdx, int subIdx);
    double getBarHigh(int symIdx, int subIdx);
};

//+------------------------------------------------------------------+

void FilterFb::init() {
    if(isInit) { return; }
    
    shortName = "FB";

#ifdef __MQL5__
    getFastHandle = true;
    loadIndicatorHandles(iMaFastHandle);
    getFastHandle = false;
    loadIndicatorHandles(iMaSlowHandle);
#endif

    isInit = true;
}

void FilterFb::deInit() {
#ifdef __MQL5__
    unloadIndicatorHandles(iMaFastHandle);
    unloadIndicatorHandles(iMaSlowHandle);

    isInit = false;
#endif
}

#ifdef __MQL5__
int FilterFb::getNewIndicatorHandle(int symIdx, int subIdx) {
    if(getFastHandle) {
        return iMA(MainSymbolMan.symbols[symIdx].name, Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), maPeriodFast[subIdx], 0, (ENUM_MA_METHOD)maAvgModeFast[subIdx], maPriceFast[subIdx]);
    } else {
        if(maEnableSlow[subIdx]) {
            return iMA(MainSymbolMan.symbols[symIdx].name, Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), maPeriodSlow[subIdx], 0, (ENUM_MA_METHOD)maAvgModeSlow[subIdx], maPriceSlow[subIdx]);
        } else { return INVALID_HANDLE; }
    }
}
#endif

//+------------------------------------------------------------------+

void FilterFb::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , int maPeriodFastIn
    , int maAvgModeFastIn
    , int maPriceFastIn
    , bool maEnableSlowIn
    , int maPeriodSlowIn
    , int maAvgModeSlowIn
    , int maPriceSlowIn
    , bool compareMaFastSlowIn
    , int shiftIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(maPeriodFast, maPeriodFastIn);
    Common::ArrayPush(maAvgModeFast, maAvgModeFastIn);
    Common::ArrayPush(maPriceFast, maPriceFastIn);
    Common::ArrayPush(maEnableSlow, maEnableSlowIn);
    Common::ArrayPush(maPeriodSlow, maPeriodSlowIn);
    Common::ArrayPush(maAvgModeSlow, maAvgModeSlowIn);
    Common::ArrayPush(maPriceSlow, maPriceSlowIn);
    Common::ArrayPush(compareMaFastSlow, compareMaFastSlowIn);
    Common::ArrayPush(shift, shiftIn);
}

void FilterFb::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string timeFrameList
    , string maPeriodFastList
    , string maAvgModeFastList
    , string maPriceFastList
    , string maEnableSlowList
    , string maPeriodSlowList
    , string maAvgModeSlowList
    , string maPriceSlowList
    , string compareMaFastSlowList
    , string shiftList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(maPeriodFastList, maPeriodFast, count, addToExisting);
        MultiSettings::Parse(maAvgModeFastList, maAvgModeFast, count, addToExisting);
        MultiSettings::Parse(maPriceFastList, maPriceFast, count, addToExisting);
        MultiSettings::Parse(maEnableSlowList, maEnableSlow, count, addToExisting);
        MultiSettings::Parse(maPeriodSlowList, maPeriodSlow, count, addToExisting);
        MultiSettings::Parse(maAvgModeSlowList, maAvgModeSlow, count, addToExisting);
        MultiSettings::Parse(maPriceSlowList, maPriceSlow, count, addToExisting);
        MultiSettings::Parse(compareMaFastSlowList, compareMaFastSlow, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

bool FilterFb::calculate(int subIdx, int symIdx, DataUnit *dataOut) {
    if(!checkSafe(subIdx)) { return false; }
    string symbol = MainSymbolMan.symbols[symIdx].name;
    
    double maFastVal = getMaValue(symIdx, subIdx, true);
    double maSlowVal = getMaValue(symIdx, subIdx, false);

    if(maFastVal == 0 || (maEnableSlow[subIdx] && maSlowVal == 0)) { return false; } // indi does not load instantly on mt5
    
    double barLow = getBarLow(symIdx, subIdx);
    double barHigh = getBarHigh(symIdx, subIdx);
    
    if(barLow == 0 || barHigh == 0) { return false; }
    
    bool fbLong = false, fbShort = false;
    if(compareMaFastSlow[subIdx]) {
        fbShort = barLow > maSlowVal && maSlowVal > maFastVal;
        fbLong = barHigh < maFastVal && maFastVal < maFastVal;
    } else {
        fbShort = barLow > MathMax(maFastVal, maSlowVal);
        fbLong = barHigh < MathMin(maFastVal, maSlowVal);
    }
    
    SignalType signal = fbLong ? SignalLong : fbShort ? SignalShort : SignalNone;
    
    dataOut.setRawValue(0, signal);
    
    return true;
}

double FilterFb::getMaValue(int symIdx, int subIdx, bool isFast) {
#ifdef __MQL4__
    if(isFast) { 
        return iMA(MainSymbolMan.getSymbolName(symIdx),timeFrame[subIdx],maPeriodFast[subIdx],0,maAvgModeFast[subIdx],maPriceFast[i],shift[subIdx]);
    } else {
        if(!maEnableSlow[subIdx]) { return 0; }
        return iMA(MainSymbolMan.getSymbolName(symIdx),timeFrame[subIdx],maPeriodSlow[subIdx],0,maAvgModeSlow[subIdx],maPriceSlow[i],shift[subIdx]);
    }
#else
#ifdef __MQL5__
    if(isFast) {
        if(iMaFastHandle[symIdx]._[subIdx] == INVALID_HANDLE) { return 0; }
        return Common::GetSingleValueFromBuffer(iMaFastHandle[symIdx]._[subIdx], shift[subIdx]);
    } else {
        if(!maEnableSlow[subIdx]) { return 0; }
        if(iMaSlowHandle[symIdx]._[subIdx] == INVALID_HANDLE) { return 0; }
        return Common::GetSingleValueFromBuffer(iMaSlowHandle[symIdx]._[subIdx], shift[subIdx]);
    }
#endif
#endif
}

double FilterFb::getBarLow(int symIdx, int subIdx) {
#ifdef __MQL4__
    return iLow(MainSymbolMan.getSymbolName(symIdx),timeFrame[subIdx],shift[subIdx]);
#else
#ifdef __MQL5__
    double barUnits[];
    if(CopyLow(MainSymbolMan.getSymbolName(symIdx), Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), shift[subIdx], 1, barUnits) >=1) {
        return barUnits[0];
    } else { return 0; }
#endif
#endif
}

double FilterFb::getBarHigh(int symIdx, int subIdx) {
#ifdef __MQL4__
    return iHigh(MainSymbolMan.getSymbolName(symIdx),timeFrame[subIdx],shift[subIdx]);
#else
#ifdef __MQL5__
    double barUnits[];
    if(CopyHigh(MainSymbolMan.getSymbolName(symIdx), Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), shift[subIdx], 1, barUnits) >=1) {
        return barUnits[0];
    } else { return 0; }
#endif
#endif
}