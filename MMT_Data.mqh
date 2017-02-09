//+------------------------------------------------------------------+
//|                                                     MMT_Data.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Helper_OptionsParser.mqh"

enum SignalType {
    SignalNone,
    SignalBuy,
    SignalSell
};

// FilterDatum: One unit of data
class FilterDatum {
    private:
    string rawValueString;
    int rawValueInt;
    double rawValueDouble;
    bool rawValueBool;
    
    double lastChangedTime;
    
    public:
    FilterData();
    FilterData(string rawValue, SignalType signalInput = SignalNone, string debugValueInput = "")
        { rawValueString = rawValue; rawValueType = DataString; signal = signalInput; debugValue = debugValueInput; }
    FilterData(int rawValue, SignalType signalInput = SignalNone, string debugValueInput = "")
        { rawValueInt = rawValue; rawValueType = DataInt; signal = signalInput; debugValue = debugValueInput; }
    FilterData(double rawValue, SignalType signalInput = SignalNone, string debugValueInput = "")
        { rawValueDouble = rawValue; rawValueType = DataDouble; signal = signalInput; debugValue = debugValueInput; }
    FilterData(bool rawValue, SignalType signalInput = SignalNone, string debugValueInput = "")
        { rawValueBool = rawValue; rawValueType = DataBool; signal = signalInput; debugValue = debugValueInput; }
    
    DataType rawValueType;
    bool getRawValue(string& value) { if(rawValueType == DataString) { value = rawValueString; return true; } else { return false; } }
    bool getRawValue(int& value) { if(rawValueType == DataInt) { value = rawValueInt; return true; } else { return false; } }
    bool getRawValue(double& value) { if(rawValueType == DataDouble) { value = rawValueDouble; return true; } else { return false; } }
    bool getRawValue(bool& value) { if(rawValueType == DataBool) { value = rawValueBool; return true; } else { return false; } }
    
    string getRawValueString() { if(rawValueType == DataString) { return rawValueString; } else { return NULL; } }
    int getRawValueInt() { if(rawValueType == DataInt) { return rawValueInt; } else { return NULL; } }
    double getRawValueDouble() { if(rawValueType == DataDouble) { return rawValueDouble; } else { return NULL; } }
    bool getRawValueBool() { if(rawValueType == DataBool) { return rawValueBool; } else { return NULL; } };
    
    void setRawValue(string value) { rawValueString = value; rawValueType = DataString; }
    void setRawValue(int value) { rawValueInt = value; rawValueType = DataInt; }
    void setRawValue(double value) { rawValueDouble = value; rawValueType = DataDouble; }
    void setRawValue(bool value) { rawValueBool = value; rawValueType = DataBool; }
    
    string getStringValue();
    
    string debugValue;
    
    SignalType signal;
};

// FilterData: A list of FilterDatums
class FilterData {
    // List of filters, e.g., stoch
    // List of checks, e.g., stoch a b c d e ...
    // List of datum histories, e.g., [0], [1], [2], [3] (use array pop)
        // History buffer user set, update frequency is cycle count (or per candle? set by filter?)
    // Datum object
    
    // Filter should be able to access this too
    // what if it wants to do result lookback?
    
    
};