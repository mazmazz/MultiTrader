//+------------------------------------------------------------------+
//|                                                 MMT_Schedule.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include <MC_Common/MC_Common.mqh>
#include <MC_Common/MC_Error.mqh>
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
    
    doDropOut = (StopLossInitialEnabled && StopLossBelowMinimumAction == MinAdjustDrop && dropSl) || (TakeProfitInitialEnabled && TakeProfitBelowMinimumAction == MinAdjustDrop && dropTp);
    
    if(doStoploss) {
        stoplossOut = stoplossOffset == 0 ? 0
            : isLong ? oppPrice + stoplossOffset : oppPrice - stoplossOffset
            ;
        finalResult = true; //stoplossOut != 0; // in the old code, we still considered level 0 as true, do the same here
    } else { stoplossOut = 0; }
    
    if(doTakeprofit) {
        takeprofitOut = takeprofitOffset == 0 ? 0
            : isLong ? oppPrice + takeprofitOffset : oppPrice - takeprofitOffset
            ;
        finalResult = true; //finalResult ? finalResult : takeprofitOut != 0;
    } else { takeprofitOut = 0; }
    
    return finalResult;
}

bool OrderManager::checkDoExitStopLevels(long ticket, int symIdx, bool isPosition) {
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
        int digits = SymbolInfoInteger(getOrderSymbol(isPosition), SYMBOL_DIGITS);
        if(sendClose(ticket, symIdx, isPosition)) {
            Error::PrintInfo(getOrderSymbol(isPosition) + " #" + ticket + ": Close internal stop | Internal SL: " + DoubleToString(stoploss, digits) + " | Internal TP: " + DoubleToString(takeprofit, digits), true);
            return true;
        } else { return false; }
    } else { return false; }
}

//+------------------------------------------------------------------+

bool OrderManager::getModifiedStopLevel(long ticket, int symIdx, double &stopLevelOut, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double level = 0;
    string logMessage = NULL;
    bool progressChecked = false;
    
    if(!getJumpingStopLevel(ticket, symIdx, level, isPosition, progressChecked)) {
        if(!MoveStopOnlyIfProgressed && progressChecked) { return false; }
        if(!getTrailingStopLevel(ticket, symIdx, level, isPosition, progressChecked)) {
            if(!MoveStopOnlyIfProgressed && progressChecked) { return false; }
            if(!getBreakEvenStopLevel(ticket, symIdx, level, isPosition, progressChecked)) {
                return false;
            } else { logMessage = " Mod stop: Breakeven"; }
        } else { logMessage = " Mod stop: Trailing"; }
    } else { logMessage = " Mod stop: Jump"; }
    
    stopLevelOut = level;
    
    Error::PrintInfo(MainSymbolMan.symbols[symIdx].name + " #" + ticket + logMessage, true);

    return true;
}

bool OrderManager::getTrailingStopLevel(long ticket, int symIdx, double &stopLevelOut, bool isPosition, bool &progressChecked) {
    progressChecked = false;
    // level = oppositePrice - stopOffset
    // set only if level > currentStopLoss
    if(!TrailingStopEnabled) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double oppositePrice = Common::OrderIsLong(getOrderType(isPosition)) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
        
    switch(TrailByBreakEven) {
        case TrailBeforeBreakEven: if(isBreakEvenPassed(ticket, symIdx, isPosition)) { return false; } break;
        case TrailAfterBreakEven:  if(!isBreakEvenPassed(ticket, symIdx, isPosition)) { return false; } break;
    }
        
    double stopOffsetPrice = 0, stopOffsetPips = 0;
    if(!getValue(stopOffsetPips, trailingStopLoc, symIdx) || stopOffsetPips == 0) { return false; }
    stopOffsetPrice = PipsToPrice(MainSymbolMan.symbols[symIdx].name, stopOffsetPips);
    getStopLossOffset(MainSymbolMan.symbols[symIdx].name, true, stopOffsetPrice);
    
    if(stopOffsetPrice == 0 || (StopLossBelowMinimumAction == MinAdjustDrop && dropOrderByStopLoss(MainSymbolMan.symbols[symIdx].name, stopOffsetPrice))) { return false; }
    
    double level = NormalizeDouble(
        Common::OrderIsLong(getOrderType(isPosition)) ? oppositePrice + stopOffsetPrice : oppositePrice - stopOffsetPrice
        , SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_DIGITS)
        );
    
    progressChecked = true;
    if(isStopLossProgressed(ticket, symIdx, level, isPosition)) {
        stopLevelOut = level;
        return true;
    } else { return false; }
}

bool OrderManager::getJumpingStopLevel(long ticket, int symIdx, double &stopLevelOut, bool isPosition, bool &progressChecked, bool checkProgressed = true) {
    progressChecked = false;
    // level = MathFloor(oppositePrice-openingPrice/jumpDistance)
    // check if jumping stop level exceeds breakeven enabled
    if(!JumpingStopEnabled) { return false; }
    if(!isBreakEvenPassed(ticket, symIdx, isPosition)) { return false; } // Steve Hopwood's MPTM manual cites jumps happen only after breakeven
        // todo: is it possible to engage jump stop before breakeven?
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double openingPrice = getOrderOpenPrice(isPosition);
    double oppositePrice = Common::OrderIsLong(getOrderType(isPosition)) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
    
    // get jumping distance factor (how many jumps have been accomplished?)
    // subtract by 1 to get last jump to set stop
        
    double priceDiff = Common::OrderIsLong(getOrderType(isPosition)) ? oppositePrice - openingPrice : openingPrice - oppositePrice;
    
    if(priceDiff < 0) { return false; } // todo: is it possible to engage jump stop before breakeven?
    
    double priceDiffPips = PriceToPips(MainSymbolMan.symbols[symIdx].name, priceDiff);
    double jumpingDistancePips = 0;
    if(!getValue(jumpingDistancePips, jumpingStopLoc, symIdx) || jumpingDistancePips == 0) { return false; }
    
    double jumpingDistanceFactor = MathFloor(priceDiffPips/jumpingDistancePips)-1;
    if(jumpingDistanceFactor <= 0) { return false; } // first jump is empty so user can enable breakeven explicitly
    double jumpingDistancePrice = PipsToPrice(MainSymbolMan.symbols[symIdx].name, jumpingDistancePips*jumpingDistanceFactor);
    
    // figure stop offset
    
    double jumpStopOffsetPrice = 0;
    if(Common::OrderIsLong(getOrderType(isPosition))) {
        jumpStopOffsetPrice = (openingPrice + jumpingDistancePrice) - oppositePrice;
    } else{
        jumpStopOffsetPrice = oppositePrice - (openingPrice - jumpingDistancePrice);
    }
    
    getStopLossOffset(MainSymbolMan.symbols[symIdx].name, true, jumpStopOffsetPrice);
    
    if(jumpStopOffsetPrice == 0 || (StopLossBelowMinimumAction == MinAdjustDrop && dropOrderByStopLoss(MainSymbolMan.symbols[symIdx].name, jumpStopOffsetPrice))) { return false; }
    
    double level = NormalizeDouble(
        Common::OrderIsLong(getOrderType(isPosition)) ? oppositePrice + jumpStopOffsetPrice : oppositePrice - jumpStopOffsetPrice
        , SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_DIGITS)
        );
    
    progressChecked = true;
    if(!checkProgressed || isStopLossProgressed(ticket, symIdx, level, isPosition)) {
        stopLevelOut = level;
        return true;
    } else { return false; }
}

bool OrderManager::getBreakEvenStopLevel(long ticket, int symIdx, double &stopLevelOut, bool isPosition, bool &progressChecked, bool checkProgressed = true) {
    progressChecked = false;
    if(!BreakEvenStopEnabled) { return false; }
    if(!isBreakEvenPassed(ticket, symIdx, isPosition)) { return false; }
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    double openingPrice = getOrderOpenPrice(isPosition);
    double oppositePrice = Common::OrderIsLong(getOrderType(isPosition)) ? 
        SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_BID)
        : SymbolInfoDouble(MainSymbolMan.symbols[symIdx].name, SYMBOL_ASK)
        ;
        
    // todo: sanity check, is profit price less than jump distance?
    // todo: spread check???
        
    double breakEvenProfitPrice = PipsToPrice(MainSymbolMan.symbols[symIdx].name, BreakEvenProfit);
    double stopLevelOffsetPrice = 0;
    if(Common::OrderIsLong(getOrderType(isPosition))) {
        stopLevelOffsetPrice = (openingPrice + breakEvenProfitPrice) - oppositePrice;
    } else{
        stopLevelOffsetPrice = oppositePrice - (openingPrice - breakEvenProfitPrice);
    }
    getStopLossOffset(MainSymbolMan.symbols[symIdx].name, true, stopLevelOffsetPrice);
    
    if(stopLevelOffsetPrice == 0 || (StopLossBelowMinimumAction == MinAdjustDrop && dropOrderByStopLoss(MainSymbolMan.symbols[symIdx].name, stopLevelOffsetPrice))) { return false; }
    
    double newStopLevel = NormalizeDouble(
        Common::OrderIsLong(getOrderType(isPosition)) ? oppositePrice + stopLevelOffsetPrice : oppositePrice - stopLevelOffsetPrice
        , SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_DIGITS)
        );
    
    progressChecked = true;
    if(!checkProgressed || isStopLossProgressed(ticket, symIdx, newStopLevel, isPosition)) {
        stopLevelOut = newStopLevel;
        return true;
    } else { return false; }
}

bool OrderManager::isBreakEvenPassed(long ticket, int symIdx, bool isPosition) {
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

bool OrderManager::isStopLossProgressed(long ticket, int symIdx, double &newStopLoss, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    if(newStopLoss == 0) { return false; }
    
    if(getOrderStopLoss(isPosition) == 0 && newStopLoss != 0) { return true; } // assume we want to set a modified stop loss when no SL was previously set
    
    bool isLong = Common::OrderIsLong(getOrderType(isPosition));
    newStopLoss = NormalizeDouble(newStopLoss, SymbolInfoInteger(getOrderSymbol(isPosition), SYMBOL_DIGITS));
    double currentStopLoss = NormalizeDouble(getOrderStopLoss(isPosition), SymbolInfoInteger(getOrderSymbol(isPosition), SYMBOL_DIGITS));
    //if(!unOffsetStopLossFromOrder(getOrderTicket(isPosition), getOrderSymbol(isPosition), currentStopLoss, isPosition)) { return false; }
    double stopThreshold = MathAbs(PipsToPrice(MainSymbolMan.getSymbolName(symIdx), MoveStopThreshold));
    
    if(MoveStopOnlyIfProgressed) {
        if(isLong) {
            return newStopLoss > (currentStopLoss + stopThreshold);
        } else {
            return newStopLoss < (currentStopLoss - stopThreshold);
        }
    } else {
        if(newStopLoss <= currentStopLoss+stopThreshold && newStopLoss >= currentStopLoss-stopThreshold) { return false; }
        
        string message = "";
        double jumpSl = 0, breakevenSl = 0, initialSl = 0, initialTp = 0; bool doDrop = false, progressChecked = false;
        if(JumpingStopEnabled && getJumpingStopLevel(ticket, symIdx, jumpSl, isPosition, progressChecked, false) && jumpSl != 0) {
            if((isLong ? newStopLoss < jumpSl : newStopLoss > jumpSl)) {
                message = MainSymbolMan.symbols[symIdx].name + " #" + ticket + " reset stop: jumping (old " + newStopLoss + ")";
                newStopLoss = NormalizeDouble(jumpSl, SymbolInfoInteger(getOrderSymbol(isPosition), SYMBOL_DIGITS));
                
            }
        } else 
        if(BreakEvenStopEnabled /*&& isBreakEvenPassed(ticket, symIdx, isPosition) */&& getBreakEvenStopLevel(ticket, symIdx, breakevenSl, isPosition, progressChecked, false) && breakevenSl != 0) {
            if((isLong ? newStopLoss < breakevenSl : newStopLoss > breakevenSl)) {
                // set new stoploss to breakeven
                message = MainSymbolMan.symbols[symIdx].name + " #" + ticket + " reset stop: breakeven (old " + newStopLoss + ")";
                newStopLoss = NormalizeDouble(breakevenSl, SymbolInfoInteger(getOrderSymbol(isPosition), SYMBOL_DIGITS));
            }
        } else
        if(StopLossInitialEnabled && getInitialStopLevels(isLong, symIdx, true, false, initialSl, initialTp, doDrop) && initialSl != 0) {
            if((isLong ? newStopLoss < initialSl : newStopLoss > initialSl)) {
                // set stop loss to initial sl
                message = MainSymbolMan.symbols[symIdx].name + " #" + ticket + " reset stop: initial (old " + newStopLoss + ")";
                newStopLoss = NormalizeDouble(initialSl, SymbolInfoInteger(getOrderSymbol(isPosition), SYMBOL_DIGITS));
            }
        } 
        
        if(newStopLoss > currentStopLoss+stopThreshold || newStopLoss < currentStopLoss-stopThreshold) {
            if(StringLen(message) > 0) { Error::PrintInfo(message, NULL, NULL, true); }
            return true;
        } else { return false; }
    }
}

//+------------------------------------------------------------------+

void OrderManager::unOffsetStopLevels(string symName, bool isLong, double &stoplossOut, double &takeprofitOut) {
    double slOffset = 0, tpOffset = 0;
    getStopLevelOffset(symName, false, slOffset, tpOffset);
    
    if(!isLong) {
        slOffset = slOffset*-1;
        tpOffset = tpOffset*-1;
    }
    
    if(stoplossOut != 0 && slOffset != 0 && StopLossInternal) { 
        stoplossOut = unOffsetValue(stoplossOut, slOffset, symName, false); 
    }
    
    if(takeprofitOut != 0 && tpOffset != 0 && TakeProfitInternal) {
        takeprofitOut = unOffsetValue(takeprofitOut, tpOffset, symName, false); 
    }
}

double OrderManager::unOffsetStopLoss(string symName, bool isLong, double stoploss) {
    double takeprofit = 0;
    
    unOffsetStopLevels(symName, isLong, stoploss, takeprofit);
    
    return stoploss;
}

double OrderManager::unOffsetTakeProfit(string symName, bool isLong, double takeprofit) {
    double stoploss = 0;
    
    unOffsetStopLevels(symName, isLong, stoploss, takeprofit);
    
    return takeprofit;
}

bool OrderManager::unOffsetStopLevelsFromOrder(long ticket, string symName, double &stoplossOut, double &takeprofitOut, bool isPosition) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    
    stoplossOut = getOrderStopLoss(isPosition);
    takeprofitOut = getOrderTakeProfit(isPosition);
    
    unOffsetStopLevels(symName, Common::OrderIsLong(getOrderType(isPosition)), stoplossOut, takeprofitOut);
    
    return true;
}

bool OrderManager::unOffsetStopLossFromOrder(long ticket, string symName, double &stoplossOut, bool isPosition) {
    double takeProfit = 0;
    return unOffsetStopLevelsFromOrder(ticket, symName, stoplossOut, takeProfit, isPosition);
}

bool OrderManager::unOffsetTakeProfitFromOrder(long ticket, string symName, double &takeprofitOut, bool isPosition) {
    double stopLoss = 0;
    return unOffsetStopLevelsFromOrder(ticket, symName, stopLoss, takeprofitOut, isPosition);
}

//+------------------------------------------------------------------+

void OrderManager::getStopLevelOffset(string symName, bool checkMinimum, double &stoplossOffset, double &takeprofitOffset) {
    // if called from prepare[...]Order, offsets will already be filled with initial offsets.
    stoplossOffset += PipsToPrice(symName, StopLossBrokerOffset); takeprofitOffset += PipsToPrice(symName, TakeProfitBrokerOffset);
    double minStop = PointsToPrice(symName, SymbolInfoInteger(symName, SYMBOL_TRADE_STOPS_LEVEL));
    
    if(StopLossMinimumAdd) { stoplossOffset -= minStop; }
    if(TakeProfitMinimumAdd) { takeprofitOffset += minStop; }
    
    if(!checkMinimum || minStop == 0) { return; }
    
    if(stoplossOffset > MathAbs(minStop)*(-1)) {
        switch(StopLossBelowMinimumAction) {
            case MinAdjustDrop:
            case MinAdjustDoNotSet: stoplossOffset = 0; break;
            case MinAdjustSetEqual: stoplossOffset = MathAbs(minStop)*(-1); break;
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

//+------------------------------------------------------------------+

void OrderManager::getStopLevelDrop(string symName, double stoplossOffset, double takeprofitOffset, bool &dropSlOut, bool &dropTpOut) {
    stoplossOffset += PipsToPrice(symName, StopLossBrokerOffset); takeprofitOffset += PipsToPrice(symName, TakeProfitBrokerOffset);
    double minStop = PointsToPrice(symName, SymbolInfoInteger(symName, SYMBOL_TRADE_STOPS_LEVEL));
    
    if(StopLossMinimumAdd) { stoplossOffset -= minStop; }
    if(TakeProfitMinimumAdd) { takeprofitOffset += minStop; }
    
    if(minStop == 0) {
        dropSlOut = dropTpOut = false;
    } else {
        dropSlOut = (stoplossOffset > MathAbs(minStop)*-1);
        dropTpOut = (takeprofitOffset < minStop);
    }
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

//+------------------------------------------------------------------+

void OrderManager::logInternalStopLevels(long ticket, double stoploss, double takeprofit, bool isPosition) {
    if((stoploss != 0 || takeprofit != 0) && Error::HasLevel(ErrorInfo) && checkDoSelect(ticket, isPosition)) {
        double internalSl = stoploss, internalTp = takeprofit;
        int digits = SymbolInfoInteger(getOrderSymbol(isPosition), SYMBOL_DIGITS);
        unOffsetStopLevels(getOrderSymbol(isPosition), Common::OrderIsLong(getOrderType(isPosition)), internalSl, internalTp);

        string logMessage = NULL;
        if(stoploss != 0 && stoploss != NormalizeDouble(internalSl, digits)) { logMessage += "Internal SL: " + DoubleToString(internalSl, digits) + " | Real: " + DoubleToString(stoploss, digits) + " | Offset: " + DoubleToString(stoploss-internalSl, digits) + " | "; }
        if(takeprofit != 0 && takeprofit != NormalizeDouble(internalTp, digits)) { logMessage += "Internal TP: " + DoubleToString(internalTp, digits) + " | Real: " + DoubleToString(takeprofit, digits) + " | Offset: " + DoubleToString(takeprofit-internalTp, digits); }
    
        if(logMessage != NULL) { Error::PrintInfo(getOrderSymbol(isPosition) + " #" + ticket + " " + logMessage, true); }
        Error::PrintInfo("+------------------------------------------------------------------+");
    }
}