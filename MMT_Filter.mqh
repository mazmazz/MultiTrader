//+------------------------------------------------------------------+
//|                                    MultiTrader Main Settings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Helper_Error.mqh"
#include "MMT_OptionsParser.mqh"

enum CheckMode {
    CheckDisabled,
    CheckNormal,
    CheckOpposite,
    CheckNotOpposite
};

enum CheckType {
    CheckAllTypes,
    CheckEntry,
    CheckExit,
    CheckValue
};

class Filter {
    protected:    
    void setupChecks(string pairList, CheckType checkTypeIn, bool addToArray = false);
    void setupOptions() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
    
    public:
    int checkMode[];
    
    int entryCheckId[]; int entryCheckCount;
    int exitCheckId[]; int exitCheckCount;
    int valueCheckId[]; int valueCheckCount;
    
    string shortName;
    
    void calculateEntry() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
    void calculateExit() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
};

class FilterManager {
    private:
    Filter *filters[];

    public:
    FilterManager();
    ~FilterManager();
    
    int addFilter(Filter *unit);
    int getFilterId(string filterShortName);
    int getFilterCheckCount(string filterShortName, CheckType type = CheckAllTypes);
    int getFilterCheckCount(int filterId, CheckType type = CheckAllTypes);
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

int FilterManager::getFilterCheckCount(string filterShortName, CheckType type = CheckAllTypes) {
    int filterId = getFilterId(filterShortName);
    
    if(filterId < 0) { return -1; }
    else { return getFilterCheckCount(filterId, type); }
}

int FilterManager::getFilterCheckCount(int filterId, CheckType type = CheckAllTypes) {
    switch(type) {
        case CheckEntry: return filters[filterId].entryCheckCount;
        case CheckExit: return filters[filterId].exitCheckCount;
        case CheckValue: return filters[filterId].valueCheckCount;
        default: return filters[filterId].entryCheckCount + filters[filterId].exitCheckCount + filters[filterId].valueCheckCount;
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

void Filter::setupChecks(string pairList, CheckType checkTypeIn, bool addToArray = false) {
    switch(checkTypeIn) {
        case CheckEntry:
            entryCheckCount = OptionsParser::CountPairs(pairList);
            if(entryCheckCount > 0) { OptionsParser::Parse(pairList, checkMode, entryCheckId, entryCheckCount, addToArray); }
            break;
        
        case CheckExit:
            exitCheckCount = OptionsParser::CountPairs(pairList);
            if(exitCheckCount > 0) { OptionsParser::Parse(pairList, checkMode, exitCheckId, exitCheckCount, addToArray); }
            break;
            
        case CheckValue:
            valueCheckCount = OptionsParser::CountPairs(pairList);
            if(valueCheckCount > 0) { OptionsParser::Parse(pairList, checkMode, valueCheckId, valueCheckCount, addToArray); }
            break;
    }
}

//+------------------------------------------------------------------+
// Helper methods [HELPERS]
//+------------------------------------------------------------------+
