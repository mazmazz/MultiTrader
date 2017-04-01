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
    if(!IsTradeAllowed() || IsTradeContextBusy()) { return -1; }
    
    if(signal == gridDirection[symIdx] || gridDirection[symIdx] == SignalOpen) { return -1; } // only one grid set at a time
        // gridDirection is set after successful setup, and reset after closing

    string posSymName = MainSymbolMan.symbols[symIdx].name;
    
    double posVolume;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    int posSlippage = 40; // todo: slippage
    
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
    if(gridDirection[symIdx] == SignalNone) { gridDirection[symIdx] = signal; }
    else { gridDirection[symIdx] == SignalOpen; } 
        // logic is that if gridDirection is already SignalLong/Short, then only the opposite direction will be set. (Same direction is rejected and returned)
        // when finished with opposite direction, both directions will be open, hence we use gridDirection = SignalOpen to mean both directions
    
    return finalResult;
}

int OrderManager::prepareGridOrder(SignalType signal, bool isHedge, bool isDual, bool isMarket, int gridIndex, string posSymName, double posVolume, double posPriceDist, int posSlippage, double stoplossOffset, double takeprofitOffset, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
    int cmd;
    if(isMarket) {
        if((!isHedge && !isDual) || (isHedge && isDual)) { cmd = (signal == SignalLong) ? OP_BUY : OP_SELL; }
        else { Common::OrderIsLong(signal) ? OP_SELL : OP_BUY; }
    } else {
        if((!isHedge && !isDual) || (isHedge && isDual)) { cmd = (signal == SignalLong) ? OP_BUYSTOP : OP_SELLSTOP; }
        else { cmd = Common::OrderIsLong(signal) ? OP_SELLSTOP : OP_BUYSTOP; }
    }
    
    int gridIndexPrice = isHedge ? (MathAbs(gridIndex)*-1) : gridIndex;
    
    double priceBaseNormal = Common::OrderIsLong(cmd) ? SymbolInfoDouble(posSymName, SYMBOL_ASK) : SymbolInfoDouble(posSymName, SYMBOL_BID);
    double priceBaseOpposite = Common::OrderIsLong(cmd) ? SymbolInfoDouble(posSymName, SYMBOL_BID) : SymbolInfoDouble(posSymName, SYMBOL_ASK);
    double posPriceNormal = priceBaseNormal+(posPriceDist*gridIndexPrice);
    double posPriceOpposite = priceBaseOpposite+(posPriceDist*gridIndexPrice);
    
    double posStoploss, posTakeprofit;
    if(stoplossOffset != 0) {
        posStoploss = Common::OrderIsLong(cmd) ? posPriceOpposite + (stoplossOffset*gridIndex) : posPriceOpposite - (stoplossOffset*gridIndex); // offset is negative
    }
    if(takeprofitOffset != 0) {
        posTakeprofit = Common::OrderIsLong(cmd) ? posPriceOpposite + (takeprofitOffset*gridIndex) : posPriceOpposite - (takeprofitOffset*gridIndex);
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
        gridDirection[symbolIdx] = SignalNone;
    }
}

bool OrderManager::isGridOpen(int symIdx, bool checkPendingsOnly = false) {
    if(checkPendingsOnly) { return (openPendingCount[symIdx] > 0); }
    else { return (openPendingCount[symIdx] > 0 || openMarketCount[symIdx] > 0); }
}

bool OrderManager::isTradeModeGrid() {
    return (TradeModeType == TradeGrid);
}
