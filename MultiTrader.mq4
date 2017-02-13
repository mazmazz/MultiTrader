//+------------------------------------------------------------------+
//|                                                  MultiTrader.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      ""
#property strict
//+------------------------------------------------------------------+
//| Comments
//+------------------------------------------------------------------+
//
// How to Add Filters and Risks
// 1. Add include to include list - search [INCLUDES]
// 2. Add filter or risk to OnInit() - search [HOOKS]
//
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
const string MMT_EaName = "MultiTrader";
const string MMT_EaShortName = "MMT";
const string MMT_Version = "v0.1 02/2017";

#include "MMT_Library/MMT_Library.mqh"

#include "MMT_Main.mqh"

//+------------------------------------------------------------------+
// 1. Include filter and risk includes here [INCLUDES]
//    Include order affects settings order in config window
//+------------------------------------------------------------------+

#include "MMT_Filter_Stoch.mqh"

//+------------------------------------------------------------------+
// 2. Add filters and risks to OnInit below [HOOKS]
//    Add order affects display order on dashboard
//+------------------------------------------------------------------+

int OnInit() {
    Main = new MainManager();
    Main.addFilter(new FilterStoch());

    return Main.onInit();
}

void OnTick() {
    Main.onTick();
}

void OnDeinit(const int reason) {
    Main.onDeinit(reason);
    delete(Main);
}
