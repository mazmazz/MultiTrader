//+------------------------------------------------------------------+
//|                                             F_Filter_Stoch.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "FG_Defines.mqh"
#include "FG_Predict.mqh"
#include "FG_Calculate.mqh"

#include "../F_Filter.mqh"
#include <MC_Common/MC_MultiSettings.mqh>
#include "../../D_Data/D_DataUnit.mqh"
#include "../../S_Symbol.mqh"
#include <MC_Common/depends/PipFactor.mqh>

//+------------------------------------------------------------------+

void FilterGeno::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , string timeFrameIn
    , int lookupDelayIn
    , int lookbackCountIn
    , bool includeCurrentIn
    , string dataSourceIn
    
    , bool useGMTIn
    , bool checkCandlesIn
    , bool resetOnNewTimePointIn
    , bool closeOnMissingSignalIn
) {
    setupSubfilters(mode, name, hidden, type);
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(lookupDelay, lookupDelayIn);
    Common::ArrayPush(lookbackCount, lookbackCountIn);
    Common::ArrayPush(includeCurrent, includeCurrentIn);
    Common::ArrayPush(dataSource, dataSourceIn);
    
    Common::ArrayPush(useGMT, useGMTIn);
    Common::ArrayPush(checkCandles, checkCandlesIn);
    Common::ArrayPush(resetOnNewTimePoint, resetOnNewTimePointIn);
    Common::ArrayPush(closeOnMissingSignal, closeOnMissingSignalIn);
}

void FilterGeno::addSubfilter(string modeList, string nameList, string hiddenList, string typeList
    , string timeFrameList
    , string lookupDelayList
    , string lookbackCountList
    , string includeCurrentList
    , string dataSourceList
    
    , string useGMTList
    , string checkCandlesList
    , string resetOnNewTimePointList
    , string closeOnMissingSignalList
    , bool addToExisting = false
) {
    int count = setupSubfilters(modeList, nameList, hiddenList, typeList);
    
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(lookupDelayList, lookupDelay, count, addToExisting);
        MultiSettings::Parse(lookbackCountList, lookbackCount, count, addToExisting);
        MultiSettings::Parse(includeCurrentList, includeCurrent, count, addToExisting);
        MultiSettings::Parse(dataSourceList, dataSource, count, addToExisting);
        
        MultiSettings::Parse(useGMTList, useGMT, count, addToExisting);
        MultiSettings::Parse(checkCandlesList, checkCandles, count, addToExisting);
        MultiSettings::Parse(resetOnNewTimePointList, resetOnNewTimePoint, count, addToExisting);
        MultiSettings::Parse(closeOnMissingSignalList, closeOnMissingSignal, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

void FilterGeno::init() {
    if(isInit) { return; }
    
    shortName = "Geno";
    
    initApiSets();
    
    isInit = true;
}

void FilterGeno::initApiSets() {
    int subfilterCount = getSubfilterCount();
    ArrayFree(apiSetTargetSub); ArrayFree(apiSetSymbolLists); ArrayFree(apiSetTimeframeLists); ArrayFree(apiSetFirstRun);
    ArrayResize(apiSetSubRef, subfilterCount);
    string symbolList = getSymbolList();

    for(int i = 0; i < subfilterCount; i++) {
        if(subfilterMode[i] == SubfilterDisabled) { continue; }
        
        int existingSetIndex = getApiSetMatchingIndex(i);
        if(existingSetIndex >= 0) {
            apiSetSubRef[i] = existingSetIndex;
            updateListString(apiSetTimeframeLists[existingSetIndex], timeFrame[i]);
            updateListUnits(apiSetTimeframes[existingSetIndex]._, timeFrame[i]);
            updateApiInterval(apiIntervalMins[existingSetIndex], timeFrame[i]);
            // todo: add currencies if those lists will be different
        } else {
            int newSetIndex = getApiSetCount();
            apiSetSubRef[i] = newSetIndex;
            Common::ArrayPush(apiSetTargetSub, i);
            Common::ArrayPush(apiSetTimeframeLists, timeFrame[i]);
            Common::ArrayPush(apiSetSymbolLists, symbolList);
            ArrayResize(apiSetTimeframes, ArraySize(apiSetTimeframes)+1);
            updateListUnits(apiSetTimeframes[newSetIndex]._, timeFrame[i]);
            
            Common::ArrayPush(apiIntervalMins, 0);
            Common::ArrayPush(apiLastProcessedInterval, (datetime)0);
            updateApiInterval(apiIntervalMins[newSetIndex], timeFrame[i]);
            Common::ArrayPush(apiSetFirstRun, true);
            
            if(dataSource[apiSetTargetSub[newSetIndex]] == "filePredClient") {
                ArrayResize(apiSetCsvFiles, newSetIndex+1);
                apiSetCsvFiles[newSetIndex].reopen("Genotick_Data.csv", FILE_CSV|FILE_READ|FILE_ANSI);
            } 
        }
    }
    
    resetLastData(); // sets up lastPrediction etc. arrays
}

int FilterGeno::getApiSetMatchingIndex(int subIdx) {
    for(int i = 0; i < getApiSetCount(); i++) {
        if(isApiSetSame(subIdx, i)) { return i; }
    }
    return -1;
}

bool FilterGeno::isApiSetSame(int subIdx, int testSetIdx) {
    return lookbackCount[subIdx] == lookbackCount[apiSetTargetSub[testSetIdx]]
        && includeCurrent[subIdx] == includeCurrent[apiSetTargetSub[testSetIdx]]
        && dataSource[subIdx] == dataSource[apiSetTargetSub[testSetIdx]]
        ;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void FilterGeno::updateListString(string &targetVal, string sourceVal) {
    string sourceUnits[];
    StringSplit(sourceVal, ',', sourceUnits);
    for(int i = 0; i < ArraySize(sourceUnits); i++) {
        if(StringFind(targetVal, sourceUnits[i]) < 0) {
            targetVal += (StringLen(targetVal) <= 0 ? "" : ",") + sourceUnits[i];
        }
    }
}

template<typename T>
void FilterGeno::updateListUnits(T &targetArr[], string sourceVal) {
    string sourceUnits[];
    StringSplit(sourceVal, ',', sourceUnits);
    for(int i = 0; i < ArraySize(sourceUnits); i++) {
        bool found = false;
        for(int j = 0; j < ArraySize(targetArr); j++) {
            if(targetArr[j] == sourceUnits[i]) { 
                found = true;
                continue; 
            }
        }
        if(!found) { Common::ArrayPush(targetArr, sourceVal); }
    }    
}

void FilterGeno::updateApiInterval(int &targetInterval, string timeFrameList) {
    string timeFrameUnits[];
    StringSplit(timeFrameList, ',', timeFrameUnits);
    for(int i = 0; i < ArraySize(timeFrameUnits); i++) {
        int testInterval = Common::GetMinutesFromTimeFrame(Common::GetTimeFrameFromString(timeFrameUnits[i]));
        if(targetInterval == 0 || testInterval < targetInterval) { targetInterval = testInterval; }
    }
}

string FilterGeno::getSymbolList() {
    string result = "";
    int size = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < size; i++) {
        result += (StringLen(result) <= 0 ? "" : ",") + MainSymbolMan.symbols[i].bareName;
    }
    return result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int FilterGeno::getApiSetCount() {
    return ArraySize(apiSetTargetSub);
}

int FilterGeno::getApiSetTimeframeCount(int apiSetIdx) {
    return ArraySize(apiSetTimeframes[apiSetIdx]._);
}

int FilterGeno::getApiSetSymbolCount(int apiSetIdx) {
    // return ArraySize(apiSetSymbols[apiSetIdx]._);
    return MainSymbolMan.getSymbolCount();
}

int FilterGeno::getApiSetTimeframeIndex(int apiSetIdx, string testTimeframe) {
    for(int i = 0; i < ArraySize(apiSetTimeframes[apiSetIdx]._); i++) {
        if(apiSetTimeframes[apiSetIdx]._[i] == testTimeframe) { return i; }
    }
    return -1;
}   

int FilterGeno::getApiSetSymbolIndex(int apiSetIdx, string testSymbol) {
    //for(int i = 0; i < ArraySize(apiSetSymbols[apiSetIdx]._); i++) {
    //    if(apiSetSymbols[apiSetIdx]._[i] == testSymbol) { return i; }
    //}
    //return -1;
    return MainSymbolMan.getSymbolId(testSymbol, true);
}