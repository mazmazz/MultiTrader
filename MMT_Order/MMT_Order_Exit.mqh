#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "../MMT_Data/MMT_Data.mqh"
#include "../MMT_Symbol.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "MMT_Order_Defines.mqh"

bool OrderManager::isExitSafe(int symIdx) {
    if(!IsTradeAllowed()) { return false; }
    if(SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL
        && SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_CLOSEONLY
    ) { return false; }
        // MT5: LONGONLY and SHORTONLY
        // MT4: CLOSEONLY, FULL, or DISABLED
    if(!isTradeModeGrid() && !TradeExitEnabled) { return false; }
    
    // exit by market schedule works as a force flag, not as a safe flag, so don't check here
    
    return (getCurrentSessionIdx(symIdx) >= 0);
}

bool OrderManager::checkDoExitSignals(int ticket, int symIdx) {
    if(!isExitSafe(symIdx)) { return false; }
    if(!checkDoSelectOrder(ticket)) { return false; }
    
    int posType = OrderType();
    
    if(isTradeModeGrid()) {
        if(!GridCloseMarketOnSignal && !Common::OrderIsPending(posType)) { return false; }
        if(!GridClosePendingOnSignal && Common::OrderIsPending(posType)) { return false; }
    }
    
    string posSymName = OrderSymbol();
    
    // todo: grid - how to close pendings when encountering an opposite signal?
    bool checkSig;
    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(false);
    checkSig = !Common::IsInvalidPointer(checkUnit) && !checkUnit.fulfilled; // todo: how is this affected by retrace?
    if(!checkSig && !CloseOrderOnOppositeSignal && !isTradeModeGrid()) { return false; }
    
    bool checkEntry;
    SignalUnit *entryCheckUnit;
    if(CloseOrderOnOppositeSignal || isTradeModeGrid()) {
        entryCheckUnit = MainDataMan.symbol[symIdx].getSignalUnit(true);
        checkEntry = !Common::IsInvalidPointer(entryCheckUnit) && !entryCheckUnit.fulfilled;
        if(!checkSig && !checkEntry) { return false; }
    }
    
    bool posIsBuy = (isTradeModeGrid()) ? (gridDirection[symIdx] == SignalLong) : Common::OrderIsLong(posType);
    
    bool entryIsTrigger,exitIsTrigger;
    if(!checkEntry) { 
        if(checkUnit.type != SignalLong && checkUnit.type != SignalShort && checkUnit.type != SignalClose) { return false; }
        if(posIsBuy && checkUnit.type == SignalLong) { return false; } // signals are negated for exits -- "SignalLong" means Buy OK, close Shorts.
        else if(!posIsBuy && checkUnit.type == SignalShort) { return false; }
        else { exitIsTrigger = true; }
    }
    else {
        bool checkIsEmpty, entryIsEmpty;
        if(checkUnit.type != SignalLong && checkUnit.type != SignalShort && checkUnit.type != SignalClose) { checkIsEmpty = true; }
        if(entryCheckUnit.type != SignalLong && entryCheckUnit.type != SignalShort && entryCheckUnit.type != SignalClose) { entryIsEmpty = true; }
        if(checkIsEmpty && entryIsEmpty) { return false; }
        
        if(posIsBuy) {
            if(!checkIsEmpty && checkUnit.type == SignalLong) { return false; }
            if(!entryIsEmpty && entryCheckUnit.type == SignalLong) { return false; }
            
            if(!checkIsEmpty && (checkUnit.type == SignalShort || checkUnit.type == SignalClose)) { exitIsTrigger = true; }
            if(!exitIsTrigger && !entryIsEmpty && (entryCheckUnit.type == SignalShort || checkUnit.type == SignalClose)) { entryIsTrigger = true; }
        } else {
            if(!checkIsEmpty && checkUnit.type == SignalShort) { return false; }
            if(!entryIsEmpty && entryCheckUnit.type == SignalShort) { return false; }
            
            if(!checkIsEmpty && (checkUnit.type == SignalLong || checkUnit.type == SignalClose)) { exitIsTrigger = true; }
            if(!exitIsTrigger && !entryIsEmpty && (entryCheckUnit.type == SignalLong || checkUnit.type == SignalClose)) { entryIsTrigger = true; }
        } 
    }
    
    if(!exitIsTrigger && !entryIsTrigger) { 
        Error::PrintNormal("Neither exit nor entry is trigger", FunctionTrace, posSymName +"|"+posType, true);
    }
    
    if(isTradeModeGrid()) { // if order is market, not pending, then close according to signal
        if(exitIsTrigger) {
            if(posType == OP_BUY && checkUnit.type == SignalLong) { return false; }
            if(posType == OP_SELL && checkUnit.type == SignalShort) { return false; }
        } else if(entryIsTrigger) {
            if(posType == OP_BUY && entryCheckUnit.type == SignalLong) { return false; }
            if(posType == OP_SELL && entryCheckUnit.type == SignalShort) { return false; }
        }
    }
    
    // todo: retracement protection?
    
    bool result = sendClose(ticket, symIdx);
    if(result) {
        if(!isTradeModeGrid()) { 
            if(exitIsTrigger) { checkUnit.fulfilled = true; } // do not set opposite entry fulfilled; that's set by entry action
        } else {
            gridExitBySignal[symIdx] = exitIsTrigger;
            gridExitByOpposite[symIdx] = entryIsTrigger;
        }
    } else {
        Error::PrintNormal((exitIsTrigger ? "Exit: " + checkUnit.type : entryIsTrigger ? "Entry: " + entryCheckUnit.type : "No trigger"), NULL, NULL, true);
    }
    return result;
}

bool OrderManager::sendClose(int ticket, int symIdx) {
#ifdef __MQL4__
    if(IsTradeContextBusy()) { return false; }
#endif

    bool result;
    if(!checkDoSelectOrder(ticket)) { return false; }

    string posSymName = OrderSymbol();
    double posLots = OrderLots();
    int posType = OrderType();
    double posPrice;
    if(Common::OrderIsLong(posType)) { posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); } // Buy order, even idx
    else { posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); } // Sell order, odd idx
    
    int posSlippage;
    if(!getValuePoints(posSlippage, maxSlippageLoc, symIdx)) { return -1; }
    
#ifdef _OrderReliable
    result = 
        !Common::OrderIsPending(posType) ? 
        OrderCloseReliable(ticket, posLots, posPrice, posSlippage)
        : OrderDeleteReliable(ticket) // pending order
        ;
#else
    result = 
        !Common::OrderIsPending(posType) ? 
        OrderClose(ticket, posLots, posPrice, posSlippage)
        : OrderDelete(ticket) // pending order
        ;
#endif
    
    if(result) {
        if(isTradeModeGrid()) { 
            // set flag to trigger fulfilled in aggregate at end of loop
            // todo: grid - how to handle failures?
            gridExit[symIdx] = true;
        }
    } else {
        Error::PrintNormal("Failed Closing Ticket " + ticket + " - " + "Type: " + posType, NULL, NULL, true);
    }
    
    return result;
}
