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
#include "../D_Data/D_DataUnit.mqh"

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
    int subfilterHidden[];
    
    int entrySubfilterId[];
    int exitSubfilterId[];
    int valueSubfilterId[];
    
    string shortName;
    
    bool signalMaster; // overrides all signals when getting symbolSignal
    bool alwaysStable; 
        // consider implementing as custom stable seconds, per subfilter
        // changes in D_Data.mqh where updateSymbolSignal checks for filter signal stability
        // and H_Dashboard.mqh where signalToString checks for stable seconds
    
    Filter();
    ~Filter();
    
    int getSubfilterCount(SubfilterType type = SubfilterAllTypes);
    
    virtual void init() { Error::ThrowError(ErrorNormal, "Filter: init not implemented", FunctionTrace, shortName); }
    virtual void deInit() { }
    virtual bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) { Error::ThrowError(ErrorNormal, "Filter: Calculate not implemented", FunctionTrace, shortName); return false; }
    
    protected:
    void clearSubfilters();
    void setupSubfilters(int mode, string name, bool hidden, SubfilterType type);
    void setupSubfilters(string pairList, string nameList, SubfilterType subfilterTypeIn, bool addToArray = true);
    void setupSubfilters(string pairList, string nameList, string hiddenList, SubfilterType subfilterTypeIn, bool addToArray = true);
    bool checkSafe(int subfilterId);
    
#ifdef __MQL5__
    virtual int getNewIndicatorHandle(int symIdx, int subIdx) { return INVALID_HANDLE; }
    void loadIndicatorHandles(ArrayDim<int> &buffer[]);
    void unloadIndicatorHandles(ArrayDim<int> &buffer[]);
#endif
};

void Filter::Filter() {
    shortName = NULL;
    signalMaster = false;
    alwaysStable = false;
};

void Filter::~Filter() {
    deInit();
}

int Filter::getSubfilterCount(SubfilterType type = SubfilterAllTypes) {
    switch(type) {
        case SubfilterEntry: return ArraySize(entrySubfilterId);
        case SubfilterExit: return ArraySize(exitSubfilterId);
        case SubfilterValue: return ArraySize(valueSubfilterId);
        default: return ArraySize(subfilterMode); //ArraySize(filters[filterId].entrySubfilterId) + ArraySize(filters[filterId].exitSubfilterId) + ArraySize(filters[filterId].valueSubfilterId);
    }
}

void Filter::clearSubfilters() {
    // note: filter-specific settings need to be reset too
    ArrayFree(subfilterMode);
    ArrayFree(subfilterName);
    ArrayFree(subfilterType);
    ArrayFree(subfilterHidden);
    
    ArrayFree(entrySubfilterId);
    ArrayFree(exitSubfilterId);
    ArrayFree(valueSubfilterId);
}

void Filter::setupSubfilters(int mode, string name, bool hidden, SubfilterType type) {
    int size = Common::ArrayPush(subfilterMode, (SubfilterMode)mode);
    Common::ArrayPush(subfilterName, name);
    Common::ArrayPush(subfilterHidden, (int)false);
    Common::ArrayPush(subfilterType, type);
    
    switch(type) {
        case SubfilterEntry: Common::ArrayPush(entrySubfilterId, size-1); break;
        case SubfilterExit: Common::ArrayPush(exitSubfilterId, size-1); break;
        case SubfilterValue: Common::ArrayPush(valueSubfilterId, size-1); break;
    }
}

void Filter::setupSubfilters(string pairList, string nameList, SubfilterType subfilterTypeIn, bool addToArray = true) {
    setupSubfilters(pairList, nameList, NULL, subfilterTypeIn, addToArray);
}

void Filter::setupSubfilters(string pairList, string nameList, string hiddenList, SubfilterType subfilterTypeIn, bool addToArray = true) {
    int pairCount = MultiSettings::CountPairs(pairList);
    int oldSize = ArraySize(subfilterMode);
    
    if(pairCount <= 0) { return; }
    
    switch(subfilterTypeIn) {
        case SubfilterEntry:
            MultiSettings::Parse(pairList, subfilterMode, entrySubfilterId, pairCount, addToArray, false);
            break;
        
        case SubfilterExit:
            MultiSettings::Parse(pairList, subfilterMode, exitSubfilterId, pairCount, addToArray, false);
            break;
            
        case SubfilterValue:
            MultiSettings::Parse(pairList, subfilterMode, valueSubfilterId, pairCount, addToArray, false);
            break;
    }
    
    Common::ArrayReserve(subfilterName, pairCount);
    if(StringLen(nameList) > 0) { MultiSettings::Parse(nameList, subfilterName, pairCount, addToArray, true); }
    else { ArrayResize(subfilterName, addToArray ? ArraySize(subfilterName)+pairCount : pairCount); }
    
    Common::ArrayReserve(subfilterHidden, pairCount);
    if(StringLen(hiddenList) > 0) { MultiSettings::Parse(hiddenList, subfilterHidden, pairCount, addToArray, true); }
    else { ArrayResize(subfilterHidden, addToArray ? ArraySize(subfilterHidden)+pairCount : pairCount); ArrayInitialize(subfilterHidden, 0); }
    
    for(int i = oldSize; i < oldSize + ArraySize(subfilterMode); i++) {
        Common::ArrayPush(subfilterType, subfilterTypeIn);
    }
}

bool Filter::checkSafe(int subfilterId) {
    if(subfilterId >= getSubfilterCount()) {
        Error::PrintNormal("Subfilter index does not exist", FunctionTrace, shortName + "-" + subfilterId + "|" + getSubfilterCount());
        return false;
    }
    
    if(subfilterMode[subfilterId] <= 0) {
        //Error::PrintMinor("Subfilter index is disabled, skipping.", FunctionTrace, shortName + "-" + subfilterId);
        return false;
    }

    return true;
}

#ifdef __MQL5__
void Filter::loadIndicatorHandles(ArrayDim<int> &buffer[]) {
    int subfilterCount = getSubfilterCount();
    int symbolCount = MainSymbolMan.getSymbolCount();
    
    ArrayFree(buffer);
    ArrayResize(buffer, symbolCount);
    
    for(int i = 0; i < symbolCount; i++) {
        int result = ArrayResize(buffer[i]._, subfilterCount);
        ArrayInitialize(buffer[i]._, INVALID_HANDLE);
        
        for(int j = 0; j < subfilterCount; j++) {
            if(buffer[i]._[j] != INVALID_HANDLE) { IndicatorRelease(buffer[i]._[j]); }
            if(subfilterMode[j] == SubfilterDisabled) { continue; }
            
            buffer[i]._[j] = getNewIndicatorHandle(i, j);
        }
    }
}

void Filter::unloadIndicatorHandles(ArrayDim<int> &buffer[]) {
    int subfilterCount = getSubfilterCount();
    int symbolCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symbolCount; i++) {
        for(int j = 0; j < subfilterCount; j++) {
            if(buffer[i]._[j] != INVALID_HANDLE) { IndicatorRelease(buffer[i]._[j]); }
        }
        ArrayFree(buffer[i]._);
    }
}
#endif
