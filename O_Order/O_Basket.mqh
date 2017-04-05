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
    
    if(BasketEnableStopLoss && (basketProfit+basketBookedProfit) <= BasketStopLossValue) {
        sendBasketClose();
        basketLosses++;
    }
    
    if(BasketEnableTakeProfit && (basketProfit+basketBookedProfit) >= BasketTakeProfitValue) {
        sendBasketClose();
        basketWins++;
    }
}

void OrderManager::sendBasketClose() {
    for(int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderMagicNumber() != MagicNumber) { 
            continue; 
        }
        
        bool exitResult;
        
        if(BasketClosePendings || !Common::OrderIsPending(OrderType())) {
            exitResult = sendClose(OrderTicket(), MainSymbolMan.getSymbolId(OrderSymbol()));
        }
        
        if(exitResult) {
            i--; // deleting a position mid-loop changes the index, attempt same index as orders shift
        }
    }
}

//+------------------------------------------------------------------+

void OrderManager::fillBasketFlags() {
    basketProfit = 0;
    if(!BasketTotalPerDay || basketDay != DayOfWeek()) { basketBookedProfit = 0; } // basketDay != DayOfWeek() is done in checkDoBasketExit()
    if(basketDay != DayOfWeek()) { // todo: basket - period length: hours? days? weeks?
        basketLosses = 0;
        basketWins = 0;
        basketDay = DayOfWeek();
    }
}

//+------------------------------------------------------------------+

double OrderManager::getProfitPips(int ticket) {
    double profit;
    getProfitPips(ticket, profit);
    return profit;
}

double OrderManager::getProfitPips(double openPrice, int opType, string symName) {
    bool isBuy = Common::OrderIsLong(opType);
    double curPrice = isBuy ? SymbolInfoDouble(symName, SYMBOL_BID) : SymbolInfoDouble(symName, SYMBOL_ASK);
    double diff = isBuy ? curPrice - openPrice : openPrice - curPrice;
    return PriceToPips(symName, diff);
    
    // todo: approximate commission and swap in pips?
}

bool OrderManager::getProfitPips(int ticket, double &profitOut) {
    if(!checkDoSelectOrder(ticket)) { return false; }
    if(Common::OrderIsPending(ticket)) { return false; }
    
    profitOut = getProfitPips(OrderOpenPrice(), OrderType(), OrderSymbol());
    return true;
    // todo: approximate commission and swap in pips?
}
