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

bool OrderManager::getInitialStopLevels(bool isLong, int symIdx, bool doStoploss, bool doTakeprofit, double &stoplossOut, double &takeprofitOut, bool &doDropOut) {
    bool finalResult = false;
    
    double oppPrice = 0; // , posPrice;
    if(isLong) {
        //posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
        oppPrice = SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID); 
    } else { 
        //posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
        oppPrice = SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK); 
    } 
    
    double stoplossOffset = 0, takeprofitOffset = 0;
    if(!getValuePrice(stoplossOffset, stopLossLoc, symIdx)) { return false; }
    if(!getValuePrice(takeprofitOffset, takeProfitLoc, symIdx)) { return false; }
    bool dropSl = false, dropTp = false;
    getStopLevelDrop(MainSymbolMan.symbols[symIdx].name, stoplossOffset, takeprofitOffset, dropSl, dropTp);
    getStopLevelOffset(MainSymbolMan.symbols[symIdx].name, true, stoplossOffset, takeprofitOffset);
    
    doDropOut = (StopLossEnabled && StopLossBelowMinimumAction == MinAdjustDrop && dropSl) || (TakeProfitEnabled && TakeProfitBelowMinimumAction == MinAdjustDrop && dropTp);
    
    if(doStoploss) {
        stoplossOut = stoplossOffset == 0 ? 0
            : isLong ? oppPrice + stoplossOffset : oppPrice - stoplossOffset
            ;
        finalResult = true; //stoplossOut != 0; // in the old code, we still considered level 0 as true, do the same here
    }
    
    if(doTakeprofit) {
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
        
    double stopOffsetPips = 0;
    if(!getValue(stopOffsetPips, trailingStopLoc, symIdx) || stopOffsetPips == 0) { return false; }
    if(StopLossBelowMinimumAction == MinAdjustDrop && dropOrderByStopLoss(MainSymbolMan.symbols[symIdx].name, stopOffsetPips)) { return false; }
    getStopLossOffset(MainSymbolMan.symbols[symIdx].name, true, stopOffsetPips);
    
    double stopOffsetPrice = PipsToPrice(MainSymbolMan.symbols[symIdx].name, stopOffsetPips);
    
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
    
    double priceDiffPips = PriceToPips(MainSymbolMan.symbols[symIdx].name, priceDiff);
    double jumpingDistancePips = 0;
    if(!getValue(jumpingDistancePips, jumpingStopLoc, symIdx) || jumpingDistancePips == 0) { return false; }
    double jumpStopOffsetPips = jumpingDistancePips*(MathFloor(priceDiffPips/jumpingDistancePips)-1);
    if(StopLossBelowMinimumAction == MinAdjustDrop && dropOrderByStopLoss(MainSymbolMan.symbols[symIdx].name, jumpStopOffsetPips)) { return false; }
    getStopLossOffset(MainSymbolMan.symbols[symIdx].name, true, jumpStopOffsetPips);
    
    double jumpStopOffsetPrice = PipsToPrice(MainSymbolMan.symbols[symIdx].name, jumpStopOffsetPips);
    
    double level = Common::OrderIsLong(getOrderType(isPosition)) ? openingPrice + jumpStopOffsetPrice : openingPrice - jumpStopOffsetPrice;
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
        
    double stopOffsetPips = BreakEvenProfit;
    if(StopLossBelowMinimumAction == MinAdjustDrop && dropOrderByStopLoss(MainSymbolMan.symbols[symIdx].name, stopOffsetPips)) { return false; }
    getStopLossOffset(MainSymbolMan.symbols[symIdx].name, true, stopOffsetPips);
        
    double breakEvenProfitPrice = PipsToPrice(MainSymbolMan.symbols[symIdx].name, stopOffsetPips);
    
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
    //if(!unOffsetStopLossFromOrder(getOrderTicket(isPosition), getOrderSymbol(isPosition), currentStopLoss, isPosition)) { return false; }
    
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
    
    double slOffset = 0, tpOffset = 0;
    getStopLevelOffset(symName, false, slOffset, tpOffset);
    
    if(Common::OrderIsShort(getOrderType(isPosition))) {
        slOffset = slOffset*-1;
        tpOffset = tpOffset*-1;
    }
    
    if(stoplossOut != 0 && slOffset != 0 && StopLossInternal) { 
        stoplossOut = unOffsetValue(getOrderStopLoss(isPosition), slOffset, symName, false); 
    }
    
    if(takeprofitOut != 0 && tpOffset != 0 && TakeProfitInternal) {
        takeprofitOut = unOffsetValue(getOrderTakeProfit(isPosition), tpOffset, symName, false); 
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

//+------------------------------------------------------------------+

void OrderManager::getStopLevelDrop(string symName, double stoplossOffset, double takeprofitOffset, bool &dropSlOut, bool &dropTpOut) {
    stoplossOffset += PipsToPrice(symName, StopLossBrokerOffset); takeprofitOffset += PipsToPrice(symName, TakeProfitBrokerOffset);
    double minStop = PointsToPrice(symName, SymbolInfoInteger(symName, SYMBOL_TRADE_STOPS_LEVEL));
    
    if(StopLossMinimumAdd) { stoplossOffset -= minStop; }
    if(TakeProfitMinimumAdd) { takeprofitOffset += minStop; }
    
    dropSlOut = (stoplossOffset > MathAbs(minStop)*-1);
    dropTpOut = (takeprofitOffset < minStop);
}

bool OrderManager::dropOrderByStopLoss(string symName, double stoplossOffset) {
    bool dropSlOut = false, dropTpOut = false;
    getStopLevelDrop(symName, stoplossOffset, 0, dropSlOut, dropTpOut);
    return dropSlOut;
}

bool OrderManager::dropOrderByTakeProfit(string symName, double takeprofitOffset) {
    bool dropSlOut = false, dropTpOut = false;
    getStopLevelDrop(symName, 0, takeprofitOffset, dropSlOut, dropTpOut);
    return dropTpOut;
}

void OrderManager::getStopLevelOffset(string symName, bool checkMinimum, double &stoplossOffset, double &takeprofitOffset) {
    // if called from prepare[...]Order, offsets will already be filled with initial offsets.
    stoplossOffset += PipsToPrice(symName, StopLossBrokerOffset); takeprofitOffset += PipsToPrice(symName, TakeProfitBrokerOffset);
    double minStop = PointsToPrice(symName, SymbolInfoInteger(symName, SYMBOL_TRADE_STOPS_LEVEL));
    
    if(StopLossMinimumAdd) { stoplossOffset -= minStop; }
    if(TakeProfitMinimumAdd) { takeprofitOffset += minStop; }
    
    if(!checkMinimum) { return; }
    
    if(stoplossOffset > MathAbs(minStop)*-1) {
        switch(StopLossBelowMinimumAction) {
            case MinAdjustDrop:
            case MinAdjustDoNotSet: stoplossOffset = 0; break;
            case MinAdjustSetEqual: stoplossOffset = minStop; break;
        }
    }
    
    if(takeprofitOffset < minStop) {
        switch(TakeProfitBelowMinimumAction) {
            case MinAdjustDrop:
            case MinAdjustDoNotSet: takeprofitOffset = 0; break;
            case MinAdjustSetEqual: takeprofitOffset = minStop; break;
        }
    }
}

void OrderManager::getStopLossOffset(string symName, bool checkMinimum, double &stoplossOffset) {
    double tpOffset = 0;
    getStopLevelOffset(symName, checkMinimum, stoplossOffset, tpOffset);
}
