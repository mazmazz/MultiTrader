//+------------------------------------------------------------------+
//|                                             MMT_Filter_Stoch.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Filter.mqh"
#include "MMT_OptionsParser.mqh"

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
extern string Stoch_Entry="a=1;b=1;c=1";
extern string Stoch_Exit="1";

extern string LbL_Stoch_Entry_="---- Stoch Entry Settings ----";
extern string Stoch_TimeFrame_="a=15;b=30;c=60";
extern string Stoch_KPeriod_="a=5;b=5;c=5";
extern string Stoch_DPeriod_="a=3;b=3;c=3";
extern string Stoch_Slowing_="a=3;b=3;c=3";
extern string Stoch_Method_="a=3;b=3;c=3";
extern string Stoch_BuySellZone_="a=22.0;b=22.0;c=22.0";

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
    
    setupChecks(Stoch_Entry, CheckEntry, false);
    setupChecks(Stoch_Exit, CheckExit, true);
    setupOptions();
}

void FilterStoch::setupOptions() {
    if(entryCheckCount > 0) {
        OptionsParser::Parse(Stoch_TimeFrame_, timeFrame, entryCheckCount, false);
        OptionsParser::Parse(Stoch_KPeriod_, kPeriod, entryCheckCount, false);
        OptionsParser::Parse(Stoch_DPeriod_, dPeriod, entryCheckCount, false);
        OptionsParser::Parse(Stoch_Slowing_, slowing, entryCheckCount, false);
        OptionsParser::Parse(Stoch_Method_, method, entryCheckCount, false);
        OptionsParser::Parse(Stoch_BuySellZone_, buySellZone, entryCheckCount, false);
    }
    
    if(exitCheckCount > 0) {
        OptionsParser::Parse(Stoch_Exit_TimeFrame_, timeFrame, exitCheckCount, true);
        OptionsParser::Parse(Stoch_Exit_KPeriod_, kPeriod, exitCheckCount, true);
        OptionsParser::Parse(Stoch_Exit_DPeriod_, dPeriod, exitCheckCount, true);
        OptionsParser::Parse(Stoch_Exit_Slowing_, slowing, exitCheckCount, true);
        OptionsParser::Parse(Stoch_Exit_Method_, method, exitCheckCount, true);
        OptionsParser::Parse(Stoch_Exit_BuySellZone_, buySellZone, exitCheckCount, true);
    }
}

void FilterStoch::calculateEntry() {
    if(entryCheckCount < 1) { return; }
    
    
}

void FilterStoch::calculateExit() {
    if(exitCheckCount < 1) { return; }
    
    
}
