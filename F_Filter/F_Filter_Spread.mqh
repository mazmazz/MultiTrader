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

class FilterSpread : public Filter {
    public:
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type);
    void addSubfilter(string modeList, string nameList, string hiddenList, string typeList
        , bool addToExisting = false
    );
    
    private:
    bool isInit;
    
    public:
    void init();

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterSpread::addSubfilter(int mode, string name, bool hidden, SubfilterType type) {
    setupSubfilters(mode, name, hidden, type);
}

void FilterSpread::addSubfilter(string modeList, string nameList, string hiddenList, string typeList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeList);
}

//+------------------------------------------------------------------+

void FilterSpread::init() {
    if(isInit) { return; }
    
    shortName = "Spread";
    
    isInit = true;
}

//+------------------------------------------------------------------+

bool FilterSpread::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
    int spreadPoints = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    
    double pips = NormalizeDouble(PointsToPips(spreadPoints), 2);
    dataOut.setRawValue(pips, SignalNone, DoubleToString(pips, 1));
    
    return true;
}
