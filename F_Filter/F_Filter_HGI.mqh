//+------------------------------------------------------------------+
//|                                             F_Filter_Hgi.mqh |
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
#include <hgi_lib.mqh>

class FilterHgi : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int shift[];
    int onTrend[];
    int onRange[];
    int onRad[];
    int onSignal[];
    int onSlope[];
    
    public:
    void init();
    
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , int shiftIn
        , int onTrendIn
        , int onRangeIn
        , int onRadIn
        , int onSignalIn
        , int onSlopeIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string timeFrameList
        , string shiftList
        , string onTrendList
        , string onRangeList
        , string onRadList
        , string onSignalList
        , string onSlopeList
        , bool addToExisting = false
    );
    
    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterHgi::init() {
    if(isInit) { return; }
    
    shortName = "HGI";
    
    isInit = true;
}

//+------------------------------------------------------------------+

void FilterStoch::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , int shiftIn
    , int onTrendIn
    , int onRangeIn
    , int onRadIn
    , int onSignalIn
    , int onSlopeIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(shift, shiftIn);
    Common::ArrayPush(onTrend, onTrendIn);
    Common::ArrayPush(onRange, onRangeIn);
    Common::ArrayPush(onRad, onRadIn);
    Common::ArrayPush(onSignal, onSignalIn);
    Common::ArrayPush(onSlope, onSlopeIn);
}

void FilterStoch::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string timeFrameList
    , string shiftList
    , string onTrendList
    , string onRangeList
    , string onRadList
    , string onSignalList
    , string onSlopeList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
        MultiSettings::Parse(onTrendList, onTrend, count, addToExisting);
        MultiSettings::Parse(onRangeList, onRange, count, addToExisting);
        MultiSettings::Parse(onRadList, onRad, count, addToExisting);
        MultiSettings::Parse(onSignalList, onSignal, count, addToExisting);
        MultiSettings::Parse(onSlopeList, onSlope, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

bool FilterHgi::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
    int hgiSignal = getHGISignal(symbol, timeFrame[subfilterId], shift[subfilterId]);
    int hgiSlope = getHGISlope(symbol, timeFrame[subfilterId], shift[subfilterId]);
    
    // 0 = Do not track, 1 = OR, 2 = AND
    int OR = 1;
    int AND = 2;
    
    SignalType signalTrend = SignalNone;
    SignalType signalSlope = SignalNone;
    SignalType signalFinal = SignalNone;
    
    switch(hgiSignal) {
        case TRENDUP: signalTrend = onTrend[subfilterId] ? SignalBuy  : SignalNone; break;
        case RANGEUP: signalTrend = onRange[subfilterId] ? SignalBuy  : SignalNone; break;
        case TRENDDN: signalTrend = onTrend[subfilterId] ? SignalSell : SignalNone; break;
        case RANGEDN: signalTrend = onRange[subfilterId] ? SignalSell : SignalNone; break;
        case RADUP:   signalTrend = onRad[subfilterId]   ? SignalBuy  : SignalNone; break;
        case RADDN:   signalTrend = onRad[subfilterId]   ? SignalSell : SignalNone; break;
        default: break;
    }
    
    switch(hgiSlope) {
        case TRENDBELOW: signalSlope = onTrend[subfilterId] ? SignalBuy  : SignalNone; break;
        case RANGEBELOW: signalSlope = onRange[subfilterId] ? SignalBuy  : SignalNone; break;
        case TRENDABOVE: signalSlope = onTrend[subfilterId] ? SignalSell : SignalNone; break;
        case RANGEABOVE: signalSlope = onRange[subfilterId] ? SignalSell : SignalNone; break;
        default: break;
    }
    
    if(onSignal[subfilterId] == OR && signalTrend != SignalNone) { signalFinal = signalTrend; }
    else if(onSlope[subfilterId] == OR && signalSlope != SignalNone) { signalFinal = signalSlope; }
    else if(onSignal[subfilterId] == AND && onSlope[subfilterId] == AND
        && signalTrend != SignalNone && signalSlope != SignalNone
        && signalTrend == signalSlope
    ) { signalFinal = signalTrend; }
    
    
    dataOut.setRawValue(
        (hgiSignal == TRENDUP ? "ATU "
            : hgiSignal == RANGEUP ? "ARU "
            : hgiSignal == TRENDDN ? "ATD "
            : hgiSignal == RANGEDN ? "ARD "
            : hgiSignal == RADUP ? "AAU "
            : hgiSignal == RADDN ? "AAD "
            : "    "
            )
        + (hgiSlope == TRENDBELOW ? "WTU"
            : hgiSlope == RANGEBELOW ? "WRU"
            : hgiSlope == TRENDABOVE ? "WTD"
            : hgiSlope == RANGEABOVE ? "WRD"
            : "   "
            )
        , signalFinal
        );
    
    return true;
}
