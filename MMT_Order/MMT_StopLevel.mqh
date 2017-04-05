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
#include "../MMT_Data/MMT_Data.mqh"
#include "../MMT_Symbol.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "MMT_Order_Defines.mqh"

bool OrderManager::getInitialStopLevels(bool isLong, int symIdx, double &stoplossOut, double &takeprofitOut) {
    bool finalResult;
    
    double oppPrice; // , posPrice;
    if(isLong) {
        //posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
        oppPrice = SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID); 
    } else { 
        //posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
        oppPrice = SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK); 
    } 
    
    double stoploss, takeprofit;
    if(StopLossEnabled) {
        double stoplossOffset;
        if(!getValuePrice(stoplossOffset, stopLossLoc, symIdx)) { return false; }
        stoplossOut = stoplossOffset == 0 ? 0
            : isLong ? oppPrice + stoplossOffset : oppPrice - stoplossOffset
            ;
        finalResult = true; //stoplossOut != 0; // in the old code, we still considered level 0 as true, do the same here
    }
    
    if(TakeProfitEnabled) {
        double takeprofitOffset;
        if(!getValuePrice(takeprofitOffset, takeProfitLoc, symIdx)) { return false; }
        takeprofitOut = takeprofitOffset == 0 ? 0
            : isLong ? oppPrice + takeprofitOffset : oppPrice - takeprofitOffset
            ;
        finalResult = true; //finalResult ? finalResult : takeprofitOut != 0;
    }
    
    return finalResult;
}

bool OrderManager::checkDoExitStopLevels(int ticket, int symIdx) {
    if(!checkDoSelectOrder(ticket)) { return false; }
    if(Common::OrderIsPending(OrderType())) { return false; }
    
    double stoploss, takeprofit;
    if(!unOffsetStopLevelsFromOrder(ticket, MainSymbolMan.symbols[symIdx].name, stoploss, takeprofit)) { return false; }
    
    double priceCompare; bool trigger;
    if(Common::OrderIsLong(OrderType())) { 
        priceCompare = SymbolInfoDouble(OrderSymbol(), SYMBOL_BID); 
        trigger = ((StopLossInternal && stoploss != 0 && (priceCompare <= stoploss)) || (TakeProfitInternal && takeprofit != 0 && (priceCompare >= takeprofit)));
    }
    else { 
        priceCompare = SymbolInfoDouble(OrderSymbol(), SYMBOL_ASK); 
        trigger = ((StopLossInternal && stoploss != 0 && (priceCompare >= stoploss)) || (TakeProfitInternal && takeprofit != 0 &&  (priceCompare <= takeprofit)));
    }
    
    if(trigger) {
        Error::PrintInfo("Closing order " + ticket + ": Internal stop level triggered.", NULL, "Offset SL: " + stoploss + " | Offset TP: " + takeprofit, true);
        return sendClose(ticket, symIdx);
    } else { return false; }
}

//+------------------------------------------------------------------+

bool OrderManager::getModifiedStopLevel(int ticket, int symIdx, double &stopLevelOut) {
    if(!checkDoSelectOrder(ticket)) { return false; }
    
    double level;
    
    if(!getJumpingStopLevel(ticket, symIdx, level)) {
        if(!getTrailingStopLevel(ticket, symIdx, level)) {
            if(!getBreakEvenStopLevel(ticket, symIdx, level)) {
                return false;
            }
        }
    }
    
    stopLevelOut = level;

    return true;
}

bool OrderManager::getTrailingStopLevel(int ticket, int symIdx, double &stopLevelOut) {
    // level = oppositePrice - stopOffset
    // set only if level > currentStopLoss
    if(!TrailingStopEnabled) { return false; }
    if(!checkDoSelectOrder(ticket)) { return false; }
    
    double oppositePrice = Common::OrderIsLong(OrderType()) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
        
    if(TrailAfterBreakEvenOnly && BreakEvenEnabled && !isBreakEvenPassed(ticket, symIdx)) { return false; }
        
    double stopOffsetPrice; 
    if(!getValuePrice(stopOffsetPrice, trailingStopLoc, symIdx) || stopOffsetPrice == 0) { return false; }
    
    double level = Common::OrderIsLong(OrderType()) ? oppositePrice + stopOffsetPrice : oppositePrice - stopOffsetPrice;
    
    if(isStopLossProgressed(ticket, level)) {
        stopLevelOut = level;
        return true;
    } else { return false; }
}

bool OrderManager::getJumpingStopLevel(int ticket, int symIdx, double &stopLevelOut) {
    // level = MathFloor(oppositePrice-openingPrice/jumpDistance)
    // check if jumping stop level exceeds breakeven enabled
    if(!JumpingStopEnabled) { return false; }
    if(!checkDoSelectOrder(ticket)) { return false; }
    
    double openingPrice = OrderOpenPrice();
    double oppositePrice = Common::OrderIsLong(OrderType()) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
    double priceDiff = Common::OrderIsLong(OrderType()) ? oppositePrice - openingPrice : openingPrice - oppositePrice;
    
    if(JumpAfterBreakEvenOnly && BreakEvenEnabled && !isBreakEvenPassed(ticket, symIdx)) { return false; }
    
    double jumpingDistancePrice;
    if(!getValuePrice(jumpingDistancePrice, jumpingStopLoc, symIdx) || jumpingDistancePrice == 0) { return false; }
    
    double jumpStopOffset = jumpingDistancePrice*(MathFloor(priceDiff/jumpingDistancePrice)-1);
    
    double level = Common::OrderIsLong(OrderType()) ? openingPrice + jumpStopOffset : openingPrice - jumpStopOffset;
    if(isStopLossProgressed(ticket, level)) {
        stopLevelOut = level;
        return true;
    } else { return false; }
}

bool OrderManager::getBreakEvenStopLevel(int ticket, int symIdx, double &stopLevelOut) {
    if(!BreakEvenEnabled) { return false; }
    if(!checkDoSelectOrder(ticket)) { return false; }
    
    double openingPrice = OrderOpenPrice();
    double oppositePrice = Common::OrderIsLong(OrderType()) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
    double breakEvenProfitPrice = PipsToPrice(MainSymbolMan.symbols[symIdx].name, BreakEvenProfit);
    
    if(isBreakEvenPassed(ticket, symIdx)) { // if we make breakEvenProfitPrice into a Loc, check if it == 0, then return false
        double newStopLevel = Common::OrderIsLong(OrderType()) ? openingPrice + breakEvenProfitPrice : openingPrice - breakEvenProfitPrice; // todo: what about spread???
        if(isStopLossProgressed(ticket, newStopLevel)) {
            stopLevelOut = newStopLevel;
            return true;
        }
    }
    
    return false;
}

bool OrderManager::isBreakEvenPassed(int ticket, int symIdx) {
    if(!checkDoSelectOrder(ticket)) { return false; }

    double openingPrice = OrderOpenPrice();
    double oppositePrice = Common::OrderIsLong(OrderType()) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
    double breakEvenJumpDistancePrice;
    if(!getValuePrice(breakEvenJumpDistancePrice, breakEvenJumpDistanceLoc, symIdx) || breakEvenJumpDistancePrice == 0) { return false; }
    
    double breakEvenJumpDiff = Common::OrderIsLong(OrderType()) ? oppositePrice - openingPrice : openingPrice - oppositePrice;
    return breakEvenJumpDiff >= breakEvenJumpDistancePrice;
}

bool OrderManager::isStopLossProgressed(int ticket, double newStopLoss) {
    if(!checkDoSelectOrder(ticket)) { return false; }
    if(newStopLoss == 0) { return false; }
    
    if(OrderStopLoss() == 0 && newStopLoss != 0) { return true; } // assume we want to set a modified stop loss when no SL was previously set
    
    double currentStopLoss;
    if(!unOffsetStopLossFromOrder(OrderTicket(), OrderSymbol(), currentStopLoss)) { return false; }
    
    if(Common::OrderIsLong(OrderType())) {
        return newStopLoss > currentStopLoss;
    } else {
        return newStopLoss < currentStopLoss;
    }
}

//+------------------------------------------------------------------+
    
bool OrderManager::unOffsetStopLevelsFromOrder(int ticket, string symName, double &stoplossOut, double &takeprofitOut) {
    if(!checkDoSelectOrder(ticket)) { return false; }
    
    stoplossOut = OrderStopLoss();
    takeprofitOut = OrderTakeProfit();
    
    double slOffset = StopLossBrokerOffset, tpOffset = TakeProfitBrokerOffset;
    if(Common::OrderIsShort(OrderType())) {
        slOffset = slOffset*-1;
        tpOffset = tpOffset*-1;
    }
    
    if(stoplossOut != 0 && slOffset != 0 && StopLossInternal) { 
        stoplossOut = unOffsetValue(OrderStopLoss(), slOffset, symName); 
    }
    
    if(takeprofitOut != 0 && tpOffset != 0 && TakeProfitInternal) {
        takeprofitOut = unOffsetValue(OrderTakeProfit(), tpOffset, symName); 
    }
    
    return true;
}

bool OrderManager::unOffsetStopLossFromOrder(int ticket, string symName, double &stoplossOut) {
    double takeProfit;
    return unOffsetStopLevelsFromOrder(ticket, symName, stoplossOut, takeProfit);
}

bool OrderManager::unOffsetTakeProfitFromOrder(int ticket, string symName, double &takeprofitOut) {
    double stopLoss;
    return unOffsetStopLevelsFromOrder(ticket, symName, stopLoss, takeprofitOut);
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
    double takeprofit;
    offsetStopLevels(isShort, symName, stoploss, takeprofit);
}

void OrderManager::offsetTakeProfit(bool isShort,string symName,double &takeprofit) {
    double stoploss;
    offsetStopLevels(isShort, symName, stoploss, takeprofit);
}