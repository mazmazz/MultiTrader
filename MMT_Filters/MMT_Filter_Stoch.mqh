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

class FilterStoch : public Filter {
    private:
    int timeFrame[];
    int kPeriod[];
    int dPeriod[];
    int slowing[];
    int method[];
    double buySellZone[];
    
    protected:
    void setupOptions();
    
    public:
    FilterStoch();
    
    void calculateEntry();
    void calculateExit();
};

//+------------------------------------------------------------------+
// Params
//+------------------------------------------------------------------+

extern string Lbl_Stoch_1="-------- Stoch Settings --------";
extern string Stoch_Entry="a=1|b=1|c=1";
extern string Stoch_Exit="1";

extern string LbL_Stoch_Entry_="---- Stoch Entry Settings ----";
extern string Stoch_TimeFrame_="a=15|b=30|c=60";
extern string Stoch_KPeriod_="a=5|b=5|c=5";
extern string Stoch_DPeriod_="a=3|b=3|c=3";
extern string Stoch_Slowing_="a=3|b=3|c=3";
extern string Stoch_Method_="a=3|b=3|c=3";
extern string Stoch_BuySellZone_="a=22.0|b=22.0|c=22.0";

extern string LbL_Stoch_Exit_="---- Stoch Exit Settings ----";
extern string Stoch_Exit_TimeFrame_="15";
extern string Stoch_Exit_KPeriod_="5";
extern string Stoch_Exit_DPeriod_="3";
extern string Stoch_Exit_Slowing_="3";
extern string Stoch_Exit_Method_="3";
extern string Stoch_Exit_BuySellZone_="30.0";

//+------------------------------------------------------------------+
// Methods
//+------------------------------------------------------------------+

void FilterStoch::FilterStoch() {
    shortName = "Stoch";
    
    setupSubfilters(Stoch_Entry, SubfilterEntry, false);
    setupSubfilters(Stoch_Exit, SubfilterExit, true);
    setupOptions();
}

void FilterStoch::setupOptions() {
    if(entrySubfilterCount > 0) {
        MultiSettings::Parse(Stoch_TimeFrame_, timeFrame, entrySubfilterCount, false);
        MultiSettings::Parse(Stoch_KPeriod_, kPeriod, entrySubfilterCount, false);
        MultiSettings::Parse(Stoch_DPeriod_, dPeriod, entrySubfilterCount, false);
        MultiSettings::Parse(Stoch_Slowing_, slowing, entrySubfilterCount, false);
        MultiSettings::Parse(Stoch_Method_, method, entrySubfilterCount, false);
        MultiSettings::Parse(Stoch_BuySellZone_, buySellZone, entrySubfilterCount, false);
    }
    
    if(exitSubfilterCount > 0) {
        MultiSettings::Parse(Stoch_Exit_TimeFrame_, timeFrame, exitSubfilterCount, true);
        MultiSettings::Parse(Stoch_Exit_KPeriod_, kPeriod, exitSubfilterCount, true);
        MultiSettings::Parse(Stoch_Exit_DPeriod_, dPeriod, exitSubfilterCount, true);
        MultiSettings::Parse(Stoch_Exit_Slowing_, slowing, exitSubfilterCount, true);
        MultiSettings::Parse(Stoch_Exit_Method_, method, exitSubfilterCount, true);
        MultiSettings::Parse(Stoch_Exit_BuySellZone_, buySellZone, exitSubfilterCount, true);
    }
}

void FilterStoch::calculateEntry() {
    if(entrySubfilterCount < 1) { return; }
    
    
}

void FilterStoch::calculateExit() {
    if(exitSubfilterCount < 1) { return; }
    
    
}
