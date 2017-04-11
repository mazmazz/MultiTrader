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
    
    if((signal == SignalLong && gridSetLong[symIdx]) || (signal == SignalShort && gridSetShort[symIdx])) { 
        Error::PrintInfo("Aborting open: Grid already set up for direction - " + EnumToString(signal), true);
        return -1; 
    } // only one grid set at a time // gridSetLong/Short is set after successful setup, and reset after closing

    string posSymName = MainSymbolMan.symbols[symIdx].name;
    
    double posVolume = 0;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    int posSlippage = 0;
    if(!getValuePoints(posSlippage, maxSlippageLoc, symIdx)) { return -1; }
    
    double stoplossOffset = 0, takeprofitOffset = 0;
    if(StopLossEnabled) {
        if(!getValuePrice(stoplossOffset, stopLossLoc, symIdx)) { return -1; }
    }
    if(TakeProfitEnabled) {
        if(!getValuePrice(takeprofitOffset, takeProfitLoc, symIdx)) { return -1; }
    }
    
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    datetime posExpiration = 0;
    // datetime posExpiration
    
    double priceDistPoints = 0; 
    if(!getValuePrice(priceDistPoints, gridDistanceLoc, symIdx)) { return -1; }

    int finalResult = 0;
    
    if(GridOpenMarketInitial) {
        if(prepareGridOrder(signal, false, false, true, 0, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) { 
            finalResult++; 
        }
    }
    
    for(int i = 1; i <= GridCount; i++) {
        if(GridSetStopOrders) {
            if(prepareGridOrder(signal, false, false, false, i, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
        
        if(GridSetLimitOrders) {
            if(prepareGridOrder(signal, false, true, false, i, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
        
        if(GridSetHedgeStopOrders) {
            if(prepareGridOrder(signal, true, false, false, i, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
            
        if(GridSetHedgeLimitOrders) {
            if(prepareGridOrder(signal, true, true, false, i, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
    }
    
    // todo: grid - check if all orders succeeded
    if(signal == SignalLong) { 
        gridSetLong[symIdx] = true;
        if(GridSetHedgeStopOrders || GridSetLimitOrders) { gridSetShort[symIdx] = true; } // these set the opposite type of long/short
    } else { 
        gridSetShort[symIdx] = true; 
        if(GridSetHedgeStopOrders || GridSetLimitOrders) { gridSetLong[symIdx] = true; }
    }
    
    return finalResult;
}

int OrderManager::prepareGridOrder(SignalType signal, bool isHedge, bool isDual, bool isMarket, int gridIndex, string posSymName, double posVolume, double posPriceDist, int posSlippage, double stoplossOffset, double takeprofitOffset, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
    int cmd = -1, gridIndexPrice = 0;
    if(!isDual) {
        if(isMarket) {
            if(!isHedge) { cmd = (signal == SignalLong) ? OrderTypeBuy : OrderTypeSell; }
            else { cmd = (signal == SignalLong) ? OrderTypeSell : OrderTypeBuy; }
        } else {
            if(!isHedge) { cmd = (signal == SignalLong) ? OrderTypeBuyStop : OrderTypeSellStop; }
            else { cmd = (signal == SignalLong) ? OrderTypeSellStop : OrderTypeBuyStop; }
        }
        gridIndexPrice = Common::OrderIsShort(cmd) ? (MathAbs(gridIndex)*-1) : gridIndex;
    } else {
        if(isMarket) {
            if(!isHedge) { cmd = (signal == SignalLong) ? OrderTypeSell : OrderTypeBuy; }
            else { cmd = (signal == SignalLong) ? OrderTypeBuy : OrderTypeSell; }
        } else {
            if(!isHedge) { cmd = (signal == SignalLong) ? OrderTypeSellLimit : OrderTypeBuyLimit; }
            else { cmd = (signal == SignalLong) ? OrderTypeBuyLimit : OrderTypeSellLimit; }
        }
        gridIndexPrice = Common::OrderIsLong(cmd) ? (MathAbs(gridIndex)*-1) : gridIndex;
    }
    
    // todo: dual orders: should they use the proper ask/bid price, or the opposite? Using the proper price, the dual stop is offsetted by spread
        // I would argue do it as normal -- it's considered the same level after spread.
    double priceBaseNormal = Common::OrderIsLong(cmd) ? SymbolInfoDouble(posSymName, SYMBOL_ASK) : SymbolInfoDouble(posSymName, SYMBOL_BID);
    double priceBaseOpposite = Common::OrderIsLong(cmd) ? SymbolInfoDouble(posSymName, SYMBOL_BID) : SymbolInfoDouble(posSymName, SYMBOL_ASK);
    double posPriceNormal = priceBaseNormal+(posPriceDist*gridIndexPrice);
    double posPriceOpposite = priceBaseOpposite+(posPriceDist*gridIndexPrice);
    
    double posStoploss = 0, posTakeprofit = 0;
    if((isMarket || SetStopsOnPendings) && stoplossOffset != 0) {
        posStoploss = Common::OrderIsLong(cmd) ? posPriceOpposite + stoplossOffset : posPriceOpposite - stoplossOffset; // offset is negative
    }
    if((isMarket || SetStopsOnPendings) && takeprofitOffset != 0) {
        posTakeprofit = Common::OrderIsLong(cmd) ? posPriceOpposite + takeprofitOffset : posPriceOpposite - takeprofitOffset;
    }
    
    offsetStopLevels(Common::OrderIsShort(cmd), posSymName, posStoploss, posTakeprofit);
    
    int resultInitial = sendOpen(posSymName, cmd, posVolume, posPriceNormal, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
    return resultInitial;
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
    gridSetLong[symbolIdx] = isGridOpen(symbolIdx, true, GridOpenIfMarketExists);
    gridSetShort[symbolIdx] = isGridOpen(symbolIdx, false, GridOpenIfMarketExists);
}

bool OrderManager::isGridOpen(int symIdx, bool checkPendingsOnly) {
    return isGridOpen(symIdx, true, checkPendingsOnly) && isGridOpen(symIdx, false, checkPendingsOnly);
}

bool OrderManager::isGridOpen(int symIdx, bool isLong, bool checkPendingsOnly) {
    // short limit orders are considered part of a long grid and buy limit orders are part of a short grid
    if(isLong) {
        if(checkPendingsOnly) { return (openPendingLongCount[symIdx]-openPendingLongLimitCount[symIdx]+openPendingShortLimitCount[symIdx] > 0); }
        else { return (openPendingLongCount[symIdx]-openPendingLongLimitCount[symIdx]+openPendingShortLimitCount[symIdx] > 0 || openMarketLongCount[symIdx] > 0); }
    } else {
        if(checkPendingsOnly) { return (openPendingShortCount[symIdx]-openPendingShortLimitCount[symIdx]+openPendingLongLimitCount[symIdx] > 0); }
        else { return (openPendingShortCount[symIdx]-openPendingShortLimitCount[symIdx]+openPendingLongLimitCount[symIdx] > 0 || openMarketShortCount[symIdx] > 0); }
    }
}

bool OrderManager::isTradeModeGrid() {
    return (TradeModeType == TradeGrid);
}
