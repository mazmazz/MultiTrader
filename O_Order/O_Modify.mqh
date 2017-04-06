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

void OrderManager::doModifyPosition(int ticket, int symIdx, bool isPosition) {
    // For each setting (sltp, etc) retrieve filter value and update if necessary
    if(!TradeValueEnabled) { return; }
    if(!getLastTimeElapsed(symIdx, false, TimeSettingUnit, ValueBetweenDelay)) { return; }
    if(!checkDoSelect(ticket, isPosition)) { return; }
    
    double stopLevel = 0;
    double profitLevel = 0;
    unOffsetTakeProfitFromOrder(ticket, getOrderSymbol(isPosition), profitLevel, isPosition);
    if(getModifiedStopLevel(ticket, symIdx, stopLevel, isPosition) 
        && stopLevel != 0 
        && (profitLevel == 0 || (Common::OrderIsLong(getOrderType(isPosition)) ? stopLevel < profitLevel : stopLevel > profitLevel))
    ) { // todo: compare to SL
        offsetStopLoss(Common::OrderIsShort(getOrderType(isPosition)), getOrderSymbol(isPosition), stopLevel);
        sendModify(ticket, getOrderOpenPrice(isPosition), stopLevel, getOrderTakeProfit(isPosition), getOrderExpiration(isPosition), isPosition);
    } else if(getOrderStopLoss(isPosition) == 0 && getOrderTakeProfit(isPosition) == 0 && !Common::OrderIsPending(getOrderType(isPosition))
        && getInitialStopLevels(Common::OrderIsLong(getOrderType(isPosition)), symIdx, stopLevel, profitLevel)
        && (stopLevel != 0 || profitLevel != 0)
    ) {
        offsetStopLevels(Common::OrderIsShort(getOrderType(isPosition)), getOrderSymbol(isPosition), stopLevel, profitLevel);
        sendModify(ticket, getOrderOpenPrice(isPosition), stopLevel, profitLevel, getOrderExpiration(isPosition), isPosition);
    }
    
    setLastTimePoint(symIdx, false);
}
