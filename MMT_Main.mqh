#property copyright "Copyright 2017, Marco Z"
#property link      ""
#property strict

#include "MMT_Filters/MMT_Filters.mqh"
#include "MMT_Symbols.mqh"
#include "MMT_Data/MMT_Data.mqh"
#include "MMT_Order.mqh"
#include "MMT_Dashboard.mqh"

//+------------------------------------------------------------------+

class MainMultiTrader {
    public:
    void MainMultiTrader();
    int onInit();
    void onTick();
    void onTimer();
    void onDeinit(const int reason);
    void ~MainMultiTrader();
    void doCycle();
    
    void addFilter(Filter *inputFilter);
};

void MainMultiTrader::MainMultiTrader() {
    MainFilterMan = new FilterManager();
    
    // We need to add filters in root file
    // After filters are added, run onInit()
}

void MainMultiTrader::addFilter(Filter *inputFilter) {
    MainFilterMan.addFilter(inputFilter);
}

int MainMultiTrader::onInit() {
    MainSymbolMan = new SymbolManager(IncludeSymbols, ExcludeSymbols, ExcludeCurrencies);
    MainDataMan = new DataManager(MainSymbolMan.symbolCount(), MainFilterMan.filterCount());
    MainOrderMan = new OrderManager();
    MainDashboardMan = new DashboardManager();
    
    return INIT_SUCCEEDED;
}

void MainMultiTrader::onTick() {
    // Toggle to do OnTimer or OnTick
    // Per order update, risk calc, or filter calc
    // Per tick or per cycle time (whichever method is picked)
    //uint newTickCount = GetTickCount(); //GetMicrosecondCount();
    
    //((cur) >= (prev)) ? ((cur)-(prev)) : ((0xFFFFFFFF-(prev))+(cur)+1)
    
    // Procedure to check cycle time goes here
    // If cycle time, then do cycle
}

void MainMultiTrader::onTimer() {
    doCycle();
}

void MainMultiTrader::doCycle() {
    // MainSymbolMan.retrieveData();
        // iterates through symbols, calls filters and subs on all of them
        // filters feed data
        
    // MainOrderMan.doAllTrades();
    
    // MainDashboardMan.update();
    
    // MainDataWriterMan.writeStuff();
}

void MainMultiTrader::onDeinit(const int reason) {
    delete(MainDashboardMan);
    delete(MainOrderMan);
    delete(MainDataMan);
    delete(MainSymbolMan);
    delete(MainFilterMan);
}

void MainMultiTrader::~MainMultiTrader() {
    
}

MainMultiTrader *Main;
