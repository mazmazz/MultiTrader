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

void OrderManager::doPositions(bool firstRun) {
    fillBasketFlags();
    resetOpenCount();

#ifdef __MQL4__
    doCurrentPositions(firstRun, false);
#else
#ifdef __MQL5__
    doCurrentPositions(firstRun, false); // todo: order matters? position first, order second?
    doCurrentPositions(firstRun, true);
#endif
#endif

    checkDoBasketExit();
    
    int symbolCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symbolCount; i++) {
        if(isTradeModeGrid()) { fillGridExitFlags(i); }
        checkDoEntrySignals(i); // todo: add to openPending/MarketCount? what's the point, since we end the cycle anyway
    }
}

void OrderManager::doCurrentPositions(bool firstRun, bool isPosition) {
//#ifdef __MQL5__
//    cycleIsPosition = isPosition;
//#endif

    for(int i = 0; i < getOrdersTotal(isPosition); i++) {
        getOrderSelect(i, SELECT_BY_POS, MODE_TRADES, isPosition);

        if(getOrderMagicNumber(isPosition) != MagicNumber) { 
            continue; 
        }
        string symbolName = getOrderSymbol(isPosition);
        int symbolIdx = MainSymbolMan.getSymbolId(symbolName);
        if(symbolIdx < 0) { continue; }
        
        int ticket = getOrderTicket(isPosition);
        double profit = getProfitPips(ticket, isPosition);
        
        if(firstRun) { evaluateFulfilledFromOrder(ticket, symbolIdx, isPosition); }
        
        bool exitResult = false;
        exitResult = checkDoExitSchedule(symbolIdx, ticket, isPosition);
        if(!exitResult) { exitResult = checkDoExitSignals(ticket, symbolIdx, isPosition); }
        if(!exitResult) { exitResult = checkDoExitStopLevels(ticket, symbolIdx, isPosition); }
        
        if(!exitResult) {
            basketProfit += profit;
            addOrderToOpenCount(ticket, symbolIdx, isPosition);
            doModifyPosition(ticket, symbolIdx, isPosition);
        } else {
            basketBookedProfit += profit;
            i--; // deleting a position mid-loop changes the index, attempt same index as orders shift
        }
    }
    
    // grid - set symbol exit signal fulfilled and in doPositions loop so we don't loop an extra time
}

void OrderManager::evaluateFulfilledFromOrder(int ticket, int symbolIdx, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return; }

    // if signal already exists for open order, raise fulfilled flag so no repeat is opened

    int orderAct = getOrderType(isPosition);
    SignalUnit *checkEntrySignal = MainDataMan.symbol[symbolIdx].getSignalUnit(true);
    if(!Common::IsInvalidPointer(checkEntrySignal)) {
        if(!isTradeModeGrid()) {
            if(
                (Common::OrderIsLong(orderAct) && checkEntrySignal.type == SignalLong)
                || (Common::OrderIsShort(orderAct) && checkEntrySignal.type == SignalShort)
            ) { checkEntrySignal.fulfilled = true; }
        } else if(checkEntrySignal.type == SignalLong || checkEntrySignal.type == SignalShort) { checkEntrySignal.fulfilled = true; }
            // todo: grid - better firstRun rules. set gridDirection by checking if all buy stops are above current price point, etc. ???
    }
}

void OrderManager::resetOpenCount() {
    ArrayInitialize(openPendingCount, 0);
    ArrayInitialize(openMarketCount, 0);
}

void OrderManager::addOrderToOpenCount(int ticket, int symIdx, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return; }
#ifdef __MQL5__
    if(isPosition && !Common::IsAccountHedging() && ticket != PositionGetInteger(POSITION_IDENTIFIER)) { return; }
#endif
    if(symIdx < 0) { symIdx = MainSymbolMan.getSymbolId(getOrderSymbol(isPosition)); }
    if(symIdx < 0) { return; }
    
    if(Common::OrderIsPending(getOrderType(isPosition))) { openPendingCount[symIdx]++; }
    else { openMarketCount[symIdx]++; }
}