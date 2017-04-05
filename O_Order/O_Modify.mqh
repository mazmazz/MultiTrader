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

void OrderManager::doModifyPosition(int ticket, int symIdx) {
    // For each setting (sltp, etc) retrieve filter value and update if necessary
    if(!TradeValueEnabled) { return; }
    if(!getLastTimeElapsed(symIdx, false, TimeSettingUnit, ValueBetweenDelay)) { return; }
    if(!checkDoSelectOrder(ticket)) { return; }
    
    double stopLevel;
    double profitLevel;
    unOffsetTakeProfitFromOrder(ticket, OrderSymbol(cycleIsOrder), profitLevel);
    if(getModifiedStopLevel(ticket, symIdx, stopLevel) 
        && stopLevel != 0 
        && (profitLevel == 0 || (Common::OrderIsLong(OrderType(cycleIsOrder)) ? stopLevel < profitLevel : stopLevel > profitLevel))
    ) { // todo: compare to SL
        offsetStopLoss(Common::OrderIsShort(OrderType(cycleIsOrder)), OrderSymbol(cycleIsOrder), stopLevel);
        sendModify(ticket, OrderOpenPrice(cycleIsOrder), stopLevel, OrderTakeProfit(cycleIsOrder), OrderExpiration(cycleIsOrder));
    } else if(OrderStopLoss(cycleIsOrder) == 0 && OrderTakeProfit(cycleIsOrder) == 0 && !Common::OrderIsPending(OrderType(cycleIsOrder))
        && getInitialStopLevels(Common::OrderIsLong(OrderType(cycleIsOrder)), symIdx, stopLevel, profitLevel)
        && (stopLevel != 0 || profitLevel != 0)
    ) {
        offsetStopLevels(Common::OrderIsShort(OrderType(cycleIsOrder)), OrderSymbol(cycleIsOrder), stopLevel, profitLevel);
        sendModify(ticket, OrderOpenPrice(cycleIsOrder), stopLevel, profitLevel, OrderExpiration(cycleIsOrder));
    }
    
    setLastTimePoint(symIdx, false);
}
