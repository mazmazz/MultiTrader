//+------------------------------------------------------------------+
//|                                                    MMT_Order.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

#include "MC_Common/MC_Common.mqh"
#include "MMT_Symbols.mqh"

class OrderManager {
    public:
    OrderManager();
    ~OrderManager();
    
    void doPositions();
    
    private:
    // keyed by symbolId
    TimePoint lastTradeBetweenTime[];
    TimePoint lastValueBetweenTime[];
    
    void enterPositionsBySymbol(int symbolId);
    void updateOpenPositions();
    void exitPositionsBySymbol(string symbol);
    void exitPositionsBySymbol(int symbolId);
    void changePositionsBySymbol(string symbol);
    void changePositionsBySymbol(int symbolId);
};

void OrderManager::OrderManager() {
//    EntryStable
//    ExitStable
//    * Check against lastSignalX in DataHistory
//    
//    ExitFirstCheckDelay
//    * Just compare to order open time
//    
//    TradeBetweenDelay
//    * Record last trade time per symbol in OrderMan
//    ValueBetweenDelay
//    * Record last value time per symbol (per trade???) in OrderMan

    ArrayResize(lastTradeBetweenTime, ArraySize(MainSymbolMan.symbols));
    ArrayResize(lastValueBetweenTime, ArraySize(MainSymbolMan.symbols));
}

void OrderManager::~OrderManager() {

}

void OrderManager::doPositions() {
    // todo: separate cycles for updating vs. enter/exit?
    updateOpenPositions();
    
    int symbolCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symbolCount; i++) {
        enterPositionsBySymbol(i);
    }
}

void OrderManager::updateOpenPositions() {
    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderMagicNumber() != MagicNumber) { continue; }
        
        // todo: cache pending value and exit updates?
        changePositionsBySymbol(OrderSymbol());
        exitPositionsBySymbol(OrderSymbol());
    }
}

//+------------------------------------------------------------------+

void OrderManager::changePositionsBySymbol(string symbol) {
    changePositionsBySymbol(MainSymbolMan.getSymbolId(symbol));
}

void OrderManager::changePositionsBySymbol(int symbolId) {
    // For each setting (sltp, etc) retrieve filter value and update if necessary
}

//+------------------------------------------------------------------+

void OrderManager::exitPositionsBySymbol(string symbol) {
    exitPositionsBySymbol(MainSymbolMan.getSymbolId(symbol));
}

void OrderManager::exitPositionsBySymbol(int symbolId) {
    // Check exit signal for symbol and exit the trade
}

//+------------------------------------------------------------------+

void OrderManager::enterPositionsBySymbol(int symbolId) {

}

//+------------------------------------------------------------------+



OrderManager *MainOrderMan;