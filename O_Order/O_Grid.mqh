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

long OrderManager::prepareGrid(int symIdx, SignalType signal) {
    // todo: grid - smarter entry rules on pendings. Only enter when no pendings exist on the symbol? Or no trades at all on the symbol?
    if(!IsTradeAllowed()) { return -1; }
    
#ifdef __MQL4__
    if(IsTradeContextBusy()) { return -1; }
#endif
    
    bool signalIsLong = signal == SignalLong;
    
    bool gridOpenNormal = false, gridOpenHedge = false
        , openNormalEnabled = false, openNormalIfPending = false, openNormalIfPosition = false
        , openHedgeEnabled = false, openHedgeIfPending = false, openHedgeIfPosition = false
        ;
        
    getGridOpenPermission(symIdx, signalIsLong, gridOpenNormal, gridOpenHedge
        , openNormalEnabled, openNormalIfPending, openNormalIfPosition
        , openHedgeEnabled, openHedgeIfPending, openHedgeIfPosition
        );
    
    if(openNormalEnabled && GridOpenIfPendingsOpen && openNormalIfPending) { 
        Error::PrintMinor("Resetting grid normal for stop threshold", true);
        checkDoExitGrid(symIdx, signalIsLong, false); 
    }
    
    if(openHedgeEnabled && GridOpenIfPendingsOpen && openHedgeIfPending) {
        Error::PrintMinor("Resetting grid hedge for stop threshold", true);
        checkDoExitGrid(symIdx, !signalIsLong, false);
    }
    
    if(gridOpenNormal && !gridOpenHedge && openHedgeEnabled && GridResetHedgeOnOpenSignal) {
        Error::PrintMinor("Attempting grid open by resetting hedge", true);
        checkDoExitGrid(symIdx, !signalIsLong, true);
        gridOpenHedge = true; // assume closes have succeeded
    }
    
    if(!gridOpenNormal && !gridOpenHedge) {
        Error::PrintMinor("Ignoring open: Grid already set up in both directions", true);
        return -1;
    }

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

    long finalResult = 0;
    
    // how to get grid direction from signal? use it to decide per order which ones to fire
    
    if(GridOpenMarketInitial && gridOpenNormal) {
        if(prepareGridOrder(signal, false, false, true, 0, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration) > 0) { 
            finalResult++; 
        }
    }
    
    for(int i = 1; i <= GridCount; i++) {
        if(GridSetStopOrders && gridOpenNormal) {
            if(prepareGridOrder(signal, false, false, false, i, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration) > 0) {
                finalResult++;
            }
        }
        
        if(GridSetLimitOrders && gridOpenNormal) {
            if(prepareGridOrder(signal, false, true, false, i, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration) > 0) {
                finalResult++;
            }
        }
        
        if(GridSetHedgeStopOrders && gridOpenHedge) {
            if(prepareGridOrder(signal, true, false, false, i, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration) > 0) {
                finalResult++;
            }
        }
            
        if(GridSetHedgeLimitOrders && gridOpenHedge) {
            if(prepareGridOrder(signal, true, true, false, i, symIdx, posSymName, posVolume, priceDistPoints, posSlippage, posComment, posMagic, posExpiration) > 0) {
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

long OrderManager::prepareGridOrder(SignalType signal, bool isHedge, bool isDual, bool isMarket, int gridIndex, int symIdx, string posSymName, double posVolume, double posPriceDist, int posSlippage, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
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
    if(posStoploss != 0) { posStoploss += (posPriceDist*gridIndexPrice); }
    if(posTakeprofit != 0) { posTakeprofit += (posPriceDist * gridIndexPrice); }
    
    if(!doDrop) {
        long resultInitial = sendOpen(posSymName, cmd, posVolume, posPriceNormal, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
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
            SignalUnit *checkUnit = MainDataMan.symbol[symbolIdx].getSymbolSignalUnit(false);
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

int OrderManager::getGridNewTradeCount(int symIdx, bool signalIsLong) {
    int finalResult = 0;
    
    bool gridOpenNormal = false, gridOpenHedge = false
        , openNormalEnabled = false, openNormalIfPending = false, openNormalIfPosition = false
        , openHedgeEnabled = false, openHedgeIfPending = false, openHedgeIfPosition = false
        ;
        
    getGridOpenPermission(symIdx, signalIsLong, gridOpenNormal, gridOpenHedge
        , openNormalEnabled, openNormalIfPending, openNormalIfPosition
        , openHedgeEnabled, openHedgeIfPending, openHedgeIfPosition
        );
    
    // reset normal direction if threshold met
    if(openNormalEnabled && GridOpenIfPendingsOpen && openNormalIfPending) {
        finalResult -= getGridCount(symIdx, signalIsLong, true, false, true); // run on actual count
    }
    
    // reset hedge direction if threshold met
    if(openHedgeEnabled && GridOpenIfPendingsOpen && openHedgeIfPending) {
        finalResult -= getGridCount(symIdx, !signalIsLong, true, false, true); // run on actual count
    }
    
    // reset hedge direction if setting normal dir and GridResetHedgeOnOpenSignal is true
    if(gridOpenNormal && !gridOpenHedge && openHedgeEnabled && GridResetHedgeOnOpenSignal) {
        finalResult -= getGridCount(symIdx, !signalIsLong, true, false, true); // run on actual count
        gridOpenHedge = true; // assume success for count
    }
    
    if(!gridOpenNormal && !gridOpenHedge) {
        return 0; 
    }
    
    Error::PrintMinor("Grid subtract pre-count: " + finalResult, true);
    
    if(gridOpenNormal) {
        if(GridSetStopOrders) { finalResult += GridCount; }
        if(GridSetLimitOrders) { finalResult += GridCount; }
    }
    
    if(gridOpenHedge) {
        if(GridSetHedgeStopOrders) { finalResult += GridCount; }
        if(GridSetHedgeLimitOrders) { finalResult += GridCount; }
    }
    
    if(GridOpenMarketInitial) { finalResult += 1; }
    
    Error::PrintMinor("Grid pre-count: " + finalResult, true);
    return finalResult;
}

void OrderManager::getGridOpenPermission(int symIdx, bool signalIsLong, bool &gridOpenNormal, bool &gridOpenHedge
        , bool &openNormalEnabled, bool &openNormalIfPending, bool &openNormalIfPosition
        , bool &openHedgeEnabled, bool &openHedgeIfPending, bool &openHedgeIfPosition
) {
    openNormalIfPending = (GridOpenIfPendingsOpen && (GridStopThreshold == 0 || getGridCount(symIdx, signalIsLong, true, false, false) <= GridStopThreshold))
        || (!GridOpenIfPendingsOpen && getGridCount(symIdx, signalIsLong, true, false, true) <= 0)
        ;
        
    openNormalIfPosition = (GridOpenIfPositionsOpen && (GridMarketThreshold == 0 || getGridCount(symIdx, signalIsLong, false, true, false) <= GridMarketThreshold))
        || (!GridOpenIfPositionsOpen && getGridCount(symIdx, signalIsLong, false, true, false) <= 0)
        ;
        
    openHedgeIfPending = (GridOpenIfPendingsOpen && (GridStopThreshold == 0 || getGridCount(symIdx, !signalIsLong, true, false, false) <= GridStopThreshold))
        || (!GridOpenIfPendingsOpen && getGridCount(symIdx, !signalIsLong, true, false, true) <= 0)
        ;
        
    openHedgeIfPosition = (GridOpenIfPositionsOpen && (GridMarketThreshold == 0 || getGridCount(symIdx, !signalIsLong, false, true, false) <= GridMarketThreshold))
        || (!GridOpenIfPositionsOpen && getGridCount(symIdx, !signalIsLong, false, true, false) <= 0)
        ;
        
    openNormalEnabled = (GridSetStopOrders || GridSetLimitOrders);
    openHedgeEnabled = (GridSetHedgeStopOrders || GridSetHedgeLimitOrders);
    //if(GridOpenIfPendingsOpen && GridOpenIfPositionsOpen
    //    || !GridOpenIfPendingsOpen && !GridOpenIfPositionsOpen
    //) { 
        gridOpenNormal = openNormalEnabled && openNormalIfPending && openNormalIfPosition; 
        gridOpenHedge = openHedgeEnabled && openHedgeIfPending && openHedgeIfPosition;
    //} else if(GridOpenIfPendingsOpen && !GridOpenIfPositionsOpen) {
    //    gridOpenNormal = gridOpenNormal && openNormalIfPending && !openNormalIfPosition;
    //} else if(!GridOpenIfPendingsOpen && GridOpenIfPositionsOpen) {
    //
    //}
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
    if(!force && GridStopThreshold != 0 && currentStopCount > GridStopThreshold) { return; }
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
        
        long ticket = getOrderTicket(isPosition);
        
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
