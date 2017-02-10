//+------------------------------------------------------------------+
//|                                    MultiTrader Main Settings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Helper_Error.mqh"

//+------------------------------------------------------------------+
//| Comments
//+------------------------------------------------------------------+
//
// How to Add Filters
// 1. Add include to include list [INCLUDES]
// 2. Add OnTick indi call to FilterList_OnTick [HOOKS]
//
//+------------------------------------------------------------------+

enum FilterMode {
    FilterDisabled,
    FilterNormal,
    FilterOpposite,
    FilterNotOpposite
};

class Filter {
    protected:
    int checkMode[];
    int exit_checkMode[];
    
    bool doEntry;
    bool doExit;
    
    void setupChecks(string entryList, string exitList);
    void setupOptions() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
    
    public:
    string shortName;
    int checkCount;
    int exit_checkCount;
    
    void onInit() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
    void onTimer() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
    void onDeinit() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
    
    void calculateEntry() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
    void calculateExit() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
};

class FilterManager {
    private:
    Filter *filters[];
    string filterShortNames[];

    public:
    FilterManager();
    
    void onInit();
    void onTimer();
    void onDeinit();
    
    int addFilter(Filter *unit);
    int getFilterId(string filterShortName);
    int getFilterCheckCount(string filterShortName, bool checkCount = false);
    int getFilterCheckCount(int filterId, bool checkCount = false);
    void deleteAllFilters();
    
    int filterCount;
    static int getMaxCheckMode(int &checkModeList[]);
};

extern string Lbl_IndisAndFilters="********** Indicators & Filters **********"; // Filter List
extern string Lbl_FilterLegend="0 = Disabled; 1 = Normal; 2 = Opposite; 3 = Not Opposite"; // Legend
extern string Lbl_Format="a=1;b=0;c=1 -OR- 1;0;1 -OR- 1"; // Format
extern string Lbl_Format2="# of values must be same across a filter's settings."; // Format
extern string Lbl_Format3="Do not add a trailing ; unless last value shall be empty.";
extern string Lbl_Format4="Only use double ;s with empty values.";

//+------------------------------------------------------------------+
// 1. Include filter includes here [INCLUDES]
//+------------------------------------------------------------------+

#include "MMT_Filter_Stoch.mqh"

//+------------------------------------------------------------------+
// 2. Add indi call to below method [HOOKS]
//+------------------------------------------------------------------+

void FilterManager::FilterManager() {
    addFilter(new FilterStoch());
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

int FilterManager::getFilterCheckCount(string filterShortName, bool exitCheck = false) {
    int filterId = getFilterId(filterShortName);
    
    if(filterId < 0) { return -1; }
    else { return getFilterCheckCount(filterId, exitCheck); }
}

int FilterManager::getFilterCheckCount(int filterId, bool exitCheck = false) {
    return exitCheck ? filters[filterId].exit_checkCount : filters[filterId].checkCount;
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

void Filter::setupChecks(string entryList, string exitList) {
    checkCount = OptionsParser::CountPairs(entryList);
    exit_checkCount = OptionsParser::CountPairs(exitList);
    
    if(checkCount < 1 && exit_checkCount < 1) {
        doEntry = false;
        doExit = false;
        return; 
    }
    
    OptionsParser::Parse(entryList, checkMode, checkCount);
    OptionsParser::Parse(exitList, exit_checkMode, exit_checkCount);
    
    doEntry = (FilterManager::getMaxCheckMode(checkMode) > 0);
    doExit = (FilterManager::getMaxCheckMode(exit_checkMode) > 0);
}

//+------------------------------------------------------------------+
// Runtime methods [RUNTIME]
//+------------------------------------------------------------------+

void FilterManager::onInit() {
    
}
//
//void FilterList_OnTick() {
//    
//}

void FilterManager::onTimer() {
    
}

void FilterManager::onDeinit() {
    deleteAllFilters();
}

//+------------------------------------------------------------------+
// Helper methods [HELPERS]
//+------------------------------------------------------------------+

int FilterManager::getMaxCheckMode(int &checkModeList[]) {
    int maxValueId = ArrayMaximum(checkModeList);
    
    if(maxValueId < 0) { return -1; }
    else { return checkModeList[maxValueId]; }
}

FilterManager *MainFilterManager;