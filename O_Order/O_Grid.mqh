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

int OrderManager::prepareGrid(int symIdx, SignalType signal) {
    // todo: grid - smarter entry rules on pendings. Only enter when no pendings exist on the symbol? Or no trades at all on the symbol?
    if(!IsTradeAllowed()) { return -1; }
    
#ifdef __MQL4__
    if(IsTradeContextBusy()) { return -1; }
#endif
    
    bool signalIsLong = signal == SignalLong;
    
    checkDoExitGrid(symIdx, signalIsLong, false);
    
    bool gridOpenNormal = (GridOpenIfPendingsOpen && (GridStopThreshold == 0 || getGridCount(symIdx, signalIsLong, true, false, false) <= GridStopThreshold)) 
        || (GridOpenIfPositionsOpen && (GridMarketThreshold == 0 || getGridCount(symIdx, signalIsLong, false, true, false) <= GridMarketThreshold))
        ;
    bool gridOpenHedge = (GridOpenIfPendingsOpen && (GridStopThreshold == 0 || getGridCount(symIdx, !signalIsLong, true, false, false) <= GridStopThreshold)) 
        || (GridOpenIfPositionsOpen && (GridMarketThreshold == 0 || getGridCount(symIdx, !signalIsLong, false, true, false) <= GridMarketThreshold))
        ;
    
    if(gridOpenHedge && (GridOpenIfPendingsOpen && (GridStopThreshold == 0 || getGridCount(symIdx, !signalIsLong, true, false, false) <= GridStopThreshold))) {
        Error::PrintMinor("Resetting grid hedge for stop threshold", true);
        checkDoExitGrid(symIdx, !signalIsLong, false);
    }
    
    if(gridOpenNormal && !gridOpenHedge && GridResetHedgeOnOpenSignal) {
        Error::PrintMinor("Attempting grid open by resetting hedge", true);
        checkDoExitGrid(symIdx, !signalIsLong, true);
        gridOpenHedge = (GridOpenIfPendingsOpen && (GridStopThreshold == 0 || getGridCount(symIdx, !signalIsLong, true, false, false) <= GridStopThreshold)) 
            || (GridOpenIfPositionsOpen && (GridMarketThreshold == 0 || getGridCount(symIdx, !signalIsLong, false, true, false) <= GridMarketThreshold))
            ;
    }
    
    if(!gridOpenNormal && !gridOpenHedge) {
        Error::PrintMinor("Ignoring open: Grid already set up in both directions", true);
        return -1;
    }
    
    //if((signal == SignalLong && gridSetLong[symIdx]) || (signal == SignalShort && gridSetShort[symIdx])) { 
    //    Error::PrintInfo("Aborting open: Grid already set up for direction - " + EnumToString(signal), true);
    //    return -1; 
    //} // only one grid set at a time // gridSetLong/Short is set after successful setup, and reset after closing

    string posSymName = MainSymbolMan.symbols[symIdx].name;
    
    double posVolume = 0;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    int posSlippage = 0;
    if(!getValuePoints(posSlippage, maxSlippageLoc, symIdx)) { return -1; }
    
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    datetime posExpiration = 0;
    // datetime posExpiration
    
    double priceDistPoints = 0; 
    if(!getValuePrice(priceDistPoints, gridDistanceLoc, symIdx)) { return -1; }

    int finalResult = 0;
    
    // how to get grid direction from signal? use it to decide per order which ones to fire
    
    if(GridOpenMarketInitial && gridOpenNormal) {
        if(prepareGridOrder(signal, false, false, true, 0, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration)) { 
            finalResult++; 
        }
    }
    
    for(int i = 1; i <= GridCount; i++) {
        if(GridSetStopOrders && gridOpenNormal) {
            if(prepareGridOrder(signal, false, false, false, i, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
        
        if(GridSetLimitOrders && gridOpenNormal) {
            if(prepareGridOrder(signal, false, true, false, i, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
        
        if(GridSetHedgeStopOrders && gridOpenHedge) {
            if(prepareGridOrder(signal, true, false, false, i, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
            
        if(GridSetHedgeLimitOrders && gridOpenHedge) {
            if(prepareGridOrder(signal, true, true, false, i, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
    }
    
    // todo: grid - check if all orders succeeded
    if(signalIsLong) { 
        gridSetLong[symIdx] = true;
        if(GridSetHedgeStopOrders || GridSetLimitOrders) { gridSetShort[symIdx] = true; } // these set the opposite type of long/short
    } else { 
        gridSetShort[symIdx] = true; 
        if(GridSetHedgeStopOrders || GridSetLimitOrders) { gridSetLong[symIdx] = true; }
    }
    
    return finalResult;
}

int OrderManager::prepareGridOrder(SignalType signal, bool isHedge, bool isDual, bool isMarket, int gridIndex, int symIdx, string posSymName, double posVolume, double posPriceDist, int posSlippage, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
    int cmd = 0, gridIndexPrice = gridIndex;
    getGridOrderType(signal, isHedge, isDual, isMarket, cmd, gridIndexPrice);
    
    
    // todo: dual orders: should they use the proper ask/bid price, or the opposite? Using the proper price, the dual stop is offsetted by spread
        // I would argue do it as normal -- it's considered the same level after spread.
    double priceBaseNormal = Common::OrderIsLong(cmd) ? SymbolInfoDouble(posSymName, SYMBOL_ASK) : SymbolInfoDouble(posSymName, SYMBOL_BID);
    double priceBaseOpposite = Common::OrderIsLong(cmd) ? SymbolInfoDouble(posSymName, SYMBOL_BID) : SymbolInfoDouble(posSymName, SYMBOL_ASK);
    double posPriceNormal = priceBaseNormal+(posPriceDist*gridIndexPrice);
    double posPriceOpposite = priceBaseOpposite+(posPriceDist*gridIndexPrice);
    
    double posStoploss = 0, posTakeprofit = 0; bool doDrop = false;
    getInitialStopLevels(Common::OrderIsLong(cmd), symIdx
        , (isMarket || SetStopsOnPendings) && StopLossInitialEnabled, (isMarket || SetStopsOnPendings) && TakeProfitInitialEnabled
        , posStoploss, posTakeprofit
        , doDrop
        );
    
    if(!doDrop) {
        int resultInitial = sendOpen(posSymName, cmd, posVolume, posPriceNormal, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
        return resultInitial;
    } else { return 0; }
}

void OrderManager::getGridOrderType(SignalType signal, bool isHedge, bool isDual, bool isMarket, int &cmdOut, int &gridIndexOut) {
    if(!isDual) {
        if(isMarket) {
            if(!isHedge) { cmdOut = (signal == SignalLong) ? OrderTypeBuy : OrderTypeSell; }
            else { cmdOut = (signal == SignalLong) ? OrderTypeSell : OrderTypeBuy; }
        } else {
            if(!isHedge) { cmdOut = (signal == SignalLong) ? OrderTypeBuyStop : OrderTypeSellStop; }
            else { cmdOut = (signal == SignalLong) ? OrderTypeSellStop : OrderTypeBuyStop; }
        }
        gridIndexOut = Common::OrderIsShort(cmdOut) ? (MathAbs(gridIndexOut)*-1) : gridIndexOut;
    } else {
        if(isMarket) {
            if(!isHedge) { cmdOut = (signal == SignalLong) ? OrderTypeSell : OrderTypeBuy; }
            else { cmdOut = (signal == SignalLong) ? OrderTypeBuy : OrderTypeSell; }
        } else {
            if(!isHedge) { cmdOut = (signal == SignalLong) ? OrderTypeSellLimit : OrderTypeBuyLimit; }
            else { cmdOut = (signal == SignalLong) ? OrderTypeBuyLimit : OrderTypeSellLimit; }
        }
        gridIndexOut = Common::OrderIsLong(cmdOut) ? (MathAbs(gridIndexOut)*-1) : gridIndexOut;
    }
}

int OrderManager::getGridOrderType(SignalType signal, bool isHedge, bool isDual, bool isMarket) {
    int cmd = 0, gridIndex = 0;
    getGridOrderType(signal, isHedge, isDual, isMarket, cmd, gridIndex);
    return cmd;
}

void OrderManager::fillGridExitFlags(int symbolIdx) { 
    if(isTradeModeGrid() && gridExit[symbolIdx]) {
        if(gridExitBySignal[symbolIdx]) {
            SignalUnit *checkUnit = MainDataMan.symbol[symbolIdx].getSignalUnit(false);
            if(!Common::IsInvalidPointer(checkUnit)) { 
                checkUnit.fulfilled = true;
            }
        } else if (gridExitByOpposite[symbolIdx]) { gridExitByOpposite[symbolIdx] = false; } // no fulfilled flag to set
        gridExit[symbolIdx] = false;
    }
    
    // in the past, these flags are not reset at cycle start, because exit cycle needed this last known info
    // so we set these here in the affirmative before starting the entry cycle
    // right now, we reset these flags at cycle start
    gridSetLong[symbolIdx] = isGridOpen(symbolIdx, true, GridOpenIfPositionsOpen);
    gridSetShort[symbolIdx] = isGridOpen(symbolIdx, false, GridOpenIfPositionsOpen);
}

bool OrderManager::isGridOpen(int symIdx, bool checkPendingsOnly) {
    return isGridOpen(symIdx, true, checkPendingsOnly) && isGridOpen(symIdx, false, checkPendingsOnly);
}

bool OrderManager::isGridOpen(int symIdx, bool isLong, bool checkPendingsOnly) {
    // short limit orders are considered part of a long grid and buy limit orders are part of a short grid
    if(checkPendingsOnly) { return getGridCount(symIdx, isLong, true, false, true) > 0; }
    else { return getGridCount(symIdx, isLong, true, true, true) > 0; }
}

int OrderManager::getGridCount(int symIdx, bool isLong, bool checkPendings, bool checkPositions, bool checkLimitOrders) {
    int finalResult = 0;
    
    if(isLong) {
        if(checkPendings) { finalResult += openPendingLongCount[symIdx]-openPendingLongLimitCount[symIdx]+ (checkLimitOrders ? openPendingShortLimitCount[symIdx] : 0); }
        if(checkPositions) { finalResult += openMarketLongCount[symIdx]; }
    } else {
        if(checkPendings) { finalResult += openPendingShortCount[symIdx]-openPendingShortLimitCount[symIdx]+ (checkLimitOrders ? openPendingLongLimitCount[symIdx] : 0); }
        if(checkPositions) { finalResult += openMarketShortCount[symIdx]; }
    }
    
    return finalResult;
}

bool OrderManager::isTradeModeGrid() {
    return (TradeModeType == TradeGrid);
}

SignalType OrderManager::getGridOrderDirection(int orderType) {
    switch(orderType) {
        case OrderTypeBuy:
        case OrderTypeBuyStop:
        case OrderTypeSellLimit:
        case OrderTypeSellStopLimit:
            return SignalLong;
            
        case OrderTypeSell:
        case OrderTypeSellStop:
        case OrderTypeBuyLimit:
        case OrderTypeBuyStopLimit:
            return SignalShort;
            
        default:
            return SignalNone;        
    }
}

bool OrderManager::isGridOrderTypeLong(int orderType) {
    return getGridOrderDirection(orderType) == SignalLong;
}

bool OrderManager::isGridOrderTypeShort(int orderType) {
    return getGridOrderDirection(orderType) == SignalShort;
}

void OrderManager::checkDoExitGrid(int symIdx, bool closeLong, bool force) {
    int currentStopCount = getGridCount(symIdx, closeLong, true, false, false); // check on consolidated count (no duals)
    if(!force && currentStopCount > GridStopThreshold) { return; }
    currentStopCount = getGridCount(symIdx, closeLong, true, false, true); // run on actual count
    
    bool isPosition = false; // cycle through orders/pendings only
    int closeCount = 0;
    for(int i = 0; i < getOrdersTotal(isPosition); i++) { 
        getOrderSelect(i, SELECT_BY_POS, MODE_TRADES, isPosition);

        if(getOrderMagicNumber(isPosition) != MagicNumber) { 
            continue; 
        }
        
        int orderType = getOrderType(isPosition);
        if(!Common::OrderIsPending(orderType)) { continue; }
        if(getGridOrderDirection(orderType) != (closeLong ? SignalLong : SignalShort)) { continue; }
        
        string symName = getOrderSymbol(isPosition);
        int orderSymIdx = MainSymbolMan.getSymbolId(symName);
        if(orderSymIdx != symIdx) { continue; }
        
        int ticket = getOrderTicket(isPosition);
        
        bool result = sendClose(getOrderTicket(isPosition), symIdx, isPosition);
        if(result) {
            Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + (!force ? ": Grid stop threshold" : ": Grid force close"));
            addOrderToOpenCount(symIdx, orderType, true);
            closeCount++;
            if(closeCount >= currentStopCount) { break; }
            
            i--; // deleting a position mid-loop changes the index, attempt same index as orders shift
        }
    }
}