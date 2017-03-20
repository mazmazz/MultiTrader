//+------------------------------------------------------------------+
//|                                                     MMT_Data.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MMT_Settings.mqh"
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
    Common::SafeDeletePointerArray(subfilter);
}

//+------------------------------------------------------------------+

class DataSymbol {
    public:
    DataFilter *filter[];
    SignalUnit *entrySignal[];
    SignalUnit *exitSignal[];
    SignalType pendingEntrySignalType;
    SignalType pendingExitSignalType;
    
    DataSymbol();
    DataSymbol(int filterCount);
    ~DataSymbol();
    
    void addSignalUnit(SignalType signal, bool isEntry);
    SignalUnit *getSignalUnit(bool isEntry, int index = 0);
    void updateSymbolSignal(int filterIdx, int subfilterIdx);
    
    private:
    int signalHistoryCount;
    
    void setHistoryCount(int signalHistoryCountIn = -1);
};

void DataSymbol::DataSymbol(int filterCount) {
    ArrayResize(filter, filterCount);
    
    for(int i = 0; i < filterCount; i++) {
        filter[i] = new DataFilter(
            MainFilterMan.filters[i].getSubfilterCount(),
            -1 //MainFilterMan.getFilterHistoryCount(i) //, MainFilterMan.getFilterHistoryCount(i, true)
            );
    }
    
    ArraySetAsSeries(entrySignal, true);
    ArraySetAsSeries(exitSignal, true);
    setHistoryCount(SignalHistoryLevel);
}

void DataSymbol::~DataSymbol() {
    Common::SafeDeletePointerArray(filter);
    Common::SafeDeletePointerArray(entrySignal);
    Common::SafeDeletePointerArray(exitSignal);
}

void DataSymbol::setHistoryCount(int signalHistoryCountIn = -1) {
    signalHistoryCount = signalHistoryCountIn < 1 ? MathMax(1, SignalHistoryLevel) : signalHistoryCountIn;

    int size = ArraySize(entrySignal);
    if(size > signalHistoryCount) { 
        Common::ArrayDelete(entrySignal, 0, size-signalHistoryCount);
        size = signalHistoryCount; 
    }
    ArrayResize(entrySignal, size, signalHistoryCount-size); 
    
    size = ArraySize(exitSignal);
    if(size > signalHistoryCount) { 
        Common::ArrayDelete(exitSignal, 0, size-signalHistoryCount);
        size = signalHistoryCount; 
    }
    ArrayResize(exitSignal, size, signalHistoryCount-size); 
}

void DataSymbol::addSignalUnit(SignalType signal, bool isEntry) {
    bool force; 
    SignalType compareSignal;
    SignalUnit *compareUnit = getSignalUnit(isEntry);
    if(Common::IsInvalidPointer(compareUnit)) { force = true; }
    else { compareSignal = compareUnit.type; }
    
    if (force || (signal != compareSignal)) {
        SignalUnit *signalUnit = new SignalUnit();
        signalUnit.timeMilliseconds = GetTickCount();
        signalUnit.timeDatetime = TimeCurrent();
        signalUnit.timeCycles = 0;
        signalUnit.type = signal;
        if(isEntry) { Common::ArrayPush(entrySignal, signalUnit, signalHistoryCount); }
        else { Common::ArrayPush(exitSignal, signalUnit, signalHistoryCount); }
    } else {
        if(isEntry) {
            if(ArraySize(entrySignal) > 0 && !Common::IsInvalidPointer(entrySignal[0])) { 
                entrySignal[0].timeCycles++;
            }
        } else {
            if(ArraySize(exitSignal) > 0 && !Common::IsInvalidPointer(exitSignal[0])) { 
                exitSignal[0].timeCycles++;
            }
        }
    }
}

SignalUnit *DataSymbol::getSignalUnit(bool isEntry, int index = 0) {
    if(isEntry) {
        if(ArraySize(entrySignal) > index) { return entrySignal[index]; }
        else { return NULL; }
    } else {
        if(ArraySize(exitSignal) > index) { return exitSignal[index]; }
        else { return NULL; }
    }
}

void DataSymbol::updateSymbolSignal(int filterIdx, int subfilterIdx) {
    SubfilterType subType = MainFilterMan.filters[filterIdx].subfilterType[subfilterIdx];
    SubfilterMode subMode = MainFilterMan.filters[filterIdx].subfilterMode[subfilterIdx];
    SignalType subSignalType = filter[filterIdx].subfilter[subfilterIdx].history.getSignal();
    bool subSignalStable;
    
    if(subMode == SubfilterDisabled) { return; }
    //if(subSignalType != SignalBuy && subSignalType != SignalSell) { return; }
    if(subType != SubfilterEntry && subType != SubfilterExit) { return; }
    
    SignalType compareSignalType;
    SignalType resultSignalType = SignalNone;
    
    if(subType == SubfilterEntry) { compareSignalType = pendingEntrySignalType; }
    else { compareSignalType = pendingExitSignalType; }
    
    if(compareSignalType == SignalHold) { return; }
    
    if(subSignalType != SignalNone) {
        subSignalStable = filter[filterIdx].subfilter[subfilterIdx].history.getSignalStable(
            subType == SubfilterEntry ? EntryStableTime : ExitStableTime
            , TimeSettingUnit
            );
    } else { subSignalStable = true; } // we want this to negate symbolSignals right away
    
    switch(subMode) {
        case SubfilterNormal:
            if(!subSignalStable) { 
                if(subSignalType == SignalBuy || subSignalType == SignalSell) {
                    resultSignalType = SignalHold; 
                }
            } else {
                switch(subSignalType) {
                    case SignalBuy:
                        if(compareSignalType == SignalShort) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalLong;
                        }
                        break;
                        
                    case SignalSell:
                        if(compareSignalType == SignalLong) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalShort;
                        }
                        break;
                        
                    default:
                        resultSignalType = SignalHold;
                        break;
                }
            }
            break;
            
        case SubfilterOpposite:
            if(!subSignalStable) {
                if(subSignalType == SignalBuy || subSignalType == SignalSell) {
                    resultSignalType = SignalHold; 
                }
            } else {
                switch(subSignalType) {
                    case SignalBuy:
                        if(compareSignalType == SignalLong) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalShort;
                        }
                        break;
                        
                    case SignalSell:
                        if(compareSignalType == SignalShort) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalLong;
                        }
                        break;
                        
                    default:
                        resultSignalType = SignalHold;
                        break;
                }
            }
            break;
            
        case SubfilterNotOpposite:
            if(!subSignalStable) { break; }
            
            if(
                (compareSignalType == SignalLong && subSignalType == SignalSell)
                || (compareSignalType == SignalShort && subSignalType == SignalBuy)
            ) {
                resultSignalType = SignalHold;
            }
            break;
            
        default: break;
    }
    
    if(subType == SubfilterEntry) { pendingEntrySignalType = resultSignalType; } 
    else { pendingExitSignalType = resultSignalType; }
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
    
    bool retrieveDataFromFilters();
    
    // void deleteAllSymbolData();
};

void DataManager::DataManager(int symbolCount, int filterCount) {
    ArrayResize(symbol, symbolCount);
    
    for(int i = 0; i < symbolCount; i++) {
        symbol[i] = new DataSymbol(filterCount);
    }
}

void DataManager::~DataManager() {
    Common::SafeDeletePointerArray(symbol);
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

bool DataManager::retrieveDataFromFilters() {
    int size = ArraySize(MainSymbolMan.symbols);
    
    for(int i = 0; i < size; i++) {
        symbol[i].pendingEntrySignalType = SignalNone;
        symbol[i].pendingExitSignalType = SignalNone;
        MainFilterMan.calculateFilters(i);
        symbol[i].addSignalUnit(symbol[i].pendingEntrySignalType, true);
        symbol[i].addSignalUnit(symbol[i].pendingExitSignalType, false);
        
    }
    
    return true;
}

DataManager *MainDataMan;
