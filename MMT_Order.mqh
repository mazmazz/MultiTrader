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
//#include "depends/OrderReliable.mqh"

enum StopLossMode {
    StopModeNormal
    , StopModeValue
    , StopModeTrailing
    , StopModeJumping
    , StopModeBreakeven
};

class OrderManager {
    public:
    OrderManager();
    ~OrderManager();
    
    void doPositions();
    
    private:
    // keyed by symbolId
    TimePoint lastTradeBetweenTime[];
    TimePoint lastValueBetweenTime[];
    
    void processCurrentPositions();
    void changePositionsBySymbol(string symbol);
    void changePositionsBySymbol(int symbolId);
    
    bool checkExitPosition(int ticket);
    
    int enterPositionBySymbol(int symIdx);
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
    processCurrentPositions();
    
    int symbolCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symbolCount; i++) {
        enterPositionBySymbol(i);
    }
}

void OrderManager::processCurrentPositions() {
    for(int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderMagicNumber() != MagicNumber) { continue; }
        
        // todo: cache pending value and exit updates?
        //changePositionsBySymbol(OrderSymbol());
        checkExitPosition(OrderTicket());
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

bool OrderManager::checkExitPosition(int ticket) {
    if(OrderTicket() != ticket) { 
        if(!OrderSelect(ticket, SELECT_BY_TICKET)) { return false; } 
    }
    string posSymName = OrderSymbol();
    int symIdx = MainSymbolMan.getSymbolId(posSymName);
    
    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(false);
    if(Common::IsInvalidPointer(checkUnit)) { return true; }
    else if(checkUnit.fulfilled) { return true; }
    
    if(checkUnit.type != SignalLong && checkUnit.type != SignalShort) { return true; }
    
    if(!MainDataMan.symbol[symIdx].getSignalStable(ExitStableTime, TimeSettingUnit, checkUnit)) { return true; }
    
    int posType = OrderType();
    if(posType == OP_BUY && checkUnit.type == SignalLong) { return true; } // signals are negated for exits -- "SignalLong" means Buy OK, close Shorts.
    else if(posType == OP_SELL && checkUnit.type == SignalShort) { return true; }
    
    double posLots = OrderLots();
    double posPrice = posType == OP_SELL ? MarketInfo(posSymName, MODE_ASK) : MarketInfo(posSymName, MODE_BID);
    int posSlippage = 40; // todo: get slippage from filter?
    
    bool result = OrderClose(ticket, posLots, posPrice, posSlippage);
    checkUnit.fulfilled = result;
    return result;
}

//+------------------------------------------------------------------+

int OrderManager::enterPositionBySymbol(int symIdx) {
    // todo: for exit, check if entrySignal[0] is opposite to pending signal 
    // if yes, block entrySignal[0] from fulfillment
    // if no, check stability: if last exitSignal[0] is stable
        // if yes, allow fulfillment of entrySignal[0]
        // if no, block fulfillment of entrySignal[0]
        
    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(true);
    if(Common::IsInvalidPointer(checkUnit)) { return 0; }
    else if(checkUnit.fulfilled) { return 0; }
    
    if(checkUnit.type != SignalLong && checkUnit.type != SignalShort) { return 0; }
    
    if(!MainDataMan.symbol[symIdx].getSignalStable(EntryStableTime, TimeSettingUnit, checkUnit)) { return 0; }
    
    // check exit signal conflict here
    
    
    // todo: check spread for entry
    
    
    string posSymName = MainSymbolMan.symbols[symIdx].name;
    int posCmd = checkUnit.type == SignalLong ? OP_BUY : OP_SELL; // todo: pending orders?
    double posVolume = 0.01; // todo: get order size
    double posPrice = posCmd == OP_SELL ? MarketInfo(posSymName, MODE_BID) : MarketInfo(posSymName, MODE_ASK);
    int posSlippage = 40; // todo: get slippage
    double posStoploss = 0; // todo: get stop loss
    double posTakeprofit = 0; // todo: get take profit
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    // datetime posExpiration
    
    int result = OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic);
    checkUnit.fulfilled = (result > -1);
    return result;
}

//+------------------------------------------------------------------+

OrderManager *MainOrderMan;