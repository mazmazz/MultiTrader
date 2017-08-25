//+------------------------------------------------------------------+
//|                                                   FG_Predict.mqh |
//|                                                          mazmazz |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "mazmazz"
#property link      "https://github.com/mazmazz"
#property strict

#include "FG_Defines.mqh"

#include "../F_Filter.mqh"
#include "../../D_Data/D_DataUnit.mqh"
#include "../../S_Symbol.mqh"
#include "../../depends/CsvString.mqh"
#include "../../depends/ApiKey.mqh"
#include "../../depends/internetlib.mqh"

//+------------------------------------------------------------------+

//string apiSetSymbolLists[]; //[]; indexed by set: symbol list of set, right now should be same for every set
//string apiSetTimeframeLists[]; //[]; indexed by set: timeframe list of set
//int apiSetTargetSub[]; // indexed by set: value is the source sub where settings exist
//int apiSetSubRef[]; // indexed by subfilters: api set idx of subfilter
//    
//ArrayDim<bool> isNewTimePoint[];

//static datetime OffsetDatetimeByZone(datetime value, int offsetHours);
//static datetime UnoffsetDatetimeByZone(datetime value, int offsetHours);
//static datetime AlignCandleDatetimeByOffset(datetime value, ENUM_TIMEFRAMES period, int alignOffsetHours=0);

void FilterGeno::doPreCycleWork() {
    int size = getApiSetCount();
    for(int i = 0; i < size; i++) {
        datetime testTime = 0;
        if(!isTimeInCurrent(i, testTime)) { // todo: throttling on client side?
            CsvString predictCsv(NULL, 0);
            if(getApiPredict(i, predictCsv)) {
                if(processPredict(i, predictCsv)) {
                    // todo: don't update until we verify we have new candles
                    // BUT: What if it's initial execution, and the very first
                    // candle is old?
                    apiLastProcessedInterval[i] = testTime;
                }
            }
        }
    }
}

bool FilterGeno::isTimeInCurrent(int apiSetIdx, datetime &testTime) {
    int apiSetSubIdx = apiSetTargetSub[apiSetIdx];
    //if(sampleTime <= 0) { sampleTime = useGMT[apiSetSubIdx] ? TimeGMT() : TimeCurrent(); }
    
    // measure on timecurrent only (and hope timecurrent does not update during market close)
    // align to candle time
    // store result
    // on next cycle, see if the result is same. if different, do api calls
    
    // todo: should we also take last candle into account? in case it returns an old candle
    testTime = Common::AlignCandleDatetimeByOffset(TimeCurrent(), apiIntervalMins[apiSetIdx]);
    return apiLastProcessedInterval[apiSetIdx] >= testTime;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool FilterGeno::getApiPredict(int apiSetIdx, CsvString &predictCsv) {
    return sendServerRequest(
        predictCsv
        , apiSetTimeframeLists[apiSetIdx]
        , apiSetSymbolLists[apiSetIdx]
        , 0 // startPoint
        , 0 // endPoint
        , 1 //predictCount[apiSetTargetSub[apiSetIdx]]
        , lookbackCount[apiSetTargetSub[apiSetIdx]]
        , includeCurrent[apiSetTargetSub[apiSetIdx]]
        , dataSource[apiSetTargetSub[apiSetIdx]]
        // , // broker input data
    );
}

bool FilterGeno::sendServerRequest(CsvString &predictCsvOut, string periodList, string symbolList, datetime startPoint=0, datetime endPoint=0, int predictCount=-1, int lookbackCount=-1, bool includeCurrent=false, string source=NULL, string candleCsvInput = NULL) {
    MqlNet net;
    tagRequest request;
    
    request.stVerb = "POST";
    request.stObject = "/predict";
    request.stHead = "Content-Type: application/x-www-form-urlencoded";
    request.stData = NULL;
    request.stData += "period=" + net.UrlEncode(periodList); // IntegerToString(ModelOrder);
    request.stData += "&instrument=" + net.UrlEncode(symbolList);
    
    if(startPoint > 0) { request.stData += "&startPoint=" + formatDatetimeToGenoTime(startPoint); }
    if(endPoint > 0) { request.stData += "&endPoint=" + formatDatetimeToGenoTime(endPoint); }
    if(predictCount > -1) { request.stData += "&predictCount=" + predictCount; }
    if(lookbackCount > -1) { request.stData += "&lookbackCount=" + lookbackCount; }
    if(includeCurrent) { request.stData += "&includeCurrent=true"; }
    if(source != NULL && StringLen(source) > 0) { request.stData += "&source=" + net.UrlEncode(source); }
    if(candleCsvInput != NULL && StringLen(candleCsvInput) > 0) { request.stData += "&data=" + net.UrlEncode(candleCsvInput); }
    
    request.fromFile = false;
    request.toFile = false;
    Common::ArrayPush(request.stHeaderNamesIn, "Mmc-Api-Version");
    Common::ArrayPush(request.stHeaderDataIn, "1");
    Common::ArrayPush(request.stHeaderNamesOut, "Mmc-Api-Success");
    Common::ArrayPush(request.stHeaderDataOut, "");

#ifndef _ApiDev
    Common::ArrayPush(request.stHeaderNamesIn, "Mmc-Api-Request-Key");
    Common::ArrayPush(request.stHeaderDataIn, MakeApiKey(GetApiDatetime(), true));
    Common::ArrayPush(request.stHeaderNamesOut, "Mmc-Api-Response-Key");
    Common::ArrayPush(request.stHeaderDataOut, "");
#endif
    
    if(net.Open("localhost", 8080, NULL, NULL, INTERNET_SERVICE_HTTP)) {
        net.Request(request);
        if(request.stHeaderDataOut[0] != "true") { return false; } // try again next tick
#ifndef _ApiDev
        if(request.stHeaderDataOut[1] == NULL || !ValidateApiKey(request.stHeaderDataOut[1], false)) { return false; }
#endif
    }
    
    predictCsvOut.reopen(request.stOut, 0);
    return true;
}

string FilterGeno::formatDatetimeToGenoTime(datetime value) {
    MqlDateTime valueMqlDt = {};
    if(!TimeToStruct(value, valueMqlDt)) { return TimeToString(value); }
    
    string resultFormat = "%04u%02u%02u%02u%02u";
    string result = StringFormat(resultFormat, valueMqlDt.year, valueMqlDt.mon, valueMqlDt.day, valueMqlDt.hour, valueMqlDt.min);
    return result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//// indexed by api set, then by timeframe, then by symIdx
//ArrayDim<ArrayDim<datetime>> lastDatetime[];
//ArrayDim<ArrayDim<datetime>> lastProcessedDatetime[];
//ArrayDim<ArrayDim<int>> lastPrediction[];

bool FilterGeno::processPredict(int apiSetIdx, CsvString &predictCsv) {
    while(!predictCsv.isDataEnding()) {
        while(!predictCsv.isLineEnding(true) && !predictCsv.isDataEnding()) {
            string tfIn = predictCsv.readString();
            string symbolIn = predictCsv.readString();
            datetime dtIn = predictCsv.readDateTime(); // todo: must correct to broker time zone? does this matter?
            int predIn = (int)(predictCsv.readNumber());
            
            int tfIdx = getApiSetTimeframeIndex(apiSetIdx, tfIn), symIdx = getApiSetSymbolIndex(apiSetIdx, symbolIn);
            lastDatetime[apiSetIdx]._[tfIdx]._[symIdx] = dtIn;
            //lastProcessedDatetime is handled in Calculate
            lastPrediction[apiSetIdx]._[tfIdx]._[symIdx] = predIn;
        }
    }

    return true;
}

void FilterGeno::resetLastData() {
    int apiSetSize = getApiSetCount();
    Common::ResetArrayBySize(true, lastDatetime, apiSetSize);
    Common::ResetArrayBySize(true, lastProcessedDatetime, apiSetSize);
    Common::ResetArrayBySize(true, lastPrediction, apiSetSize);
    
    for(int i = 0; i < apiSetSize; i++) {
        int apiSetTimeframeSize = getApiSetTimeframeCount(i);
        Common::ResetArrayBySize(lastDatetime[i]._, apiSetTimeframeSize);
        Common::ResetArrayBySize(lastProcessedDatetime[i]._, apiSetTimeframeSize);
        Common::ResetArrayBySize(lastPrediction[i]._, apiSetTimeframeSize);
        
        for(int j = 0; j < apiSetTimeframeSize; j++) {
            int apiSetSymbolSize = getApiSetSymbolCount(i);
            Common::ResetArrayBySize(lastDatetime[i]._[j]._, apiSetSymbolSize, (datetime)0);
            Common::ResetArrayBySize(lastProcessedDatetime[i]._[j]._, apiSetSymbolSize, (datetime)0);
            Common::ResetArrayBySize(lastPrediction[i]._[j]._, apiSetSymbolSize, 0);
        }
    }
}

//+------------------------------------------------------------------+
//| Miscellaneous                                                                 |
//+------------------------------------------------------------------+
//datetime getCandleDatetime(string symbol, ENUM_TIMEFRAMES period, int offset) {
//    datetime timeResult[]; //datetime timeTest[];
//    //CopyTime(symbol, period, 0, 5, timeTest);
//    if(CopyTime(symbol, period, offset, 1, timeResult) > 0) {
//        return timeResult[0];
//    } else { return 0; }
//}
////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//double getLowerToUpperPeriodFactor(ENUM_TIMEFRAMES lowerPeriod, ENUM_TIMEFRAMES upperPeriod) {
//    int lowerSeconds = Common::GetMinutesFromTimeFrame(lowerPeriod)*60;
//    int upperSeconds = Common::GetMinutesFromTimeFrame(upperPeriod)*60;
//    
//    return ((double)lowerSeconds)/((double)upperSeconds);
//}
////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//ENUM_TIMEFRAMES getLowerPeriodFromUpperPeriod(ENUM_TIMEFRAMES upperPeriod) {
//    switch(upperPeriod) {
//        case PERIOD_MN1:
//        case PERIOD_W1:
//            return PERIOD_D1;
//        case PERIOD_D1:
//#ifdef __MQL5__
//        case PERIOD_H12:
//        case PERIOD_H8:
//        case PERIOD_H6:
//#endif
//        case PERIOD_H4:
//#ifdef __MQL5__
//        case PERIOD_H3:
//        case PERIOD_H2:
//#endif
//            return PERIOD_H1;
//        case PERIOD_H1:
//        case PERIOD_M30:
//#ifdef __MQL5__        
//        case PERIOD_M20:
//#endif
//        case PERIOD_M15:
//#ifdef __MQL5__
//        case PERIOD_M12:
//        case PERIOD_M10:
//        case PERIOD_M6:
//#endif
//        case PERIOD_M5:
//#ifdef __MQL5__
//        case PERIOD_M4:
//        case PERIOD_M3:
//        case PERIOD_M2:
//#endif
//            return PERIOD_M1;
//        default:
//            return upperPeriod;
//    }
//}
