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

//+------------------------------------------------------------------+

class FilterManager {
    public:
    Filter *filters[];
    
    FilterManager();
    ~FilterManager();
    
    int addFilter(Filter *unit);
    int getFilterId(string filterName, bool isDualName = false);
    int getSubfilterId(string filterDualName);
    int getSubfilterId(string filterName, string subfilterName);
    int getSubfilterId(int filterId, string subfilterName, bool isDualId = false);
    int getFilterCount();
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
string FilterManager::DualIdDelimiter = "^";

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

int FilterManager::getFilterId(string filterName, bool isDualName = false) {
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
        if(StringToLower(filters[i].shortName) == StringToLower(filterName)) { return i; }
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
        if(StringToLower(filters[filterId].subfilterName[i]) == StringToLower(subfilterName)) { return i; }
    }

    return -1;
}

int FilterManager::getFilterCount() {
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

void FilterManager::calculateSubfilterByIndex(int filterIndex, int subfilterId, int symbolIndex) {
    DataUnit *data = new DataUnit();
    
    if(filters[filterIndex].calculate(subfilterId, symbolIndex, data)) {
        data.success = true;
        // data datetime?
        MainDataMan.getDataHistory(symbolIndex, filterIndex, subfilterId).addData(data);
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
