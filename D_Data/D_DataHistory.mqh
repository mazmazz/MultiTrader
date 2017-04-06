//+------------------------------------------------------------------+
//|                                              D_DataHistory.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#include "../MC_Common/MC_Common.mqh"
#include "D_DataUnit.mqh"
#include "../T_Settings.mqh"

class DataHistory {
    // We need this to maintain a data history
    private: 
    DataUnit *data[];
    
    public:
    SignalUnit *signal[];
    
    DataHistory();
    DataHistory(int dataHistoryCount, int signalHistoryCount);
    ~DataHistory();
    int dataHistoryCount;
    int signalHistoryCount;
    
    void setHistoryCount(int dataHistoryCountIn = -1, int signalHistoryCountIn = -1);

    void addData(DataUnit *data);

    template<typename T>
    void addData(bool success, T value, SignalType signal = SignalNone, string debugValue = "", datetime lastUpdate = 0);
    
    DataUnit *getData(int index = 0) { 
        if(index >= ArraySize(data)) { return NULL; }
        else { return data[MathMax(0,index)]; }
    }
    
    void deleteAllData();

    void addSignalUnit(SignalType curSignal, int checkIndex = 0);
    
    template<typename T>
    void compareRawValues(DataUnit *unit, DataUnit *compareUnit);
    
    SignalType getSignal(int unitIdx = 0);
    int getSignalDuration(TimeUnits stableUnits, SignalUnit *prevUnit, SignalUnit *curUnit = NULL);
    bool getSignalStable(int stableLength, TimeUnits stableUnits);
    
    SignalUnit *getSignalUnit(int index = 0);
};

void DataHistory::DataHistory() {
    dataHistoryCount = 0;
    signalHistoryCount = 0;
    ArraySetAsSeries(data, true); 
    ArraySetAsSeries(signal, true);
        // this affects ArrayResize behavior by shifting all values up in index 
        // (i.e., element 0 is copied onto index 1 and then index 0 is freed.)
}

void DataHistory::DataHistory(int dataHistoryCountIn, int signalHistoryCountIn) {
    dataHistoryCount = 0;
    signalHistoryCount = 0;
    ArraySetAsSeries(data, true); 
    ArraySetAsSeries(signal, true);
        // this affects ArrayResize behavior by s
    setHistoryCount(dataHistoryCountIn, signalHistoryCountIn);
}

void DataHistory::~DataHistory() {
    deleteAllData();
}

void DataHistory::setHistoryCount(int dataHistoryCountIn = -1, int signalHistoryCountIn = -1) {
    dataHistoryCount = dataHistoryCountIn < 1 ? MathMax(1, DataHistoryLevel) : dataHistoryCountIn;
    signalHistoryCount = signalHistoryCountIn < 1 ? MathMax(1, SignalHistoryLevel) : signalHistoryCountIn;

    int size = ArraySize(data);
    if(size > dataHistoryCount) { Common::ArrayDelete(data, 0, size-dataHistoryCount); size = dataHistoryCount; }
    ArrayResize(data, size, dataHistoryCount-size); 
    
    size = ArraySize(signal);
    if(size > signalHistoryCount) { 
        Common::ArrayDelete(signal, 0, size-signalHistoryCount);
        size = signalHistoryCount; 
    }
    ArrayResize(signal, size, signalHistoryCount-size); 
}

void DataHistory::addData(DataUnit *unit) {
    addSignalUnit(unit.signal);
    
    Common::ArrayPush(data, unit, dataHistoryCount);
}

template<typename T>
void DataHistory::addData(bool success, T value, SignalType signal = SignalNone, string debugValue = "", datetime lastUpdate = 0) {
    DataUnit *newData = NULL;
    newData = new DataUnit(success, value, signal, debugValue, lastUpdate);
    
    addData(newData);
}

void DataHistory::deleteAllData() {
    Common::SafeDeletePointerArray(data);
    Common::SafeDeletePointerArray(signal);
}

SignalType DataHistory::getSignal(int unitIdx = 0) { // kept for compatibility, this looks at data history, not signal history
    if(unitIdx >= ArraySize(data) || Common::IsInvalidPointer(data[unitIdx])) { return SignalNone; }
    else { return data[unitIdx].signal; }
}

void DataHistory::addSignalUnit(SignalType curSignal, int checkIndex = 0) {
    bool force = false;
    SignalType compareSignal = SignalNone;
    SignalUnit *compareUnit = getSignalUnit(checkIndex);
    if(Common::IsInvalidPointer(compareUnit)) { force = true; }
    else { compareSignal = compareUnit.type; }

    if (force || (curSignal != compareSignal)) {
        SignalUnit *signalUnit = new SignalUnit();
        signalUnit.timeMilliseconds = GetTickCount();
        signalUnit.timeDatetime = TimeCurrent();
        signalUnit.timeCycles = 0;
        signalUnit.type = curSignal;
        Common::ArrayPush(signal, signalUnit, signalHistoryCount);
    } else if(ArraySize(signal) > 0 && !Common::IsInvalidPointer(signal[0])) { signal[0].timeCycles++; }
}

SignalUnit *DataHistory::getSignalUnit(int index = 0) {
    if(ArraySize(signal) > index) { return signal[index]; }
    else { return NULL; }
}

int DataHistory::getSignalDuration(TimeUnits stableUnits, SignalUnit *prevUnit = NULL, SignalUnit *curUnit = NULL) {
    if(Common::IsInvalidPointer(prevUnit)) { prevUnit = getSignalUnit(); }
    if(Common::IsInvalidPointer(prevUnit)) { return -1; }
    
    //((cur) >= (prev)) ? ((cur)-(prev)) : ((0xFFFFFFFF-(prev))+(cur)+1)
    switch(stableUnits) {
        case UnitSeconds: {
            datetime cur = !Common::IsInvalidPointer(curUnit) ? curUnit.timeDatetime : TimeCurrent();
            datetime prev = prevUnit.timeDatetime;
            return Common::GetTimeDuration(cur, prev);
        }
        
        case UnitMilliseconds: {
            uint cur = !Common::IsInvalidPointer(curUnit) ? curUnit.timeMilliseconds : GetTickCount();
            uint prev = prevUnit.timeMilliseconds;
            uint duration = (cur >= prev) ? cur-prev : UINT_MAX-prev+cur+1;
            return Common::GetTimeDuration(cur, prev);
        }
            
        case UnitTicks: {
            return prevUnit.timeCycles; // this is just added iteratively
        }
            
        default:
            return -1;
    }
}

bool DataHistory::getSignalStable(int stableLength, TimeUnits stableUnits) {
    return (getSignalDuration(stableUnits) >= stableLength);
}
