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
    int checkCount;
    int exit_checkCount;
    
    int checkMode[];
    int exit_checkMode[];
    
    bool doEntry;
    bool doExit;
    
    void setupChecks(string entryList, string exitList);
    void setupOptions() { ThrowError(1, ErrorFunctionTrace, "Not implemented"); }
    
    public:
    string shortName;
    
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
    void deleteAllFilters();
    
    static int getMaxCheckMode(int &checkModeList[]);
};

extern string Lbl_IndisAndFilters="********** Indicators & Filters **********"; // Filter List
extern string Lbl_FilterLegend="0 = Disabled; 1 = Normal; 2 = Opposite; 3 = Not Opposite"; // Legend
extern string Lbl_Format="a=1;b=0;c=1"; // Format
extern string Lbl_Format2="BE CAREFUL of double ;s and trailing ;s - only use with empty values."; // Format single digit

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
    
    return size+1;
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
