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
    
    double oldSl = getOrderStopLoss(isPosition), oldTp = getOrderTakeProfit(isPosition);
    double stopLevel = 0;
    double profitLevel = 0;
    unOffsetTakeProfitFromOrder(ticket, getOrderSymbol(isPosition), profitLevel, isPosition);
    
    // both getModifiedStopLevel and getInitialStopLevel give price levels
    bool doCancel = false;
    if(getModifiedStopLevel(ticket, symIdx, stopLevel, isPosition) 
        && stopLevel != oldSl
        && (profitLevel == 0 || (Common::OrderIsLong(getOrderType(isPosition)) ? stopLevel < profitLevel : stopLevel > profitLevel))
    ) { 
        sendModify(ticket, getOrderOpenPrice(isPosition), stopLevel, getOrderTakeProfit(isPosition), getOrderExpiration(isPosition), isPosition);
        //Error::PrintInfo("+------------------------------------------------------------------+");
    } else {
        bool attemptSl = oldSl == 0;
        bool attemptTp = oldTp == 0;
        if((attemptSl || attemptTp) 
            && !Common::OrderIsPending(getOrderType(isPosition))
            && getInitialStopLevels(Common::OrderIsLong(getOrderType(isPosition)), symIdx, attemptSl && StopLossInitialEnabled, attemptTp && TakeProfitInitialEnabled, stopLevel, profitLevel, doCancel)
            && !doCancel
            && ((attemptSl && (stopLevel != oldSl && stopLevel != 0)) || (attemptTp && (profitLevel != oldTp && profitLevel != 0)))
        ) { // initial SLTP
            Error::PrintInfo(getOrderSymbol(isPosition) + " #" + ticket + " Initial stop from modify post-open"); 
            sendModify(ticket, getOrderOpenPrice(isPosition), attemptSl ? stopLevel : oldSl, attemptTp ? profitLevel : oldTp, getOrderExpiration(isPosition), isPosition);
            //Error::PrintInfo("+------------------------------------------------------------------+");
        }
    }
    
    setLastTimePoint(symIdx, false);
}
