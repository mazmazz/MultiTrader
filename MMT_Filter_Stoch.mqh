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
    
    int exit_TimeFrame[];
    int exit_KPeriod[];
    int exit_DPeriod[];
    int exit_Slowing[];
    int exit_Method[];
    double exit_BuySellZone[];
    
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
    
    setupChecks(Stoch_Entry, Stoch_Exit);
    setupOptions();
}

void FilterStoch::setupOptions() {
    if(doEntry) {
        OptionsParser::Parse(Stoch_TimeFrame_, timeFrame, checkCount);
        OptionsParser::Parse(Stoch_KPeriod_, kPeriod, checkCount);
        OptionsParser::Parse(Stoch_DPeriod_, dPeriod, checkCount);
        OptionsParser::Parse(Stoch_Slowing_, slowing, checkCount);
        OptionsParser::Parse(Stoch_Method_, method, checkCount);
        OptionsParser::Parse(Stoch_BuySellZone_, buySellZone, checkCount);
    }
    
    if(doExit) {
        OptionsParser::Parse(Stoch_Exit_TimeFrame_, exit_TimeFrame, exit_checkCount);
        OptionsParser::Parse(Stoch_Exit_KPeriod_, exit_KPeriod, exit_checkCount);
        OptionsParser::Parse(Stoch_Exit_DPeriod_, exit_DPeriod, exit_checkCount);
        OptionsParser::Parse(Stoch_Exit_Slowing_, exit_Slowing, exit_checkCount);
        OptionsParser::Parse(Stoch_Exit_Method_, exit_Method, exit_checkCount);
        OptionsParser::Parse(Stoch_Exit_BuySellZone_, exit_BuySellZone, exit_checkCount);
    }
}

void FilterStoch::calculateEntry() {
    if(!doEntry) { return; }
    
    
}

void FilterStoch::calculateExit() {
    if(!doExit) { return; }
    
    
}
