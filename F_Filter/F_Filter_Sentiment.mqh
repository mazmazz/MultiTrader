//+------------------------------------------------------------------+
//|                                             F_Filter_Stoch.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "F_Filter.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../D_Data/D_DataUnit.mqh"
#include "../S_Symbol.mqh"

enum ENUM_OSCILLATOR_TRIGGER {
    TRIGGER_ZONE_ENTER
    , TRIGGER_ZONE_EXIT
    , TRIGGER_ZONE_TURN
    , TRIGGER_MID_CROSS
    , TRIGGER_MID_TURN
};
enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};
enum enMaTypes
{
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma,   // Linear weighted MA
   ma_tema    // Tripple exponential moving average
};
enum enLevelType
{
   lvl_floa,  // Floating levels
   lvl_quan   // Quantile levels
};
enum enColorOn
{
   cc_onSlope,   // Change color on slope change
   cc_onMiddle,  // Change color on middle line cross
   cc_onLevels   // Change color on outer levels cross
};

class FilterSentiment : public Filter {
    private:
    bool isInit;
    int bufferSize;
    int timeFrame[];
    ENUM_OSCILLATOR_TRIGGER trigger[];
    int szoPeriod[];
    int filterPeriod[];
    int levelPeriod[];
    int shift[];
#ifdef __MQL5__
    ArrayDim<int> iSentimentHandle[];
#endif
    
    int calcUpperZone(int subIdx, int symIdx, int shift, double &upperZone[]);
    int calcLowerZone(int subIdx, int symIdx, int shift, double &lowerZone[]);
    int calcMidZone(int subIdx, int symIdx, int shift, double &midZone[]);
    int calcOsc(int subIdx, int symIdx, int shift, double &osc[]);
    
    double calcSlope(double pointAy, double pointBy, double pointAx = 0, double pointBx = 1) ;
    
    public:
    void init();
    void deInit();
#ifdef __MQL5__
    int getNewIndicatorHandle(int symIdx, int subIdx);
#endif

    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , int triggerIn
        , int szoPeriodIn
        , int filterPeriodIn
        , int levelPeriodIn
        , int shiftIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string timeFrameList
        , string triggerList
        , string szoPeriodList
        , string filterPeriodList
        , string levelPeriodList
        , string shiftList
        , bool addToExisting = false
    );
    
    int iSentiment(
        string symbol
        , ENUM_TIMEFRAMES tf
        , int szoPeriodIn = 14
        , enMaTypes szoMethodIn = ma_tema
        , enPrices priceIn = pr_close
        , int priceFilteringIn = 14
        , enMaTypes priceFilteringMethodIn = ma_sma
        , enColorOn colorOnIn = cc_onLevels
        , enLevelType levelTypeIn = lvl_quan
        , int levelPeriodIn = 25
        , double levelUpIn = 90.0
        , double levelDownIn = 10.0
    );
    
    bool isSubfilterMatching(int compareIdx, int subIdx);

    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterSentiment::init() {
    if(isInit) { return; }
    
    bufferSize = 3;
    shortName = "Sentiment";
    consolidateHandles = true;
    
#ifdef __MQL5__
    loadIndicatorHandles(iSentimentHandle);
#endif
    
    isInit = true;
}

void FilterSentiment::deInit() {
#ifdef __MQL5__
    unloadIndicatorHandles(iSentimentHandle);
#endif
    isInit = false;
}

#ifdef __MQL5__
int FilterSentiment::getNewIndicatorHandle(int symIdx, int subIdx) {
    return iSentiment(
        MainSymbolMan.symbols[symIdx].name
        , GetMql5TimeFrame(timeFrame[subIdx])
        , szoPeriod[subIdx]
        , ma_tema, pr_close
        , filterPeriod[subIdx]
        , ma_sma, cc_onLevels, lvl_quan
        , levelPeriod[subIdx]
        );
}
#endif

//+------------------------------------------------------------------+

int FilterSentiment::iSentiment(
    string symbol
    , ENUM_TIMEFRAMES tf
    , int szoPeriodIn = 14
    , enMaTypes szoMethodIn = ma_tema
    , enPrices priceIn = pr_close
    , int priceFilteringIn = 14
    , enMaTypes priceFilteringMethodIn = ma_sma
    , enColorOn colorOnIn = cc_onLevels
    , enLevelType levelTypeIn = lvl_quan
    , int levelPeriodIn = 25
    , double levelUpIn = 90.0
    , double levelDownIn = 10.0
) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    MqlParam params[];
    ArrayResize(params, 11);
    params[0].type = TYPE_STRING; 
    params[0].string_value = "Sentiment_zone_oscillator";
    params[1].type = TYPE_INT; //input int             SzoPeriod            = 14;             // Sentiment zone period
    params[1].integer_value = szoPeriodIn;
    params[2].type = TYPE_INT; //input enMaTypes       SzoMethod            = ma_tema;        // Sentiment zone calculating method
    params[2].integer_value = szoMethodIn;
    params[3].type = TYPE_INT; //input enPrices        Price                = pr_close;       // Price
    params[3].integer_value = priceIn;
    params[4].type = TYPE_INT; //input int             PriceFiltering       = 14;             // Price filtering period
    params[4].integer_value = priceFilteringIn;
    params[5].type = TYPE_INT; //input enMaTypes       PriceFilteringMethod = ma_sma;         // Price filtering method
    params[5].integer_value = priceFilteringMethodIn;
    params[6].type = TYPE_INT; //input enColorOn       ColorOn              = cc_onLevels;    // Color change
    params[6].integer_value = colorOnIn;
    params[7].type = TYPE_INT; //input enLevelType     LevelType            = lvl_quan;       // Level type
    params[7].integer_value = levelTypeIn;
    params[8].type = TYPE_INT; //input int             LevelPeriod          = 25;             // Levels period
    params[8].integer_value = levelPeriodIn;
    params[9].type = TYPE_DOUBLE; //input double          LevelUp              = 90.0;           // Up level %
    params[9].double_value = levelUpIn;
    params[10].type = TYPE_DOUBLE; //input double          LevelDown            = 10.0;           // Down level %
    params[10].double_value = levelDownIn;
    
    return IndicatorCreate(symbol, tf, IND_CUSTOM, ArraySize(params), params);
#endif
#endif
}

//+------------------------------------------------------------------+

void FilterSentiment::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , int triggerIn
    , int szoPeriodIn
    , int filterPeriodIn
    , int levelPeriodIn
    , int shiftIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(trigger, (ENUM_OSCILLATOR_TRIGGER)triggerIn);
    Common::ArrayPush(szoPeriod, szoPeriodIn);
    Common::ArrayPush(filterPeriod, filterPeriodIn);
    Common::ArrayPush(levelPeriod, levelPeriodIn);
    Common::ArrayPush(shift, shiftIn);
}

void FilterSentiment::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string timeFrameList
    , string triggerList
    , string szoPeriodList
    , string filterPeriodList
    , string levelPeriodList
    , string shiftList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(triggerList, trigger, count, addToExisting);
        MultiSettings::Parse(szoPeriodList, szoPeriod, count, addToExisting);
        MultiSettings::Parse(filterPeriodList, filterPeriod, count, addToExisting);
        MultiSettings::Parse(levelPeriodList, levelPeriod, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
    }
}

bool FilterSentiment::isSubfilterMatching(int compareIdx, int subIdx) {
    return timeFrame[compareIdx] == timeFrame[subIdx]
        && szoPeriod[compareIdx] == szoPeriod[subIdx]
        && filterPeriod[compareIdx] == filterPeriod[subIdx]
        && levelPeriod[compareIdx] == levelPeriod[subIdx]
        ;
}

//+------------------------------------------------------------------+

bool FilterSentiment::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
    double lowerZone[]; ArraySetAsSeries(lowerZone, true);
    double upperZone[]; ArraySetAsSeries(upperZone, true);
    double midZone[]; ArraySetAsSeries(midZone, true);
    double osc[]; ArraySetAsSeries(osc, true);
    
    if(calcUpperZone(subfilterId, symbolIndex, shift[subfilterId], upperZone) < bufferSize
        || calcLowerZone(subfilterId, symbolIndex, shift[subfilterId], lowerZone) < bufferSize
        || calcMidZone(subfilterId, symbolIndex, shift[subfilterId], midZone) < bufferSize
        || calcOsc(subfilterId, symbolIndex, shift[subfilterId], osc) < bufferSize
    ) { return false; }
    
    SignalType signal = SignalNone;
    string statusText = "";
    
    switch(trigger[subfilterId]) {
        case TRIGGER_ZONE_ENTER: {
            if(osc[1] < upperZone[1] && osc[0] > upperZone[0]) { 
                signal = SignalSell; 
                statusText = "EntUpr";
            }
            else if(osc[1] > lowerZone[1] && osc[0] < lowerZone[0]) { 
                signal = SignalBuy; 
                statusText = "EntLow";
            }
            break;
        }
        case TRIGGER_ZONE_EXIT: {
            if(osc[1] > upperZone[1] && osc[0] < upperZone[0]) { 
                signal = SignalSell; 
                statusText = "ExitUpr";
            }
            else if(osc[1] < lowerZone[1] && osc[0] > lowerZone[0]) { 
                signal = SignalBuy; 
                statusText = "ExitLow";
            }
            break;
        }
        case TRIGGER_MID_CROSS: {
            if(osc[1] < midZone[1] && osc[0] > midZone[0]) { 
                signal = SignalBuy; 
                statusText = "CrossUpr";
            }
            else if(osc[1] > midZone[1] && osc[0] < midZone[0]) { 
                signal = SignalSell; 
                statusText = "CrossLow";
            }
            break;
        }
        case TRIGGER_ZONE_TURN: 
        case TRIGGER_MID_TURN: {
            double slope1 = calcSlope(osc[2], osc[1]);
            double slope2 = calcSlope(osc[1], osc[0]);
            
            double checkUpr0 = trigger[subfilterId] == TRIGGER_MID_TURN ? midZone[0] : upperZone[0];
            double checkUpr1 = trigger[subfilterId] == TRIGGER_MID_TURN ? midZone[1] : upperZone[1];
            double checkUpr2 = trigger[subfilterId] == TRIGGER_MID_TURN ? midZone[2] : upperZone[2];
            double checkLow0 = trigger[subfilterId] == TRIGGER_MID_TURN ? midZone[0] : lowerZone[0];
            double checkLow1 = trigger[subfilterId] == TRIGGER_MID_TURN ? midZone[1] : lowerZone[1];
            double checkLow2 = trigger[subfilterId] == TRIGGER_MID_TURN ? midZone[2] : lowerZone[2];
            
            if(osc[0] > checkUpr0 || osc[1] > checkUpr1 || osc[2] > checkUpr2) {
                if(slope1 > 0 && slope2 < 0) { 
                    signal = SignalSell; 
                    statusText = "TurnUpr";
                }
            } else if(osc[0] < checkLow0 || osc[1] < checkLow1 || osc[2] < checkLow2) {
                if(slope1 < 0 && slope2 > 0) { 
                    signal = SignalBuy; 
                    statusText = "TurnLow";
                }
            }
            
            break;
        }
            
    }
    
    dataOut.setRawValue(statusText, signal);
    
    return true;
}

int FilterSentiment::calcUpperZone(int subIdx, int symIdx, int shift, double &upperZone[]) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    return CopyBuffer(iSentimentHandle[symIdx]._[subIdx], 2, 0+shift, bufferSize, upperZone);
#endif
#endif
}

int FilterSentiment::calcLowerZone(int subIdx, int symIdx, int shift, double &lowerZone[]) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    return CopyBuffer(iSentimentHandle[symIdx]._[subIdx], 4, 0+shift, bufferSize, lowerZone);
#endif
#endif
}

int FilterSentiment::calcMidZone(int subIdx, int symIdx, int shift, double &midZone[]) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    return CopyBuffer(iSentimentHandle[symIdx]._[subIdx], 3, 0+shift, bufferSize, midZone);
#endif
#endif
}

int FilterSentiment::calcOsc(int subIdx, int symIdx, int shift, double &osc[]) {
#ifdef __MQL4__
    return 0;
#else
#ifdef __MQL5__
    return CopyBuffer(iSentimentHandle[symIdx]._[subIdx], 5, 0+shift, bufferSize, osc);
#endif
#endif
}

double FilterSentiment::calcSlope(double pointAy, double pointBy, double pointAx = 0, double pointBx = 1) {
    return (pointBy-pointAy)/(pointBx-pointAx);
}