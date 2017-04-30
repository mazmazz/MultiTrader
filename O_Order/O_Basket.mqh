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

bool OrderManager::checkBasketSafe(int symIdx) {
    return checkBasketMasterSafe() && checkBasketSymbolSafe(symIdx);
}

bool OrderManager::checkBasketMasterSafe() {
    return (basketLosses < MathMax(1, BasketMaxLosingPerDay) && basketWins < MathMax(1, BasketMaxWinningPerDay));
}

bool OrderManager::checkBasketSymbolSafe(int symIdx) {
    return (basketSymbolLosses[symIdx] < MathMax(1, BasketSymbolMaxLosingPerDay) && basketSymbolWins[symIdx] < MathMax(1, BasketSymbolMaxWinningPerDay));
}

void OrderManager::checkDoBasketExit() {
    checkDoBasketMasterExit();
    checkDoBasketSymbolExit();
}

void OrderManager::checkDoBasketMasterExit() {
    bool close = false;
    if(basketMasterStopLoss != 0 && isBasketStopEnabled(true, false, true, false) && (basketProfit+basketBookedProfit) <= basketMasterStopLoss) {
        Error::PrintInfo("Master Close Basket - SL: " + basketMasterStopLoss + " | Current: " + (basketProfit + basketBookedProfit), true);
        close = true;
        basketLosses++;
    }
    
    if(basketMasterTakeProfit != 0 && isBasketStopEnabled(false, true, true, false) && (basketProfit+basketBookedProfit) >= basketMasterTakeProfit) {
        Error::PrintInfo("Master Close Basket - TP: " + basketMasterTakeProfit + " | Current: " + (basketProfit + basketBookedProfit), true);
        close = true;
        basketWins++;
    }
    
    if(close) {
#ifdef __MQL4__
        sendBasketClose(false);
#else
#ifdef __MQL5__
        sendBasketClose(true);
        sendBasketClose(false);
#endif
#endif

        updateBasketStopLevels(); // reset both master and symbol stops if necessary now, orders can open before next cycle
    }
}

void OrderManager::checkDoBasketSymbolExit() {
    if(!BasketSymbolInitialStopLossEnabled && BasketSymbolInitialTakeProfitEnabled) { return; }

    int symCount = ArraySize(MainSymbolMan.symbols);
    
    for(int i = 0; i < symCount; i++) {
        checkDoBasketSymbolExit(i); // todo: consolidate close order loop into one pass
    }
}

void OrderManager::checkDoBasketSymbolExit(int symIdx) {
    bool close = false;
    if(basketSymbolStopLoss[symIdx] != 0 && isBasketStopEnabled(true, false, false, true) && (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]) <= basketSymbolStopLoss[symIdx]) {
        Error::PrintInfo(MainSymbolMan.symbols[symIdx].name + " Close Basket - SL: " + basketSymbolStopLoss[symIdx] + " | Current: " + (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]), true);
        close = true;
        basketSymbolLosses[symIdx]++;
    }
    
    if(basketSymbolTakeProfit[symIdx] != 0 && isBasketStopEnabled(false, true, false, true) && (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]) >= basketSymbolTakeProfit[symIdx]) {
        Error::PrintInfo(MainSymbolMan.symbols[symIdx].name + " Close Basket - TP: " + basketSymbolTakeProfit[symIdx] + " | Current: " + (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]), true);
        close = true;
        basketSymbolWins[symIdx]++;
    }
    
    if(close) { // todo: consolidate close order loop into one pass
#ifdef __MQL4__
        sendBasketClose(symIdx, false);
#else
#ifdef __MQL5__
        sendBasketClose(symIdx, true);
        sendBasketClose(symIdx, false);
#endif
#endif
        
        updateBasketStopLevels(); // reset both master and symbol stops if necessary now, orders can open before next cycle
    }
}

void OrderManager::sendBasketClose(bool isPosition) {
    sendBasketClose(-1, isPosition);
}

void OrderManager::sendBasketClose(int symIdx, bool isPosition) {
    for(int i = 0; i < getOrdersTotal(isPosition); i++) {
        getOrderSelect(i, SELECT_BY_POS, MODE_TRADES, isPosition);
        if(getOrderMagicNumber(isPosition) != MagicNumber) { 
            continue; 
        }
        
        if(symIdx >= 0 && MainSymbolMan.symbols[symIdx].name != getOrderSymbol(isPosition)) { continue; }
        
        long ticket = getOrderTicket(isPosition);
        int orderSymIdx = MainSymbolMan.getSymbolId(getOrderSymbol(isPosition));
        long orderType = getOrderType(isPosition);
        bool exitResult = false;
        
        if(BasketClosePendings || !Common::OrderIsPending(getOrderType(isPosition))) {
            Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Basket", true);
            exitResult = sendClose(ticket, orderSymIdx, isPosition);
        }
        
        if(exitResult) {
            i--; // deleting a position mid-loop changes the index, attempt same index as orders shift
            addOrderToOpenCount(symIdx, orderType, true); // subtract
        }
    }
}

//+------------------------------------------------------------------+

void OrderManager::fillBasketFlags() {
    basketProfit = 0;
    basketLongProfit = 0;
    basketShortProfit = 0;
    ArrayInitialize(basketProfitSymbol, 0);
    ArrayInitialize(basketLongProfitSymbol, 0);
    ArrayInitialize(basketShortProfitSymbol, 0);
    ArrayInitialize(basketSymbolClose, false);
    
    if(!BasketTotalPerDay || basketDay != DayOfWeek()) { basketBookedProfit = 0; } // basketDay != DayOfWeek() is done in checkDoBasketExit()
    
    if(basketDay != DayOfWeek()) { // todo: basket - period length: hours? days? weeks?
        basketLosses = 0;
        basketWins = 0;
        basketDay = DayOfWeek();
        ArrayInitialize(basketSymbolWins, 0);
        ArrayInitialize(basketSymbolLosses, 0);
    }
}

//+------------------------------------------------------------------+

double OrderManager::getProfitPips(long ticket, bool isPosition) {
    double profit = 0;
    getProfitPips(ticket, isPosition, profit);
    return profit;
}

bool OrderManager::getProfitPips(long ticket, bool isPosition, double &profitOut) {
    if(!checkDoSelect(ticket, isPosition)) { return false; }
    if(Common::OrderIsPending(getOrderType(isPosition))) { return false; }
    
    profitOut = getProfitPips(getOrderOpenPrice(isPosition), getOrderType(isPosition), getOrderSymbol(isPosition));
    return true;
    // todo: approximate commission and swap in pips?
}

double OrderManager::getProfitPips(double openPrice, int opType, string symName) {
    bool isBuy = Common::OrderIsLong(opType);
    double curPrice = isBuy ? SymbolInfoDouble(symName, SYMBOL_BID) : SymbolInfoDouble(symName, SYMBOL_ASK);
    double diff = isBuy ? curPrice - openPrice : openPrice - curPrice;
    return PriceToPips(symName, diff);
    
    // todo: approximate commission and swap in pips?
}

//+------------------------------------------------------------------+

void OrderManager::updateBasketStopLevels() {
    updateBasketSymbolStopLevels();
    updateBasketMasterStopLevels();
}

void OrderManager::updateBasketMasterStopLevels() {
    updateBasketMasterStopLevel(true);
    updateBasketMasterStopLevel(false);
}

void OrderManager::updateBasketMasterStopLevel(bool isStopLoss) {
    if(isStopLoss) {
        if(isBasketStopEnabled(true, false, true, false) && getTotalMasterOrderCount(true, false) > 0) {
            if(basketMasterStopLoss == 0 && BasketMasterInitialStopLossMode != BasketStopDisable) {
                basketMasterStopLoss = getBasketMasterInitialStopLevel(isStopLoss);
            } 
            //else {
                double level = 0;
                if(getBasketModifiedStopLevel(-1, level)) {
                    basketMasterStopLoss = level;
                }
            //}
        } else { basketMasterStopLoss = 0; }
    }
    else { 
        if(isBasketStopEnabled(false, true, true, false) && getTotalMasterOrderCount(true, false) > 0) {
            if(basketMasterTakeProfit == 0 && BasketMasterInitialTakeProfitMode != BasketStopDisable) { 
                basketMasterTakeProfit = getBasketMasterInitialStopLevel(isStopLoss);
            }
        } else { basketMasterTakeProfit = 0; }
    }
}

void OrderManager::updateBasketSymbolStopLevels() {
    if(!isBasketStopEnabled(true, true, false, true)) { return; }

    int symCount = ArraySize(MainSymbolMan.symbols);
    
    for(int i = 0; i < symCount; i++) {
        updateBasketSymbolStopLevel(i, true);
        updateBasketSymbolStopLevel(i, false);
    }
}

void OrderManager::updateBasketSymbolStopLevel(int symIdx, bool isStopLoss) {
    double stopLevel = 0;
    if(isStopLoss) {
        if(isBasketStopEnabled(true, false, false, true) && openMarketLongCount[symIdx] + openMarketShortCount[symIdx] > 0) {
            if(basketSymbolStopLoss[symIdx] == 0 && BasketSymbolInitialStopLossEnabled) {
                if(getBasketSymbolInitialStopLevel(symIdx, isStopLoss, stopLevel)) {
                    basketSymbolStopLoss[symIdx] = stopLevel;
                }
            } 
            //else {
                if(getBasketModifiedStopLevel(symIdx, stopLevel)) {
                    basketSymbolStopLoss[symIdx] = stopLevel;
                }
            //}
        } else { basketSymbolStopLoss[symIdx] = 0; }
    } else {
        if(isBasketStopEnabled(false, true, false, true) && openMarketLongCount[symIdx] + openMarketShortCount[symIdx] > 0) {
            if(basketSymbolTakeProfit[symIdx] == 0 && BasketSymbolInitialTakeProfitEnabled) {
                if(getBasketSymbolInitialStopLevel(symIdx, isStopLoss, stopLevel)) {
                    basketSymbolTakeProfit[symIdx] = stopLevel;
                }
            }
        } else { basketSymbolTakeProfit[symIdx] = 0; }
    }
}

//+------------------------------------------------------------------+

double OrderManager::getBasketMasterInitialStopLevel(bool isStopLoss) {
    if((isStopLoss && BasketMasterInitialStopLossMode == BasketStopDisable)
        || (!isStopLoss && BasketMasterInitialTakeProfitMode == BasketStopDisable)
    ) { return 0; }
    
    double level = 0;
    //bool sumAllSymbols = false;
    BasketStopMode stopMode = isStopLoss ? BasketMasterInitialStopLossMode : BasketMasterInitialTakeProfitMode;
    
    switch(stopMode) {
        case BasketStopExactValue: level = isStopLoss ? BasketStopLossValue : BasketTakeProfitValue; break;
        //case BasketStopSumAllSymbols: 
        //    sumAllSymbols = true;
//        case BasketStopSumActiveSymbols: {
//            int symCount = ArraySize(MainSymbolMan.symbols);
//    
//            for(int i = 0; i < symCount; i++) { // todo: detect skipping loop when no updates?
//                if(!sumAllSymbols && openMarketLongCount[i] + openMarketShortCount[i] <= 0) { continue; }
//                
//                level += isStopLoss ? basketSymbolStopLoss[i] : basketSymbolTakeProfit[i]; // todo: rules for moving stops?
//            }
//            
//            level *= isStopLoss ? BasketStopLossFactor : BasketTakeProfitFactor;
//            break;
//        }
        case BasketStopDisable: 
        default: 
            level = 0; break;
    }
    
    Error::PrintInfo("Master Basket initial " + (isStopLoss ? "SL: " : "TP: ") + level);
    
    return level;
}

bool OrderManager::getBasketSymbolInitialStopLevel(int symIdx, bool isStopLoss, double &stopLevelOut) {
    if((isStopLoss && !BasketSymbolInitialStopLossEnabled)
        || (!isStopLoss && !BasketSymbolInitialTakeProfitEnabled)
    ) { return false; }
    
    double stopLevel = 0;
    bool finalResult = false;
    
    if(isStopLoss) {
        if(getValue(stopLevel, basketSymbolStopLossLoc, symIdx)) {
            stopLevelOut = stopLevel;
            finalResult = true;
        }
    } else {
        if(getValue(stopLevel, basketSymbolTakeProfitLoc, symIdx)) {
            stopLevelOut = stopLevel;
            finalResult = true;
        }
    }
    
    Error::PrintInfo(MainSymbolMan.symbols[symIdx].name + " Basket initial " + (isStopLoss ? "SL: " : "TP: ") + stopLevel);
    
    return finalResult;
}

bool OrderManager::getBasketModifiedStopLevel(int symIdx, double &stopLevelOut) {
    double level = 0;
    string logMessage = NULL;
    
    if(!getBasketJumpingStopLevel(symIdx, level)) {
        if(!getBasketTrailingStopLevel(symIdx, level)) {
            if(!getBasketBreakEvenStopLevel(symIdx, level)) {
                return false;
            } else { logMessage = "Basket mod stop - Breakeven: "; }
        } else { logMessage = "Basket mod stop - Trailing: "; }
    } else { logMessage = "Basket mod stop - Jump: "; }
    
    stopLevelOut = level;
    
    Error::PrintInfo((symIdx >= 0 ? MainSymbolMan.symbols[symIdx].name + " " : "Master ") + logMessage + level + " | Current: "
        + (symIdx >= 0 ? (basketProfitSymbol[symIdx]+basketBookedProfitSymbol[symIdx]) 
            : basketProfit+basketBookedProfit
            )
        , true);

    return true;
}

bool OrderManager::getBasketBreakEvenStopLevel(int symIdx, double &stopLevelOut) {
    bool enabled = symIdx < 0 ? BasketMasterBreakEvenStopEnabled : BasketSymbolBreakEvenStopEnabled;
    if(!enabled) { return false; }
    
    if(!isBasketBreakEvenPassed(symIdx)) { return false; }
    
    double stopPips = symIdx < 0 ? BasketMasterBreakEvenProfit : BasketSymbolBreakEvenProfit;
    
    if(isBasketStopLossProgressed(symIdx, stopPips)) {
        stopLevelOut = stopPips;
        return true;
    } else { return false; }
}

bool OrderManager::getBasketTrailingStopLevel(int symIdx, double &stopLevelOut) {
    bool enabled = symIdx < 0 ? BasketMasterTrailingStopEnabled : BasketSymbolTrailingStopEnabled;
    if(!enabled) { return false; }
    
    TrailStopMode mode = symIdx < 0 ? BasketMasterTrailByBreakEven : BasketSymbolTrailByBreakEven;
    switch(mode) {
        case TrailBeforeBreakEven: if(isBasketBreakEvenPassed(symIdx)) { return false; } break;
        case TrailAfterBreakEven:  if(!isBasketBreakEvenPassed(symIdx)) { return false; } break;
    }
    
    double currentPips = symIdx < 0 ? basketProfit : basketProfitSymbol[symIdx];
    
    double stopPips = 0;
    if(symIdx >= 0) {
        if(!getValue(stopPips, basketSymbolTrailingStopLoc, symIdx)) { return false; }
    } else { stopPips = BasketMasterTrailingStop; }
    stopPips = currentPips - stopPips;
    
    if(isBasketStopLossProgressed(symIdx, stopPips)) {
        stopLevelOut = stopPips;
        return true;
    } else { return false; }
}

bool OrderManager::getBasketJumpingStopLevel(int symIdx, double &stopLevelOut) {
    bool enabled = symIdx < 0 ? BasketMasterJumpingStopEnabled : BasketSymbolJumpingStopEnabled;
    if(!enabled) { return false; }
    
    double currentPips = symIdx < 0 ? basketProfit : basketProfitSymbol[symIdx];
    
    if(currentPips < 0) { return false; } // todo: booked profit
    
    double jumpPips = 0;
    if(symIdx >= 0) {
        if(!getValue(jumpPips, basketSymbolJumpingStopLoc, symIdx) || jumpPips == 0) { return false; }
    } else { 
        jumpPips = BasketMasterJumpingStop; 
        if(jumpPips == 0) { return false; }
    }
    
    double jumpingDistanceFactor = MathFloor(currentPips/jumpPips)-1;
    if(jumpingDistanceFactor <= 0) { return false; } // first jump is empty so user can enable breakeven explicitly
    
    double jumpStopPips = jumpPips*jumpingDistanceFactor;
    
    if(isBasketStopLossProgressed(symIdx, jumpStopPips)) {
        stopLevelOut = jumpStopPips;
        return true;
    } else { return false; }
}

bool OrderManager::isBasketBreakEvenPassed(int symIdx) {
    double breakEvenJumpPips = 0;
    if(symIdx >= 0) {
        if(!getValue(breakEvenJumpPips, basketSymbolBreakEvenJumpDistanceLoc, symIdx)) { return false; }
    } else { breakEvenJumpPips = BasketMasterBreakEvenJumpDistance; }
    
    double currentPips = symIdx < 0 ? basketProfit : basketProfitSymbol[symIdx];
    
    return currentPips >= breakEvenJumpPips; // todo: booked profit
}

bool OrderManager::isBasketStopLossProgressed(int symIdx, double newStopLoss) {
    double oldStopLoss = symIdx < 0 ? basketMasterStopLoss : basketSymbolStopLoss[symIdx];
    return newStopLoss != 0 && (oldStopLoss == 0 || newStopLoss > oldStopLoss);
        // if proposed stop loss = 0, return false because 0 is reserved for uninited (next cycle, initial stop is set)
}

bool OrderManager::isBasketStopEnabled(bool checkStopLoss = true, bool checkTakeProfit = true, bool checkMaster = true, bool checkSymbol = true) {
    return 
        (checkMaster && checkStopLoss && BasketMasterInitialStopLossMode != BasketStopDisable)
        || (checkMaster && checkTakeProfit && BasketMasterInitialTakeProfitMode != BasketStopDisable)
        || (checkMaster && checkStopLoss && BasketMasterBreakEvenStopEnabled)
        || (checkMaster && checkStopLoss && BasketMasterTrailingStopEnabled)
        || (checkMaster && checkStopLoss && BasketMasterJumpingStopEnabled)
        
        || (checkSymbol && checkStopLoss && BasketSymbolInitialStopLossEnabled)
        || (checkSymbol && checkTakeProfit && BasketSymbolInitialTakeProfitEnabled)
        || (checkSymbol && checkStopLoss && BasketSymbolBreakEvenStopEnabled)
        || (checkSymbol && checkStopLoss && BasketSymbolTrailingStopEnabled)
        || (checkSymbol && checkStopLoss && BasketSymbolJumpingStopEnabled)
        ;
}