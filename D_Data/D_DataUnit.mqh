//+------------------------------------------------------------------+
//|                                                 D_DataUnit.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include <MC_Common/MC_Common.mqh>

enum SignalType {
    SignalNone,
    SignalBuy,
    SignalSell,
    SignalHold,
    SignalOpen,
    SignalClose,
    SignalLong,
    SignalShort
};

class SignalUnit { // ordinarily this would be a struct, but you can't get pointers from structs
    public: 
    SignalType type;
    string message;
    uint timeMilliseconds;
    datetime timeDatetime;
    uint timeCycles;
    
    bool fulfilled;
    bool blocked;
    bool retry;
    //bool force;
    
    SignalUnit() {
        type = SignalNone;
        message = NULL;
        timeMilliseconds = 0;
        timeDatetime = 0;
        timeCycles = 0;
        fulfilled = false;
        blocked = false;
        retry = false;
        //force = false;
    }
    
    SignalType getOppositeType() {
        switch(type) {
            case SignalBuy: return SignalSell;
            case SignalSell: return SignalBuy;
            case SignalLong: return SignalShort;
            case SignalShort: return SignalLong;
            case SignalOpen: return SignalClose;
            case SignalClose: return SignalOpen;
            case SignalHold:
            default: return SignalNone;
        }
    };
};

//+------------------------------------------------------------------+
// DataList and DataUnit
//+------------------------------------------------------------------+

class DataUnit {
    public:
    bool success;
    //bool force;
    SignalType signal;
    string rawValueType;
    string stringValue;
    datetime lastChangedTime; // todo: how to express milliseconds?
    
    DataUnit();
    DataUnit(bool successIn);
    template<typename T>
    DataUnit(bool successIn, T value, SignalType signalInput = SignalNone, string stringValueInput = "", datetime lastUpdate = 0/*, bool forceIn = false*/);
    
    template <typename T>
    void setRawValue(T value, SignalType signalInput = SignalNone, string stringValueInput = "", datetime lastChangedTimeInput = 0/*, bool forceIn = false*/);
    
    template<typename T>
    bool getRawValue(T &value);
    template <typename T>
    T getRawValue();
    
    string getStringValue(int doubleDigits = -1);
    
    private:
    string rawValueString;
    int rawValueInt;
    double rawValueDouble;
    bool rawValueBool;
};

void DataUnit::DataUnit() { 
    success = false;
    signal = SignalNone;
    rawValueType = NULL; 
    stringValue = NULL;
    lastChangedTime = 0;
    rawValueString = NULL;
    rawValueInt = 0;
    rawValueDouble = 0;
    rawValueBool = false;
    //force = false;
}

void DataUnit::DataUnit(bool successIn) {
    success = successIn;
    signal = SignalNone;
    rawValueType = NULL; 
    stringValue = NULL;
    lastChangedTime = 0;
    rawValueString = NULL;
    rawValueInt = 0;
    rawValueDouble = 0;
    rawValueBool = false;
    //force = false;
}

template <typename T>
void DataUnit::DataUnit(bool successIn, T value, SignalType signalInput = SignalNone, string stringValueInput = "", datetime lastUpdate = 0/*, bool forceIn = false*/) {
    success = successIn;
    signal = SignalNone;
    rawValueType = NULL; 
    stringValue = NULL;
    lastChangedTime = 0;
    rawValueString = NULL;
    rawValueInt = 0;
    rawValueDouble = 0;
    rawValueBool = false;
    //force = false;
    setRawValue(value, signalInput, stringValueInput, lastUpdate, forceIn);
}

template <typename T>
void DataUnit::setRawValue(T value, SignalType signalInput = SignalNone, string stringValueInput = "", datetime lastChangedTimeInput = 0/*, bool forceIn = false*/) { 
    rawValueType = typename(T);
    signal = signalInput; 
    stringValue = stringValueInput;
    lastChangedTime = lastChangedTimeInput <= 0 ? TimeLocal() : lastChangedTimeInput;
    //force = forceIn;
    
    if(rawValueType == "int") { rawValueInt = value; }
    else if(rawValueType == "double") { rawValueDouble = value; }
    else if(rawValueType == "bool") { rawValueBool = (int)value; }
    else { rawValueString = value; }
}

template <typename T>
bool DataUnit::getRawValue(T &value) {
    if(typename(T) != rawValueType) { return false; }
    
    if(rawValueType == "int") { value = rawValueInt; }
    else if(rawValueType == "double") { value = rawValueDouble; }
    else if(rawValueType == "bool") { value = (int)value; }
    else { value = rawValueString; }
    
    return true;
}

template <typename T>
T DataUnit::getRawValue() {
    if(typename(T) != rawValueType) { return NULL; }
    
    if(rawValueType == "int") { return rawValueInt; }
    else if(rawValueType == "double") { return rawValueDouble; }
    else if(rawValueType == "bool") { return rawValueBool; }
    else { return rawValueString; }
}

string DataUnit::getStringValue(int doubleDigits = -1) {
    string result = NULL;
    
    if(StringLen(stringValue) > 0) { return stringValue; }
    
    if(rawValueType == "int") { return IntegerToString(rawValueInt); }
    else if(rawValueType == "double") { return doubleDigits > -1 ? DoubleToString(rawValueDouble, doubleDigits) : DoubleToString(rawValueDouble); }
    else if(rawValueType == "bool") { return rawValueBool ? "True" : "False"; }
    else { return rawValueString; }
}
