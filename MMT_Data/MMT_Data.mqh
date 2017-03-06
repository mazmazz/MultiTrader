//+------------------------------------------------------------------+
//|                                                     MMT_Data.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MC_Common/MC_MultiSettings.mqh"
#include "../MMT_Main.mqh"
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
    DataSubfilter(int historyCount = -1);
    DataHistory *data;
    
    //void deleteAllDataHistory();
};

class DataFilter {
    public:
    DataFilter(int totalSubfilterCount, int historyCount = -1);
    DataSubfilter *subfilter[];
    
    //void deleteAllSubfilterData();
};

class DataSymbol {
    public:
    DataSymbol();
    DataSymbol(int filterCount);
    DataFilter *filter[];
    
    // void deleteAllFilterData();
};

class DataManager {
    private:
    DataSymbol *symbol[];
    
    public:
    DataManager(int symbolCount, int filterCount);
    ~DataManager();
    
    DataHistory *getDataHistory(string symName, string filterName, int filterSubfilterId);
    DataHistory *getDataHistory(int symbolId, int filterId, int filterSubfilterId);
    DataHistory *getDataHistory(int symbolId, string filterName, int filterSubfilterId);
    DataHistory *getDataHistory(string symbolId, int filterId, int filterSubfilterId);
    
    // void deleteAllSymbolData();
};

void DataSubfilter::DataSubfilter(int historyCount = -1) {
    data = new DataHistory(historyCount);
}

void DataFilter::DataFilter(int totalSubfilterCount, int historyCount = -1) {
    ArrayResize(subfilter, totalSubfilterCount);
    
    //todo: subfilter if disabled?
    
    int i = 0;
    for(i = 0; i < totalSubfilterCount; i++) {
        subfilter[i] = new DataSubfilter(historyCount);
    }
}

void DataSymbol::DataSymbol(int filterCount) {
    ArrayResize(filter, filterCount);
    
    for(int i = 0; i < filterCount; i++) {
        filter[i] = new DataFilter(
            Main.filterMan.getFilterSubfilterCount(i),
            -1 //Main.filterMan.getFilterHistoryCount(i) //, Main.filterMan.getFilterHistoryCount(i, true)
            );
    }
}

void DataManager::~DataManager() {
    int symbolCount = Main.symbolMan.symbolCount;
    int filterCount = 0; int subfilterCount = 0; int k = 0;
    
    //void deleteAllSymbolData();
    for(int i = 0; i < symbolCount; i++) {
        filterCount = Main.filterMan.filterCount;
        
        //void deleteAllFilterData();
        for(int j = 0; j < filterCount; j++) {
            subfilterCount = ArraySize(symbol[i].filter[j].subfilter);
            //void deleteAllSubfilterData();
            for(k = 0; k < subfilterCount; k++) {
                delete(symbol[i].filter[j].subfilter[k].data); //void deleteAllDataHistory();
                delete(symbol[i].filter[j].subfilter[k]); 
            }
            
            delete(symbol[i].filter[j]);
        }
        
        delete(symbol[i]);
    }
}

void DataManager::DataManager(int symbolCount, int filterCount) {
    ArrayResize(symbol, symbolCount);
    
    for(int i = 0; i < symbolCount; i++) {
        symbol[i] = new DataSymbol(filterCount);
    }
}

DataHistory *DataManager::getDataHistory(int symbolId, int filterId, int filterSubfilterId){
    return symbol[symbolId].filter[filterId].subfilter[filterSubfilterId].data;
}

DataHistory *DataManager::getDataHistory(string symName, string filterName, int filterSubfilterId){
    return getDataHistory(Main.symbolMan.getSymbolId(symName), Main.filterMan.getFilterId(filterName), filterSubfilterId);
}

DataHistory *DataManager::getDataHistory(int symbolId, string filterName, int filterSubfilterId){
    return getDataHistory(symbolId, Main.filterMan.getFilterId(filterName), filterSubfilterId);
}

DataHistory *DataManager::getDataHistory(string symName, int filterId, int filterSubfilterId){
    return getDataHistory(Main.symbolMan.getSymbolId(symName), filterId, filterSubfilterId);
}
