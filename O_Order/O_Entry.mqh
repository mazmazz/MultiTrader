#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "../D_Data/D_Data.mqh"
#include "../S_Symbol.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "O_Defines.mqh"

bool OrderManager::isEntrySafe(int symIdx) {
    if(!IsTradeAllowed()) { return false; }
    if(SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL) { return false; }
        // MT5: LONGONLY and SHORTONLY
        // MT4: CLOSEONLY, FULL, or DISABLED
    if(!TradeEntryEnabled) { return false; }
    if(!checkBasketSafe()) { return false; }
    
    if(getCurrentSessionIdx(symIdx) >= 0) {
        if(!getOpenByMarketSchedule(symIdx)) { return false; }
    } else { return false; }

    int maxSpread;
    if(!getValuePoints(maxSpread, maxSpreadLoc, symIdx)) { return false; }
    int currentSpread = SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_SPREAD);
    if(currentSpread > maxSpread) { return false; }

    return true;
}

int OrderManager::checkDoEntrySignals(int symIdx) {
    if(!isEntrySafe(symIdx)) { return 0; }
    if(!getLastTimeElapsed(symIdx, true, TimeSettingUnit, TradeBetweenDelay)) { return 0; }
    if(AccountInfoDouble(ACCOUNT_MARGIN) > 0 && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < TradeMinMarginLevel) { return 0; }
    if(!isTradeModeGrid() && MaxTradesPerSymbol > 0 && MaxTradesPerSymbol <= (openPendingCount[symIdx] + openMarketCount[symIdx])) { return 0; }

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
    
    int posCmd, result;
    switch(TradeModeType) {
        case TradeGrid: 
            result = prepareGrid(symIdx, checkUnit.type);
            break;
            
        case TradeMarket: 
        case TradeLimitOrders:
        default: 
            result = prepareSingleOrder(symIdx, checkUnit.type, TradeModeType == TradeLimitOrders);
            break;
    }
    
    if(result > 0) {
        checkUnit.fulfilled = true;
        setLastTimePoint(symIdx, true);
    }
    return result;
}

int OrderManager::prepareSingleOrder(int symIdx, SignalType signal, bool isPending) {
    if(!IsTradeAllowed()) { return -1; }
    
#ifdef __MQL4__
    if(IsTradeContextBusy()) { return -1; }
#endif
    
    string posSymName = MainSymbolMan.symbols[symIdx].name;
    bool isLong = (signal == SignalLong);
    
    int posCmd;
    if(isPending) { posCmd = (isLong ? OP_BUYLIMIT : OP_SELLLIMIT); }
    else { posCmd = (isLong ? OP_BUY : OP_SELL); }
    
    double posVolume;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    double posPrice; //, oppPrice;
    if(isLong) {
        posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
        //oppPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
    } else { 
        posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
        //oppPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
    } 
    
    int posSlippage;
    if(!getValuePoints(posSlippage, maxSlippageLoc, symIdx)) { return -1; }
    
    double posStoploss, posTakeprofit;
    if((StopLossEnabled || TakeProfitEnabled) && (!isPending || SetStopsOnPendings)) {
        if(!getInitialStopLevels(isLong, symIdx, posStoploss, posTakeprofit)) { return -1; }
    }
        
    offsetStopLevels(isLong, posSymName, posStoploss, posTakeprofit);
    
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    datetime posExpiration = 0;
    int result = sendOpenOrder(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
    
    return result;
}

int OrderManager::sendOpenOrder(string posSymName, int posCmd, double posVolume, double posPrice, double posSlippage, double posStoploss, double posTakeprofit, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
    int result;
    
#ifdef _OrderReliable
    result = OrderSendReliable(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
#else
    if(BrokerTwoStep && (posStoploss > 0 || posTakeprofit > 0)) { //  && !Common::OrderIsPending(posCmd)
        result = OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, 0, 0, posComment, posMagic, posExpiration);
        if(result > 0 && OrderSelect(result, SELECT_BY_TICKET)) {
            if(!OrderModify(result, posPrice, posStoploss, posTakeprofit, posExpiration)) {
                Error::PrintError(ErrorFatal, "Could not set stop loss/take profit for order " + result, FunctionTrace, NULL, true);
            }
        }
    } else {
        result = OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
    }
#endif

    if(result > -1) { addOrderToOpenCount(result); }
    
    return result;
}
