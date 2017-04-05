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
    doCurrentPositions(firstRun);
#else
#ifdef __MQL5__
    doCurrentPositions(firstRun, true); // todo: order matters? position first, order second?
    doCurrentPositions(firstRun, false);
#endif
#endif
    
    checkDoBasketExit();
    
    int symbolCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symbolCount; i++) {
        if(isTradeModeGrid()) { fillGridExitFlags(i); }
        checkDoEntrySignals(i); // todo: add to openPending/MarketCount? what's the point, since we end the cycle anyway
    }
}

void OrderManager::doCurrentPositions(bool firstRun, bool isOrder = false) {
#ifdef __MQL5__
    cycleIsOrder = isOrder;
#endif

    for(int i = 0; i < OrdersTotal(cycleIsOrder); i++) {
#ifdef __MQL4__
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
#else
#ifdef __MQL5__
        if(isOrder) {
            OrderGetTicket(i);
        } else {
            PositionGetSymbol(i); // testing: does this select just the net position in netting, and multiple positions in hedging?
        }
#endif
#endif

        if(OrderMagicNumber(cycleIsOrder) != MagicNumber) { 
            continue; 
        }
        int symbolIdx = MainSymbolMan.getSymbolId(OrderSymbol(cycleIsOrder));
        int ticket = OrderTicket(cycleIsOrder);
        double profit = getProfitPips(ticket);
        
        if(firstRun) { evaluateFulfilledFromOrder(ticket, symbolIdx); }
        
        bool exitResult;
        exitResult = checkDoExitSchedule(symbolIdx, ticket);
        if(!exitResult) { exitResult = checkDoExitSignals(ticket, symbolIdx); }
        if(!exitResult) { exitResult = checkDoExitStopLevels(ticket, symbolIdx); }
        
        if(!exitResult) {
            basketProfit += profit;
            addOrderToOpenCount(ticket);
            doModifyPosition(ticket, symbolIdx);
        } else {
            basketBookedProfit += profit;
            i--; // deleting a position mid-loop changes the index, attempt same index as orders shift
        }
    }
    
    // grid - set symbol exit signal fulfilled and in doPositions loop so we don't loop an extra time
}

void OrderManager::evaluateFulfilledFromOrder(int ticket, int symbolIdx) {
    if(!checkDoSelectOrder(ticket)) { return; }

    // if signal already exists for open order, raise fulfilled flag so no repeat is opened

    int orderAct = OrderType(cycleIsOrder);
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

void OrderManager::addOrderToOpenCount(int ticket, int symIdx = -1) {
    if(!checkDoSelectOrder(ticket)) { return; }
    if(symIdx < 0) { symIdx = MainSymbolMan.getSymbolId(OrderSymbol(cycleIsOrder)); }
    
    if(Common::OrderIsPending(OrderType(cycleIsOrder))) { openPendingCount[symIdx]++; }
    else { openMarketCount[symIdx]++; }
}
