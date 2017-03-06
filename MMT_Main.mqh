#property copyright "Copyright 2017, Marco Z"
#property link      ""
#property strict

#include "MMT_Filters/MMT_Filter.mqh"
#include "MMT_Symbols.mqh"
#include "MMT_Data/MMT_Data.mqh"
#include "MMT_Dashboard.mqh"

//+------------------------------------------------------------------+

class MainManager {
    public:
    FilterManager *filterMan;
    SymbolManager *symbolMan;
    DataManager *dataMan;
    //OrderManager *orderMan;
    DashboardManager *dashboardMan;

    void MainManager();
    int onInit();
    void onTick();
    void onTimer();
    void onDeinit(const int reason);
    void ~MainManager();
    
    void addFilter(Filter *inputFilter);
};

void MainManager::MainManager() {
    filterMan = new FilterManager();
    
    // We need to add filters in root file
    // After filters are added, run onInit()
}

void MainManager::addFilter(Filter *inputFilter) {
    filterMan.addFilter(inputFilter);
}

int MainManager::onInit() {
    symbolMan = new SymbolManager(IncludeSymbols, ExcludeSymbols, ExcludeCurrencies);
    dataMan = new DataManager(symbolMan.symbolCount, filterMan.filterCount);
    // Main.orderMan = new OrderManager();

    // MainRiskManager.calculateAll();
    // Main.filterMan.calculateAll();
    // Main.orderMan.doAllTrades();
    
    dashboardMan = new DashboardManager();

    return INIT_SUCCEEDED;
}

void MainManager::onTick() {
    // Toggle to do OnTimer or OnTick
    // Per order update, risk calc, or filter calc
    // Per tick or per cycle time (whichever method is picked)
    //uint newTickCount = GetTickCount(); //GetMicrosecondCount();
    
    //((cur) >= (prev)) ? ((cur)-(prev)) : ((0xFFFFFFFF-(prev))+(cur)+1)
    
    // Procedure to calculate risk goes here
    // Procedure to update existing trades goes here
    
    // Procedure to check cycle time goes here
    // If cycle time, then calculate filters
    
    // Dashboard is updated within Main.orderMan, MainRiskManager, and Main.filterMan
    // No need to update here.
}

void MainManager::onDeinit(const int reason) {
    delete(dashboardMan);
    // delete(orderMan);
    delete(dataMan);
    delete(symbolMan);
    delete(filterMan);
}

void MainManager::~MainManager() {
    
}

MainManager *Main;
