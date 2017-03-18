//+------------------------------------------------------------------+
//|                                                     MMT_Data.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MC_Common/MC_MultiSettings.mqh"
#include "../MMT_Symbols.mqh"
#include "../MMT_Filters/MMT_FilterManager.mqh"
#include "MMT_DataHistory.mqh"

//+------------------------------------------------------------------+
// DataManager and members
//+------------------------------------------------------------------+

// Workaround for dynamic multidimensional arrays
// There's really no reason to store the data using classes
// except that multidimensional arrays are fixed
// and we don't know ahead of time how big the array needs to be.

class DataSubfilter {
    public:
    DataSubfilter(int dataHistoryCount = -1, int signalHistoryCount = -1);
    ~DataSubfilter();
    DataHistory *history;
    
    //void deleteAllDataHistory();
};

void DataSubfilter::DataSubfilter(int dataHistoryCount = -1, int signalHistoryCount = -1) {
    history = new DataHistory(dataHistoryCount, signalHistoryCount);
}

void DataSubfilter::~DataSubfilter() {
    Common::SafeDelete(history);
}

//+------------------------------------------------------------------+

class DataFilter {
    public:
    DataFilter(int totalSubfilterCount, int historyCount = -1);
    DataSubfilter *subfilter[];
    
    ~DataFilter();
};

void DataFilter::DataFilter(int totalSubfilterCount, int historyCount = -1) {
    ArrayResize(subfilter, totalSubfilterCount);
    
    //todo: subfilter if disabled?
    
    int i = 0;
    for(i = 0; i < totalSubfilterCount; i++) {
        subfilter[i] = new DataSubfilter(historyCount);
    }
}

void DataFilter::~DataFilter() {
    int size = ArraySize(subfilter);
    
    for(int i = 0; i < size; i++) {
        Common::SafeDelete(subfilter[i]);
    }
}

//+------------------------------------------------------------------+

class DataSymbol {
    public:
    DataFilter *filter[];
    
    DataSymbol();
    DataSymbol(int filterCount);
    ~DataSymbol();
    
    // void deleteAllFilterData();
};

void DataSymbol::DataSymbol(int filterCount) {
    ArrayResize(filter, filterCount);
    
    for(int i = 0; i < filterCount; i++) {
        filter[i] = new DataFilter(
            MainFilterMan.filters[i].getSubfilterCount(),
            -1 //MainFilterMan.getFilterHistoryCount(i) //, MainFilterMan.getFilterHistoryCount(i, true)
            );
    }
}

void DataSymbol::~DataSymbol() {
    int size = ArraySize(filter);
    
    for(int i = 0; i < size; i++) {
        Common::SafeDelete(filter[i]);
    }
}

//+------------------------------------------------------------------+

class DataManager {
    public:
    DataSymbol *symbol[];
    
    DataManager(int symbolCount, int filterCount);
    ~DataManager();
    
    DataHistory *getDataHistory(string symName, string filterName, int subfilterId);
    DataHistory *getDataHistory(int symbolId, int filterId, int subfilterId);
    DataHistory *getDataHistory(int symbolId, string filterName, int subfilterId);
    DataHistory *getDataHistory(string symbolId, int filterId, int subfilterId);
    
    // void deleteAllSymbolData();
};

void DataManager::DataManager(int symbolCount, int filterCount) {
    ArrayResize(symbol, symbolCount);
    
    for(int i = 0; i < symbolCount; i++) {
        symbol[i] = new DataSymbol(filterCount);
    }
}

void DataManager::~DataManager() {
    int size = MainSymbolMan.getSymbolCount();
    
    //void deleteAllSymbolData();
    for(int i = 0; i < size; i++) {
        Common::SafeDelete(symbol[i]);
    }
}

DataHistory *DataManager::getDataHistory(int symbolId, int filterId, int subfilterId){
    return symbol[symbolId].filter[filterId].subfilter[subfilterId].history;
}

DataHistory *DataManager::getDataHistory(string symName, string filterName, int subfilterId){
    return getDataHistory(MainSymbolMan.getSymbolId(symName), MainFilterMan.getFilterId(filterName), subfilterId);
}

DataHistory *DataManager::getDataHistory(int symbolId, string filterName, int subfilterId){
    return getDataHistory(symbolId, MainFilterMan.getFilterId(filterName), subfilterId);
}

DataHistory *DataManager::getDataHistory(string symName, int filterId, int subfilterId){
    return getDataHistory(MainSymbolMan.getSymbolId(symName), filterId, subfilterId);
}

DataManager *MainDataMan;
