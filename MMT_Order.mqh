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
#include "MMT_Filters/MMT_FilterManager.mqh"
#include "MMT_Data/MMT_DataHistory.mqh"

enum StopLossMode {
    StopModeNormal
    , StopModeValue
    , StopModeTrailing
    , StopModeJumping
    , StopModeBreakeven
};

struct TradeSignal{
    SignalType entryAction;
    SignalType exitAction;
    SignalType exitLongAction;
    SignalType exitShortAction;
};

class OrderManager {
    public:
    TradeSignal tradeSignals[];
    
    OrderManager();
    ~OrderManager();
    
    void doPositions();
    void updateSymbolSignals(int symbolIdx, int filterIdx, int subfilterIdx);
    void resetSymbolSignals();
    
    private:
    // keyed by symbolId
    TimePoint lastTradeBetweenTime[];
    TimePoint lastValueBetweenTime[];
    
    void enterPositionsBySymbol(int symbolId);
    void processCurrentPositions();
    //void exitPositionsBySymbol(string symbol);
    //void exitPositionsBySymbol(int symbolId);
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
    resetSymbolSignals();
}

void OrderManager::~OrderManager() {

}

void OrderManager::doPositions() {
    // todo: separate cycles for updating vs. enter/exit?
    processCurrentPositions();
    
    int symbolCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symbolCount; i++) {
        enterPositionsBySymbol(i);
    }
}

void OrderManager::processCurrentPositions() {
    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderMagicNumber() != MagicNumber) { continue; }
        
        // todo: cache pending value and exit updates?
        changePositionsBySymbol(OrderSymbol());
        //exitPositionsBySymbol(OrderSymbol());
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

//void OrderManager::exitPositionsBySymbol(string symbol) {
//    exitPositionsBySymbol(MainSymbolMan.getSymbolId(symbol));
//}

//void OrderManager::exitPositionsBySymbol(int symbolId) {
//    // Check exit signal for symbol and exit the trade
//    int filterCount = MainFilterMan.getFilterCount();
//    SignalType finalBuySignal;
//    SignalType finalSellSignal;
//    
//    for(int i = 0; i < filterCount; i++) {
//        int exitSubfilterCount = MainFilterMan.getSubfilterCount(i, SubfilterExit);
//        if(exitSubfilterCount <= 0) { continue; }
//        
//        for(int j = 0; j < exitSubfilterCount; j++) {
//            SignalType filterSignal = MainDataMan.getDataHistory(symbolId, i, j).getSignal();
//            bool signalStable = MainDataMan.getDataHistory(symbolId, i, j).getSignalStable(ExitStableTime, TimeSettingUnit);
//            
//            switch(MainFilterMan.filters[i].subfilterMode[j]) {
//                case SubfilterNormal:
//                    break;
//                    
//                case SubfilterOpposite:
//                    break;
//                    
//                case SubfilterNotOpposite:
//                    break;
//            }
//        }
//    }
//}

//+------------------------------------------------------------------+

void OrderManager::enterPositionsBySymbol(int symbolId) {
    // if symbolSignal has an entryAction = SignalBuy or SignalCell, given a symbolIdx, then do that action
}

//+------------------------------------------------------------------+

void OrderManager::resetSymbolSignals() {
    ArrayFree(tradeSignals);
    ArrayResize(tradeSignals, ArraySize(MainSymbolMan.symbols));
}

void OrderManager::updateSymbolSignals(int symbolIdx, int filterIdx, int subfilterIdx) {
    SubfilterType subType = MainFilterMan.filters[filterIdx].subfilterType[subfilterIdx];
    SubfilterMode subMode = MainFilterMan.filters[filterIdx].subfilterMode[subfilterIdx];
    SignalType subSignalType = MainDataMan.getDataHistory(symbolIdx, filterIdx, subfilterIdx).getSignal();
    bool subSignalStable;
    
    if(subMode == SubfilterDisabled) { return; }
    //if(subSignalType != SignalBuy && subSignalType != SignalSell) { return; }
    
    subSignalStable = MainDataMan.getDataHistory(symbolIdx, filterIdx, subfilterIdx).getSignalStable(EntryStableTime, TimeSettingUnit);
    
    switch(subType) {
        case SubfilterEntry:
            if(tradeSignals[symbolIdx].entryAction == SignalHold) { return; }
            
            switch(subMode) {
                case SubfilterNormal:
                    if(!subSignalStable) { 
                        if(subSignalType == SignalBuy || subSignalType == SignalSell) {
                            tradeSignals[symbolIdx].entryAction = SignalHold; 
                        }
                    } else {
                        switch(subSignalType) {
                            case SignalBuy:
                                if(tradeSignals[symbolIdx].entryAction == SignalSell) { 
                                    tradeSignals[symbolIdx].entryAction = SignalHold;
                                } else {
                                    tradeSignals[symbolIdx].entryAction = SignalBuy;
                                }
                                return;
                                
                            case SignalSell:
                                if(tradeSignals[symbolIdx].entryAction == SignalBuy) { 
                                    tradeSignals[symbolIdx].entryAction = SignalHold;
                                } else {
                                    tradeSignals[symbolIdx].entryAction = SignalSell;
                                }
                                return;
                        }
                    }
                    return;
                    
                case SubfilterOpposite:
                    if(!subSignalStable) {
                        if(subSignalType == SignalBuy || subSignalType == SignalSell) {
                            tradeSignals[symbolIdx].entryAction = SignalHold; 
                        }
                    } else {
                        switch(subSignalType) {
                            case SignalBuy:
                                if(tradeSignals[symbolIdx].entryAction == SignalBuy) { 
                                    tradeSignals[symbolIdx].entryAction = SignalHold;
                                } else {
                                    tradeSignals[symbolIdx].entryAction = SignalSell;
                                }
                                return;
                                
                            case SignalSell:
                                if(tradeSignals[symbolIdx].entryAction == SignalSell) { 
                                    tradeSignals[symbolIdx].entryAction = SignalHold;
                                } else {
                                    tradeSignals[symbolIdx].entryAction = SignalBuy;
                                }
                                return;
                        }
                    }
                    
                    return;
                    
                case SubfilterNotOpposite:
                    if(!subSignalStable) { return; }
                    
                    if(
                        (tradeSignals[symbolIdx].entryAction == SignalBuy && subSignalType == SignalSell)
                        || (tradeSignals[symbolIdx].entryAction == SignalSell && subSignalType == SignalBuy)
                    ) {
                        tradeSignals[symbolIdx].entryAction = SignalHold;
                    }
                    return;
                    
                default: return;
            }
            
        case SubfilterExit:
            if(tradeSignals[symbolIdx].exitLongAction == SignalHold 
                && tradeSignals[symbolIdx].exitShortAction == SignalHold 
            ) { return; }
            
            switch(subMode) {
                case SubfilterNormal:
                    if(!subSignalStable) { 
                        if(subSignalType == SignalBuy || subSignalType == SignalSell) {
                            tradeSignals[symbolIdx].exitLongAction = SignalHold; 
                            tradeSignals[symbolIdx].exitShortAction = SignalHold;
                        }
                    } else {
                        switch(subSignalType) {
                            case SignalBuy:
                                if(tradeSignals[symbolIdx].exitLongAction == SignalClose) { 
                                    tradeSignals[symbolIdx].exitLongAction = SignalHold;
                                }
                                
                                tradeSignals[symbolIdx].exitShortAction = SignalClose;
                                
                                return;
                                
                            case SignalSell:
                                if(tradeSignals[symbolIdx].exitShortAction == SignalClose) { 
                                    tradeSignals[symbolIdx].exitShortAction = SignalHold;
                                }
                                
                                tradeSignals[symbolIdx].exitLongAction = SignalClose;
                                
                                return;
                        }
                    }
                    return;
                    
                case SubfilterOpposite:
                    if(!subSignalStable) { 
                        if(subSignalType == SignalBuy || subSignalType == SignalSell) {
                            tradeSignals[symbolIdx].exitLongAction = SignalHold; 
                            tradeSignals[symbolIdx].exitShortAction = SignalHold;
                        }
                    } else {
                        switch(subSignalType) {
                            case SignalBuy:
                                if(tradeSignals[symbolIdx].exitShortAction == SignalClose) { 
                                    tradeSignals[symbolIdx].exitShortAction = SignalHold;
                                }
                                
                                tradeSignals[symbolIdx].exitLongAction = SignalClose;
                                
                                return;
                                
                            case SignalSell:
                                if(tradeSignals[symbolIdx].exitLongAction == SignalClose) { 
                                    tradeSignals[symbolIdx].exitLongAction = SignalHold;
                                }
                                
                                tradeSignals[symbolIdx].exitShortAction = SignalClose;
                                
                                return;
                        }
                    }
                    return;
                    
                case SubfilterNotOpposite:
                    if(!subSignalStable) { return; }
                    
                    if(
                        (tradeSignals[symbolIdx].exitLongAction == SignalClose && subSignalType == SignalSell)
                        || (tradeSignals[symbolIdx].exitLongAction == SignalClose && subSignalType == SignalBuy)
                    ) {
                        tradeSignals[symbolIdx].exitLongAction = SignalHold;
                    }
                    
                    if(
                        (tradeSignals[symbolIdx].exitShortAction == SignalClose && subSignalType == SignalSell)
                        || (tradeSignals[symbolIdx].exitShortAction == SignalClose && subSignalType == SignalBuy)
                    ) {
                        tradeSignals[symbolIdx].exitShortAction = SignalHold;
                    }
                    return;
                    
                default: return;
            }
            
        default: return;
    }
}

OrderManager *MainOrderMan;