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
#include "../MMT_Data/MMT_Data.mqh"
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
    
    int subfilterCount(SubfilterType type = SubfilterAllTypes);
    
    virtual void init() { Error::ThrowError(ErrorNormal, "Filter: init not implemented", FunctionTrace, shortName); }
    virtual bool calculate(int subfilterIndex, string symbol, DataUnit *dataOut) { Error::ThrowError(ErrorNormal, "Filter: Calculate not implemented", FunctionTrace, shortName); return false; }
    
    protected:    
    void setupSubfilters(string pairList, string nameList, SubfilterType subfilterTypeIn, bool addToArray = true);
    bool checkSafe(int subfilterIndex);
};

int Filter::subfilterCount(SubfilterType type = SubfilterAllTypes) {
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
    
    MultiSettings::Parse(nameList, subfilterName, pairCount, addToArray);
    
    for(int i = oldSize; i < oldSize + ArraySize(subfilterMode); i++) {
        Common::ArrayPush(subfilterType, subfilterTypeIn);
    }
}

bool Filter::checkSafe(int subfilterIndex) {
    if(subfilterIndex >= subfilterCount()) {
        Error::ThrowError(ErrorNormal, "Subfilter index does not exist", FunctionTrace, shortName + "-" + subfilterIndex + "|" + subfilterCount());
        return false;
    }
    
    if(subfilterMode[subfilterIndex] <= 0) {
        Error::ThrowError(ErrorMinor, "Subfilter index is disabled, skipping.", FunctionTrace, shortName + "-" + subfilterIndex);
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+

class FilterManager {
    public:
    Filter *filters[];
    
    FilterManager();
    ~FilterManager();
    
    int addFilter(Filter *unit);
    int getFilterId(string filterShortName);
    int filterCount();
    void deleteAllFilters();
    
    void calculateSubfilterByIndex(int filterIndex, int subfilterIndex, string symbol);
    void calculateSubfilters(int filterIndex, string symbol);
    void calculateFilterByIndex(int index, string symbol);
    void calculateFilters(string symbol);
};

extern string Lbl_IndisAndFilters="********** Indicators & Filters **********"; // Filter List
extern string Lbl_FilterLegend="0 = Disabled; 1 = Normal; 2 = Opposite; 3 = Not Opposite"; // Legend
extern string Lbl_Format="a=1|b=0|c=1"; // Format
extern string Lbl_Format2="# of subfilters must be same across a filter's settings."; // Format
extern string Lbl_Format3="Do not add a trailing |";

void FilterManager::FilterManager() {

}

void FilterManager::~FilterManager() {
    deleteAllFilters();
}

//+------------------------------------------------------------------+
// Class methods [METHODS]
//+------------------------------------------------------------------+

int FilterManager::addFilter(Filter *unit) {
    unit.init();
    int size = ArraySize(filters); // assuming 1-based
    Common::ArrayPush(filters, unit);
    return size+1;
}

int FilterManager::getFilterId(string filterShortName) {
    int size = ArraySize(filters);
    
    for(int i = 0; i < size; i++) {
        if(StringToLower(filters[i].shortName) == StringToLower(filterShortName)) { return i; }
    }

    return -1;
}

int FilterManager::filterCount() {
    return ArraySize(filters);
}

void FilterManager::deleteAllFilters() {
    int size = ArraySize(filters); // assuming 1-based
    
    for(int i=0; i < size; i++) {
        delete(filters[i]);
    }
    
    ArrayFree(filters);
    
    return;
}

void FilterManager::calculateSubfilterByIndex(int filterIndex, int subfilterIndex, string symbol) {
    DataUnit *data = new DataUnit();
    
    if(filters[filterIndex].calculate(subfilterIndex, symbol, data)) {
        data.success = true;
        // data datetime?
        MainDataMan.getDataHistory(symbol, filterIndex, subfilterIndex).addData(data);
    } else {
        delete(data);
    }
}

void FilterManager::calculateSubfilters(int filterIndex, string symbol) {
    int size = filters[filterIndex].subfilterCount();
    
    for(int i = 0; i < size; i++) {
        calculateSubfilterByIndex(filterIndex, i, symbol);
    }
}

void FilterManager::calculateFilterByIndex(int index, string symbol) {
    calculateSubfilters(index, symbol);
}

void FilterManager::calculateFilters(string symbol) {
    int size = ArraySize(filters);
    
    for(int i = 0; i < size; i++) {
        calculateFilterByIndex(i, symbol);
    }
}

//+------------------------------------------------------------------+
// Helper methods [HELPERS]
//+------------------------------------------------------------------+

FilterManager *MainFilterMan;
