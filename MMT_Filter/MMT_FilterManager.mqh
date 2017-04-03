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
#include "MMT_Filter.mqh"
#include "../MMT_Data/MMT_Data.mqh"
#include "../MMT_Order/MMT_OrderManager.mqh"

class FilterManager {
    public:
    Filter *filters[];
    
    FilterManager();
    ~FilterManager();
    
    int addFilter(Filter *unit);
    int getFilterId(string filterName, bool isDualName = true);
    int getSubfilterId(string filterDualName);
    int getSubfilterId(string filterName, string subfilterName);
    int getSubfilterId(int filterId, string subfilterName, bool isDualId = false);
    int getFilterCount();
    int getSubfilterCount(int filterId, SubfilterType type = SubfilterAllTypes);
    void deleteAllFilters();
    
    void calculateSubfilterByIndex(int filterIndex, int subfilterId, int symbolIndex);
    void calculateSubfilters(int filterIndex, int symbolIndex);
    void calculateFilterByIndex(int index, int symbolIndex);
    void calculateFilters(int symbolIndex);
    
    private:
    static string DualNameDelimiter;
    static string DualIdDelimiter;
};

string FilterManager::DualNameDelimiter = "-";
string FilterManager::DualIdDelimiter = "~";

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

int FilterManager::getFilterId(string filterName, bool isDualName = true) {
    if(isDualName) {
        filterName = Common::StringTrim(filterName);
        
        // attempt dual name resolution ("[filterName]-[subfilterName]")
        int delimPos = StringFind(filterName, DualNameDelimiter);
        if(delimPos > 0) { filterName = StringSubstr(filterName, 0, delimPos); }
        else {
            // attempt ID resolution ("[filterId]^[subfilterId]" in numeric or ABC format)
            delimPos = StringFind(filterName, DualIdDelimiter);
            if(delimPos > 0) {
                filterName = StringSubstr(filterName, 0, delimPos);
                return Common::AddrAbcToInt(filterName); // return ABC or 123 to int
            } else { return -1; }
        }
    }
    
    int size = ArraySize(filters);
    
    for(int i = 0; i < size; i++) {
        if(StringCompare(filters[i].shortName, filterName, false) == 0) { return i; }
    }

    return -1;
}

int FilterManager::getSubfilterId(string filterDualName) {
    return getSubfilterId(-1, filterDualName, true);
}

int FilterManager::getSubfilterId(string filterName, string subfilterName) {
    return getSubfilterId(getFilterId(filterName), subfilterName);
}

int FilterManager::getSubfilterId(int filterId, string subfilterName, bool isDualName = false) {
    if(isDualName) {
        subfilterName = Common::StringTrim(subfilterName);
    
        if(filterId < 0) { 
            filterId = getFilterId(subfilterName, true); 
            if(filterId < 0) { return -1; }
        }
        
        // attempt dual name resolution ("[filterName]-[subfilterName]")
        int delimPos = StringFind(subfilterName, DualNameDelimiter);
        if(delimPos > 0) { subfilterName = StringSubstr(subfilterName, delimPos+1); }
        else {
            // attempt ID resolution ("[filterId]^[subfilterId]" in numeric or ABC format)
            delimPos = StringFind(subfilterName, DualIdDelimiter);
            if(delimPos > 0) {
                subfilterName = StringSubstr(subfilterName, delimPos+1);
                return Common::AddrAbcToInt(subfilterName); // return ABC or 123 to int
            } else { return -1; }
        }
    }
    
    int size = ArraySize(filters[filterId].subfilterName);
    
    for(int i = 0; i < size; i++) {
        if(StringCompare(filters[filterId].subfilterName[i], subfilterName, false) == 0) { return i; }
    }

    return -1;
}

int FilterManager::getFilterCount() {
    return ArraySize(filters);
}

int FilterManager::getSubfilterCount(int filterId, SubfilterType type = 0) {
    return filters[filterId].getSubfilterCount(type);
}

void FilterManager::deleteAllFilters() {
    Common::SafeDeletePointerArray(filters);
}

void FilterManager::calculateSubfilterByIndex(int filterIndex, int subfilterId, int symbolIndex) {
    DataUnit *data = new DataUnit();
    
    if(filters[filterIndex].calculate(subfilterId, symbolIndex, data)) {
        // todo: find a better place to put data processing
        // perhaps pass a dataunit as ref to this function
        // and put processing outside
        
        data.success = true;
        
        MainDataMan.getDataHistory(symbolIndex, filterIndex, subfilterId).addData(data);
        
        // also collate trade signals and stability in OrderMan here, iteratively
        // so we don't need to loop again in OrderMan to determine composite signal
        MainDataMan.symbol[symbolIndex].updateSymbolSignal(filterIndex, subfilterId);
    } else {
        delete(data);
    }
}

void FilterManager::calculateSubfilters(int filterIndex, int symbolIndex) {
    int size = filters[filterIndex].getSubfilterCount();
    
    for(int i = 0; i < size; i++) {
        calculateSubfilterByIndex(filterIndex, i, symbolIndex);
    }
}

void FilterManager::calculateFilterByIndex(int index, int symbolIndex) {
    calculateSubfilters(index, symbolIndex);
}

void FilterManager::calculateFilters(int symbolIndex) {
    int size = ArraySize(filters);
    
    for(int i = 0; i < size; i++) {
        calculateFilterByIndex(i, symbolIndex);
    }
}

//+------------------------------------------------------------------+
// Helper methods [HELPERS]
//+------------------------------------------------------------------+

FilterManager *MainFilterMan;
