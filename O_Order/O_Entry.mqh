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

    int maxSpread = 0;
    if(!getValuePoints(maxSpread, maxSpreadLoc, symIdx)) { return false; }
    int currentSpread = SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_SPREAD);
    if(currentSpread > maxSpread) { return false; }

    return true;
}

int OrderManager::checkDoEntrySignals(int symIdx) {
    if(!isEntrySafe(symIdx)) { return 0; }
    if(!getLastTimeElapsed(symIdx, true, TimeSettingUnit, TradeBetweenDelay)) { return 0; }
    if(AccountInfoDouble(ACCOUNT_MARGIN) > 0 && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < TradeMinMarginLevel) { return 0; }
    if(!isTradeModeGrid() && MaxTradesPerSymbol > 0 && MaxTradesPerSymbol <= (openPendingLongCount[symIdx] + openPendingShortCount[symIdx] + openMarketLongCount[symIdx] + openMarketShortCount[symIdx])) { return 0; }

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
    
    int result = 0;
    bool isLong = checkUnit.type == SignalLong;
    switch(TradeModeType) {
        case TradeGrid:
            // check for swap here: getCloseByMarketSchedule passes daily and 3DS closes as false
            // for grids, we want to enforce the schedule closure despite the swap signal
            // because some orders will be long and others short
            if(SchedClose3DaySwap && getClose3DaySwap(symIdx)) { break; }
            else if(SchedCloseDaily && getCloseDaily(symIdx)) { break; }

            Error::PrintInfo("Open " + MainSymbolMan.symbols[symIdx].name + ": Entry signal - " + EnumToString(checkUnit.type));
            result = prepareGrid(symIdx, checkUnit.type);
            break;
            
        case TradeMarket: 
        case TradeLimitOrders:
        default: 
            // check for swap here: getCloseByMarketSchedule passes daily and 3DS closes as false
            // so we can check for swap closure separately here
            if(SchedClose3DaySwap && SchedCloseBySwap3DaySwap && getClose3DaySwap(symIdx)) {
                if(isSwapThresholdBroken(isLong, symIdx, true)) { break; }
                // todo: do we need to check for SchedCloseOrderOp == OrderOnlyLong && isLong here? i.e., will new longs close immediately?
            }
            else if(SchedCloseDaily && SchedCloseBySwapDaily && getCloseDaily(symIdx)) { 
                if(isSwapThresholdBroken(isLong, symIdx, false)) { break; }
            }

            Error::PrintInfo("Open " + MainSymbolMan.symbols[symIdx].name + ": Entry signal - " + EnumToString(checkUnit.type));
            result = prepareSingleOrder(symIdx, checkUnit.type, TradeModeType == TradeLimitOrders);
            break;
    }
    
    if(result > 0 
        || (TradeModeType == TradeGrid 
            && ((checkUnit.type == SignalLong && gridSetLong[symIdx]) || (checkUnit.type == SignalShort && gridSetShort[symIdx]))
            )
    ) {
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
    
    int posCmd = -1;
    if(isPending) { posCmd = (isLong ? OrderTypeBuyLimit : OrderTypeSellLimit); }
    else { posCmd = (isLong ? OrderTypeBuy : OrderTypeSell); }
    
    double posVolume = 0;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    double posPrice = 0; //, oppPrice;
    if(isLong) {
        posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
        //oppPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
    } else { 
        posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); 
        //oppPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); 
    } 
    
    int posSlippage = 0;
    if(!getValuePoints(posSlippage, maxSlippageLoc, symIdx)) { return -1; }
    
    double posStoploss = 0, posTakeprofit = 0; bool doDrop = false;
    getInitialStopLevels(isLong, symIdx
        , (!isPending || SetStopsOnPendings) && StopLossEnabled, (!isPending || SetStopsOnPendings) && TakeProfitEnabled
        , posStoploss, posTakeprofit
        , doDrop
        );
    
    if(!doDrop) {
        string posComment = OrderComment_;
        int posMagic = MagicNumber;
        datetime posExpiration = 0;
        int result = sendOpen(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
        return result;
    } else { return 0; }
}
