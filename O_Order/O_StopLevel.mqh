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

bool OrderManager::getInitialStopLevels(bool isLong, int symIdx, double &stoplossOut, double &takeprofitOut) {
    bool finalResult = false;
    
    double oppPrice = 0; // , posPrice;
    if(isLong) {
        //posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
        oppPrice = SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID); 
    } else { 
        //posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
        oppPrice = SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK); 
    } 
    
    if(StopLossEnabled) {
        double stoplossOffset = 0;
        if(!getValuePrice(stoplossOffset, stopLossLoc, symIdx)) { return false; }
        stoplossOut = stoplossOffset == 0 ? 0
            : isLong ? oppPrice + stoplossOffset : oppPrice - stoplossOffset
            ;
        finalResult = true; //stoplossOut != 0; // in the old code, we still considered level 0 as true, do the same here
    }
    
    if(TakeProfitEnabled) {
        double takeprofitOffset = 0;
        if(!getValuePrice(takeprofitOffset, takeProfitLoc, symIdx)) { return false; }
        takeprofitOut = takeprofitOffset == 0 ? 0
            : isLong ? oppPrice + takeprofitOffset : oppPrice - takeprofitOffset
            ;
        finalResult = true; //finalResult ? finalResult : takeprofitOut != 0;
    }
    
    return finalResult;
}

bool OrderManager::checkDoExitStopLevels(int ticket, int symIdx, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    if(Common::OrderIsPending(getOrderType(isPosition))) { return false; }
    
    double stoploss = 0, takeprofit = 0;
    if(!unOffsetStopLevelsFromOrder(ticket, MainSymbolMan.symbols[symIdx].name, stoploss, takeprofit, isPosition)) { return false; }
    
    double priceCompare = 0; bool trigger = false;
    if(Common::OrderIsLong(getOrderType(isPosition))) { 
        priceCompare = SymbolInfoDouble(getOrderSymbol(isPosition), SYMBOL_BID); 
        trigger = ((StopLossInternal && stoploss != 0 && (priceCompare <= stoploss)) || (TakeProfitInternal && takeprofit != 0 && (priceCompare >= takeprofit)));
    }
    else { 
        priceCompare = SymbolInfoDouble(getOrderSymbol(isPosition), SYMBOL_ASK); 
        trigger = ((StopLossInternal && stoploss != 0 && (priceCompare >= stoploss)) || (TakeProfitInternal && takeprofit != 0 &&  (priceCompare <= takeprofit)));
    }
    
    if(trigger) {
        Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Internal stop level", NULL, "Internal SL: " + stoploss + " | Internal TP: " + takeprofit, true);
        return sendClose(ticket, symIdx, isPosition);
    } else { return false; }
}

//+------------------------------------------------------------------+

bool OrderManager::getModifiedStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double level = 0;
    
    if(!getJumpingStopLevel(ticket, symIdx, level, isPosition)) {
        if(!getTrailingStopLevel(ticket, symIdx, level, isPosition)) {
            if(!getBreakEvenStopLevel(ticket, symIdx, level, isPosition)) {
                return false;
            }
        }
    }
    
    stopLevelOut = level;

    return true;
}

bool OrderManager::getTrailingStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition) {
    // level = oppositePrice - stopOffset
    // set only if level > currentStopLoss
    if(!TrailingStopEnabled) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double oppositePrice = Common::OrderIsLong(getOrderType(isPosition)) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
        
    if(TrailAfterBreakEvenOnly && BreakEvenEnabled && !isBreakEvenPassed(ticket, symIdx, isPosition)) { return false; }
        
    double stopOffsetPrice = 0; 
    if(!getValuePrice(stopOffsetPrice, trailingStopLoc, symIdx) || stopOffsetPrice == 0) { return false; }
    
    double level = Common::OrderIsLong(getOrderType(isPosition)) ? oppositePrice + stopOffsetPrice : oppositePrice - stopOffsetPrice;
    
    if(isStopLossProgressed(ticket, level, isPosition)) {
        stopLevelOut = level;
        return true;
    } else { return false; }
}

bool OrderManager::getJumpingStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition) {
    // level = MathFloor(oppositePrice-openingPrice/jumpDistance)
    // check if jumping stop level exceeds breakeven enabled
    if(!JumpingStopEnabled) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double openingPrice = getOrderOpenPrice(isPosition);
    double oppositePrice = Common::OrderIsLong(getOrderType(isPosition)) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
    double priceDiff = Common::OrderIsLong(getOrderType(isPosition)) ? oppositePrice - openingPrice : openingPrice - oppositePrice;
    
    if(JumpAfterBreakEvenOnly && BreakEvenEnabled && !isBreakEvenPassed(ticket, symIdx, isPosition)) { return false; }
    
    double jumpingDistancePrice = 0;
    if(!getValuePrice(jumpingDistancePrice, jumpingStopLoc, symIdx) || jumpingDistancePrice == 0) { return false; }
    
    double jumpStopOffset = jumpingDistancePrice*(MathFloor(priceDiff/jumpingDistancePrice)-1);
    
    double level = Common::OrderIsLong(getOrderType(isPosition)) ? openingPrice + jumpStopOffset : openingPrice - jumpStopOffset;
    if(isStopLossProgressed(ticket, level, isPosition)) {
        stopLevelOut = level;
        return true;
    } else { return false; }
}

bool OrderManager::getBreakEvenStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition) {
    if(!BreakEvenEnabled) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double openingPrice = getOrderOpenPrice(isPosition);
    double oppositePrice = Common::OrderIsLong(getOrderType(isPosition)) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
    double breakEvenProfitPrice = PipsToPrice(MainSymbolMan.symbols[symIdx].name, BreakEvenProfit);
    
    if(isBreakEvenPassed(ticket, symIdx, isPosition)) { // if we make breakEvenProfitPrice into a Loc, check if it == 0, then return false
        double newStopLevel = Common::OrderIsLong(getOrderType(isPosition)) ? openingPrice + breakEvenProfitPrice : openingPrice - breakEvenProfitPrice; // todo: what about spread???
        if(isStopLossProgressed(ticket, newStopLevel, isPosition)) {
            stopLevelOut = newStopLevel;
            return true;
        }
    }
    
    return false;
}

bool OrderManager::isBreakEvenPassed(int ticket, int symIdx, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }

    double openingPrice = getOrderOpenPrice(isPosition);
    double oppositePrice = Common::OrderIsLong(getOrderType(isPosition)) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
    double breakEvenJumpDistancePrice = 0;
    if(!getValuePrice(breakEvenJumpDistancePrice, breakEvenJumpDistanceLoc, symIdx) || breakEvenJumpDistancePrice == 0) { return false; }
    
    double breakEvenJumpDiff = Common::OrderIsLong(getOrderType(isPosition)) ? oppositePrice - openingPrice : openingPrice - oppositePrice;
    return breakEvenJumpDiff >= breakEvenJumpDistancePrice;
}

bool OrderManager::isStopLossProgressed(int ticket, double newStopLoss, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    if(newStopLoss == 0) { return false; }
    
    if(getOrderStopLoss(isPosition) == 0 && newStopLoss != 0) { return true; } // assume we want to set a modified stop loss when no SL was previously set
    
    double currentStopLoss = 0;
    if(!unOffsetStopLossFromOrder(getOrderTicket(isPosition), getOrderSymbol(isPosition), currentStopLoss, isPosition)) { return false; }
    
    if(Common::OrderIsLong(getOrderType(isPosition))) {
        return newStopLoss > currentStopLoss;
    } else {
        return newStopLoss < currentStopLoss;
    }
}

//+------------------------------------------------------------------+
    
bool OrderManager::unOffsetStopLevelsFromOrder(int ticket, string symName, double &stoplossOut, double &takeprofitOut, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    stoplossOut = getOrderStopLoss(isPosition);
    takeprofitOut = getOrderTakeProfit(isPosition);
    
    double slOffset = StopLossBrokerOffset, tpOffset = TakeProfitBrokerOffset;
    if(Common::OrderIsShort(getOrderType(isPosition))) {
        slOffset = slOffset*-1;
        tpOffset = tpOffset*-1;
    }
    
    if(stoplossOut != 0 && slOffset != 0 && StopLossInternal) { 
        stoplossOut = unOffsetValue(getOrderStopLoss(isPosition), slOffset, symName); 
    }
    
    if(takeprofitOut != 0 && tpOffset != 0 && TakeProfitInternal) {
        takeprofitOut = unOffsetValue(getOrderTakeProfit(isPosition), tpOffset, symName); 
    }
    
    return true;
}

bool OrderManager::unOffsetStopLossFromOrder(int ticket, string symName, double &stoplossOut, bool isPosition) {
    double takeProfit = 0;
    return unOffsetStopLevelsFromOrder(ticket, symName, stoplossOut, takeProfit, isPosition);
}

bool OrderManager::unOffsetTakeProfitFromOrder(int ticket, string symName, double &takeprofitOut, bool isPosition) {
    double stopLoss = 0;
    return unOffsetStopLevelsFromOrder(ticket, symName, stopLoss, takeprofitOut, isPosition);
}

void OrderManager::offsetStopLevels(bool isShort, string symName, double &stoploss, double &takeprofit) {
    double slOffset = StopLossBrokerOffset, tpOffset = TakeProfitBrokerOffset;
    if(isShort) {
        slOffset = slOffset*-1;
        tpOffset = tpOffset*-1;
    }

    if(stoploss != 0 && slOffset != 0 && StopLossInternal) { 
        stoploss = offsetValue(stoploss, slOffset, symName); 
    }
    
    if(takeprofit != 0 && tpOffset != 0 && TakeProfitInternal) { 
        takeprofit = offsetValue(takeprofit, tpOffset, symName); 
    }
}

void OrderManager::offsetStopLoss(bool isShort,string symName,double &stoploss) {
    double takeprofit = 0;
    offsetStopLevels(isShort, symName, stoploss, takeprofit);
}

void OrderManager::offsetTakeProfit(bool isShort,string symName,double &takeprofit) {
    double stoploss = 0;
    offsetStopLevels(isShort, symName, stoploss, takeprofit);
}
