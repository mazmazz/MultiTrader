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
    SignalType signalLastType[];
    uint signalLastMilliseconds[];
    datetime signalLastDatetime[];
    uint signalLastCycles[];
    
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

    void updateDataTimes(DataUnit *unit, int checkIndex = 0);
    
    template<typename T>
    void compareRawValues(DataUnit *unit, DataUnit *compareUnit);
    
    SignalType getSignal(int unitIdx = 0);
    int getSignalDuration(TimeUnits stableUnits);
    bool getSignalStable(int stableLength, TimeUnits stableUnits);
    
    SignalType getSignalLastType(int index = 0);
    uint getSignalLastMilliseconds(int index = 0);
    datetime getSignalLastDatetime(int index = 0);
    uint getSignalLastCycles(int index = 0);
};

void DataHistory::DataHistory() {
    ArraySetAsSeries(data, true); 
    ArraySetAsSeries(signalLastType, true);
    ArraySetAsSeries(signalLastMilliseconds, true);
    ArraySetAsSeries(signalLastDatetime, true);
    ArraySetAsSeries(signalLastCycles, true);
        // this affects ArrayResize behavior by shifting all values up in index 
        // (i.e., element 0 is copied onto index 1 and then index 0 is freed.)
}

void DataHistory::DataHistory(int dataHistoryCountIn, int signalHistoryCountIn) {
    ArraySetAsSeries(data, true); 
    ArraySetAsSeries(signalLastType, true);
    ArraySetAsSeries(signalLastMilliseconds, true);
    ArraySetAsSeries(signalLastDatetime, true);
    ArraySetAsSeries(signalLastCycles, true);
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
    
    size = ArraySize(signalLastType);
    if(size > signalHistoryCount) { 
        Common::ArrayDelete(signalLastType, 0, size-signalHistoryCount); 
        Common::ArrayDelete(signalLastMilliseconds, 0, size-signalHistoryCount);
        Common::ArrayDelete(signalLastDatetime, 0, size-signalHistoryCount); 
        Common::ArrayDelete(signalLastCycles, 0, size-signalHistoryCount);
        size = signalHistoryCount; 
    }
    ArrayResize(signalLastType, size, signalHistoryCount-size); 
    ArrayResize(signalLastMilliseconds, size, signalHistoryCount-size); 
    ArrayResize(signalLastDatetime, size, signalHistoryCount-size); 
    ArrayResize(signalLastCycles, size, signalHistoryCount-size); 
}

void DataHistory::addData(DataUnit *unit) {
    updateDataTimes(unit);
    
    Common::ArrayPush(data, unit, dataHistoryCount);
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
    if(ArraySize(data) <= checkIndex || Common::IsInvalidPointer(data[checkIndex])) { return; }
    
    if (unit.signal != data[checkIndex].signal) {
        Common::ArrayPush(signalLastMilliseconds, GetTickCount(), signalHistoryCount);
        Common::ArrayPush(signalLastDatetime, TimeCurrent(), signalHistoryCount);
        Common::ArrayPush(signalLastCycles, (uint)0, signalHistoryCount);
        Common::ArrayPush(signalLastType, data[checkIndex].signal, signalHistoryCount);
    } else if(ArraySize(signalLastCycles) > 0 ) { signalLastCycles[0]++; }
    
    // can't get this to work due to function template weirdness
    //if (unit.getRawValue() != data[checkIndex].getRawValue();) {
        //lastValueTime.milliseconds = GetTickCount();
        //lastValueTime.dateTime = TimeCurrent();
        //lastValueTime.cycles = 0;
    //} else { lastValueTime.cycles++; }
}

SignalType DataHistory::getSignal(int unitIdx = 0) {
    if(unitIdx >= ArraySize(data) || Common::IsInvalidPointer(data[unitIdx])) { return SignalNone; }
    else { return data[unitIdx].signal; }
}

int DataHistory::getSignalDuration(TimeUnits stableUnits) {
    //((cur) >= (prev)) ? ((cur)-(prev)) : ((0xFFFFFFFF-(prev))+(cur)+1)
    switch(stableUnits) {
        case UnitSeconds: {
            datetime cur = TimeCurrent();
            datetime prev = getSignalLastDatetime();
            int duration = (cur >= prev) ? cur-prev : INT_MAX-prev+cur+1;
            return duration;
        }
        
        case UnitMilliseconds: {
            uint cur = GetTickCount();
            uint prev = getSignalLastMilliseconds();
            uint duration = (cur >= prev) ? cur-prev : UINT_MAX-prev+cur+1;
            return duration;
        }
            
        case UnitTicks: {
            return getSignalLastCycles(); // this is just added iteratively
        }
            
        default:
            return -1;
    }
}

bool DataHistory::getSignalStable(int stableLength, TimeUnits stableUnits) {
    return (getSignalDuration(stableUnits) >= stableLength);
}

SignalType DataHistory::getSignalLastType(int index = 0) {
    if(ArraySize(signalLastType) > index) { return signalLastType[index]; }
    else { return SignalNone; }
}

uint DataHistory::getSignalLastMilliseconds(int index = 0) {
    if(ArraySize(signalLastMilliseconds) > index) { return signalLastMilliseconds[index]; }
    else { return 0; }
}

datetime DataHistory::getSignalLastDatetime(int index = 0) {
    if(ArraySize(signalLastDatetime) > index) { return signalLastDatetime[index]; }
    else { return 0; }
}

uint DataHistory::getSignalLastCycles(int index = 0) {
    if(ArraySize(signalLastCycles) > index) { return signalLastCycles[index]; }
    else { return 0; }
}