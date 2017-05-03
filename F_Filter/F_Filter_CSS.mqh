//+------------------------------------------------------------------+
//|                                                            F_Filter_Stoch.mqh |
//|                                                        Copyright 2017, Marco Z |
//|                                                            https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link        "https://www.mql5.com"
#property strict

#include "F_Filter.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../D_Data/D_DataUnit.mqh"
#include "../S_Symbol.mqh"
#include "../depends/PipFactor.mqh"
#include "../depends/LibCSS5.mqh"

enum FILTER_CSS_RESULT {
    CSS_RESULT_NONE
    , CSS_RESULT_DIFF
    , CSS_RESULT_DELTA
    , CSS_RESULT_CROSS
    , CSS_RESULT_TRADEDIRECTION
    , CSS_RESULT_TRADELEVELCROSSED
};

class FilterCss : public Filter {
    private:
    bool isInit;
    int resultType[];
    int calcMethod[];
    int timeFrame[];
    int maPeriod[];
    int atrPeriod[];
    int shift[];
    int candles[]; // Delta/Cross
    bool absolute[]; // Diff/Delta // should be bool
    double tradeLevel[]; // tradeLevelCrossed
    double differenceThreshold[]; // tradeDirection
    
    CLibCSS *cssInst;
    CLibCSS *superSlopeInst;
    
    public:
    string symbolsToWeigh;
    
    void init();
    void deInit();
    
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int resultTypeIn
        , int calcMethodIn
        , int timeFrameIn
        , int maPeriodIn
        , int atrPeriodIn
        , int shiftIn
        , int candlesIn = 0
        , bool absoluteIn = false
        , double tradeLevelIn = 0
        , double differenceThresholdIn = 0
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string resultTypeList
        , string calcMethodList
        , string timeFrameList
        , string maPeriodList
        , string atrPeriodList
        , string shiftList
        , string candlesList // Delta/Cross
        , string absoluteList // Diff/Delta
        , string tradeLevelList // TradeLevelCrossed
        , string differenceThresholdList // TradeDirection
        , bool addToExisting = false
    );
    void instantiateLib(int calcMethod);
    
    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterCss::init() {
     if(isInit) { return; }
     
     shortName = "CSS";
          
     isInit = true;
}

void FilterCss::deInit() { 
    if(!Common::IsInvalidPointer(cssInst)) { Common::SafeDelete(cssInst); }
    if(!Common::IsInvalidPointer(superSlopeInst)) { Common::SafeDelete(superSlopeInst); }
}

//+------------------------------------------------------------------+

void FilterCss::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int resultTypeIn
    , int calcMethodIn
    , int timeFrameIn
    , int maPeriodIn
    , int atrPeriodIn
    , int shiftIn
    , int candlesIn = 0
    , bool absoluteIn = false
    , double tradeLevelIn = 0
    , double differenceThresholdIn = 0
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(resultType, resultTypeIn);
    Common::ArrayPush(calcMethod, calcMethodIn);
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(maPeriod, maPeriodIn);
    Common::ArrayPush(atrPeriod, atrPeriodIn);
    Common::ArrayPush(shift, shiftIn);
    Common::ArrayPush(candles, candlesIn);
    Common::ArrayPush(absolute, absoluteIn);
    Common::ArrayPush(tradeLevel, tradeLevelIn);
    Common::ArrayPush(differenceThreshold, differenceThresholdIn);
}

void FilterCss::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string resultTypeList
    , string calcMethodList
    , string timeFrameList
    , string maPeriodList
    , string atrPeriodList
    , string shiftList
    , string candlesList // Delta/Cross
    , string absoluteList // Diff/Delta
    , string tradeLevelList // TradeLevelCrossed
    , string differenceThresholdList // TradeDirection
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(resultTypeList, resultType, count, addToExisting);
        MultiSettings::Parse(calcMethodList, calcMethod, count, addToExisting);
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(maPeriodList, maPeriod, count, addToExisting);
        MultiSettings::Parse(atrPeriodList, atrPeriod, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
        
        MultiSettings::Parse(candlesList, /*0,*/ candles, count, addToExisting);
        MultiSettings::Parse(absoluteList, /*false,*/ absolute, count, addToExisting);
        MultiSettings::Parse(tradeLevelList, /*0,*/ tradeLevel, count, addToExisting);
        MultiSettings::Parse(differenceThresholdList, /*0,*/ differenceThreshold, count, addToExisting);
    }
}

void FilterCss::instantiateLib(int calcMethod) {
    switch(calcMethod) {
        case CSS_VERSION_CSS:
        case CSS_VERSION_3_8:
            if(!Common::IsInvalidPointer(cssInst)) { return; }
            cssInst = new CLibCSS();
            cssInst.initSymbols(symbolsToWeigh);
            break;
            
        case CSS_VERSION_SUPERSLOPE: {
            if(!Common::IsInvalidPointer(superSlopeInst)) { return; }
            superSlopeInst = new CLibCSS();
            
            int size = MainSymbolMan.getSymbolCount();
            for(int i = 0; i < size; i++) {
                cssInst.initSymbols(MainSymbolMan.symbols[i].name, true);
                break;
            }
            break;
        }
    }
}

//+------------------------------------------------------------------+

bool FilterCss::calculate(int subIdx, int symIdx, DataUnit *dataOut) {
     if(!checkSafe(subIdx)) { return false; }
     string symbol = MainSymbolMan.symbols[symIdx].name;
     
     CLibCSS *inst = NULL;
     if(calcMethod[subIdx] == CSS_VERSION_SUPERSLOPE) { inst = superSlopeInst; }
     else { inst = cssInst; }
     if(Common::IsInvalidPointer(inst)) { return false; }
     
     inst.setPeriods(maPeriod[subIdx], atrPeriod[subIdx]);
     
     double value = 0;
     TRADE_DIRECTION direction = TRADE_DIRECTION_NONE;
     
     switch(resultType[subIdx]) {
        case CSS_RESULT_DIFF:
            value = inst.getCSSDiff(symbol, Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), shift[subIdx], absolute[subIdx]);
            direction = MathAbs(value) >= 0 ? TRADE_DIRECTION_LONG : TRADE_DIRECTION_SHORT; // todo: min threshold
            break;
            
        case CSS_RESULT_DELTA:
            value = inst.getCSSDelta(symbol, Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), shift[subIdx], candles[subIdx], absolute[subIdx]);
            direction = MathAbs(value) >= 0 ? TRADE_DIRECTION_LONG : TRADE_DIRECTION_SHORT; // todo: min threshold
            break;
            
        case CSS_RESULT_CROSS: // TRADE_DIRECTION
            value = inst.getCSSCross(symbol, Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), shift[subIdx], candles[subIdx]);
            direction = value;
            break;
            
        case CSS_RESULT_TRADELEVELCROSSED: // bool
            value = inst.getCSSTradeLevelCrossed(symbol, Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), shift[subIdx], tradeLevel[subIdx]);
            // signalopen?
            break;
            
        case CSS_RESULT_TRADEDIRECTION: // TRADE_DIRECTION
            value = inst.getCSSTradeDirection(symbol, Common::GetTimeFrameFromMinutes(timeFrame[subIdx]), shift[subIdx], differenceThreshold[subIdx]);
            direction = value;
            break;
            
        default:
            return false;
     }
     
     SignalType signal = SignalNone;
     switch(direction) {
        case TRADE_DIRECTION_LONG: signal = SignalBuy; break;
        case TRADE_DIRECTION_SHORT: signal = SignalSell; break;
     }
     
     dataOut.setRawValue(value, signal);
     
     return true;
}
