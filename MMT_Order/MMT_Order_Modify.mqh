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
    double profitLevel;
    unOffsetTakeProfitFromOrder(ticket, OrderSymbol(), profitLevel);
    if(getModifiedStopLevel(ticket, symIdx, stopLevel) 
        && stopLevel != 0 
        && (profitLevel == 0 || (Common::OrderIsLong(OrderType()) ? stopLevel < profitLevel : stopLevel > profitLevel))
    ) { // todo: compare to SL
        offsetStopLoss(Common::OrderIsShort(OrderType()), OrderSymbol(), stopLevel);
        sendModifyOrder(ticket, OrderOpenPrice(), stopLevel, OrderTakeProfit(), OrderExpiration());
    } // todo: if SLTP is 0 and SL/TP are enabled, set the initial SL/TP
        // todo: moving SLTP depending on spread offset
    
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
