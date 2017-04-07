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
    return (basketLosses < MathMax(1, BasketMaxLosingPerDay) && basketWins < MathMax(1, BasketMaxWinningPerDay));
}

void OrderManager::checkDoBasketExit() {
    if(!BasketEnableStopLoss && !BasketEnableTakeProfit) { return; }
    
    //Error::PrintMinor("BASKET | Current: " + basketProfit + " | Booked: " + basketBookedProfit + " | Total: " + (basketProfit + basketBookedProfit) + " | SL: " + BasketStopLossValue + " | TP: " + BasketTakeProfitValue, NULL, NULL, true);
    
    if(BasketEnableStopLoss && (basketProfit+basketBookedProfit) <= BasketStopLossValue) {
        Error::PrintInfo("Basket Stop Loss Hit: " + (basketProfit + basketBookedProfit) + " pips | Setting: " + BasketStopLossValue, NULL, NULL, true);
#ifdef __MQL4__
        sendBasketClose(false);
#else
#ifdef __MQL5__
        sendBasketClose(true);
        sendBasketClose(false);
#endif
#endif
        basketLosses++;
    }
    
    if(BasketEnableTakeProfit && (basketProfit+basketBookedProfit) >= BasketTakeProfitValue) {
        Error::PrintInfo("Basket Take Profit Hit: " + (basketProfit + basketBookedProfit) + " pips | Setting: " + BasketTakeProfitValue, NULL, NULL, true);
#ifdef __MQL4__
        sendBasketClose(false);
#else
#ifdef __MQL5__
        sendBasketClose(true);
        sendBasketClose(false);
#endif
#endif
        basketWins++;
    }
}

void OrderManager::sendBasketClose(bool isPosition) {
    for(int i = 0; i < getOrdersTotal(isPosition); i++) {
        getOrderSelect(i, SELECT_BY_POS, MODE_TRADES, isPosition);
        if(getOrderMagicNumber(isPosition) != MagicNumber) { 
            continue; 
        }
        
        bool exitResult = false;
        
        if(BasketClosePendings || !Common::OrderIsPending(getOrderType(isPosition))) {
            exitResult = sendClose(getOrderTicket(isPosition), MainSymbolMan.getSymbolId(getOrderSymbol(isPosition)), isPosition);
        }
        
        if(exitResult) {
            i--; // deleting a position mid-loop changes the index, attempt same index as orders shift
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
    if(!BasketTotalPerDay || basketDay != DayOfWeek()) { basketBookedProfit = 0; } // basketDay != DayOfWeek() is done in checkDoBasketExit()
    if(basketDay != DayOfWeek()) { // todo: basket - period length: hours? days? weeks?
        basketLosses = 0;
        basketWins = 0;
        basketDay = DayOfWeek();
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