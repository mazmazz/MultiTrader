//+------------------------------------------------------------------+
//|                                    MultiTrader Main Settings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MC_Common/MC_Error.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../MMT_Data/MMT_DataUnit.mqh"

enum SubfilterMode {
    SubfilterDisabled,
    SubfilterNormal,
    SubfilterOpposite,
    SubfilterNotOpposite
};

enum SubfilterType {
    SubfilterAllTypes,
    SubfilterEntry,
    SubfilterExit,
    SubfilterValue
};

class Filter {
    public:
    SubfilterMode subfilterMode[];
    string subfilterName[];
    SubfilterType subfilterType[];
    
    int entrySubfilterId[];
    int exitSubfilterId[];
    int valueSubfilterId[];
    
    string shortName;
    
    int getSubfilterCount(SubfilterType type = SubfilterAllTypes);
    
    virtual void init() { Error::ThrowError(ErrorNormal, "Filter: init not implemented", FunctionTrace, shortName); }
    virtual bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) { Error::ThrowError(ErrorNormal, "Filter: Calculate not implemented", FunctionTrace, shortName); return false; }
    
    protected:    
    void setupSubfilters(string pairList, string nameList, SubfilterType subfilterTypeIn, bool addToArray = true);
    bool checkSafe(int subfilterId);
};

int Filter::getSubfilterCount(SubfilterType type = SubfilterAllTypes) {
    switch(type) {
        case SubfilterEntry: return ArraySize(entrySubfilterId);
        case SubfilterExit: return ArraySize(exitSubfilterId);
        case SubfilterValue: return ArraySize(valueSubfilterId);
        default: return ArraySize(subfilterMode); //ArraySize(filters[filterId].entrySubfilterId) + ArraySize(filters[filterId].exitSubfilterId) + ArraySize(filters[filterId].valueSubfilterId);
    }
}

void Filter::setupSubfilters(string pairList, string nameList, SubfilterType subfilterTypeIn, bool addToArray = true) {
    int pairCount = MultiSettings::CountPairs(pairList);
    int oldSize = ArraySize(subfilterMode);
    
    if(pairCount <= 0) { return; }
    
    switch(subfilterTypeIn) {
        case SubfilterEntry:
            MultiSettings::Parse(pairList, subfilterMode, entrySubfilterId, pairCount, addToArray);
            break;
        
        case SubfilterExit:
            MultiSettings::Parse(pairList, subfilterMode, exitSubfilterId, pairCount, addToArray);
            break;
            
        case SubfilterValue:
            MultiSettings::Parse(pairList, subfilterMode, valueSubfilterId, pairCount, addToArray);
            break;
    }
    
    Common::ArrayReserve(subfilterName, pairCount);
    MultiSettings::Parse(nameList, subfilterName, pairCount, addToArray);
    
    for(int i = oldSize; i < oldSize + ArraySize(subfilterMode); i++) {
        Common::ArrayPush(subfilterType, subfilterTypeIn);
    }
}

bool Filter::checkSafe(int subfilterId) {
    if(subfilterId >= getSubfilterCount()) {
        Error::ThrowError(ErrorNormal, "Subfilter index does not exist", FunctionTrace, shortName + "-" + subfilterId + "|" + getSubfilterCount());
        return false;
    }
    
    if(subfilterMode[subfilterId] <= 0) {
        Error::ThrowError(ErrorMinor, "Subfilter index is disabled, skipping.", FunctionTrace, shortName + "-" + subfilterId);
        return false;
    }

    return true;
}
