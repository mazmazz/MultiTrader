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
    int onRad[];
    int onSignal[];
    int onSlope[];
    
    public:
    void init();
    bool calculate(int subfilterIndex, int symbolIndex, DataUnit *dataOut);
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
extern string Hgi_Entry_Shift="a=0";
extern string Hgi_Entry_OnTrend="a=1";
extern string Hgi_Entry_OnRange="a=1";
extern string Hgi_Entry_OnRad="a=0";
extern string Hgi_Entry_OnSignal="a=1";
extern string Hgi_Entry_OnSlope="a=0";

extern string LbL_Hgi_Exit="---- HGI Exit Settings ----";
extern string Hgi_Exit_TimeFrame="a=60";
extern string Hgi_Exit_Shift="a=0";
extern string Hgi_Exit_OnTrend="a=1";
extern string Hgi_Exit_OnRange="a=1";
extern string Hgi_Exit_OnRad="a=0";
extern string Hgi_Exit_OnSignal="a=1";
extern string Hgi_Exit_OnSlope="a=0";

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
        MultiSettings::Parse(Hgi_Entry_OnRad, onRad, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Entry_OnSignal, onSignal, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Entry_OnSlope, onSlope, entrySubfilterCount);
    }
    
    if(exitSubfilterCount > 0) {
        MultiSettings::Parse(Hgi_Exit_TimeFrame, timeFrame, exitSubfilterCount);
        MultiSettings::Parse(Hgi_Exit_Shift, shift, exitSubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnTrend, onTrend, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnRange, onRange, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnRad, onRad, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnSignal, onSignal, entrySubfilterCount);
        MultiSettings::Parse(Hgi_Exit_OnSlope, onSlope, entrySubfilterCount);
    }
    
    isInit = true;
}

bool FilterHgi::calculate(int subfilterIndex, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterIndex)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].formSymName;
    
    int hgiSignal = getHGISignal(symbol, timeFrame[subfilterIndex], shift[subfilterIndex]);
    int hgiSlope = getHGISlope(symbol, timeFrame[subfilterIndex], shift[subfilterIndex]);
    
    // 0 = Do not track, 1 = OR, 2 = AND
    int OR = 1;
    int AND = 2;
    
    SignalType signalTrend;
    SignalType signalSlope;
    SignalType signalFinal;
    
    switch(hgiSignal) {
        case TRENDUP: signalTrend = onTrend[subfilterIndex] ? SignalBuy  : SignalNone; break;
        case RANGEUP: signalTrend = onRange[subfilterIndex] ? SignalBuy  : SignalNone; break;
        case TRENDDN: signalTrend = onTrend[subfilterIndex] ? SignalSell : SignalNone; break;
        case RANGEDN: signalTrend = onRange[subfilterIndex] ? SignalSell : SignalNone; break;
        case RADUP:   signalTrend = onRad[subfilterIndex]   ? SignalBuy  : SignalNone; break;
        case RADDN:   signalTrend = onRad[subfilterIndex]   ? SignalSell : SignalNone; break;
        default: break;
    }
    
    switch(hgiSlope) {
        case TRENDBELOW: signalSlope = onTrend[subfilterIndex] ? SignalBuy  : SignalNone; break;
        case RANGEBELOW: signalSlope = onRange[subfilterIndex] ? SignalBuy  : SignalNone; break;
        case TRENDABOVE: signalSlope = onTrend[subfilterIndex] ? SignalSell : SignalNone; break;
        case RANGEABOVE: signalSlope = onRange[subfilterIndex] ? SignalSell : SignalNone; break;
        default: break;
    }
    
    if(onSignal[subfilterIndex] == OR && signalTrend != SignalNone) { signalFinal = signalTrend; }
    else if(onSlope[subfilterIndex] == OR && signalSlope != SignalNone) { signalFinal = signalSlope; }
    else if(onSignal[subfilterIndex] == AND && onSlope[subfilterIndex] == AND
        && signalTrend != SignalNone && signalSlope != SignalNone
        && signalTrend == signalSlope
    ) { signalFinal = signalTrend; }
    
    
    dataOut.setRawValue(
        (hgiSignal == TRENDUP ? "ATU "
            : hgiSignal == RANGEUP ? "ARU "
            : hgiSignal == TRENDDN ? "ATD "
            : hgiSignal == RANGEDN ? "ARD "
            : hgiSignal == RADUP ? "AAU "
            : hgiSignal == RADDN ? "AAD "
            : "    "
            )
        + (hgiSlope == TRENDBELOW ? "WTU"
            : hgiSlope == RANGEBELOW ? "WRU"
            : hgiSlope == TRENDABOVE ? "WTD"
            : hgiSlope == RANGEABOVE ? "WRD"
            : "   "
            )
        , signalFinal
        );
    
    return true;
}
