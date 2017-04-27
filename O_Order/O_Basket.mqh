//+------------------------------------------------------------------+
//|                                                 MMT_Schedule.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "../D_Data/D_Data.mqh"
#include "../S_Symbol.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "O_Defines.mqh"

//+------------------------------------------------------------------+

bool OrderManager::checkBasketSafe() {
    bool masterSafe = (basketLosses < MathMax(1, BasketMaxLosingPerDay) && basketWins < MathMax(1, BasketMaxWinningPerDay));
    
    return masterSafe;
}

void OrderManager::checkDoBasketExit() {
    checkDoBasketMasterExit();
    checkDoBasketSymbolExit();
}

void OrderManager::checkDoBasketMasterExit() {
    bool close = false;
    if(BasketMasterStopLossMode != BasketStopDisable && (basketProfit+basketBookedProfit) <= basketMasterStopLoss) {
        Error::PrintInfo("Close Basket: Stop Loss - " + (basketProfit + basketBookedProfit) + " pips | Setting: " + basketMasterStopLoss, true);
        close = true;
        basketLosses++;
    }
    
    if(BasketMasterTakeProfitMode != BasketStopDisable && (basketProfit+basketBookedProfit) >= basketMasterTakeProfit) {
        Error::PrintInfo("Close Basket: Take Profit - " + (basketProfit + basketBookedProfit) + " pips | Setting: " + basketMasterTakeProfit, true);
        close = true;
        basketWins++;
    }
    
    if(close) {
#ifdef __MQL4__
        sendBasketClose(false);
#else
#ifdef __MQL5__
        sendBasketClose(true);
        sendBasketClose(false);
#endif
#endif
    }
}

void OrderManager::checkDoBasketSymbolExit() {
    if(!BasketSymbolEnableStopLoss && BasketSymbolEnableTakeProfit) { return; }

    int symCount = ArraySize(MainSymbolMan.symbols);
    
    for(int i = 0; i < symCount; i++) {
        checkDoBasketSymbolExit(i);
    }
}

void OrderManager::checkDoBasketSymbolExit(int symIdx) {
    bool close = false;
    if(BasketSymbolEnableStopLoss && (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]) <= basketSymbolStopLoss[symIdx]) {
        Error::PrintInfo(MainSymbolMan.symbols[symIdx].name + "Close Basket: Stop Loss - " + (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]) + " pips | Setting: " + basketSymbolStopLoss[symIdx], true);
        close = true;
        basketSymbolLosses[symIdx]++;
    }
    
    if(BasketSymbolEnableTakeProfit && (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]) >= basketSymbolTakeProfit[symIdx]) {
        Error::PrintInfo(MainSymbolMan.symbols[symIdx].name + "Close Basket: Take Profit - " + (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]) + " pips | Setting: " + basketSymbolTakeProfit[symIdx], true);
        close = true;
        basketSymbolWins[symIdx]++;
    }
    
    if(close) {
#ifdef __MQL4__
        sendBasketClose(symIdx, false);
#else
#ifdef __MQL5__
        sendBasketClose(symIdx, true);
        sendBasketClose(symIdx, false);
#endif
#endif
    }
}

void OrderManager::sendBasketClose(bool isPosition) {
    sendBasketClose(-1, isPosition);
}

void OrderManager::sendBasketClose(int symIdx, bool isPosition) {
    for(int i = 0; i < getOrdersTotal(isPosition); i++) {
        getOrderSelect(i, SELECT_BY_POS, MODE_TRADES, isPosition);
        if(getOrderMagicNumber(isPosition) != MagicNumber) { 
            continue; 
        }
        
        if(symIdx >= 0 && MainSymbolMan.symbols[symIdx].name != getOrderSymbol(isPosition)) { continue; }
        
        long ticket = getOrderTicket(isPosition);
        int symIdx = MainSymbolMan.getSymbolId(getOrderSymbol(isPosition));
        long orderType = getOrderType(isPosition);
        bool exitResult = false;
        
        if(BasketClosePendings || !Common::OrderIsPending(getOrderType(isPosition))) {
            Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Basket", true);
            exitResult = sendClose(ticket, symIdx, isPosition);
        }
        
        if(exitResult) {
            i--; // deleting a position mid-loop changes the index, attempt same index as orders shift
            addOrderToOpenCount(symIdx, orderType, true); // subtract
        }
    }
}

//+------------------------------------------------------------------+

void OrderManager::fillBasketFlags() {
    basketProfit = 0;
    basketLongProfit = 0;
    basketShortProfit = 0;
    ArrayInitialize(basketProfitSymbol, 0);
    ArrayInitialize(basketLongProfitSymbol, 0);
    ArrayInitialize(basketShortProfitSymbol, 0);
    ArrayInitialize(basketSymbolClose, false);
    if(!BasketTotalPerDay || basketDay != DayOfWeek()) { basketBookedProfit = 0; } // basketDay != DayOfWeek() is done in checkDoBasketExit()
    if(basketDay != DayOfWeek()) { // todo: basket - period length: hours? days? weeks?
        basketLosses = 0;
        basketWins = 0;
        basketDay = DayOfWeek();
        ArrayInitialize(basketSymbolWins, 0);
        ArrayInitialize(basketSymbolLosses, 0);
    }
}

//+------------------------------------------------------------------+

double OrderManager::getProfitPips(int ticket, bool isPosition) {
    double profit = 0;
    getProfitPips(ticket, isPosition, profit);
    return profit;
}

bool OrderManager::getProfitPips(int ticket, bool isPosition, double &profitOut) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    if(Common::OrderIsPending(getOrderType(isPosition))) { return false; }
    
    profitOut = getProfitPips(getOrderOpenPrice(isPosition), getOrderType(isPosition), getOrderSymbol(isPosition));
    return true;
    // todo: approximate commission and swap in pips?
}

double OrderManager::getProfitPips(double openPrice, int opType, string symName) {
    bool isBuy = Common::OrderIsLong(opType);
    double curPrice = isBuy ? SymbolInfoDouble(symName, SYMBOL_BID) : SymbolInfoDouble(symName, SYMBOL_ASK);
    double diff = isBuy ? curPrice - openPrice : openPrice - curPrice;
    return PriceToPips(symName, diff);
    
    // todo: approximate commission and swap in pips?
}

//+------------------------------------------------------------------+

void OrderManager::updateBasketStopLevels() {
    updateBasketSymbolStopLevels();
    updateBasketMasterStopLevels();
}

void OrderManager::updateBasketMasterStopLevels() {
    updateBasketMasterStopLevel(true);
    updateBasketMasterStopLevel(false);
}

void OrderManager::updateBasketMasterStopLevel(bool isStopLoss) {
    BasketStopMode stopMode = isStopLoss ? BasketMasterStopLossMode : BasketMasterTakeProfitMode;
    double level = 0;
    bool sumAllSymbols = false;
    
    switch(stopMode) {
        case BasketStopExactValue: level = isStopLoss ? BasketStopLossValue : BasketTakeProfitValue; break;
        case BasketStopSumAllSymbols: 
            sumAllSymbols = true;
        case BasketStopSumActiveSymbols: {
            int symCount = ArraySize(MainSymbolMan.symbols);
    
            for(int i = 0; i < symCount; i++) { // todo: detect skipping loop when no updates?
                if(!sumAllSymbols && openMarketLongCount[i] + openMarketShortCount[i] <= 0) { continue; }
                
                level += isStopLoss ? basketSymbolStopLoss[i] : basketSymbolTakeProfit[i]; // todo: rules for moving stops?
            }
            
            level *= isStopLoss ? BasketStopLossFactor : BasketTakeProfitFactor;
            break;
        }
        case BasketStopDisable: 
        default: 
            level = 0; break;
    }
    
    if(isStopLoss) { basketMasterStopLoss = level; }
    else { basketMasterTakeProfit = level; }
}

void OrderManager::updateBasketSymbolStopLevels() {
    int symCount = ArraySize(MainSymbolMan.symbols);
    
    for(int i = 0; i < symCount; i++) {
        updateBasketSymbolStopLevel(i, true);
        updateBasketSymbolStopLevel(i, false);
    }
}

void OrderManager::updateBasketSymbolStopLevel(int symIdx, bool isStopLoss) {
    double stopLevel = 0;
    if(isStopLoss) {
        if(openMarketLongCount[symIdx] + openMarketShortCount[symIdx] > 0) {
            if(basketSymbolStopLoss[symIdx] == 0) {
                if(getBasketSymbolInitialStopLevel(symIdx, isStopLoss, stopLevel)) {
                    basketSymbolStopLoss[symIdx] = stopLevel;
                }
            }
        } else { basketSymbolStopLoss[symIdx] = 0; }
        
        // should default stop level be updated every cycle? (e.g., changing ATR)
    } else {
        if(openMarketLongCount[symIdx] + openMarketShortCount[symIdx] > 0) {
            if(basketSymbolTakeProfit[symIdx] == 0) {
                if(getBasketSymbolInitialStopLevel(symIdx, isStopLoss, stopLevel)) {
                    basketSymbolTakeProfit[symIdx] = stopLevel;
                }
            }
        } else { basketSymbolTakeProfit[symIdx] = 0; }
        
        // should default stop level be updated every cycle? (e.g., changing ATR)
    }
}

bool OrderManager::getBasketSymbolInitialStopLevel(int symIdx, bool isStopLoss, double &stopLevelOut) {
    double stopLevel = 0;
    if(isStopLoss) {
        if(getValue(stopLevel, basketSymbolStopLossLoc, symIdx)) {
            stopLevelOut = stopLevel;
            return true;
        }
    } else {
        if(getValue(stopLevel, basketSymbolTakeProfitLoc, symIdx)) {
            stopLevelOut = stopLevel;
            return true;
        }
    }
    
    return false;
}