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
    SubfilterOrAgree,
    SubfilterViewOnly,
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
    bool subfilterHidden[];
    
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
    virtual bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut, bool &forceAddOut) { forceAddOut = false; return calculate(subfilterId, symbolIndex, dataOut); }
    
    virtual void doPreCycleWork() { }
    
    protected:
    bool consolidateHandles;
    void clearSubfilters();
    int setupSubfilters(int mode, string name, bool hidden, SubfilterType type);
    int setupSubfilters(string pairList, string nameList, SubfilterType subfilterTypeIn, bool addToArray = true);
    int setupSubfilters(string pairList, string nameList, string hiddenList, SubfilterType subfilterTypeIn, bool addToArray = true);
    int setupSubfilters(string pairList, string nameList, string hiddenList, string subfilterTypeList, bool addToArray = true);
    bool checkSafe(int subfilterId);
    
#ifdef __MQL5__
    virtual int getNewIndicatorHandle(int symIdx, int subIdx) { return INVALID_HANDLE; }
    virtual bool isSubfilterMatching(int compareIdx, int subIdx) { return false; }
    void loadIndicatorHandles(ArrayDim<int> &buffer[]);
    int getExistingIndicatorHandle(ArrayDim<int> &buffer[], int symIdx,int subIdx);
    void unloadIndicatorHandles(ArrayDim<int> &buffer[]);
#endif
};

void Filter::Filter() {
    shortName = NULL;
    signalMaster = false;
    alwaysStable = false;
    consolidateHandles = false;
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

int Filter::setupSubfilters(int mode, string name, bool hidden, SubfilterType type) {
    int size = Common::ArrayPush(subfilterMode, (SubfilterMode)mode);
    Common::ArrayPush(subfilterName, name);
    Common::ArrayPush(subfilterHidden, false);
    Common::ArrayPush(subfilterType, type);
    
    switch(type) {
        case SubfilterEntry: Common::ArrayPush(entrySubfilterId, size-1); break;
        case SubfilterExit: Common::ArrayPush(exitSubfilterId, size-1); break;
        case SubfilterValue: Common::ArrayPush(valueSubfilterId, size-1); break;
    }
    
    return 1;
}

int Filter::setupSubfilters(string pairList, string nameList, SubfilterType subfilterTypeIn, bool addToArray = true) {
    return setupSubfilters(pairList, nameList, NULL, subfilterTypeIn, addToArray);
}

int Filter::setupSubfilters(string pairList, string nameList, string hiddenList, SubfilterType subfilterTypeIn, bool addToArray = true) {
    int pairCount = MultiSettings::CountPairs(pairList);
    int oldSize = ArraySize(subfilterMode);
    
    if(pairCount <= 0) { return 0; }
    
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
    
    return pairCount;
}

int Filter::setupSubfilters(string pairList, string nameList, string hiddenList, string subfilterTypeList, bool addToArray = true) {
    int pairCount = MultiSettings::CountPairs(pairList);
    int oldSize = ArraySize(subfilterMode);
    
    if(pairCount <= 0) { return 0; }
    
    SubfilterType subfilterTypeIn[];
    int subfilterModeIn[];
    string subfilterNameIn[];
    bool subfilterHiddenIn[];
    
    MultiSettings::Parse(subfilterTypeList, subfilterTypeIn, pairCount);
    MultiSettings::Parse(pairList, subfilterModeIn, pairCount);
    if(StringLen(nameList) > 0) { MultiSettings::Parse(nameList, subfilterNameIn, pairCount); }
    else { ArrayResize(subfilterNameIn, pairCount); }
    if(StringLen(hiddenList) > 0) { MultiSettings::Parse(hiddenList, subfilterHiddenIn, pairCount); }
    else { ArrayResize(subfilterHiddenIn, pairCount); }
    
    int size = ArraySize(subfilterTypeIn);
    for(int i = 0; i < size; i++) {
        setupSubfilters(subfilterModeIn[i], subfilterNameIn[i], subfilterHiddenIn[i], subfilterTypeIn[i]);
    }
    
    return pairCount;
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
            if(buffer[i]._[j] != INVALID_HANDLE) { 
                IndicatorRelease(buffer[i]._[j]);
                buffer[i]._[j] = INVALID_HANDLE;
            }
            if(subfilterMode[j] == SubfilterDisabled) { continue; }
            
            int existingHandle = consolidateHandles ? getExistingIndicatorHandle(buffer, i, j) : INVALID_HANDLE;
                        
            buffer[i]._[j] = existingHandle != INVALID_HANDLE ? existingHandle : getNewIndicatorHandle(i, j);
        }
    }
}

int Filter::getExistingIndicatorHandle(ArrayDim<int> &buffer[], int symIdx,int subIdx) {
    int size = MathMin(ArraySize(buffer[symIdx]._), subIdx);
    for(int i = 0; i < size; i++) {
        if(buffer[symIdx]._[i] == INVALID_HANDLE) { continue; }
        
        if(isSubfilterMatching(i, subIdx)) {
            return buffer[symIdx]._[i];
        }
    }
    
    return INVALID_HANDLE;
}

void Filter::unloadIndicatorHandles(ArrayDim<int> &buffer[]) {
    int unloaded[];
    
    int subfilterCount = getSubfilterCount();
    int symbolCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symbolCount; i++) {
        for(int j = 0; j < subfilterCount; j++) {
            if(buffer[i]._[j] != INVALID_HANDLE) {
                for(int k = 0; k < ArraySize(unloaded); k++) {
                    if(unloaded[k] == buffer[i]._[j]) {
                        buffer[i]._[j] = INVALID_HANDLE;
                        break;
                    }
                }
                
                if(buffer[i]._[j] != INVALID_HANDLE) {
                    int address = buffer[i]._[j];
                    if(IndicatorRelease(address)) {
                        Common::ArrayPush(unloaded, address);
                    }
                }
            }
        }
        ArrayFree(buffer[i]._);
    }
}
#endif
