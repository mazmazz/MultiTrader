//+------------------------------------------------------------------+
//|                                             MMT_Filter_Stoch.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Filters.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../MMT_Data/MMT_DataUnit.mqh"

class FilterStoch : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int kPeriod[];
    int dPeriod[];
    int slowing[];
    int method[];
    double buySellZone[];
    
    protected:
    void setupOptions();
    
    public:
    void initFilter();
    bool calculate(int subfilterIndex, string symbol, DataUnit *dataOut);
};

//+------------------------------------------------------------------+
// Params
//+------------------------------------------------------------------+

extern string Lbl_Stoch_1="-------- Stoch Settings --------";
extern string Stoch_Entry="a=1|b=1|c=1";
extern string Stoch_Exit="a=1";

extern string LbL_Stoch_Entry_="---- Stoch Entry Settings ----";
extern string Stoch_TimeFrame_="a=15|b=30|c=60";
extern string Stoch_KPeriod_="a=5|b=5|c=5";
extern string Stoch_DPeriod_="a=3|b=3|c=3";
extern string Stoch_Slowing_="a=3|b=3|c=3";
extern string Stoch_Method_="a=3|b=3|c=3";
extern string Stoch_BuySellZone_="a=22.0|b=22.0|c=22.0";

extern string LbL_Stoch_Exit_="---- Stoch Exit Settings ----";
extern string Stoch_Exit_TimeFrame_="a=15";
extern string Stoch_Exit_KPeriod_="a=5";
extern string Stoch_Exit_DPeriod_="a=3";
extern string Stoch_Exit_Slowing_="a=3";
extern string Stoch_Exit_Method_="a=3";
extern string Stoch_Exit_BuySellZone_="a=30.0";

//+------------------------------------------------------------------+
// Methods
//+------------------------------------------------------------------+

void FilterStoch::initFilter() {
    if(isInit) { return; }
    
    shortName = "Stoch";
    
    setupSubfilters(Stoch_Entry, SubfilterEntry);
    setupSubfilters(Stoch_Exit, SubfilterExit);
    setupOptions();
    
    isInit = true;
}

void FilterStoch::setupOptions() {
    int entrySubfilterCount = ArraySize(entrySubfilterId);
    int exitSubfilterCount = ArraySize(exitSubfilterId);
    if(ArraySize(entrySubfilterId) > 0) {
        MultiSettings::Parse(Stoch_TimeFrame_, timeFrame, entrySubfilterCount);
        MultiSettings::Parse(Stoch_KPeriod_, kPeriod, entrySubfilterCount);
        MultiSettings::Parse(Stoch_DPeriod_, dPeriod, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Slowing_, slowing, entrySubfilterCount);
        MultiSettings::Parse(Stoch_Method_, method, entrySubfilterCount);
        MultiSettings::Parse(Stoch_BuySellZone_, buySellZone, entrySubfilterCount);
    }
    
    if(ArraySize(exitSubfilterId) > 0) {
        MultiSettings::Parse(Stoch_Exit_TimeFrame_, timeFrame, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_KPeriod_, kPeriod, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_DPeriod_, dPeriod, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_Slowing_, slowing, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_Method_, method, exitSubfilterCount);
        MultiSettings::Parse(Stoch_Exit_BuySellZone_, buySellZone, exitSubfilterCount);
    }
}

bool FilterStoch::calculate(int subfilterIndex, string symbol, DataUnit *dataOut) {
    if(subfilterIndex >= subfilterCount()) {
        Error::ThrowError(ErrorNormal, "Subfilter index does not exist", FunctionTrace, shortName + "|" + subfilterIndex + "|" + subfilterCount());
        dataOut.success = false;
        return false;
    }
    
    return true;
}
