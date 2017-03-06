//+------------------------------------------------------------------+
//|                                              MMT_DataHistory.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#include "MMT_DataUnit.mqh"
#include "../MMT_Settings.mqh"

class DataHistory {
    // We need this to maintain a data history
    private: 
    DataUnit *datum[];
    
    public:
    DataHistory(int historyCount = -1);
    int historyCount;

    template<typename T>
    void addData(T value, SignalType signal = SignalNone, string debugValue = "", datetime lastUpdate = 0);
    
    DataUnit *getData(int historyIndex = 0) { return datum[MathMax(0,historyIndex)]; }
};

void DataHistory::DataHistory(int historyCountIn = -1) {
    historyCount = historyCountIn < 1 ? MathMax(1, HistoryLevel) : historyCountIn;
    
    ArraySetAsSeries(datum, true); 
        // this affects ArrayResize behavior by shifting all values up in index 
        // (i.e., element 0 is copied onto index 1 and then index 0 is freed.)
    ArrayResize(datum, historyCount, 1); // plus 1 is needed to resize an array in excess of 1, then delete last element
}

template<typename T>
void DataHistory::addData(T value, SignalType signal = SignalNone, string debugValue = "", datetime lastUpdate = 0) {
    DataUnit *newData;
    newData = new DataUnit(value, signal, debugValue);
    
    Common::ArrayPush(datum, newData);
}
