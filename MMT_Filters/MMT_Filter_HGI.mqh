//+------------------------------------------------------------------+
//|                                             MMT_Filter_Hgi.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Filters.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../MMT_Data/MMT_DataUnit.mqh"
#include <hgi_lib.mqh>

class FilterHgi : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int shift[];
    int onTrend[];
    int onRange[];
    int onSlopeTrend[];
    int onSlopeRange[];
    
    public:
    void init();
    bool calculate(int subfilterIndex, string symbol, DataUnit *dataOut);
};

//+------------------------------------------------------------------+
// Params
//+------------------------------------------------------------------+

extern string Lbl_Hgi_1="________ HGI Settings [HGI] ________";
extern string Hgi_Entry_Modes="a=1";
extern string Hgi_Entry_Names="a=M60";
extern string Hgi_Exit_Modes="a=1";
extern string Hgi_Exit_Names="a=M60";

extern string LbL_Hgi_Entry="---- HGI Entry Settings ----";
extern string Hgi_Entry_TimeFrame="a=60";
extern string Hgi_Entry_Shift="a=60";
extern string Hgi_Entry_OnTrend="a=1";
extern string Hgi_Entry_OnRange="a=0";
extern string Hgi_Entry_OnSlopeTrend="a=0";
extern string Hgi_Entry_OnSlopeRange="a=0";

extern string LbL_Hgi_Exit="---- HGI Exit Settings ----";
extern string Hgi_Exit_TimeFrame="a=60";
extern string Hgi_Exit_Shift="a=60";
extern string Hgi_Exit_OnTrend="a=1";
extern string Hgi_Exit_OnRange="a=0";
extern string Hgi_Exit_OnSlopeTrend="a=0";
extern string Hgi_Exit_OnSlopeRange="a=0";

//+------------------------------------------------------------------+
// Methods
//+------------------------------------------------------------------+

void FilterHgi::init() {
    if(isInit) { return; }
    
    // 1. Define a shortName -- other settings will refer to this filter using this name (case-insensitive).
    shortName = "HGI";
    
    // 2. Call setupSubfilters for every type offered -- entry, exit, and/or value.
    setupSubfilters(Hgi_Entry_Modes, Hgi_Entry_Names, SubfilterEntry);
    setupSubfilters(Hgi_Exit_Modes, Hgi_Exit_Names, SubfilterExit);
    
    // 3. Set up options per subfilter type.
    int entrySubfilterCount = ArraySize(entrySubfilterId);
    int exitSubfilterCount = ArraySize(exitSubfilterId);
    if(entrySubfilterCount > 0) {
        MultiSettings::Parse(Hgi_Entry_TimeFrame, timeFrame, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Entry_Shift, shift, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Entry_OnTrend, onTrend, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Entry_OnRange, onRange, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Entry_OnSlopeTrend, onSlopeTrend, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Entry_OnSlopeRange, onSlopeRange, entrySubfilterCount);
    }
    
    if(exitSubfilterCount > 0) {
        MultiSettings::Parse(Hgi_Exit_TimeFrame, timeFrame, exitSubfilterCount);
        MultiSettings::Parse(Hgi_Exit_Shift, shift, exitSubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnTrend, onTrend, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnRange, onRange, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnSlopeTrend, onSlopeTrend, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnSlopeRange, onSlopeRange, entrySubfilterCount);
    }
    
    isInit = true;
}

bool FilterHgi::calculate(int subfilterIndex, string symbol, DataUnit *dataOut) {
    if(!checkSafe(subfilterIndex)) { return false; }
    
    int hgiSignal = getHGISignal(symbol, timeFrame[subfilterIndex], shift[subfilterIndex]);
    int hgiSlope = getHGISlope(symbol, timeFrame[subfilterIndex], shift[subfilterIndex]);
    
    bool buyTrendSignal = !onTrend[subfilterIndex] || hgiSignal == TRENDUP;
    bool buyRangeSignal = !onRange[subfilterIndex] || hgiSignal == RANGEUP; 
    bool buyTrendSlope = !onSlopeTrend[subfilterIndex] || hgiSlope == TRENDBELOW; 
    bool buyRangeSlope = !onSlopeRange[subfilterIndex] || hgiSlope == RANGEBELOW;
    bool sellTrendSignal = !onTrend[subfilterIndex] || hgiSignal == TRENDDN;
    bool sellRangeSignal = !onRange[subfilterIndex] || hgiSignal == RANGEDN; 
    bool sellTrendSlope = !onSlopeTrend[subfilterIndex] || hgiSlope == TRENDABOVE; 
    bool sellRangeSlope = !onSlopeRange[subfilterIndex] || hgiSlope == RANGEABOVE;
    
    SignalType signal = 
        buyTrendSignal && buyRangeSignal && buyTrendSlope && buyRangeSlope ? SignalBuy
        : sellTrendSignal && sellRangeSignal && sellTrendSlope && sellRangeSlope ? SignalSell
        : SignalNone
        ;
    
    dataOut.setRawValue(
        buyTrendSignal && buyRangeSignal && buyTrendSlope && buyRangeSlope ? "Buy"
            : sellTrendSignal && sellRangeSignal && sellTrendSlope && sellRangeSlope ? "Sell"
            : "None"
        , signal
        );
    
    return true;
}
