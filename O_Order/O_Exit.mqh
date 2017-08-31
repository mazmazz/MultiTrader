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

#include "../H_Alerts.mqh"

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

bool OrderManager::checkDoExitSignals(long ticket, int symIdx, bool isPosition) {
    if(!isExitSafe(symIdx)) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    int posType = getOrderType(isPosition);
    
    if(isTradeModeGrid()) {
        if(!GridCloseMarketOnSignal && !Common::OrderIsPending(posType)) { return false; }
        if(!GridClosePendingOnSignal && Common::OrderIsPending(posType)) { return false; }
    }
    
    string posSymName = getOrderSymbol(isPosition);
    
    // todo: grid - how to close pendings when encountering an opposite signal?
    bool checkExit = false, exitIsEmpty = false;
    SignalUnit *exitCheckUnit = MainDataMan.symbol[symIdx].getSymbolSignalUnit(false);
    checkExit = !Common::IsInvalidPointer(exitCheckUnit) && !exitCheckUnit.fulfilled; // todo: how is this affected by retrace?
    if(checkExit) { exitIsEmpty = exitCheckUnit.type != SignalLong && exitCheckUnit.type != SignalShort && exitCheckUnit.type != SignalClose; }
    
    if(!checkExit && !CloseOrderOnOppositeSignal && !isTradeModeGrid()) { return false; }
    
    bool checkEntry = false, entryIsEmpty = false;
    SignalUnit *entryCheckUnit = NULL;
    if(CloseOrderOnOppositeSignal/* || isTradeModeGrid()*/) {
        entryCheckUnit = MainDataMan.symbol[symIdx].getSymbolSignalUnit(true);
        checkEntry = !Common::IsInvalidPointer(entryCheckUnit) && !entryCheckUnit.fulfilled;
        if(checkEntry) { entryIsEmpty = entryCheckUnit.type != SignalLong && entryCheckUnit.type != SignalShort && entryCheckUnit.type != SignalClose; }
    }
    
    if(!checkExit && !checkEntry) { return false; }
    if(exitIsEmpty && entryIsEmpty) { return false; }
    
    bool entryIsTrigger = false,exitIsTrigger = false;
//    if(isTradeModeGrid() && Common::OrderIsPending(posType)) { // market orders follow same rules as non-grid
//        if(checkExit && !exitIsEmpty) {
//            if(gridSetLong[symIdx] && exitCheckUnit.type == SignalLong) { return false; } // signals are negated for exits -- "SignalLong" means Buy OK, close Shorts.
//            else if(Common::OrderIsShort(posType) && exitCheckUnit.type == SignalShort) { return false; }
//            else { exitIsTrigger = true; }
//        }
//        
//        if(!exitIsTrigger && checkEntry && !entryIsEmpty) {
//            if(Common::OrderIsLong(posType) && entryCheckUnit.type == SignalLong) { return false; }
//            else if(Common::OrderIsShort(posType) && entryCheckUnit.type == SignalShort) { return false; }
//            else { entryIsTrigger = true; }
//        }
//    } else {
        if(checkExit && !exitIsEmpty) {
            if(Common::OrderIsLong(posType) && exitCheckUnit.type == SignalLong) { return false; } // signals are negated for exits -- "SignalLong" means Buy OK, close Shorts.
            else if(Common::OrderIsShort(posType) && exitCheckUnit.type == SignalShort) { return false; }
            else { exitIsTrigger = true; }
        }
        
        if(!exitIsTrigger && checkEntry && !entryIsEmpty) {
            if(Common::OrderIsLong(posType) && entryCheckUnit.type == SignalLong) { return false; }
            else if(Common::OrderIsShort(posType) && entryCheckUnit.type == SignalShort) { return false; }
            else { entryIsTrigger = true; }
        }
    //}
    
    if(!exitIsTrigger && !entryIsTrigger) { return false; }
    
    // todo: retracement protection?
    
    bool result = sendClose(ticket, symIdx, isPosition);
    if(result) {
        Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": " + (exitIsTrigger ? "Exit signal - " + EnumToString(exitCheckUnit.type) : entryIsTrigger ? "Entry signal - " + EnumToString(entryCheckUnit.type) : "No trigger"), true);
        MainAlertMan.alertByTradeAction(symIdx, false);

        if(!isTradeModeGrid()) { 
            if(exitIsTrigger) { Common::ArrayPush(exitSignalsToFulfill, exitCheckUnit); } // fulfill after exit cycle is done // do not set opposite entry fulfilled; that's set by entry action
        } else {
            gridExitBySignal[symIdx] = exitIsTrigger;
            gridExitByOpposite[symIdx] = entryIsTrigger;
        }
    }
    return result;
}

bool OrderManager::checkDoExitByDistance(long ticket, int symIdx, double distancePips, bool byGrid, bool isPosition) {
    if(distancePips == 0) { return false; }
    if(!isExitSafe(symIdx)) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double currentDistance = 0;
    if(!getDistanceFromOpen(ticket, symIdx, currentDistance, byGrid, isPosition)) { return false; }
    
    bool isLong = byGrid ? isGridOrderTypeLong(getOrderType(isPosition)) : Common::OrderIsLong(getOrderType(isPosition));
    
    bool distanceCrossed = distancePips < 0 ? currentDistance <= distancePips : currentDistance >= distancePips;
    
    bool result = false;
    if(distanceCrossed) {
        result = sendClose(ticket, symIdx, isPosition);
        if(result) {
            int digits = SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_DIGITS);
            Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Distance " + DoubleToString(currentDistance, BrokerPipDecimal) + "/" + DoubleToString(distancePips, BrokerPipDecimal), true);
        }
    }
    
    return result;
}

bool OrderManager::getDistanceFromOpen(long ticket, int symIdx, double &distanceOut, bool byGrid, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    bool isLong = byGrid ? isGridOrderTypeLong(getOrderType(isPosition)) : Common::OrderIsLong(getOrderType(isPosition));
    
    double currentPrice =
        isLong ? 
            SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
            : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
        
    distanceOut = PriceToPips(MainSymbolMan.symbols[symIdx].name
        , isLong ? currentPrice - getOrderOpenPrice(isPosition) : getOrderOpenPrice(isPosition) - currentPrice
        );
        
    return true;
}

int OrderManager::forceExit() {
    int result = 0;
    int size = ArraySize(MainSymbolMan.symbols);
    int symIdxList[];
    ArrayResize(symIdxList, size);
    for(int i = 0; i < size; i++) {
        symIdxList[i] = i;
    }
    return forceExit(symIdxList);
}

int OrderManager::forceExit(int &symIdxList[]) {
    int result = 0;
    
#ifdef __MQL4__
    result += forceExit(symIdxList, false);
#else
#ifdef __MQL5__
    result += forceExit(symIdxList, true);
    result += forceExit(symIdxList, false);
#endif
#endif

    return result;
}

int OrderManager::forceExit(int &symIdxList[], bool isPosition) {
    int result = 0;
    
    for(int i = 0; i < getOrdersTotal(isPosition); i++) {
        getOrderSelect(i, SELECT_BY_POS, MODE_TRADES, isPosition);
        
        if(getOrderMagicNumber(isPosition) != MagicNumber) { 
            continue; 
        }
        string symbolName = getOrderSymbol(isPosition);
        int symIdx = MainSymbolMan.getSymbolId(symbolName);
        if(symIdx < 0 || Common::ArrayFind(symIdxList, symIdx) < 0) { continue; }
        
        long ticket = getOrderTicket(isPosition); // in mql5 returns long, for native ulong ticket use OrderGetTicket(i)
        double profit = getProfitPips(ticket, isPosition);
        int type = getOrderType(isPosition);
        
        if(forceExit(ticket, symIdx, isPosition)) {
            result++;
            i--; // decrement because getOrdersTotal doesn't update
        }
    }
    
    return result;
}

bool OrderManager::forceExit(long ticket, int symIdx, bool isPosition) {
    if(!isExitSafe(symIdx)) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    bool result = sendClose(ticket, symIdx, isPosition);
    if(result) {
        Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Forced exit", true);
        MainAlertMan.alertByTradeAction(symIdx, false);

        if(!isTradeModeGrid()) {
            // HANDLE SIGNAL FULFILLMENT HERE
        } else {
            gridExitBySignal[symIdx] = true;
            gridExitByOpposite[symIdx] = false;
        }
    }
    return result;
}