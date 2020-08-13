#property copyright "Copyright 2017, Marco Z"
#property link      ""
#property strict

#include "F_Filter/F_FilterManager.mqh"
#include "S_Symbol.mqh"
#include "D_Data/D_Data.mqh"
#include "O_Order/O_OrderManager.mqh"
#include "H_Dashboard.mqh"
#include "H_Alerts.mqh"

//+------------------------------------------------------------------+

class MainMultiTrader {
    public:
    bool firstRunComplete;
    
    void MainMultiTrader();
    int onInit();
    void onTick();
    void onTimer();
    void onDeinit(const int reason);
    void ~MainMultiTrader();
    void doCycle();
    void doFirstRun();
    
    void addFilter(Filter *inputFilter);
    
#ifdef _EmulatedTicks
    bool setAverageTickTimer(bool setValueOnly = false);
#endif
    
    private:
    int averageTickLength;
};

void MainMultiTrader::MainMultiTrader() {
    firstRunComplete = false;
#ifdef _EmulatedTicks
    averageTickLength = AverageTickStartMil;
#endif
    
    MainSymbolMan = new SymbolManager(IncludeSymbols, ExcludeSymbols, ExcludeCurrencies);
    MainFilterMan = new FilterManager();
    
    // We need to add filters in root file
    // After filters are added, run onInit()
}

void MainMultiTrader::addFilter(Filter *inputFilter) {
    MainFilterMan.addFilter(inputFilter);
}

int MainMultiTrader::onInit() {
    MainDataMan = new DataManager(MainSymbolMan.getSymbolCount(), MainFilterMan.getFilterCount());
    MainOrderMan = new OrderManager();
    MainDashboardMan = new DashboardManager();
    MainAlertMan = new AlertManager();
    
    return INIT_SUCCEEDED;
}

void MainMultiTrader::onTick() {
    doCycle();
}

void MainMultiTrader::onTimer() {
    doCycle();
}

void MainMultiTrader::doCycle() {
#ifdef _Benchmark
    Benchmark_Message = (++Benchmark_FilterCounter) + " | Timer mils: " + (GetTickCount() - Benchmark_LastMilCounter);
    Error::PrintNormal(TimeCurrent() + " | Cycle started: " + Benchmark_Message);
    Benchmark_WorkMilCounter = GetTickCount();
#endif
    
    MainDataMan.retrieveDataFromFilters();
        // iterates through symbols, calls filters and subs on all of them
        // filters feed data
    
    MainOrderMan.doPositions(!firstRunComplete);
    
    MainDashboardMan.updateDashboard();
    
    MainAlertMan.updateAlerts();
    
    // MainDataWriterMan.writeStuff();
    
#ifdef _Benchmark
    Error::PrintNormal(TimeCurrent() + " | Cycle finished: " + Benchmark_FilterCounter + " | Work mils: " + (GetTickCount() - Benchmark_WorkMilCounter));
    Benchmark_LastMilCounter = GetTickCount();
#endif
}

void MainMultiTrader::onDeinit(const int reason) {
    // cleanup
}

void MainMultiTrader::~MainMultiTrader() {
    Common::SafeDelete(MainAlertMan);
    Common::SafeDelete(MainDashboardMan);
    Common::SafeDelete(MainFilterMan);
    Common::SafeDelete(MainOrderMan);
    Common::SafeDelete(MainDataMan);
    Common::SafeDelete(MainSymbolMan);
}

#ifdef _EmulatedTicks
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
#endif

void MainMultiTrader::doFirstRun() {
    firstRunComplete = false;
    doCycle();
    firstRunComplete = true;
}

MainMultiTrader *Main = NULL;
