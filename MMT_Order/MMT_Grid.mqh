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

int OrderManager::prepareGrid(int symIdx, SignalType signal) {
    // todo: grid - smarter entry rules on pendings. Only enter when no pendings exist on the symbol? Or no trades at all on the symbol?
    if(!IsTradeAllowed()) { return -1; }
    
#ifdef __MQL4__
    if(IsTradeContextBusy()) { return -1; }
#endif
    
    if((signal == SignalLong && gridSetLong[symIdx]) || (signal == SignalShort && gridSetShort[symIdx])) { return -1; } // only one grid set at a time // gridSetLong/Short is set after successful setup, and reset after closing

    string posSymName = MainSymbolMan.symbols[symIdx].name;
    
    double posVolume;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    int posSlippage;
    if(!getValuePoints(posSlippage, maxSlippageLoc, symIdx)) { return -1; }
    
    double stoplossOffset, takeprofitOffset;
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
    
    double priceDistPoints; 
    if(!getValuePrice(priceDistPoints, gridDistanceLoc, symIdx)) { return -1; }

    int finalResult;
    
    if(GridOpenMarketInitial) {
        if(prepareGridOrder(signal, false, false, true, 0, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) { 
            finalResult++; 
        }
    }
    
    for(int i = 1; i <= GridCount; i++) {
        if(prepareGridOrder(signal, false, false, false, i, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) {
            finalResult++;
        }
        
        if(GridSetDualPendings) {
            if(prepareGridOrder(signal, false, true, false, i, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
        }
        
        if(GridHedging) {
            if(prepareGridOrder(signal, true, false, false, i, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) {
                finalResult++;
            }
            
            if(GridSetDualPendings) {
                if(prepareGridOrder(signal, true, true, false, i, posSymName, posVolume, priceDistPoints, posSlippage, stoplossOffset, takeprofitOffset, posComment, posMagic, posExpiration)) {
                    finalResult++;
                }
            }
        }
    }
    
    // todo: grid - check if all orders succeeded
    if(signal == SignalLong) { 
        gridSetLong[symIdx] = true;
        if(GridHedging) { gridSetShort[symIdx] = true; }
    } else { 
        gridSetShort[symIdx] = true; 
        if(GridHedging) { gridSetLong[symIdx] = true; }
    }
    
    return finalResult;
}

int OrderManager::prepareGridOrder(SignalType signal, bool isHedge, bool isDual, bool isMarket, int gridIndex, string posSymName, double posVolume, double posPriceDist, int posSlippage, double stoplossOffset, double takeprofitOffset, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
    int cmd, gridIndexPrice;
    if(!isDual) {
        if(isMarket) {
            if(!isHedge) { cmd = (signal == SignalLong) ? OP_BUY : OP_SELL; }
            else { cmd = (signal == SignalLong) ? OP_SELL : OP_BUY; }
        } else {
            if(!isHedge) { cmd = (signal == SignalLong) ? OP_BUYSTOP : OP_SELLSTOP; }
            else { cmd = (signal == SignalLong) ? OP_SELLSTOP : OP_BUYSTOP; }
        }
        gridIndexPrice = Common::OrderIsShort(cmd) ? (MathAbs(gridIndex)*-1) : gridIndex;
    } else {
        if(isMarket) {
            if(!isHedge) { cmd = (signal == SignalLong) ? OP_SELL : OP_BUY; }
            else { cmd = (signal == SignalLong) ? OP_BUY : OP_SELL; }
        } else {
            if(!isHedge) { cmd = (signal == SignalLong) ? OP_SELLLIMIT : OP_BUYLIMIT; }
            else { cmd = (signal == SignalLong) ? OP_BUYLIMIT : OP_SELLLIMIT; }
        }
        gridIndexPrice = Common::OrderIsLong(cmd) ? (MathAbs(gridIndex)*-1) : gridIndex;
    }
    
    // todo: dual orders: should they use the proper ask/bid price, or the opposite? Using the proper price, the dual stop is offsetted by spread
        // I would argue do it as normal -- it's considered the same level after spread.
    double priceBaseNormal = Common::OrderIsLong(cmd) ? SymbolInfoDouble(posSymName, SYMBOL_ASK) : SymbolInfoDouble(posSymName, SYMBOL_BID);
    double priceBaseOpposite = Common::OrderIsLong(cmd) ? SymbolInfoDouble(posSymName, SYMBOL_BID) : SymbolInfoDouble(posSymName, SYMBOL_ASK);
    double posPriceNormal = priceBaseNormal+(posPriceDist*gridIndexPrice);
    double posPriceOpposite = priceBaseOpposite+(posPriceDist*gridIndexPrice);
    
    double posStoploss, posTakeprofit;
    if(GridSetStopsOnPendings && stoplossOffset != 0) {
        posStoploss = Common::OrderIsLong(cmd) ? posPriceOpposite + stoplossOffset : posPriceOpposite - stoplossOffset; // offset is negative
    }
    if(GridSetStopsOnPendings && takeprofitOffset != 0) {
        posTakeprofit = Common::OrderIsLong(cmd) ? posPriceOpposite + takeprofitOffset : posPriceOpposite - takeprofitOffset;
    }
    
    offsetStopLevels(Common::OrderIsShort(cmd), posSymName, posStoploss, posTakeprofit);
    
    int resultInitial = sendOpenOrder(posSymName, cmd, posVolume, posPriceNormal, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
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
    
    if(!isGridOpen(symbolIdx, GridOpenIfMarketExists)) { // todo: grid - should grid direction be reset even if market orders are still open?
        gridSetLong[symbolIdx] = false;
        gridSetShort[symbolIdx] = false;
    }
}

bool OrderManager::isGridOpen(int symIdx, bool checkPendingsOnly = false) {
    if(checkPendingsOnly) { return (openPendingCount[symIdx] > 0); }
    else { return (openPendingCount[symIdx] > 0 || openMarketCount[symIdx] > 0); }
}

bool OrderManager::isTradeModeGrid() {
    return (TradeModeType == TradeGrid);
}
