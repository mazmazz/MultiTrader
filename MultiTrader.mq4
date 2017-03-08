//+------------------------------------------------------------------+
//|                                                  MultiTrader.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
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

#include "MMT_Settings.mqh"
#include "MMT_Main.mqh"

//+------------------------------------------------------------------+
// 1. Include filter and risk includes here [INCLUDES]
//    Include order affects settings order in config window
//+------------------------------------------------------------------+

#include "MMT_Filters/MMT_Filter_Stoch.mqh"

//+------------------------------------------------------------------+
// 2. Add filters to OnInit below [HOOKS]
//    Add order affects display order on dashboard
//+------------------------------------------------------------------+

int OnInit() {
    Main = new MainMultiTrader();
    Main.addFilter(new FilterStoch());

    return Main.onInit();
}

void OnTimer() {
    Main.onTimer();
}

void OnDeinit(const int reason) {
    Main.onDeinit(reason);
    delete(Main);
}
