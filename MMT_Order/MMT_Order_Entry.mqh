#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "../MMT_Data/MMT_Data.mqh"
#include "../MMT_Symbols.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "MMT_Order_Defines.mqh"

int OrderManager::doEnterPosition(int symIdx) {
    if(!TradeEntryEnabled) { return 0; }
    if(!getLastTimeElapsed(symIdx, true, TimeSettingUnit, TradeBetweenDelay)) { return 0; }
    if(AccountInfoDouble(ACCOUNT_MARGIN) > 0 && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < TradeMinMarginLevel) { return 0; }
    if(TradeModeType != TradeGrid && MaxTradesPerSymbol > 0 && MaxTradesPerSymbol <= positionOpenCount[symIdx]) { return 0; }

    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(true);
    if(Common::IsInvalidPointer(checkUnit)) { return 0; }
    else if(checkUnit.fulfilled) { 
        //Error::ThrowError(ErrorNormal, "checkUnit fulfilled " + checkUnit.type);
        return 0; 
    }
    
    //Error::ThrowError(ErrorNormal, "checkUnit " + checkUnit.type);
    
    if(checkUnit.type != SignalLong && checkUnit.type != SignalShort) { return 0; }
    
    // check exit signal conflict here
    //int exitUnitCount = ArraySize(MainDataMan.symbol[symIdx].exitSignal);
    //for(int i = 0; i < exitUnitCount; i++) {
    //    if(
    //        !Common::IsInvalidPointer(MainDataMan.symbol[symIdx].exitSignal[i])
    //        && ((checkUnit.type == SignalLong && MainDataMan.symbol[symIdx].exitSignal[i].type == SignalShort)
    //            || (checkUnit.type == SignalShort && MainDataMan.symbol[symIdx].exitSignal[i].type == SignalLong) 
    //        )
    //        && MainDataMan.symbol[symIdx].getSignalDuration(TimeSettingUnit, MainDataMan.symbol[symIdx].exitSignal[i]) >= SignalRetraceDelay
    //    ) {
    //        return 0;
    //    }
    //}
    
    SignalUnit *checkExitUnit = MainDataMan.symbol[symIdx].getSignalUnit(false);
    if(!Common::IsInvalidPointer(checkExitUnit)) {
        // todo: how to handle retraces where exit signal is temporarily not in opposite?
        // retracement delay? loop through buffer and see if exit signal existed within retracement delay?
        if(checkUnit.type == SignalLong && checkExitUnit.type == SignalShort) { return 0; }
        if(checkUnit.type == SignalShort && checkExitUnit.type == SignalLong) { return 0; }
    }
    
    // todo: check spread for entry
    
    int posCmd, result;
    switch(TradeModeType) {
        case TradeGrid: 
            result = sendGrid(symIdx, checkUnit.type);
            break;
            
        case TradeMarket: 
        case TradeLimitOrders:
        default: 
            result = sendOrder(symIdx, checkUnit.type, TradeModeType == TradeLimitOrders);
            break;
    }
    
    if(result > -1) {
        checkUnit.fulfilled = true;
        setLastTimePoint(symIdx, true);
        positionOpenCount[symIdx]++;
    }
    return result;
}

int OrderManager::sendOrder(int symIdx, SignalType signal, bool isPending) {
    string posSymName = MainSymbolMan.symbols[symIdx].name;
    
    int posCmd;
    if(isPending) { posCmd = (signal == SignalLong ? OP_BUYLIMIT : OP_SELLLIMIT); }
    else { posCmd = (signal == SignalLong ? OP_BUY : OP_SELL); }
    
    double posVolume;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    double posPrice;
    double oppPrice;
    if(signal == SignalLong) { // posCmd % 2 > 0
        // Buy, Buy Limit, or Buy Stop (even idxes)
        posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
        oppPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
    } else { 
        // Sell, Sell Limit, or Sell Stop (odd idxes)
        posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
        oppPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
    } 
    
    int posSlippage = 40; // todo: slippage
    
    double stoplossOffset, takeprofitOffset;
    if(StopLossEnabled) {
        double stoplossOffsetPips;
        if(!getValue(stoplossOffsetPips, stopLossLoc, symIdx)) { return -1; }
        Error::PrintInfo("stoplossOffsetPips: " + stoplossOffsetPips);
        stoplossOffset = PipsToPrice(posSymName, stoplossOffsetPips);
    }
    if(TakeProfitEnabled) {
        double takeprofitOffsetPips;
        if(!getValue(takeprofitOffsetPips, takeProfitLoc, symIdx)) { return -1; }
        takeprofitOffset = PipsToPrice(posSymName, takeprofitOffsetPips);
    }
    
    double posStoploss = stoplossOffset == 0 ? 0
        : (signal == SignalLong) ? oppPrice + stoplossOffset : oppPrice - stoplossOffset
        ;
    double posTakeprofit = takeprofitOffset == 0 ? 0
        : (signal == SignalLong) ? oppPrice + takeprofitOffset : oppPrice - takeprofitOffset
        ;
    
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    datetime posExpiration = 0;
    
#ifdef _OrderReliable
    return OrderSendReliable(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
#else
    if(BrokerTwoStep && (posStoploss > 0 || posTakeprofit > 0)) {
        int result = OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, 0, 0, posComment, posMagic, posExpiration);
        if(result > -1) {
            if(!OrderModify(result, posPrice, posStoploss, posTakeprofit, posExpiration)) {
                Error::PrintError(ErrorFatal, "Could not set stop loss/take profit for order " + result, FunctionTrace, NULL, true);
            }
        }
        return result;
    } else {
        return OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
    }
#endif
}

int OrderManager::sendGrid(int symIdx, SignalType signal) {
    // todo: grid - smarter entry rules on pendings. Only enter when no pendings exist on the symbol? Or no trades at all on the symbol?

    if(signal == gridDirection[symIdx]) { return -1; } // only one grid set at a time
        // gridDirection is set after successful setup, and reset after closing

    string posSymName = MainSymbolMan.symbols[symIdx].name;
    double posVolume;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    int posSlippage = 40; // todo: slippage
    
    double stoplossOffset, takeprofitOffset;
    if(StopLossEnabled) {
        double stoplossOffsetPips;
        if(!getValue(stoplossOffsetPips, stopLossLoc, symIdx)) { return -1; }
        stoplossOffset = PipsToPrice(posSymName, stoplossOffsetPips);
    }
    if(TakeProfitEnabled) {
        double takeprofitOffsetPips;
        if(!getValue(takeprofitOffsetPips, takeProfitLoc, symIdx)) { return -1; }
        takeprofitOffset = PipsToPrice(posSymName, takeprofitOffsetPips);
    }
    
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    datetime posExpiration = 0;
    // datetime posExpiration
    
    double priceBaseSignal = (signal == SignalLong) ? SymbolInfoDouble(posSymName, SYMBOL_ASK) : SymbolInfoDouble(posSymName, SYMBOL_BID);
    double priceBaseHedge = (signal == SignalLong) ? SymbolInfoDouble(posSymName, SYMBOL_BID) : SymbolInfoDouble(posSymName, SYMBOL_ASK);
    
    double priceDistPips; 
    if(!getValue(priceDistPips, gridDistanceLoc, symIdx)) { return -1; }
    double priceDistPoints = PipsToPrice(posSymName, priceDistPips);
    double priceDistSignal = (signal == SignalLong) ? priceDistPoints : priceDistPoints*-1;
    double priceDistHedge = priceDistSignal*-1;
    
    int cmdSignal = (signal == SignalLong) ? OP_BUYSTOP : OP_SELLSTOP;
    int cmdHedge = (signal == SignalLong) ? OP_SELLSTOP : OP_BUYSTOP;
    int resultSignal, resultHedge;
    int finalResult;
    for(int i = 1; i <= GridCount; i++) {
        double posPriceSignal = priceBaseSignal+(priceDistSignal*i);
        double posPriceHedge = priceBaseHedge+(priceDistHedge*i);
        double posStoploss = stoplossOffset == 0 ? 0
            : cmdSignal == OP_BUYSTOP ? posPriceHedge + (stoplossOffset*i) : posPriceHedge - (stoplossOffset*i)
            ; // opposite price of signal
        double posTakeprofit = takeprofitOffset == 0 ? 0
            : cmdSignal == OP_BUYSTOP ? posPriceHedge + (takeprofitOffset*i) : posPriceHedge - (takeprofitOffset*i)
            ;
            
#ifdef _OrderReliable
        resultSignal = OrderSendReliable(posSymName, cmdSignal, posVolume, posPriceSignal, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
#else
        if(BrokerTwoStep && (posStoploss > 0 || posTakeprofit > 0)) {
            resultSignal = OrderSend(posSymName, cmdSignal, posVolume, posPriceSignal, posSlippage, 0, 0, posComment, posMagic, posExpiration);
            if(resultSignal > -1) {
                if(!OrderModify(resultSignal, posPriceSignal, posStoploss, posTakeprofit, posExpiration)) {
                    Error::PrintError(ErrorFatal, "Could not set stop loss/take profit for order " + resultSignal, FunctionTrace, NULL, true);
                }
            }
        } else {
            resultSignal = OrderSend(posSymName, cmdSignal, posVolume, posPriceSignal, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
        }
#endif
        if(resultSignal > -1) { finalResult++; }
        
        if(GridHedging) {
            posStoploss = 
                stoplossOffset == 0 ? 0 
                : cmdHedge == OP_BUYSTOP ? posPriceSignal + (stoplossOffset*i) : posPriceSignal - (stoplossOffset*i)
                ; // opposite price of hedge
            posTakeprofit = 
                takeprofitOffset == 0 ? 0 
                : cmdHedge == OP_BUYSTOP ? posPriceSignal + (takeprofitOffset*i) : posPriceSignal - (takeprofitOffset*i)
                ;

#ifdef _OrderReliable            
            resultHedge = OrderSendReliable(posSymName, cmdHedge, posVolume, posPriceHedge, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
#else
            if(BrokerTwoStep && (posStoploss > 0 || posTakeprofit > 0)) {
                resultHedge = OrderSend(posSymName, cmdHedge, posVolume, posPriceHedge, posSlippage, 0, 0, posComment, posMagic, posExpiration);
                if(resultHedge > -1) {
                    if(!OrderModify(resultHedge, posPriceHedge, posStoploss, posTakeprofit, posExpiration)) {
                        Error::PrintError(ErrorFatal, "Could not set stop loss/take profit for order " + resultHedge, FunctionTrace, NULL, true);
                    }
                }
            } else {
                resultHedge = OrderSend(posSymName, cmdHedge, posVolume, posPriceHedge, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
            }
#endif
            if(resultHedge > -1) { finalResult++; }
        }
    }
    
    // todo: grid - check if all pendings succeeded
    gridDirection[symIdx] = signal;
    
    return finalResult;
}
