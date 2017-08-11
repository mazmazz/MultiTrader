//+------------------------------------------------------------------+
//|                                             F_Filter_Stoch.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#property tester_file "Genotick_Data.csv"

#include "F_Filter.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../D_Data/D_DataUnit.mqh"
#include "../S_Symbol.mqh"
#include "../depends/PipFactor.mqh"

class FilterGeno : public Filter {
    public:
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , string fileNameIn
        , bool resetOnSameSignalIn
        , bool closeOnMissingSignalIn
        );
    void addSubfilter(string modeList, string nameList, string hiddenList, string typeList
        , string fileNameList
        , string resetOnSameSignalList
        , string closeOnMissingSignalIn
        , bool addToExisting = false
    );
    
    private:
    bool isInit;
    string fileNames[];
    bool resetOnSameSignal[];
    bool closeOnMissingSignal[];
    
    int fileHandles[]; // indexed by unique file loaded
    string fileHandleNames[]; // indexed per fileHandles
    int fileSubIndex[]; // indexed by subfilters
    
    // indexed per fileHandles, then by symbol entry
    datetime lastDatetime[];
    ArrayDim<int> lastSymIndex[];
    ArrayDim<int> lastPrediction[];
    datetime currentDatetime[];
    ArrayDim<int> currentSymIndex[];
    ArrayDim<int> currentPrediction[];
    datetime nextDatetime[];
    ArrayDim<int> nextSymIndex[];
    ArrayDim<int> nextPrediction[];
    
    void loadFiles();
    
    public:
    void init();
    void deInit();

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
    
    private:    
    bool isTimeInCurrent(int subIdx, datetime sampleTime = 0);
    void seekTimePoint(int subIdx, int pointOffset = 0);
    void loadTimePointData(int subIdx, int symIdx);
    void copyTimePoint(int fileSubIdx, datetime &datetimeDest[], int &symIndexDest[], int &predictionDest[], datetime &datetimeSrc[], int &symIndexSrc[], int &predictionSrc[]);
    void fillTimePoint(int fileSubIdx, datetime &datetimeDest[], int &symIndexDest[], int &predictionDest[], datetime datetimeVal, int symIndexVal, int predictionVal);
    void loadTimePointRow(int fileSubIdx, datetime &datetimeDest[], int &symIndexDest[], int &predictionDest[]);
    bool getPrediction(int subIdx, int symIdx, int &predictionOut);
};

//+------------------------------------------------------------------+

void FilterGeno::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , string fileNameIn
    , bool resetOnSameSignalIn
    , bool closeOnMissingSignalIn
) {
    setupSubfilters(mode, name, hidden, type);
    Common::ArrayPush(fileNames, fileNameIn);
    Common::ArrayPush(resetOnSameSignal, resetOnSameSignalIn);
    Common::ArrayPush(closeOnMissingSignal, closeOnMissingSignalIn);
}

void FilterGeno::addSubfilter(string modeList, string nameList, string hiddenList, string typeList
    , string fileNameList
    , string resetOnSameSignalList
    , string closeOnMissingSignalList
    , bool addToExisting = false
) {
    int count = setupSubfilters(modeList, nameList, hiddenList, typeList);
    
    if(count > 0) {
        MultiSettings::Parse(fileNameList, fileNames, count, addToExisting);
        MultiSettings::Parse(resetOnSameSignalList, resetOnSameSignal, count, addToExisting);
        MultiSettings::Parse(closeOnMissingSignalList, closeOnMissingSignal, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

void FilterGeno::init() {
    if(isInit) { return; }
    
    shortName = "Geno";
    
    loadFiles();
    
    isInit = true;
}

void FilterGeno::loadFiles() {
    for(int i = 0; i < ArraySize(fileNames); i++) {
        StringToLower(fileNames[i]);
        int existingIndex = Common::ArrayFind(fileHandleNames, fileNames[i]);
        if(existingIndex >= 0) {
            Common::ArrayPush(fileSubIndex, existingIndex);
        } else {
            if(FileIsExist(fileNames[i])) {
                Common::ArrayPush(fileHandles, FileOpen(fileNames[i], FILE_SHARE_READ|FILE_CSV|FILE_ANSI, ','));
            } else {
                Common::ArrayPush(fileHandles, INVALID_HANDLE);
            }
            Common::ArrayPush(fileHandleNames, fileNames[i]);
            Common::ArrayPush(fileSubIndex, i);
            Common::ArrayPush(lastDatetime, (datetime)0);
            ArrayResize(lastSymIndex, ArraySize(lastSymIndex)+1);
            ArrayResize(lastPrediction, ArraySize(lastPrediction)+1);
            Common::ArrayPush(currentDatetime, (datetime)0);
            ArrayResize(currentSymIndex, ArraySize(currentSymIndex)+1);
            ArrayResize(currentPrediction, ArraySize(currentPrediction)+1);
            Common::ArrayPush(nextDatetime, (datetime)0);
            ArrayResize(nextSymIndex, ArraySize(nextSymIndex)+1);
            ArrayResize(nextPrediction, ArraySize(nextPrediction)+1);
        }
    }
}

void FilterGeno::deInit() {
    for(int i = 0; i < ArraySize(fileHandles); i++) {
        if(fileHandles[i] != INVALID_HANDLE) { FileClose(fileHandles[i]); }
    }
}

//+------------------------------------------------------------------+

bool FilterGeno::calculate(int subIdx, int symIdx, DataUnit *dataOut) {
    if(!checkSafe(subIdx)) { return false; }
    string symbol = MainSymbolMan.symbols[symIdx].name;
    
    if(!isTimeInCurrent(subIdx)) { loadTimePointData(subIdx, symIdx); }
    int prediction = 0;
    if(!isTimeInCurrent(subIdx) || !getPrediction(subIdx, symIdx, prediction)) {
        dataOut.setRawValue(0, closeOnMissingSignal[subIdx] ? SignalClose : SignalNone, "-");
        return true;
    }
    
    switch(prediction) {
        case 1: // UP
            dataOut.setRawValue(prediction, SignalBuy, "Up");
            break;
        case 0: // OUT
            dataOut.setRawValue(prediction, SignalClose, "Out");
            break;
        case -1: // DOWN
            dataOut.setRawValue(prediction, SignalSell, "Down");
            break;
        default:
            dataOut.setRawValue(0, SignalNone, "None");
            break;
    }
    
    return true;
}

bool FilterGeno::isTimeInCurrent(int subIdx, datetime sampleTime = 0) {
    if(sampleTime <= 0) { sampleTime = TimeGMT(); }
    
    return (lastDatetime[fileSubIndex[subIdx]] > 0 && sampleTime > lastDatetime[fileSubIndex[subIdx]]
        && currentDatetime[fileSubIndex[subIdx]] > 0 && sampleTime >= currentDatetime[fileSubIndex[subIdx]]
        && nextDatetime[fileSubIndex[subIdx]] > 0 && sampleTime < nextDatetime[fileSubIndex[subIdx]]
        );
}

void FilterGeno::seekTimePoint(int subIdx, int pointOffset = 0) {
    int fileSubIdx = fileSubIndex[subIdx];
    if(fileHandles[fileSubIdx] == INVALID_HANDLE) { return; }
    
    ulong pointOffsets[];
    int offsetCount = MathMax(3, MathAbs(pointOffset)+2);
    datetime currentTime = 0, nextTime = 0, testTime = TimeGMT();
    
    Common::ArrayPush(pointOffsets, FileTell(fileHandles[fileSubIdx]), offsetCount);
    
    // todo: re-seek file to beginning, if EOF?
    // would allow program to suddenly find an existing date
    // if it did not immediately find one
    // but this would be a lot slower during execution
    // valid use case: user forgets to add prior day data to beginning
    // and sets starting date to same trading date
    
    bool timeFound = false, timePointIsMulti = false;
    while(!timeFound && !FileIsEnding(fileHandles[fileSubIdx])) {
        if(currentTime == 0 || nextTime == 0 || testTime < currentTime || testTime > nextTime) { 
            currentTime = nextTime;
            nextTime = FileReadDatetime(fileHandles[fileSubIdx]);
            while(!FileIsLineEnding(fileHandles[fileSubIdx]) && !FileIsEnding(fileHandles[fileSubIdx])) { FileReadString(fileHandles[fileSubIdx]); } // skip to end of line
            ulong newTimePos = FileTell(fileHandles[fileSubIdx]);
            datetime newTime = FileReadDatetime(fileHandles[fileSubIdx]);
            FileSeek(fileHandles[fileSubIdx], newTimePos, SEEK_SET);
            if(nextTime != newTime) {
                Common::ArrayPush(pointOffsets, FileTell(fileHandles[fileSubIdx]), offsetCount);
                timePointIsMulti = false; // reset for next time point
            } else { timePointIsMulti = true; }
        } else { timeFound = true; }
    }
    
    if(pointOffset >= 0) {
        FileSeek(fileHandles[fileSubIdx], pointOffsets[MathMin(ArraySize(pointOffsets)-1, pointOffset)], SEEK_SET);
    } else {
        int proposedIndex = ArraySize(pointOffsets)-MathAbs(pointOffset)-2+((int)timePointIsMulti);
        FileSeek(fileHandles[fileSubIdx], pointOffsets[MathMin(ArraySize(pointOffsets)-1, MathMax(0, proposedIndex))], SEEK_SET);
    }
}

void FilterGeno::loadTimePointData(int subIdx, int symIdx) {
    int fileSubIdx = fileSubIndex[subIdx];
    if(fileHandles[fileSubIdx] == INVALID_HANDLE) { return; }
    
    int timeDelta = MathMax(1, 
        MathMin(
            (currentDatetime[fileSubIdx] > 0 ? currentDatetime[fileSubIdx] : INT_MAX) - (lastDatetime[fileSubIdx] > 0 ? lastDatetime[fileSubIdx] : INT_MAX)
            , (nextDatetime[fileSubIdx] > 0 ? nextDatetime[fileSubIdx] : INT_MAX) - (currentDatetime[fileSubIdx] > 0 ? currentDatetime[fileSubIdx] : INT_MAX)
            )
        );
        
    // only the last time point prediction is retrieved
    // and the current/next datetime are actually used
    // we just copy current/next symbol and prediction so they are used later as time point shifts
        
    if(currentDatetime[fileSubIdx] > 0) {
        copyTimePoint(fileSubIdx, lastDatetime, lastSymIndex[fileSubIdx]._, lastPrediction[fileSubIdx]._, currentDatetime, currentSymIndex[fileSubIdx]._, currentPrediction[fileSubIdx]._);
    } else {
        seekTimePoint(subIdx, -1);
        loadTimePointRow(fileSubIdx, lastDatetime, lastSymIndex[fileSubIdx]._, lastPrediction[fileSubIdx]._);
    }
    
    if(nextDatetime[fileSubIdx] > 0) {
        copyTimePoint(fileSubIdx, currentDatetime, currentSymIndex[fileSubIdx]._, currentPrediction[fileSubIdx]._, nextDatetime, nextSymIndex[fileSubIdx]._, nextPrediction[fileSubIdx]._);
    } else {
        seekTimePoint(subIdx, 0);
        loadTimePointRow(fileSubIdx, currentDatetime, currentSymIndex[fileSubIdx]._, currentPrediction[fileSubIdx]._);
    }
    
    if(FileIsEnding(fileHandles[fileSubIdx])) {
        // todo: at end, should all symbols be closed, or leave open a la "no data"?
        // we'd likely solve this as we implement live training
        // for now, just make all data missing
        // maybe make it a setting? CloseIfMissing
        fillTimePoint(fileSubIdx, nextDatetime, nextSymIndex[fileSubIdx]._, nextPrediction[fileSubIdx]._, currentDatetime[fileSubIdx] + timeDelta, -1, 0);
    } else {
        loadTimePointRow(fileSubIdx, nextDatetime, nextSymIndex[fileSubIdx]._, nextPrediction[fileSubIdx]._);
    }
}

void FilterGeno::copyTimePoint(int fileSubIdx, datetime &datetimeDest[], int &symIndexDest[], int &predictionDest[], datetime &datetimeSrc[], int &symIndexSrc[], int &predictionSrc[]) {
    ArrayFree(symIndexDest);
    ArrayFree(predictionDest);
    datetimeDest[fileSubIdx] = datetimeSrc[fileSubIdx];
    ArrayCopy(symIndexDest, symIndexSrc);
    ArrayCopy(predictionDest, predictionSrc);
}

void FilterGeno::fillTimePoint(int fileSubIdx, datetime &datetimeDest[], int &symIndexDest[], int &predictionDest[], datetime datetimeVal, int symIndexVal, int predictionVal) {
    ArrayFree(symIndexDest);
    ArrayFree(predictionDest);
    datetimeDest[fileSubIdx] = datetimeVal;
    Common::ArrayPush(symIndexDest, symIndexVal);
    Common::ArrayPush(predictionDest, predictionVal);
}

void FilterGeno::loadTimePointRow(int fileSubIdx, datetime &datetimeDest[], int &symIndexDest[], int &predictionDest[]) {
    ArrayFree(symIndexDest);
    ArrayFree(predictionDest);
    ulong linePos = FileTell(fileHandles[fileSubIdx]);
    
    // if we decide to implement re-seeking in seekTimePoint,
    // this should not be reached
    if(FileIsEnding(fileHandles[fileSubIdx])) { return; }
    
    do {
        FileSeek(fileHandles[fileSubIdx], linePos, SEEK_SET);
        datetime datetimeRow = FileReadDatetime(fileHandles[fileSubIdx]);
        if(datetimeDest[fileSubIdx] != datetimeRow) { datetimeDest[fileSubIdx] = datetimeRow; }
        Common::ArrayPush(symIndexDest, MainSymbolMan.getSymbolId(FileReadString(fileHandles[fileSubIdx]), true));
        //string text = FileReadString(fileHandles[fileSubIdx]);
        Common::ArrayPush(predictionDest, (int)FileReadNumber(fileHandles[fileSubIdx]));
        while(!FileIsLineEnding(fileHandles[fileSubIdx]) && !FileIsEnding(fileHandles[fileSubIdx])) { FileReadString(fileHandles[fileSubIdx]); } // skip to end of line
        linePos = FileTell(fileHandles[fileSubIdx]);
    } while(datetimeDest[fileSubIdx] == FileReadDatetime(fileHandles[fileSubIdx]));
    FileSeek(fileHandles[fileSubIdx], linePos, SEEK_SET);
}

bool FilterGeno::getPrediction(int subIdx, int symIdx, int &predictionOut) {
    int fileSubIdx = fileSubIndex[subIdx];
    if(fileHandles[fileSubIdx] == INVALID_HANDLE) { return false; }
    
    // retrieve from last time point because that prediction applies to current period
    
    int timePointSymIndex = Common::ArrayFind(lastSymIndex[fileSubIdx]._, symIdx);
    if(timePointSymIndex < 0) { return false; }
    
    predictionOut = lastPrediction[fileSubIdx]._[timePointSymIndex];
    return true;
}