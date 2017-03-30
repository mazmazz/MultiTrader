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
    if(TradeModeType != TradeGrid && !TradeExitEnabled) { return false; }
    
    // exit by market schedule works as a force flag, not as a safe flag, so don't check here
    
    return (getCurrentSessionIdx(symIdx) >= 0);
}

bool OrderManager::checkDoExitSignals(int ticket, int symIdx) {
    if(!isExitSafe(symIdx)) { return false; }
    if(TradeModeType == TradeGrid && gridDirection[symIdx] != SignalLong && gridDirection[symIdx] != SignalShort) { return false; }
    
    if(!checkDoSelectOrder(ticket)) { return false; }
    
    int posType = OrderType();
    if(TradeModeType == TradeGrid && !Common::OrderIsPending(posType) && !GridCloseOrdersOnSignal) { return false; }
    // todo: grid - smarter exit rules on pendings. Don't delete them at all?
    
    string posSymName = OrderSymbol();
    
    // todo: grid - how to close pendings when encountering an opposite signal?
    bool checkSig;
    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(false);
    checkSig = !Common::IsInvalidPointer(checkUnit) && !checkUnit.fulfilled; // todo: how is this affected by retrace?
    if(!checkSig && !CloseOrderOnOppositeSignal && TradeModeType != TradeGrid) { return false; }
    
    bool checkOpp;
    SignalUnit *oppCheckUnit;
    if(CloseOrderOnOppositeSignal || TradeModeType == TradeGrid) {
        oppCheckUnit = MainDataMan.symbol[symIdx].getSignalUnit(true);
        checkOpp = !Common::IsInvalidPointer(oppCheckUnit) && !oppCheckUnit.fulfilled;
        if(!checkSig && !checkOpp) { return false; }
    }
    
    bool posIsBuy = (TradeModeType == TradeGrid) ? (gridDirection[symIdx] == SignalLong) : Common::OrderIsLong(posType);
    
    bool oppIsTrigger,exitIsTrigger;
    if(!checkOpp) { 
        if(checkUnit.type != SignalLong && checkUnit.type != SignalShort && checkUnit.type != SignalClose) { return false; }
        if(posIsBuy && checkUnit.type == SignalLong) { return false; } // signals are negated for exits -- "SignalLong" means Buy OK, close Shorts.
        else if(!posIsBuy && checkUnit.type == SignalShort) { return false; }
        else { exitIsTrigger = true; }
    }
    else {
        bool checkIsEmpty, oppIsEmpty;
        if(checkUnit.type != SignalLong && checkUnit.type != SignalShort && checkUnit.type != SignalClose) { checkIsEmpty = true; }
        if(oppCheckUnit.type != SignalLong && oppCheckUnit.type != SignalShort && oppCheckUnit.type != SignalClose) { oppIsEmpty = true; }
        if(checkIsEmpty && oppIsEmpty) { return false; }
        
        if(posIsBuy) {
            if(!checkIsEmpty && checkUnit.type == SignalLong) { return false; }
            if(!oppIsEmpty && oppCheckUnit.type == SignalLong) { return false; }
            
            if(!checkIsEmpty && (checkUnit.type == SignalShort || checkUnit.type == SignalClose)) { exitIsTrigger = true; }
            if(!exitIsTrigger && !oppIsEmpty && (oppCheckUnit.type == SignalShort || checkUnit.type == SignalClose)) { oppIsTrigger = true; }
        } else {
            if(!checkIsEmpty && checkUnit.type == SignalShort) { return false; }
            if(!oppIsEmpty && oppCheckUnit.type == SignalShort) { return false; }
            
            if(!checkIsEmpty && (checkUnit.type == SignalLong || checkUnit.type == SignalClose)) { exitIsTrigger = true; }
            if(!exitIsTrigger && !oppIsEmpty && (oppCheckUnit.type == SignalLong || checkUnit.type == SignalClose)) { oppIsTrigger = true; }
        } 
    }
    
    if(!exitIsTrigger && !oppIsTrigger) { 
        Error::PrintNormal("Neither exit nor opp is trigger", FunctionTrace, posSymName +"|"+posType, true);
    }
    
    if(TradeModeType == TradeGrid) { // if order is market, not pending, then close according to signal
        if(exitIsTrigger) {
            if(posType == OP_BUY && checkUnit.type == SignalLong) { return false; }
            if(posType == OP_SELL && checkUnit.type == SignalShort) { return false; }
        } else if(oppIsTrigger) {
            if(posType == OP_BUY && oppCheckUnit.type == SignalLong) { return false; }
            if(posType == OP_SELL && oppCheckUnit.type == SignalShort) { return false; }
        }
    }
    
    // todo: retracement protection?
    
    bool result = sendClose(ticket, symIdx);
    if(result) {
        if(TradeModeType != TradeGrid) { 
            if(exitIsTrigger) { checkUnit.fulfilled = true; } // do not set opposite entry fulfilled; that's set by entry action
        } else {
            gridExitBySignal[symIdx] = exitIsTrigger;
            gridExitByOpposite[symIdx] = oppIsTrigger;
        }
    } else {
        Error::PrintNormal((exitIsTrigger ? "Exit: " + checkUnit.type : oppIsTrigger ? "Entry: " + oppCheckUnit.type : "No trigger"), NULL, NULL, true);
    }
    return result;
}

bool OrderManager::sendClose(int ticket, int symIdx) {
    if(IsTradeContextBusy()) { return false; }

    bool result;
    if(!checkDoSelectOrder(ticket)) { return false; }

    string posSymName = OrderSymbol();
    double posLots = OrderLots();
    int posType = OrderType();
    double posPrice;
    if(Common::OrderIsLong(posType)) { posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); } // Buy order, even idx
    else { posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); } // Sell order, odd idx
    int posSlippage = 40; // todo: slippage
    
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
        if(TradeModeType != TradeGrid) { 
            positionOpenCount[symIdx]--;
        } else {
            // set flag to trigger fulfilled in aggregate at end of loop
            // todo: grid - how to handle failures?
            gridExit[symIdx] = true;
        }
    } else {
        Error::PrintNormal("Failed Closing Ticket " + ticket + " - " + "Type: " + posType, NULL, NULL, true);
    }
    
    return result;
}
