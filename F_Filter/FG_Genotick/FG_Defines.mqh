//+------------------------------------------------------------------+
//|                                                   FG_Defines.mqh |
//|                                                          mazmazz |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "mazmazz"
#property link      "https://github.com/mazmazz"
#property strict

#property tester_file "Genotick_Data.csv"
#property tester_file "Genotick_Data2.csv"
#property tester_file "Genotick_Data3.csv"
#property tester_file "Genotick_Data4.csv"
#property tester_file "Genotick_Data5.csv"

#include "../F_Filter.mqh"
#include "../../depends/CsvString.mqh"
//+------------------------------------------------------------------+

class FilterGeno : public Filter {
    public:
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , string timeFrameIn
        , int lookbackCountIn
        , bool includeCurrentIn
        , string dataSourceIn
        
        , bool useGMTIn
        , bool resetOnNewTimePointIn
        , bool closeOnMissingSignalIn
        );
    void addSubfilter(string modeList, string nameList, string hiddenList, string typeList
        , string timeFrameList
        , string lookbackCountList
        , string includeCurrentList
        , string dataSourceList
        
        , string useGMTList
        , string resetOnNewTimePointList
        , string closeOnMissingSignalList
        , bool addToExisting = false
    );
    
    private:
    bool isInit;
    string timeFrame[]; // timeframe by name (H2, H4, etc.)
    int lookbackCount[];
    bool includeCurrent[];
    string dataSource[];
    
    bool useGMT[];
    bool resetOnNewTimePoint[];
    bool closeOnMissingSignal[];
    
    //+------------------------------------------------------------------+
    
    ArrayDim<string> apiSetTimeframes[]; // indexed by set, then order of timeframes appearance in settings
    // ArrayDim<int> apiSetSymbols[];
    string apiSetSymbolLists[]; //[]; indexed by set: symbol list of set, right now should be same for every set
    string apiSetTimeframeLists[]; //[]; indexed by set: timeframe list of set
    int apiSetTargetSub[]; // indexed by set: value is the source sub where settings exist
    int apiSetSubRef[]; // indexed by subfilters: api set idx of subfilter
    
    // defined below
    //int apiIntervalMins[]; // indexed by api set
    //datetime apiLastProcessedInterval[]; // indexed by api set
    
    void initApiSets();
    int getApiSetMatchingIndex(int subIdx);
    bool isApiSetSame(int subIdx, int testSetIdx);
    
    void updateListString(string &targetVal, string sourceVal);
    template<typename T>
    void updateListUnits(T &targetArr[], T sourceVal);
    void updateApiInterval(int &targetInterval, string timeFrameList);
    string getSymbolList();
    
    int getApiSetCount();
    int getApiSetTimeframeCount(int apiSetIdx);
    int getApiSetSymbolCount(int apiSetIdx);
    int getApiSetTimeframeIndex(int apiSetIdx, string testTimeframe);
    int getApiSetSymbolIndex(int apiSetIdx, string testSymbol);
    
    //+------------------------------------------------------------------+
    
    int apiIntervalMins[]; // indexed by api set
    datetime apiLastProcessedInterval[]; // indexed by api set
    
    // indexed by api set, then by timeframe, then by symIdx
    ArrayDim<ArrayDim<datetime>> lastDatetime[];
    ArrayDim<ArrayDim<datetime>> lastProcessedDatetime[];
    ArrayDim<ArrayDim<int>> lastPrediction[];
    
    // void doPreCycleWork(); // defined below
    bool isTimeInCurrent(int apiSetIdx, datetime &testTime);
    bool getApiPredict(int apiSetIdx, CsvString &predictCsv);
    bool sendServerRequest(CsvString &predictCsvOut, string periodList, string symbolList, datetime startPoint=0, datetime endPoint=0, int predictCount=-1, int lookbackCount=-1, bool includeCurrent=false, string source=NULL, string candleCsvInput = NULL);   
    string formatDatetimeToGenoTime(datetime value);
    
    bool processPredict(int apiSetIdx, CsvString &predictCsv);
    void resetLastData();
    
    //+------------------------------------------------------------------+
    
    public:
    void init();
    //void deInit();
    void doPreCycleWork();

    //+------------------------------------------------------------------+

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
    
    private:
    bool getPrediction(int subIdx, int symIdx, int &predictionOut);
};
