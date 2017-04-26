//+------------------------------------------------------------------+
//|                                                     D_Data.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../T_Settings.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../S_Symbol.mqh"
#include "../F_Filter/F_FilterManager.mqh"
#include "D_DataHistory.mqh"

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
    bool masterEntrySet;
    bool masterExitSet;
    
    DataSymbol();
    DataSymbol(int filterCount);
    ~DataSymbol();
    
    void addSignalUnit(SignalType signal, bool isEntry);
    SignalUnit *getSignalUnit(bool isEntry, int index = 0);
    void updateSymbolSignal(int filterIdx, int subfilterIdx);
    int getSignalDuration(TimeUnits stableUnits, SignalUnit *prevUnit, SignalUnit *curUnit = NULL);
    
    private:
    int signalHistoryCount;
    
    void setHistoryCount(int signalHistoryCountIn = -1);
};

void DataSymbol::DataSymbol(int filterCount) {
    pendingEntrySignalType = SignalNone;
    pendingExitSignalType = SignalNone;
    masterEntrySet = false;
    masterExitSet = false;
    signalHistoryCount = 0;

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
    bool force = false; 
    SignalType compareSignal = SignalNone;
    SignalUnit *compareUnit = getSignalUnit(isEntry);
    if(Common::IsInvalidPointer(compareUnit)) { force = true; }
    else { compareSignal = compareUnit.type; }
    
    if (force || (signal != compareSignal)/* || (!Common::IsInvalidPointer(compareUnit) ? compareUnit.retry : false)*/) { // note: allowing a retry upends the "every consecutive signal is different" assumption. Plus, when retrying, should we be modifying the existing signal, or no?
        SignalUnit *newUnit = new SignalUnit();
        newUnit.timeMilliseconds = GetTickCount();
        newUnit.timeDatetime = TimeCurrent();
        newUnit.timeCycles = 0;
        newUnit.type = signal;
        
        if(isEntry && signal != SignalHold && !Common::IsInvalidPointer(compareUnit)) {  // may need to change this if exit signals become more complex or SignalHold fulfilled/blocked becomes significant
            // retracement avoidance: for entry, check last entrySignal[1] if signal type is equal and was fulfilled, then also set fulfilled flag on new unit
            int entryUnitCount = ArraySize(entrySignal);
            for(int h = 1; h < entryUnitCount; h++) { // this assumes that newUnit and entry[0] are not the same. We check if entry[1] is different.
                SignalUnit *secondCompareUnit = getSignalUnit(true, h);
                if(Common::IsInvalidPointer(secondCompareUnit)) { continue; }
                
                if(signal != secondCompareUnit.type) { break; } // == secondCompareUnit.getOppositeType()
                else { newUnit.blocked = true; }
                // if signal == secondCompareUnit.type, throw dodge 
                
                // falsify block if SignalRetraceOpen and time has elapsed
                if(SignalRetraceOpenAfterDelay && newUnit.blocked) { // attempt to falsify
                    // todo: more sophisticated rule? should extra lots be allowed to open, after a time?
                    // should we be tracking signal type? Maybe not, signal retrace delays should be agnostic of type
                    int duration = getSignalDuration(TimeSettingUnit, compareUnit);
                    if(duration < SignalRetraceDelay) {
                        newUnit.blocked = true;
                        // newUnit.retry = true; // retry on next cycle, if signal persists beyond SignalRetraceTime
                    } else { newUnit.blocked = false; }
                }
                
                if(!newUnit.blocked 
                    || !SignalRetraceOpenAfterExit
                    //|| (SignalRetraceOpenAfterDelay && SignalRetraceOpenAfterExit && newUnit.blocked) // AND -- fail if delay did not elapse
                ) { break; }
                
                // falsify if exitSignal.type == signal and it was fulfilled (i.e., was old trade already closed?)
                    // AND is not superceded by a more recent entry signal ==
                int exitUnitCount = ArraySize(exitSignal);
                for(int i = 0; i < exitUnitCount /*exitUnitCount*/; i++) { // todo: should we be looking more than 1 back?
                    if(
                       !Common::IsInvalidPointer(exitSignal[i])
                       && signal == exitSignal[i].getOppositeType() // need to refer opposite: an exit SignalShort means open Short, close Long
                       && exitSignal[i].fulfilled
                       //&& getSignalDuration(TimeSettingUnit, exitSignal[i]) < SignalRetraceTime 
                            // todo: retracement blocked - ??? do we want to be tracking exit signals for any length of time? do we want to work entirely on order count?
                    ) {
                        // todo: check if exit signal was superceded by later entry signal
                        bool dodgeSupercede = false;
                        for(int j = 0; j < entryUnitCount; j++) {
                            if(Common::IsInvalidPointer(entrySignal[j])) { continue; }
                            int duration = getSignalDuration(TimeSettingUnit, exitSignal[i], entrySignal[j]);
                            if(duration > 0
                                && signal == entrySignal[j].type // ???
                            ) {
                                dodgeSupercede = true;
                                break;
                            }
                        }
                       newUnit.blocked = dodgeSupercede;
                       break;
                    }
                }
                
                break;
                
                //if(newUnit.blocked) { break; }
                
                // order count checked in ordermanager
            }
        }
        
        if(isEntry) { Common::ArrayPush(entrySignal, newUnit, signalHistoryCount); }
        else { Common::ArrayPush(exitSignal, newUnit, signalHistoryCount); }
    } else {
        if(isEntry) {
            // todo: retracement blocked - should we be re-evaluating after SignalRetraceTime is elapsed?
        
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
    bool subSignalStable = false;
    bool filterMaster = MainFilterMan.filters[filterIdx].signalMaster;
    
    if(subMode == SubfilterDisabled) { return; }
    //if(subSignalType != SignalBuy && subSignalType != SignalSell) { return; }
    if(subType != SubfilterEntry && subType != SubfilterExit) { return; }
    
    if(subType == SubfilterEntry && masterEntrySet) { return; }
    if(subType == SubfilterExit && masterExitSet) { return; }

    SignalType compareSignalType = SignalNone;
    SignalType resultSignalType = SignalNone;
    
    if(subType == SubfilterEntry) { compareSignalType = pendingEntrySignalType; }
    else { compareSignalType = pendingExitSignalType; }
    
    // todo: specific rules for master override

    if(compareSignalType == SignalHold && !filterMaster) { return; }
    
    if(subSignalType != SignalNone) {
        subSignalStable = filter[filterIdx].subfilter[subfilterIdx].history.getSignalStable(
            MainFilterMan.filters[filterIdx].alwaysStable ? 0
            : subType == SubfilterEntry ? EntryStableTime : ExitStableTime
            , TimeSettingUnit
            );
    } else { subSignalStable = true; } // we want this to negate symbolSignals right away
    
    switch(subMode) {
        case SubfilterNormal:
            if(!subSignalStable) { 
                if(subSignalType == SignalBuy || subSignalType == SignalSell || subSignalType == SignalClose) {
                    if(!filterMaster) { resultSignalType = SignalHold; }
                    else { resultSignalType = compareSignalType; }
                }
            } else {
                switch(subSignalType) {
                    case SignalBuy:
                        if(compareSignalType == SignalShort && !filterMaster) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalLong;
                        }
                        break;
                        
                    case SignalSell:
                        if(compareSignalType == SignalLong && !filterMaster) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalShort;
                        }
                        break;

                    case SignalClose:
                        if(compareSignalType != SignalClose && compareSignalType != SignalNone && !filterMaster) {
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalClose;
                        }
                        break;
                        
                    default:
                        if(!filterMaster) { resultSignalType = SignalHold; }
                        else { resultSignalType = compareSignalType; }
                        break;
                }
            }
            break;
            
        case SubfilterOpposite:
            if(!subSignalStable) {
                if(subSignalType == SignalBuy || subSignalType == SignalSell || subSignalType == SignalClose) {
                    if(!filterMaster) { resultSignalType = SignalHold; }
                    else { resultSignalType = compareSignalType; }
                }
            } else {
                switch(subSignalType) {
                    case SignalBuy:
                        if(compareSignalType == SignalLong && !filterMaster) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalShort;
                        }
                        break;
                        
                    case SignalSell:
                        if(compareSignalType == SignalShort && !filterMaster) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalLong;
                        }
                        break;

                    case SignalClose:
                        if(compareSignalType == SignalClose && compareSignalType != SignalNone && !filterMaster) {
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = compareSignalType; // don't set as SignalClose, trying to do opposite
                        }
                        break;
                        
                    default:
                        if(!filterMaster) { resultSignalType = SignalHold; }
                        else { resultSignalType = compareSignalType; }
                        break;
                }
            }
            break;
            
        case SubfilterNotOpposite:
            if(!subSignalStable) { break; }
            
            // todo: if compareSignalType == SignalNone && subSignalStable, then resultSignalType == matching signal?
            
            if(compareSignalType == SignalNone) {
                switch(subSignalType) {
                    case SignalBuy: resultSignalType = SignalLong; break;
                    case SignalSell: resultSignalType = SignalShort; break;
                    case SignalClose: resultSignalType = SignalClose; break;
                    // default: break; // do nothing, only set signal if affirmative
                }
            } else if(
                ((compareSignalType == SignalLong && subSignalType == SignalSell)
                    || (compareSignalType == SignalShort && subSignalType == SignalBuy)
                    || (compareSignalType == SignalClose && subSignalType == SignalNone)
                    ) // or subSignalType != SignalClose ?
                 && !filterMaster // signalMaster can't place SignalHold
            ) {
                resultSignalType = SignalHold;
            } else { resultSignalType = compareSignalType; }
            break;
            
        default: break;
    }
    
    if(filterMaster
        && (subSignalType == SignalBuy || subSignalType == SignalSell || subSignalType == SignalClose) 
        && resultSignalType != SignalHold && resultSignalType != SignalNone
    ) {
        if(subType == SubfilterEntry) { masterEntrySet = true; }
        else { masterExitSet = true; }
    }

    if(subType == SubfilterEntry) { pendingEntrySignalType = resultSignalType; } 
    else { pendingExitSignalType = resultSignalType; }
}

int DataSymbol::getSignalDuration(TimeUnits stableUnits, SignalUnit *prevUnit, SignalUnit *curUnit = NULL) {
    if(Common::IsInvalidPointer(prevUnit)) { return -1; }
    
    //((cur) >= (prev)) ? ((cur)-(prev)) : ((0xFFFFFFFF-(prev))+(cur)+1)
    switch(stableUnits) {
        case UnitSeconds: {
            datetime cur = !Common::IsInvalidPointer(curUnit) ? curUnit.timeDatetime : TimeCurrent();
            datetime prev = prevUnit.timeDatetime;
            return Common::GetTimeDuration(cur, prev);
        }
        
        case UnitMilliseconds: {
            uint cur = !Common::IsInvalidPointer(curUnit) ? curUnit.timeMilliseconds : GetTickCount();
            uint prev = prevUnit.timeMilliseconds;
            uint duration = (cur >= prev) ? cur-prev : UINT_MAX-prev+cur+1;
            return Common::GetTimeDuration(cur, prev);
        }
            
        case UnitTicks: {
            return prevUnit.timeCycles; // this is just added iteratively
        }
            
        default:
            return -1;
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
        symbol[i].masterEntrySet = false;
        symbol[i].masterExitSet = false;
        MainFilterMan.calculateFilters(i);
        symbol[i].addSignalUnit(symbol[i].pendingEntrySignalType, true);
        symbol[i].addSignalUnit(symbol[i].pendingExitSignalType, false);
        
    }
    
    return true;
}

DataManager *MainDataMan = NULL;
