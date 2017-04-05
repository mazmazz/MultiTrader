#property copyright "Copyright 2017, Marco Z"
#property link      ""
#property strict

#include "F_Filter/F_FilterManager.mqh"
#include "S_Symbol.mqh"
#include "D_Data/D_Data.mqh"
#include "O_Order/O_OrderManager.mqh"
#include "H_Dashboard.mqh"

//+------------------------------------------------------------------+

class MainMultiTrader {
    public:
    bool firstRunComplete;
    bool cycleRunning;
    
    void MainMultiTrader();
    int onInit();
    void onTick();
    void onTimer();
    void onDeinit(const int reason);
    void ~MainMultiTrader();
    void doCycle();
    void doFirstRun();
    
    void addFilter(Filter *inputFilter);
    
    bool setAverageTickTimer(bool setValueOnly = false);
    
    private:
    int averageTickLength;
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
    MainDataMan = new DataManager(MainSymbolMan.getSymbolCount(), MainFilterMan.getFilterCount());
    MainOrderMan = new OrderManager();
    MainDashboardMan = new DashboardManager();
    
    return INIT_SUCCEEDED;
}

void MainMultiTrader::onTick() {
    
    doCycle();
}

void MainMultiTrader::onTimer() {
    doCycle();
}

void MainMultiTrader::doCycle() {
    if(cycleRunning) { 
        return; 
    }
    else { cycleRunning = true; }
        // undecided on this: timer events don't wait until the previous OnTimer call finishes. 
        // Are there issues to simultaneous OnTimer calls?

    MainDataMan.retrieveDataFromFilters();
        // iterates through symbols, calls filters and subs on all of them
        // filters feed data
        
    MainOrderMan.doPositions(!firstRunComplete);
    
    MainDashboardMan.updateDashboard();
    
    // MainDataWriterMan.writeStuff();
    
    cycleRunning = false;
}

void MainMultiTrader::onDeinit(const int reason) {
    // cleanup
}

void MainMultiTrader::~MainMultiTrader() {
    Common::SafeDelete(MainDashboardMan);
    Common::SafeDelete(MainOrderMan);
    Common::SafeDelete(MainDataMan);
    Common::SafeDelete(MainSymbolMan);
    Common::SafeDelete(MainFilterMan);
}

bool MainMultiTrader::setAverageTickTimer(bool setValueOnly = false) {
    //Start at 500 milliseconds
    //Compare total symbol changes (track volume?)
    //If # changes < last # changes, then slow down (timer runs too fast for ticks to occur)
    //if # changes > last # changes, then speed up (timer runs too slow, so many ticks occur)
    //IF # changes = last # changes, either do nothing OR maintain direction of delay adjustment
    //min value 100
    //max value 1000
    
    averageTickLength = 500;
    
    if(setValueOnly) { return true; }
    else { return Common::EventSetMillisecondTimerReliable(averageTickLength); }
}

void MainMultiTrader::doFirstRun() {
    firstRunComplete = false;
    doCycle();
    firstRunComplete = true;
}

MainMultiTrader *Main;
