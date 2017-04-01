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

void OrderManager::doModifyPosition(int ticket, int symIdx) {
    // For each setting (sltp, etc) retrieve filter value and update if necessary
    if(!TradeValueEnabled) { return; }
    if(!getLastTimeElapsed(symIdx, false, TimeSettingUnit, ValueBetweenDelay)) { return; }
    if(!checkDoSelectOrder(ticket)) { return; }
    
    double stopLevel;
    if(getModifiedStopLevel(ticket, symIdx, stopLevel) && stopLevel != 0) {
        sendModifyOrder(ticket, OrderOpenPrice(), stopLevel, OrderTakeProfit(), OrderExpiration());
    }
    
    setLastTimePoint(symIdx, false);
}

bool OrderManager::sendModifyOrder(int ticket, double price, double stoploss, double takeprofit, datetime expiration = 0) {
    bool result;
    
#ifdef _OrderReliable
    result = OrderModifyReliable(ticket, price, stoploss, takeprofit, expiration);
#else
    result = OrderModify(ticket, price, stoploss, takeprofit, expiration);
#endif

    return result;
}