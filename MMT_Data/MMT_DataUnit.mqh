//+------------------------------------------------------------------+
//|                                                 MMT_DataUnit.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

enum SignalType {
    SignalNone,
    SignalBuy,
    SignalSell,
    SignalHold
};

//+------------------------------------------------------------------+
// DataList and DataUnit
//+------------------------------------------------------------------+

class DataUnit {
    public:
    bool success;
    SignalType signal;
    string rawValueType;
    string debugValue;
    
    DataUnit();
    DataUnit(bool successIn);
    template<typename T>
    DataUnit(bool successIn, T value, SignalType signalInput = SignalNone, string debugValueInput = "", datetime lastUpdate = 0);
    
    template <typename T>
    void setRawValue(T value, SignalType signalInput = SignalNone, string debugValueInput = "", datetime lastChangedTimeInput = 0);
    
    template<typename T>
    bool getRawValue(T &value);
    template <typename T>
    T getRawValue();
    
    string getStringValue();
    
    private:
    //template<typename T>
    //T rawValue;
    
    string rawValueString;
    int rawValueInt;
    double rawValueDouble;
    bool rawValueBool;
    
    datetime lastChangedTime; // todo: how to express milliseconds?
};

void DataUnit::DataUnit() { 
    success = false;
}

void DataUnit::DataUnit(bool successIn) {
    success = successIn;
}

template <typename T>
void DataUnit::DataUnit(bool successIn, T value, SignalType signalInput = SignalNone, string debugValueInput = "", datetime lastUpdate = 0) {
    setRawValue(value, signalInput, debugValueInput, lastUpdate);
}

template <typename T>
void DataUnit::setRawValue(T value, SignalType signalInput = SignalNone, string debugValueInput = "", datetime lastChangedTimeInput = 0) { 
    //rawValue = value; 
    rawValueType = typename(T);
    signal = signalInput; 
    debugValue = debugValueInput;
    lastChangedTime = lastChangedTimeInput <= 0 ? TimeLocal() : lastChangedTimeInput;
    
    if(rawValueType == "int") { rawValueInt = value; }
    else if(rawValueType == "double") { rawValueDouble = value; }
    else if(rawValueType == "bool") { rawValueBool = value; }
    else { rawValueString = value; }
}

template <typename T>
bool DataUnit::getRawValue(T &value) {
    if(typename(T) != rawValueType) { return false; }
    
    //value = rawValue; 
    //return true;
    
    if(rawValueType == "int") { value = rawValueInt; }
    else if(rawValueType == "double") { value = rawValueDouble; }
    else if(rawValueType == "bool") { value = rawValueBool; }
    else { value = rawValueString; }
    
    return true;
}

template <typename T>
T DataUnit::getRawValue() {
    if(typename(T) != rawValueType) { return NULL; }
    
    //return rawValue;
    
    if(rawValueType == "int") { return rawValueInt; }
    else if(rawValueType == "double") { return rawValueDouble; }
    else if(rawValueType == "bool") { return rawValueBool; }
    else { return rawValueString; }
}

string DataUnit::getStringValue() {
    string result;
    
    //if(rawValueType == "int") { return IntegerToString(rawValue); }
    //else if(rawValueType == "double") { return DoubleToString(rawValue); }
    //else if(rawValueType == "bool") { return rawValue ? "True" : "False"; }
    //else { return rawValue; }
    
    if(rawValueType == "int") { return IntegerToString(rawValueInt); }
    else if(rawValueType == "double") { return DoubleToString(rawValueDouble); }
    else if(rawValueType == "bool") { return rawValueBool ? "True" : "False"; }
    else { return rawValueString; }
}