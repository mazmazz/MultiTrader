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
    
    // if(subSignalType != SignalNone) {
    subSignalStable = MainDataMan.getDataHistory(symbolIdx, filterIdx, subfilterIdx).getSignalStable(EntryStableTime, TimeSettingUnit);
    // }
    
    SignalType actSignalType;
    SignalType resultSignalType;
    
    switch(subType) {
        case SubfilterEntry: actSignalType = tradeSignals[symbolIdx].entryAction; break;
        case SubfilterExit: actSignalType = tradeSignals[symbolIdx].exitAction; break;
        default: return;
    }
    
    if(actSignalType == SignalHold) { return; }
    
    switch(subMode) {
        case SubfilterNormal:
            if(!subSignalStable) { 
                if(subSignalType == SignalBuy || subSignalType == SignalSell) {
                    resultSignalType = SignalHold; 
                }
            } else {
                switch(subSignalType) {
                    case SignalBuy:
                        if(actSignalType == SignalShort) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalLong;
                        }
                        break;
                        
                    case SignalSell:
                        if(actSignalType == SignalLong) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalShort;
                        }
                        break;
                        
                    default:
                        resultSignalType = SignalHold;
                        break;
                }
            }
            break;
            
        case SubfilterOpposite:
            if(!subSignalStable) {
                if(subSignalType == SignalBuy || subSignalType == SignalSell) {
                    resultSignalType = SignalHold; 
                }
            } else {
                switch(subSignalType) {
                    case SignalBuy:
                        if(actSignalType == SignalLong) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalShort;
                        }
                        break;
                        
                    case SignalSell:
                        if(actSignalType == SignalShort) { 
                            resultSignalType = SignalHold;
                        } else {
                            resultSignalType = SignalLong;
                        }
                        break;
                        
                    default:
                        resultSignalType = SignalHold;
                        break;
                }
            }
            break;
            
        case SubfilterNotOpposite:
            if(!subSignalStable) { break; }
            
            if(
                (actSignalType == SignalLong && subSignalType == SignalSell)
                || (actSignalType == SignalShort && subSignalType == SignalBuy)
            ) {
                resultSignalType = SignalHold;
            }
            break;
            
        default: break;
    }
    
    if(resultSignalType == SignalNone) { return; }
    
    switch(subType) {
        case SubfilterEntry: tradeSignals[symbolIdx].entryAction = resultSignalType; break;
        case SubfilterExit: tradeSignals[symbolIdx].exitAction = resultSignalType; break;
    }
    
}

OrderManager *MainOrderMan;