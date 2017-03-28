//+------------------------------------------------------------------+
//|                                             MMT_Filter_Stoch.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Filter.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../MMT_Data/MMT_DataUnit.mqh"
#include "../MMT_Symbol.mqh"

class FilterStoch : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int kPeriod[];
    int dPeriod[];
    int slowing[];
    int method[];
    int priceField[];
    int shift[];
    double buySellZone[];
    
    public:
    void init();
    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+
// Params
//+------------------------------------------------------------------+

extern string Lbl_Stoch_1="________ Stoch Settings [Stoch] ________";
extern string Stoch_Entry_Modes="a=1|b=1|c=1";
extern string Stoch_Entry_Names="a=M15|b=M30|c=M60";
extern string Stoch_Exit_Modes="a=1";
extern string Stoch_Exit_Names="a=M15";

extern string LbL_Stoch_Entry="---- Stoch Entry Settings ----";
extern string Stoch_Entry_TimeFrame="a=15|b=30|c=60";
extern string Stoch_Entry_KPeriod="a=5|b=5|c=5";
extern string Stoch_Entry_DPeriod="a=3|b=3|c=3";
extern string Stoch_Entry_Slowing="a=3|b=3|c=3";
extern string Stoch_Entry_Method="a=3|b=3|c=3";
extern string Stoch_Entry_PriceField="a=0|b=0|c=0";
extern string Stoch_Entry_Shift="a=0|b=0|c=0";
extern string Stoch_Entry_BuySellZone="a=22.0|b=22.0|c=22.0";

extern string LbL_Stoch_Exit="---- Stoch Exit Settings ----";
extern string Stoch_Exit_TimeFrame="a=15";
extern string Stoch_Exit_KPeriod="a=5";
extern string Stoch_Exit_DPeriod="a=3";
extern string Stoch_Exit_Slowing="a=3";
extern string Stoch_Exit_Method="a=3";
extern string Stoch_Exit_PriceField="a=0";
extern string Stoch_Exit_Shift="a=0";
extern string Stoch_Exit_BuySellZone="a=30.0";

//+------------------------------------------------------------------+
// Methods
//+------------------------------------------------------------------+

void FilterStoch::init() {
    if(isInit) { return; }
    
    // 1. Define a shortName -- other settings will refer to this filter using this name (case-insensitive).
    shortName = "Stoch";
    
    // 2. Call setupSubfilters for every type offered -- entry, exit, and/or value.
    setupSubfilters(Stoch_Entry_Modes, Stoch_Entry_Names, SubfilterEntry);
    setupSubfilters(Stoch_Exit_Modes, Stoch_Exit_Names, SubfilterExit);
    
    // 3. Set up options per subfilter type.
    int entrySubfilterCount = ArraySize(entrySubfilterId);
    int exitSubfilterCount = ArraySize(exitSubfilterId);
    if(entrySubfilterCount > 0) {
        MultiSettings::Parse(Stoch_Entry_TimeFrame, timeFrame, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Entry_KPeriod, kPeriod, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Entry_DPeriod, dPeriod, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Entry_Slowing, slowing, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Entry_Method, method, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Entry_PriceField, priceField, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Entry_Shift, shift, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Entry_BuySellZone, buySellZone, entrySubfilterCount);
    }
    
    if(exitSubfilterCount > 0) {
        MultiSettings::Parse(Stoch_Exit_TimeFrame, timeFrame, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_KPeriod, kPeriod, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_DPeriod, dPeriod, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_Slowing, slowing, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_Method, method, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_PriceField, priceField, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_Shift, shift, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_BuySellZone, buySellZone, exitSubfilterCount);
    }
    
    isInit = true;
}

bool FilterStoch::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
    if(!checkSafe(subfilterId)) { return false; }
    string symbol = MainSymbolMan.symbols[symbolIndex].name;
    
#ifdef __MQL5__
    int iStochHandle = iStochastic(
        symbol
        , GetMql5TimeFrame(timeFrame[subfilterId])
        , kPeriod[subfilterId]
        , dPeriod[subfilterId]
        , slowing[subfilterId]
        , (ENUM_MA_METHOD)method[subfilterId]
        , (ENUM_STO_PRICE)priceField[subfilterId]
        );
    if(iStochHandle == INVALID_HANDLE) { return false; }
    double value = NormalizeDouble(
        Common::GetSingleValueFromBuffer(iStochHandle, shift[subfilterId], 0)
        , MarketInfo(symbol, MODE_DIGITS)
        );
    IndicatorRelease(iStochHandle);
#else
#ifdef __MQL4__
    double value = iStochastic(
        symbol
        , timeFrame[subfilterId]
        , kPeriod[subfilterId]
        , dPeriod[subfilterId]
        , slowing[subfilterId]
        , method[subfilterId]
        , priceField[subfilterId]
        , 0
        , shift[subfilterId]
        );
#endif
#endif
    
    double lowerZone = buySellZone[subfilterId];
    double upperZone = 100-buySellZone[subfilterId];
    
    SignalType signal;
    signal = 
        value <= lowerZone ? SignalBuy
        : value >= upperZone ? SignalSell
        : SignalNone
        ;
    
    dataOut.setRawValue(value, signal, DoubleToString(value, 2));
    
    return true;
}
