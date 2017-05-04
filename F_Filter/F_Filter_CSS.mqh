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
#include "../T_Presets.mqh"

#define _FilterCssGmt

enum FILTER_CSS_RESULT {
    CSS_RESULT_NONE
    , CSS_RESULT_DIFF
    , CSS_RESULT_DELTA
    , CSS_RESULT_CROSS
    , CSS_RESULT_TRADEDIRECTION
    , CSS_RESULT_GLOBALMARKETTREND
    , CSS_RESULT_GLOBALMARKETTREND_DELTA
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
    double min[];
    double max[];
    double tradeLevel[]; // tradeLevelCrossed
    double differenceThreshold[]; // tradeDirection
    
    CLibCSS *cssInst;
    CLibCSS *superSlopeInst;
    
    public:
    string symbolsToWeigh;
    
    ~FilterCss();
    
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
        , double minIn = 0.2
        , double maxIn = 99
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
        , string minList
        , string maxList
        , string tradeLevelList // TradeLevelCrossed
        , string differenceThresholdList // TradeDirection
        , bool addToExisting = false
    );
    void instantiateLib();
    
    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterCss::~FilterCss() {
    deInit();
}

void FilterCss::init() {
     if(isInit) { return; }
     
     shortName = "CSS";
     symbolsToWeigh = CSS_SymbolsToWeigh;
     instantiateLib();
          
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
    , double minIn = 0.2
    , double maxIn = 99
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
    Common::ArrayPush(min, minIn);
    Common::ArrayPush(max, maxIn);
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
    , string minList
    , string maxList
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
        MultiSettings::Parse(minList, /*false,*/ min, count, addToExisting);
        MultiSettings::Parse(maxList, /*false,*/ max, count, addToExisting);
        MultiSettings::Parse(tradeLevelList, /*0,*/ tradeLevel, count, addToExisting);
        MultiSettings::Parse(differenceThresholdList, /*0,*/ differenceThreshold, count, addToExisting);
    }
}

void FilterCss::instantiateLib() {
    for(int i = 0; i < ArraySize(calcMethod); i++) {
        if(subfilterMode[i] == SubfilterDisabled) { continue; }
        switch(calcMethod[i]) {
            case CSS_VERSION_CSS:
            case CSS_VERSION_3_8:
                if(!Common::IsInvalidPointer(cssInst)) { break; }
                cssInst = new CLibCSS();
                cssInst.calcMethod = (CSS_VERSION)calcMethod[i];
                cssInst.initSymbols(symbolsToWeigh);
                break;
                
            case CSS_VERSION_SUPERSLOPE: {
                if(!Common::IsInvalidPointer(superSlopeInst)) { break; }
                superSlopeInst = new CLibCSS();
                superSlopeInst.calcMethod = (CSS_VERSION)calcMethod[i];
                int size = MainSymbolMan.getSymbolCount();
                for(int j = 0; j < size; j++) {
                    superSlopeInst.initSymbols(MainSymbolMan.getSymbolName(j), true);
                }
                break;
            }
        }
    }
}

//+------------------------------------------------------------------+

bool FilterCss::calculate(int subIdx, int symIdx, DataUnit *dataOut) {
     if(!checkSafe(subIdx)) { return false; }
     string symbol = MainSymbolMan.symbols[symIdx].name;
     ENUM_TIMEFRAMES timeframe = Common::GetTimeFrameFromMinutes(timeFrame[subIdx]);
     
     CLibCSS *inst = NULL;
     if((CSS_VERSION)calcMethod[subIdx] == CSS_VERSION_SUPERSLOPE) { inst = superSlopeInst; }
     else { inst = cssInst; }
     if(Common::IsInvalidPointer(inst)) { return false; }
     
     inst.setPeriods(maPeriod[subIdx], atrPeriod[subIdx]);
     
     double value = 0; string valueText = NULL;
     TRADE_DIRECTION direction = TRADE_DIRECTION_NONE;
     
     switch(resultType[subIdx]) {
        case CSS_RESULT_DIFF: {
            value = inst.getCSSDiff(symbol, timeframe, shift[subIdx], absolute[subIdx]);
            bool constraintsMet = MathAbs(value) >= MathAbs(min[subIdx]) && MathAbs(value) <= MathAbs(max[subIdx]);
            double dirValue = absolute[subIdx] ? inst.getCSSDiff(symbol, timeframe, shift[subIdx], false) : value;
            direction = !constraintsMet ? TRADE_DIRECTION_NONE : dirValue >= 0 ? TRADE_DIRECTION_LONG : TRADE_DIRECTION_SHORT; // todo: min threshold
            valueText = DoubleToString(value, 4);
            break;
        }
            
        case CSS_RESULT_DELTA: {
            value = inst.getCSSDelta(symbol, timeframe, shift[subIdx], candles[subIdx], absolute[subIdx]);
            bool constraintsMet = MathAbs(value) >= MathAbs(min[subIdx]) && MathAbs(value) <= MathAbs(max[subIdx]);
            double dirValue = absolute[subIdx] ? inst.getCSSDelta(symbol, timeframe, shift[subIdx], candles[subIdx], false) : value;
            direction = !constraintsMet ? TRADE_DIRECTION_NONE : dirValue >= 0 ? TRADE_DIRECTION_LONG : TRADE_DIRECTION_SHORT; // todo: min threshold
            valueText = DoubleToString(value, 4);
            break;
        }
        
        case CSS_RESULT_CROSS: { // TRADE_DIRECTION
            value = inst.getCSSCross(symbol, timeframe, shift[subIdx], candles[subIdx]);
            bool tradeLevelCrossed = inst.getCSSTradeLevelCrossed(symbol, timeframe, shift[subIdx], tradeLevel[subIdx]);
            direction = !tradeLevelCrossed ? TRADE_DIRECTION_NONE : value;
            valueText = value == TRADE_DIRECTION_LONG ? "Long" : value == TRADE_DIRECTION_SHORT ? "Short" : " ";
            if(!tradeLevelCrossed && value != TRADE_DIRECTION_NONE) { valueText += " N"; }
            break;
        }
            
        case CSS_RESULT_TRADEDIRECTION: // TRADE_DIRECTION
            value = inst.getCSSTradeDirection(symbol, timeframe, shift[subIdx], differenceThreshold[subIdx]);
            direction = value;
            valueText = value == TRADE_DIRECTION_LONG ? "Long" : value == TRADE_DIRECTION_SHORT ? "Short" : " ";
            break;

#ifdef _FilterCssGmt      
        case CSS_RESULT_GLOBALMARKETTREND: {
            value = inst.getGlobalMarketTrend(symbol, timeframe, shift[subIdx]);
            bool constraintsMet = MathAbs(value) >= MathAbs(min[subIdx]) && MathAbs(value) <= MathAbs(max[subIdx]);
                // directionless -- SignalOpen if constraintsMet
            valueText = DoubleToString(value, 4);
            break;
        }
            
        case CSS_RESULT_GLOBALMARKETTREND_DELTA: {
            value = inst.getGlobalMarketTrendDelta(symbol, timeframe, shift[subIdx], candles[subIdx]);
            bool constraintsMet = MathAbs(value) >= MathAbs(min[subIdx]) && MathAbs(value) <= MathAbs(max[subIdx]);
            direction = !constraintsMet ? TRADE_DIRECTION_NONE : value >= 0 ? TRADE_DIRECTION_LONG : TRADE_DIRECTION_SHORT;
                // directionless -- SignalOpen if constraintsMet. Could also have a direction flag
                // value > 0 should be long (shift-candles pos means market has grown bigger)
            valueText = DoubleToString(value, 4);
            break;
        }
 #endif
      
        case CSS_RESULT_TRADELEVELCROSSED: // bool
            value = inst.getCSSTradeLevelCrossed(symbol, timeframe, shift[subIdx], tradeLevel[subIdx]);
            // todo: signalopen
            valueText = value ? "Crossed" : " ";
            break;
            
 #ifndef _FilterCssGmt        
        case CSS_RESULT_GLOBALMARKETTREND:
        case CSS_RESULT_GLOBALMARKETTREND_DELTA:
 #endif
        default:
            return false;
     }
     
     SignalType signal = SignalNone;
     switch(direction) {
        case TRADE_DIRECTION_LONG: signal = SignalBuy; break;
        case TRADE_DIRECTION_SHORT: signal = SignalSell; break;
     }
     
     dataOut.setRawValue(value, signal, valueText);
     
     return true;
}
