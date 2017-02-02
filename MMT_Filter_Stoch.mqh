//+------------------------------------------------------------------+
//|                                             MMT_Filter_Stoch.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Filter.mqh"
#include "MMT_Helper_OptionsParser.mqh"
#include "MMT_Helper_Filter.mqh"

//+------------------------------------------------------------------+
// Params
//+------------------------------------------------------------------+

extern string Lbl_Stoch_1="---- Stoch Settings ----";
extern string Stoch_TimeFrame_="a=15;b=30;c=60";
extern string Stoch_KPeriod_="a=5;b=5;c=5";
extern string Stoch_DPeriod_="a=3;b=3;c=3";
extern string Stoch_Slowing_="a=3;b=3;c=3";
extern string Stoch_Method_="a=3;b=3;c=3";
extern string Stoch_BuySellZone_="a=22.0;b=22.0;c=25.0";

extern string LbL_Stoch_Exit_="---- Stoch Exit Settings ----";
extern string Stoch_Exit_TimeFrame_="15";
extern string Stoch_Exit_KPeriod_="5";
extern string Stoch_Exit_DPeriod_="3";
extern string Stoch_Exit_Slowing_="3";
extern string Stoch_Exit_Method_="3";
extern string Stoch_Exit_BuySellZone_="22.0";

int Stoch_CheckCount = 0;
int Stoch_Exit_CheckCount = 0;

bool Stoch_DoEntry = false;
bool Stoch_DoExit = false;

int Stoch_CheckMode[];
int Stoch_Exit_CheckMode[];

int Stoch_TimeFrame[];
int Stoch_KPeriod[];
int Stoch_DPeriod[];
int Stoch_Slowing[];
int Stoch_Method[];
double Stoch_BuySellZone[];

int Stoch_Exit_TimeFrame[];
int Stoch_Exit_KPeriod[];
int Stoch_Exit_DPeriod[];
int Stoch_Exit_Slowing[];
int Stoch_Exit_Method[];
double Stoch_Exit_BuySellZone[];

//+------------------------------------------------------------------+
// Methods
//+------------------------------------------------------------------+

void Stoch_SetupOptions() {
    Stoch_CheckCount = ParseOptions_CountPairs(Stoch_Entry);
    Stoch_Exit_CheckCount = ParseOptions_CountPairs(Stoch_Exit);
    
    if(Stoch_CheckCount < 1 && Stoch_Exit_CheckCount < 1) { return; }
    
    ParseOptions_Int(Stoch_Entry, Stoch_CheckMode, Stoch_CheckCount);
    ParseOptions_Int(Stoch_Exit, Stoch_Exit_CheckMode, Stoch_Exit_CheckCount);
    
    Stoch_DoEntry = (GetMaxCheckMode(Stoch_CheckMode) > 0);
    Stoch_DoExit = (GetMaxCheckMode(Stoch_Exit_CheckMode) > 0);
    
    if(Stoch_DoEntry) {
        ParseOptions_Int(Stoch_TimeFrame_, Stoch_TimeFrame, Stoch_CheckCount);
        ParseOptions_Int(Stoch_KPeriod_, Stoch_KPeriod, Stoch_CheckCount);
        ParseOptions_Int(Stoch_DPeriod_, Stoch_DPeriod, Stoch_CheckCount);
        ParseOptions_Int(Stoch_Slowing_, Stoch_Slowing, Stoch_CheckCount);
        ParseOptions_Int(Stoch_Method_, Stoch_Method, Stoch_CheckCount);
        ParseOptions_Double(Stoch_BuySellZone_, Stoch_BuySellZone, Stoch_CheckCount);
    }
    
    if(Stoch_DoExit) {
        ParseOptions_Int(Stoch_Exit_TimeFrame_, Stoch_Exit_TimeFrame, Stoch_Exit_CheckCount);
        ParseOptions_Int(Stoch_Exit_KPeriod_, Stoch_Exit_KPeriod, Stoch_Exit_CheckCount);
        ParseOptions_Int(Stoch_Exit_DPeriod_, Stoch_Exit_DPeriod, Stoch_Exit_CheckCount);
        ParseOptions_Int(Stoch_Exit_Slowing_, Stoch_Exit_Slowing, Stoch_Exit_CheckCount);
        ParseOptions_Int(Stoch_Exit_Method_, Stoch_Exit_Method, Stoch_Exit_CheckCount);
        ParseOptions_Double(Stoch_Exit_BuySellZone_, Stoch_Exit_BuySellZone, Stoch_Exit_CheckCount);
    }
}

void Stoch_CalculateEntry() {
    if(!Stoch_DoEntry) { return; }
    
    
}

void Stoch_CalculateExit() {
    if(!Stoch_DoExit) { return; }
    
    
}

//+------------------------------------------------------------------+
// Runtime events
//+------------------------------------------------------------------+

void Stoch_OnInit() {
    Stoch_SetupOptions();
}
//
//void function Stoch_OnTick() {
//
//}

void Stoch_OnTimer() {
    Stoch_CalculateEntry();
}
//
//void function Stoch_OnDeinit() {
//
//}