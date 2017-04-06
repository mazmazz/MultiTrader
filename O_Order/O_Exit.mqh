#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "../D_Data/D_Data.mqh"
#include "../S_Symbol.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "O_Defines.mqh"

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

bool OrderManager::checkDoExitSignals(int ticket, int symIdx, bool isPosition) {
    if(!isExitSafe(symIdx)) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    int posType = getOrderType(isPosition);
    
    if(isTradeModeGrid()) {
        if(!GridCloseMarketOnSignal && !Common::OrderIsPending(posType)) { return false; }
        if(!GridClosePendingOnSignal && Common::OrderIsPending(posType)) { return false; }
    }
    
    string posSymName = getOrderSymbol(isPosition);
    
    // todo: grid - how to close pendings when encountering an opposite signal?
    bool checkSig = false;
    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(false);
    checkSig = !Common::IsInvalidPointer(checkUnit) && !checkUnit.fulfilled; // todo: how is this affected by retrace?
    if(!checkSig && !CloseOrderOnOppositeSignal && !isTradeModeGrid()) { return false; }
    
    bool checkEntry = false;
    SignalUnit *entryCheckUnit = NULL;
    if(CloseOrderOnOppositeSignal || isTradeModeGrid()) {
        entryCheckUnit = MainDataMan.symbol[symIdx].getSignalUnit(true);
        checkEntry = !Common::IsInvalidPointer(entryCheckUnit) && !entryCheckUnit.fulfilled;
        if(!checkSig && !checkEntry) { return false; }
    }
    
    bool posIsBuy = (isTradeModeGrid()) ? gridSetLong[symIdx] : Common::OrderIsLong(posType);
    
    bool entryIsTrigger = false,exitIsTrigger = false;
    if(!checkEntry) { 
        if(checkUnit.type != SignalLong && checkUnit.type != SignalShort && checkUnit.type != SignalClose) { return false; }
        if(posIsBuy && checkUnit.type == SignalLong) { return false; } // signals are negated for exits -- "SignalLong" means Buy OK, close Shorts.
        else if(!posIsBuy && checkUnit.type == SignalShort) { return false; }
        else { exitIsTrigger = true; }
    }
    else {
        bool checkIsEmpty = false, entryIsEmpty = false;
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
            if(posType == OrderTypeBuy && checkUnit.type == SignalLong) { return false; }
            if(posType == OrderTypeSell && checkUnit.type == SignalShort) { return false; }
        } else if(entryIsTrigger) {
            if(posType == OrderTypeBuy && entryCheckUnit.type == SignalLong) { return false; }
            if(posType == OrderTypeSell && entryCheckUnit.type == SignalShort) { return false; }
        }
    }
    
    // todo: retracement protection?
    
    bool result = sendClose(ticket, symIdx, isPosition);
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
