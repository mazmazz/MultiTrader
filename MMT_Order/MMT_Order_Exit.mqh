#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "../MMT_Data/MMT_Data.mqh"
#include "../MMT_Symbols.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "MMT_Order_Defines.mqh"

bool OrderManager::doExitPosition(int ticket, int symIdx) {
    if(TradeModeType != TradeGrid && !TradeExitEnabled) { return false; }
    if(TradeModeType == TradeGrid && gridDirection[symIdx] != SignalLong && gridDirection[symIdx] != SignalShort) { return false; }
    
    if(OrderTicket() != ticket) { 
        if(!OrderSelect(ticket, SELECT_BY_TICKET)) { 
            return false; 
        } 
    }
    
    int posType = OrderType();
    if(TradeModeType == TradeGrid && (posType == OP_BUY || posType == OP_SELL) && !GridCloseOrdersOnSignal) { return false; }
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
    
    bool posIsBuy = (TradeModeType == TradeGrid) ? (gridDirection[symIdx] == SignalLong) : (posType % 2 == 0);
    
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
    
    double posLots = OrderLots();
    double posPrice;
    if(posType % 2 == 0) { posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); } // Buy order, even idx
    else { posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); } // Sell order, odd idx
    int posSlippage = 40; // todo: slippage

#ifdef _OrderReliable
    bool result = 
        posType == OP_BUY || posType == OP_SELL ? 
        OrderCloseReliable(ticket, posLots, posPrice, posSlippage)
        : OrderDeleteReliable(ticket) // pending order
        ;
#else
    bool result = 
        posType == OP_BUY || posType == OP_SELL ? 
        OrderClose(ticket, posLots, posPrice, posSlippage)
        : OrderDelete(ticket) // pending order
        ;
#endif
    if(result) {
        if(TradeModeType != TradeGrid) { 
            if(exitIsTrigger) { checkUnit.fulfilled = true; } // do not set opposite entry fulfilled; that's set by entry action
            positionOpenCount[symIdx]--;
        } else {
            // set flag to trigger fulfilled in aggregate at end of loop
            // todo: grid - how to handle failures?
            gridExit[symIdx] = true;
            gridExitByOpposite[symIdx] = oppIsTrigger;
        }
    } else {
        Error::PrintNormal("Failed Closing Ticket " + ticket + " - " + "Type: " + posType + " - " + (exitIsTrigger ? "Exit: " + checkUnit.type : oppIsTrigger ? "Entry: " + oppCheckUnit.type : "No trigger"), NULL, NULL, true);
    }
    return result;
}
