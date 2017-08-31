//+------------------------------------------------------------------+
//|                                                 FG_Calculate.mqh |
//|                                                          mazmazz |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "mazmazz"
#property link      "https://github.com/mazmazz"
#property strict

#include "FG_Defines.mqh"
#include "../F_Filter.mqh"
#include "../../MC_Common/MC_Common.mqh"

//+------------------------------------------------------------------+

bool FilterGeno::calculate(int subIdx, int symIdx, DataUnit *dataOut, bool &forceAddOut) {
    if(!checkSafe(subIdx)) { return false; }
    forceAddOut = false;
    string symbol = MainSymbolMan.symbols[symIdx].name;
    int apiSetIdx = apiSetSubRef[subIdx];
    int timeFrameIdx = getApiSetTimeframeIndex(apiSetIdx, timeFrame[subIdx]);
    
    int prediction = 0;
    if(!getPrediction(subIdx, symIdx, prediction)) { // todo: we need a failsafe here if the last api call fails
        dataOut.setRawValue(0, closeOnMissingSignal[subIdx] ? SignalClose : SignalNone, "-");
        return true;
    }
    
    if(lastDatetime[apiSetIdx]._[timeFrameIdx]._[symIdx] > lastProcessedDatetime[apiSetIdx]._[timeFrameIdx]._[symIdx]) {
        // new candle, do something?
        if(resetOnNewTimePoint[apiSetTargetSub[apiSetIdx]]) { forceAddOut = true; }
        lastProcessedDatetime[apiSetIdx]._[timeFrameIdx]._[symIdx] = lastDatetime[apiSetIdx]._[timeFrameIdx]._[symIdx];
    }
    
    //Error::PrintInfo(symbol + " Predict: " + lastDatetime[fileSubIndex[subIdx]], true);
    
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

bool FilterGeno::getPrediction(int subIdx, int symIdx, int &predictionOut) {
    int apiSetIdx = apiSetSubRef[subIdx];
    int timeFrameIdx = getApiSetTimeframeIndex(apiSetIdx, timeFrame[subIdx]);
    predictionOut = lastPrediction[apiSetIdx]._[timeFrameIdx]._[symIdx];
    
    //if(lastDatetime[apiSetIdx]._[timeFrameIdx]._[symIdx] < lastProcessedDatetime[apiSetIdx]._[timeFrameIdx]._[symIdx]) { return false; }
        // this should never happen
    return true;
}
