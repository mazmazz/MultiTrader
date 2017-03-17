//+------------------------------------------------------------------+
//|                                              MMT_DataHistory.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#include "../MC_Common/MC_Common.mqh"
#include "MMT_DataUnit.mqh"
#include "../MMT_Settings.mqh"

class DataHistory {
    // We need this to maintain a data history
    private: 
    DataUnit *data[];
    
    public:
    TimePoint lastSignalTime;
    // TimePoint lastValueTime;
    
    DataHistory();
    DataHistory(int historyCount);
    ~DataHistory();
    int historyCount;
    
    void setHistoryCount(int historyCountIn = -1);

    void addData(DataUnit *data);

    template<typename T>
    void addData(bool success, T value, SignalType signal = SignalNone, string debugValue = "", datetime lastUpdate = 0);
    
    DataUnit *getData(int index = 0) { 
        if(index >= ArraySize(data)) { return NULL; }
        else { return data[MathMax(0,index)]; }
    }
    
    void deleteAllData();

    void updateDataTimes(DataUnit *unit, int checkIndex = 0);
    
    template<typename T>
    void compareRawValues(DataUnit *unit, DataUnit *compareUnit);
};

void DataHistory::DataHistory() {
    ArraySetAsSeries(data, true); 
        // this affects ArrayResize behavior by shifting all values up in index 
        // (i.e., element 0 is copied onto index 1 and then index 0 is freed.)
}

void DataHistory::DataHistory(int historyCountIn) {
    ArraySetAsSeries(data, true); 
    setHistoryCount(historyCountIn);
}

void DataHistory::~DataHistory() {
    deleteAllData();
}

void DataHistory::setHistoryCount(int historyCountIn = -1) {
    historyCount = historyCountIn < 1 ? MathMax(1, HistoryLevel) : historyCountIn;

    int size = ArraySize(data);
    if(size > historyCount) { Common::ArrayDelete(data, 0, size-historyCount); size = historyCount; }
    ArrayResize(data, size, historyCount-size); 
}

void DataHistory::addData(DataUnit *unit) {
    updateDataTimes(unit);
    Common::ArrayPush(data, unit, historyCount);
}

template<typename T>
void DataHistory::addData(bool success, T value, SignalType signal = SignalNone, string debugValue = "", datetime lastUpdate = 0) {
    DataUnit *newData;
    newData = new DataUnit(success, value, signal, debugValue, lastUpdate);
    
    addData(newData);
}

void DataHistory::deleteAllData() {
    int size = ArraySize(data);
    
    for(int i = 0; i < size; i++) {
        if(CheckPointer(data[i]) == POINTER_DYNAMIC) { delete(data[i]); }
    }
}

void DataHistory::updateDataTimes(DataUnit *unit, int checkIndex = 0) {
    if(ArraySize(data) <= checkIndex || Common::IsInvalidPointer(data[checkIndex])) {
        lastSignalTime.milliseconds = GetTickCount();
        lastSignalTime.dateTime = TimeCurrent();
        lastSignalTime.cycles = 0;
        //lastValueTime.milliseconds = GetTickCount();
        //lastValueTime.dateTime = TimeCurrent();
        //lastValueTime.cycles = 0;
    } else {
        if (unit.signal != data[checkIndex].signal) {
            lastSignalTime.milliseconds = GetTickCount();
            lastSignalTime.dateTime = TimeCurrent();
            lastSignalTime.cycles = 0;
        } else { lastSignalTime.cycles++; }
        
        // can't get this to work due to function template weirdness
        //if (unit.getRawValue() != data[checkIndex].getRawValue();) {
            //lastValueTime.milliseconds = GetTickCount();
            //lastValueTime.dateTime = TimeCurrent();
            //lastValueTime.cycles = 0;
        //} else { lastValueTime.cycles++; }
    }
}
