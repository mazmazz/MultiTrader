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
    protected:    
    void setupSubfilters(string pairList, SubfilterType subfilterTypeIn, bool addToArray = false);
    void setupOptions() { Error::ThrowError(ErrorNormal, "Filter: Options not implemented", FunctionTrace); }
    
    public:
    int subfilterMode[];
    
    int entrySubfilterId[]; int entrySubfilterCount;
    int exitSubfilterId[]; int exitSubfilterCount;
    int valueSubfilterId[]; int valueSubfilterCount;
    
    string shortName;
    
    void calculateEntry() { Error::ThrowError(ErrorNormal, "Filter: calculateEntry not implemented", FunctionTrace); }
    void calculateExit() { Error::ThrowError(ErrorNormal, "Filter: calculateExit not implemented", FunctionTrace); }
};

class FilterManager {
    private:
    Filter *filters[];

    public:
    FilterManager();
    ~FilterManager();
    
    int addFilter(Filter *unit);
    int getFilterId(string filterShortName);
    int getFilterSubfilterCount(string filterShortName, SubfilterType type = SubfilterAllTypes);
    int getFilterSubfilterCount(int filterId, SubfilterType type = SubfilterAllTypes);
    void deleteAllFilters();
    
    int filterCount;
    string filterShortNames[];
};

extern string Lbl_IndisAndFilters="********** Indicators & Filters **********"; // Filter List
extern string Lbl_FilterLegend="0 = Disabled; 1 = Normal; 2 = Opposite; 3 = Not Opposite"; // Legend
extern string Lbl_Format="a=1;b=0;c=1 -OR- 1;0;1 -OR- 1"; // Format
extern string Lbl_Format2="# of values must be same across a filter's settings."; // Format
extern string Lbl_Format3="Do not add a trailing ; unless last value shall be empty.";
extern string Lbl_Format4="Only use double ;s with empty values.";

void FilterManager::FilterManager() {

}

void FilterManager::~FilterManager() {
    deleteAllFilters();
}

//+------------------------------------------------------------------+
// Class methods [METHODS]
//+------------------------------------------------------------------+

int FilterManager::addFilter(Filter *unit) {
    int size = ArraySize(filters); // assuming 1-based
    ArrayResize(filters, size+1);
    ArrayResize(filterShortNames, size+1);
    
    filters[size] = unit;
    filterShortNames[size] = unit.shortName;
    
    filterCount++;
    
    return size+1;
}

int FilterManager::getFilterId(string filterShortName) {
    int size = ArraySize(filterShortNames);
    
    for(int i = 0; i < size; i++) {
        if(StringCompare(filterShortNames[i], filterShortName) == 0) { return i; }
    }

    return -1;
}

int FilterManager::getFilterSubfilterCount(string filterShortName, SubfilterType type = SubfilterAllTypes) {
    int filterId = getFilterId(filterShortName);
    
    if(filterId < 0) { return -1; }
    else { return getFilterSubfilterCount(filterId, type); }
}

int FilterManager::getFilterSubfilterCount(int filterId, SubfilterType type = SubfilterAllTypes) {
    switch(type) {
        case SubfilterEntry: return filters[filterId].entrySubfilterCount;
        case SubfilterExit: return filters[filterId].exitSubfilterCount;
        case SubfilterValue: return filters[filterId].valueSubfilterCount;
        default: return filters[filterId].entrySubfilterCount + filters[filterId].exitSubfilterCount + filters[filterId].valueSubfilterCount;
    }
}

void FilterManager::deleteAllFilters() {
    int size = ArraySize(filters); // assuming 1-based
    
    for(int i=0; i < size; i++) {
        delete(filters[i]);
    }
    
    ArrayFree(filters);
    ArrayFree(filterShortNames);
    
    return;
}

void Filter::setupSubfilters(string pairList, SubfilterType subfilterTypeIn, bool addToArray = false) {
    switch(subfilterTypeIn) {
        case SubfilterEntry:
            entrySubfilterCount = MultiSettings::CountPairs(pairList);
            if(entrySubfilterCount > 0) { MultiSettings::Parse(pairList, subfilterMode, entrySubfilterId, entrySubfilterCount, addToArray); }
            break;
        
        case SubfilterExit:
            exitSubfilterCount = MultiSettings::CountPairs(pairList);
            if(exitSubfilterCount > 0) { MultiSettings::Parse(pairList, subfilterMode, exitSubfilterId, exitSubfilterCount, addToArray); }
            break;
            
        case SubfilterValue:
            valueSubfilterCount = MultiSettings::CountPairs(pairList);
            if(valueSubfilterCount > 0) { MultiSettings::Parse(pairList, subfilterMode, valueSubfilterId, valueSubfilterCount, addToArray); }
            break;
    }
}

//+------------------------------------------------------------------+
// Helper methods [HELPERS]
//+------------------------------------------------------------------+
