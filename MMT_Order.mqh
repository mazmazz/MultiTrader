//+------------------------------------------------------------------+
//|                                                    MMT_Order.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

#include "MC_Common/MC_Common.mqh"
#include "MMT_Symbols.mqh"
#include "MMT_Filters/MMT_FilterManager.mqh"
#include "MMT_Data/MMT_DataHistory.mqh"
//#include "depends/OrderReliable.mqh"
#include "depends/PipFactor.mqh"

enum StopLossMode {
    StopModeNormal
    , StopModeValue
    , StopModeTrailing
    , StopModeJumping
    , StopModeBreakeven
};

class ValueLocation {
    public:
    CalcMethod calcType;
    int filterIdx;
    int subIdx;
    double setVal;
    double factor;
};

class OrderManager {
    public:
    OrderManager();
    ~OrderManager();
    
    void doPositions(bool firstRun);
    
    private:
    ValueLocation *stopLossLoc;
    ValueLocation *takeProfitLoc;
    ValueLocation *maxSpreadLoc;
    ValueLocation *maxSlippageLoc;
    ValueLocation *lotSizeLoc;
    ValueLocation *breakEvenLoc;
    ValueLocation *gridDistanceLoc;
    
    TimePoint *lastTradeBetween[]; // keyed by symbolId
    TimePoint *lastValueBetween[];
    int positionOpenCount[];
    
    SignalType gridDirection[];
    bool gridExit[];
    bool gridExitByOpposite[];
    
    void initValueLocations();
    ValueLocation *fillValueLocation(CalcMethod calcTypeIn, double setValIn, string filterNameIn, double factorIn);
    
    void doCurrentPositions(bool firstRun);
    void doChangePosition(int ticket, int symIdx);
    bool doExitPosition(int ticket, int symIdx);
    int doEnterPosition(int symIdx);
    int sendOrder(int symIdx, SignalType signal, bool isPending);
    int sendGrid(int symIdx, SignalType signal);
    
    double getValue(ValueLocation *loc, int symbolIdx);
    template <typename T>
    bool getValue(T &outVal, ValueLocation *loc, int symbolIdx);
    void setLastTimePoint(int symbolIdx, bool isLastTrade, uint millisecondsIn = 0, datetime dateTimeIn = 0, uint cyclesIn = 0);
    bool getLastTimeElapsed(int symbolIdx, bool isLastTrade, TimeUnits compareUnit, int delayCompare);
    
    double calculateStopLoss();
    double calculateTakeProfit();
    double calculateLotSize();
    double calculateMaxSpread();
    double calculateMaxSlippage();
};

void OrderManager::OrderManager() {
    ArrayResize(positionOpenCount, ArraySize(MainSymbolMan.symbols));
    ArrayInitialize(positionOpenCount, 0);
    if(TradeModeType == TradeGrid) { 
        ArrayResize(gridDirection, ArraySize(MainSymbolMan.symbols));
        ArrayInitialize(gridDirection, SignalNone);
    }
    if(TradeBetweenDelay > 0 ) { ArrayResize(lastTradeBetween, ArraySize(MainSymbolMan.symbols)); }
    if(ValueBetweenDelay > 0 ) { ArrayResize(lastValueBetween, ArraySize(MainSymbolMan.symbols)); }
    
    initValueLocations();
}

void OrderManager::~OrderManager() {
    Common::SafeDeletePointerArray(lastTradeBetween);
    Common::SafeDeletePointerArray(lastValueBetween);

    Common::SafeDelete(lotSizeLoc);
    Common::SafeDelete(breakEvenLoc);
    Common::SafeDelete(stopLossLoc);
    Common::SafeDelete(takeProfitLoc);
    Common::SafeDelete(maxSpreadLoc);
    Common::SafeDelete(maxSlippageLoc);
    Common::SafeDelete(gridDistanceLoc);
}

void OrderManager::initValueLocations() {
    maxSpreadLoc = fillValueLocation(MaxSpreadCalcMethod, MaxSpreadValue, MaxSpreadFilterName, MaxSpreadFilterFactor);
    maxSlippageLoc = fillValueLocation(MaxSlippageCalcMethod, MaxSlippageValue, MaxSlippageFilterName, MaxSlippageFilterFactor);
    lotSizeLoc = fillValueLocation(LotSizeCalcMethod, LotSizeValue, LotSizeFilterName, LotSizeFilterFactor);
    stopLossLoc = fillValueLocation(StopLossCalcMethod, StopLossValue, StopLossFilterName, StopLossFilterFactor);
    takeProfitLoc = fillValueLocation(TakeProfitCalcMethod, TakeProfitValue, TakeProfitFilterName, TakeProfitFilterFactor);
    breakEvenLoc = fillValueLocation(BreakEvenCalcMethod, BreakEvenValue, BreakEvenFilterName, BreakEvenFilterFactor);
    gridDistanceLoc = fillValueLocation(GridDistanceCalcMethod, GridDistanceValue, GridDistanceFilterName, GridDistanceFilterFactor);
}

ValueLocation *OrderManager::fillValueLocation(CalcMethod calcTypeIn, double setValIn, string filterNameIn, double factorIn) {
    ValueLocation *targetLoc = new ValueLocation();
    
    targetLoc.calcType = calcTypeIn;
    if(calcTypeIn == CalcValue) {
        targetLoc.setVal = setValIn;
    } else {
        targetLoc.filterIdx = MainFilterMan.getFilterId(filterNameIn);
        targetLoc.subIdx = MainFilterMan.getSubfilterId(filterNameIn);
        targetLoc.factor = factorIn;
    }
    
    return targetLoc;
}

//+------------------------------------------------------------------+

void OrderManager::doPositions(bool firstRun) {
    // todo: separate cycles for updating vs. enter/exit?
    doCurrentPositions(firstRun);
    
    int symbolCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symbolCount; i++) {
        if(gridExit[i]) {
            if(!gridExitByOpposite[i]) {
                SignalUnit *checkUnit = MainDataMan.symbol[i].getSignalUnit(false);
                if(!Common::IsInvalidPointer(checkUnit)) { 
                    checkUnit.fulfilled = true;
                }
            } else { gridExitByOpposite[i] = false; }
            
            positionOpenCount[i]--;
            gridExit[i] = false;
        }
    
        doEnterPosition(i);
    }
}

void OrderManager::doCurrentPositions(bool firstRun) {
    for(int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderMagicNumber() != MagicNumber) { continue; }
        int symbolIdx = MainSymbolMan.getSymbolId(OrderSymbol());
        positionOpenCount[symbolIdx]++;
        
        if(firstRun) { // if signal already exists for open order, raise fulfilled flag so no repeat is opened
            int orderAct = OrderType();
            SignalUnit *checkEntrySignal = MainDataMan.symbol[symbolIdx].getSignalUnit(true);
            if(!Common::IsInvalidPointer(checkEntrySignal)) {
                if(
                    ((orderAct % 2 == 0)/*buy*/ && checkEntrySignal.type == SignalLong)
                    || ((orderAct % 2 > 0)/*sell*/ && checkEntrySignal.type == SignalShort)
                ) { checkEntrySignal.fulfilled = true; }
            }
        }
        
        // todo: cache pending value and exit updates?
        bool exitResult = doExitPosition(OrderTicket(), symbolIdx);
        if(!exitResult) {
            doChangePosition(OrderTicket(), symbolIdx);
        }
    }
    
    // set symbol exit signal fulfilled and positionOpenCount[symIdx]-- in doPositions loop so we don't loop an extra time
}

//+------------------------------------------------------------------+

void OrderManager::doChangePosition(int ticket, int symIdx) {
    // For each setting (sltp, etc) retrieve filter value and update if necessary
    if(!TradeValueEnabled) { return; }
    if(!getLastTimeElapsed(symIdx, false, TimeSettingUnit, ValueBetweenDelay)) { return; }
    
    // setLastTimePoint(symIdx, false);
}

//+------------------------------------------------------------------+

bool OrderManager::doExitPosition(int ticket, int symIdx) {
    if(TradeModeType != TradeGrid && !TradeExitEnabled) { return false; }

    if(OrderTicket() != ticket) { 
        if(!OrderSelect(ticket, SELECT_BY_TICKET)) { return false; } 
    }
    string posSymName = OrderSymbol();
    
    // todo: grid -- how to close pendings when encountering an opposite signal?
    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(false);
    if(Common::IsInvalidPointer(checkUnit)) { return false; }
    
    bool checkOpp;
    SignalUnit *oppCheckUnit;
    if(CloseOrderOnOppositeSignal || TradeModeType == TradeGrid) {
        oppCheckUnit = MainDataMan.symbol[symIdx].getSignalUnit(true);
        checkOpp = !Common::IsInvalidPointer(oppCheckUnit);
    }
    
    if(
        (checkOpp && checkUnit.fulfilled && oppCheckUnit.fulfilled)
        || (!checkOpp && checkUnit.fulfilled)
    ) { return false; }
    
    int posType = OrderType();
    bool posIsBuy = (posType % 2 == 0);
    
    bool oppIsTrigger,exitIsTrigger;
    if(!checkOpp) { 
        if(checkUnit.type != SignalLong && checkUnit.type != SignalShort) { return false; }
        if(posIsBuy && checkUnit.type == SignalLong) { return false; } // signals are negated for exits -- "SignalLong" means Buy OK, close Shorts.
        else if(!posIsBuy && checkUnit.type == SignalShort) { return false; }
        else { exitIsTrigger = true; }
    }
    else {
        bool checkIsEmpty, oppIsEmpty;
        if(checkUnit.type != SignalLong && checkUnit.type != SignalShort) { checkIsEmpty = true; }
        if(oppCheckUnit.type != SignalLong && oppCheckUnit.type != SignalShort) { oppIsEmpty = true; }
        if(checkIsEmpty && oppIsEmpty) { return false; }
        if(posIsBuy) {
            if(!checkIsEmpty && checkUnit.type == SignalLong) { return false; }
            if(!oppIsEmpty && oppCheckUnit.type == SignalLong) { return false; }
            
            if(!checkIsEmpty && checkUnit.type == SignalShort) { exitIsTrigger = true; }
            if(!exitIsTrigger && !oppIsEmpty && oppCheckUnit.type == SignalShort) { oppIsTrigger = true; }
        } else {
            if(!checkIsEmpty && checkUnit.type == SignalShort) { return false; }
            if(!oppIsEmpty && oppCheckUnit.type == SignalShort) { return false; }
            
            if(!checkIsEmpty && checkUnit.type == SignalLong) { exitIsTrigger = true; }
            if(!exitIsTrigger && !oppIsEmpty && oppCheckUnit.type == SignalLong) { oppIsTrigger = true; }
        } 
    }
    
    if(!exitIsTrigger && !oppIsTrigger) { 
        Error::ThrowError(ErrorNormal, "Neither exit nor opp is trigger", FunctionTrace, posSymName +"|"+posType, true);
    }
    
    // todo: retracement protection?
    
    double posLots = OrderLots();
    double posPrice; 
    if(posType % 2 > 0) { posPrice = MarketInfo(posSymName, MODE_ASK); } // Sell order, odd idx
    else { MarketInfo(posSymName, MODE_BID); } // Buy order, even idx
    int posSlippage = 40; // todo: get slippage from filter?
    
    bool result = 
        posType == OP_BUY || posType == OP_SELL ? OrderClose(ticket, posLots, posPrice, posSlippage)
        : OrderDelete(ticket) // pending order
        ;
    if(result) {
        if(TradeModeType != TradeGrid) { 
            if(exitIsTrigger) { checkUnit.fulfilled = true; } // do not set opposite entry fulfilled; that's set by entry action
            positionOpenCount[symIdx]--;
        } else {
            // set flag to indicate fulfillment set
            // todo: how to handle failures?
            gridExit[symIdx] = true;
            gridExitByOpposite[symIdx] = oppIsTrigger;
        }
    }
    return result;
}

//+------------------------------------------------------------------+

int OrderManager::doEnterPosition(int symIdx) {
    if(!TradeEntryEnabled) { return 0; }
    if(!getLastTimeElapsed(symIdx, true, TimeSettingUnit, TradeBetweenDelay)) { return 0; }
    if(AccountInfoDouble(ACCOUNT_MARGIN) > 0 && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < TradeMinMarginLevel) { return 0; }
    if(TradeModeType != TradeGrid && MaxTradesPerSymbol > 0 && MaxTradesPerSymbol <= positionOpenCount[symIdx]) { return 0; }

    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(true);
    if(Common::IsInvalidPointer(checkUnit)) { return 0; }
    else if(checkUnit.fulfilled) { return 0; }
    
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
    
    int posSlippage = 40; // todo: get slippage
    
    double stoplossOffsetPips;
    if(!getValue(stoplossOffsetPips, stopLossLoc, symIdx)) { return -1; }
    double takeprofitOffsetPips;
    if(!getValue(takeprofitOffsetPips, takeProfitLoc, symIdx)) { return -1; }
    double stoplossOffset = PipsToPrice(posSymName, stoplossOffsetPips);
    double takeprofitOffset = PipsToPrice(posSymName, takeprofitOffsetPips);
    
    double posStoploss = stoplossOffset == 0 ? 0
        : (signal == SignalLong) ? oppPrice + stoplossOffset : oppPrice - stoplossOffset
        ;
    double posTakeprofit = takeprofitOffset == 0 ? 0
        : (signal == SignalLong) ? oppPrice + takeprofitOffset : oppPrice - takeprofitOffset
        ;
    
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    // datetime posExpiration
    
    return OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic);
}

int OrderManager::sendGrid(int symIdx, SignalType signal) {
    if(signal == gridDirection[symIdx]) { return 0; /* closeGridPendings(); */ } // only one grid set at a time // or close current grid and reset with new price? 
        // gridDirection is set after successful setup, and reset after closing

    string posSymName = MainSymbolMan.symbols[symIdx].name;
    double posVolume;
    if(!getValue(posVolume, lotSizeLoc, symIdx)) { return -1; }
    
    int posSlippage = 40; // todo: get slippage
    
    double stoplossOffsetPips;
    if(!getValue(stoplossOffsetPips, stopLossLoc, symIdx)) { return -1; }
    double takeprofitOffsetPips;
    if(!getValue(takeprofitOffsetPips, takeProfitLoc, symIdx)) { return -1; }
    double stoplossOffset = PipsToPrice(posSymName, stoplossOffsetPips);
    double takeprofitOffset = PipsToPrice(posSymName, takeprofitOffsetPips);
    
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    // datetime posExpiration
    
    double priceBaseSignal = (signal == SignalLong) ? SymbolInfoDouble(posSymName, SYMBOL_ASK) : SymbolInfoDouble(posSymName, SYMBOL_BID);
    double priceBaseHedge = (signal == SignalLong) ? SymbolInfoDouble(posSymName, SYMBOL_BID) : SymbolInfoDouble(posSymName, SYMBOL_ASK);
    
    double priceDistPips; 
    if(!getValue(priceDistPips, gridDistanceLoc, symIdx)) { return -1; }
    double priceDistPoints = PipsToPrice(posSymName, priceDistPips);
    int priceDistSignal = (signal == SignalLong) ? priceDistPoints : priceDistPoints*-1;
    int priceDistHedge = priceDistSignal*-1;
    
    int cmdSignal = (signal == SignalLong) ? OP_BUYSTOP : OP_SELLSTOP;
    int cmdHedge = (signal == SignalLong) ? OP_SELLSTOP : OP_BUYSTOP;
    int resultSignal, resultHedge;
    for(int i = 1; i <= GridCount; i++) {
        // todo: calc stoploss and takeprofit here based on price
        double posPriceSignal = priceBaseSignal+(priceDistSignal*i);
        double posPriceHedge = priceBaseHedge+(priceDistHedge*i);
        double posStoploss = stoplossOffset == 0 ? 0
            : cmdSignal == OP_BUYSTOP ? posPriceHedge + stoplossOffset : posPriceHedge - stoplossOffset
            ; // opposite price of signal
        double posTakeprofit = takeprofitOffset == 0 ? 0
            : cmdSignal == OP_BUYSTOP ? posPriceHedge + takeprofitOffset : posPriceHedge - takeprofitOffset
            ;
            
        resultSignal = OrderSend(posSymName, cmdSignal, posVolume, posPriceSignal, posSlippage, posStoploss, posTakeprofit, posComment, posMagic);
        
        if(GridHedging) {
            posStoploss = cmdHedge == OP_BUYSTOP ? posPriceSignal + stoplossOffset : posPriceSignal - stoplossOffset; // opposite price of hedge
            posTakeprofit = cmdHedge == OP_BUYSTOP ? posPriceSignal + takeprofitOffset : posPriceSignal - takeprofitOffset;
            resultHedge = OrderSend(posSymName, cmdHedge, posVolume, posPriceHedge, posSlippage, posStoploss, posTakeprofit, posComment, posMagic);
        }
    }
    
    // todo: check if all pendings succeeded
    gridDirection[symIdx] = signal;
    
    return 0;
}

//+------------------------------------------------------------------+

double OrderManager::getValue(ValueLocation *loc, int symbolIdx) {
    double finalVal;
    getValue(finalVal, loc, symbolIdx);
    return finalVal;
}

template <typename T>
bool OrderManager::getValue(T &outVal, ValueLocation *loc, int symbolIdx) {
    if(Common::IsInvalidPointer(loc)) { return false; }
    
    switch(loc.calcType) {
        case CalcValue:
            outVal = loc.setVal;
            return true;
        
        case CalcFilter: {
            DataHistory *filterHist = MainDataMan.getDataHistory(symbolIdx, loc.filterIdx, loc.subIdx);
            if(Common::IsInvalidPointer(filterHist)) { return false; }
            
            DataUnit* filterData = filterHist.getData();
            if(Common::IsInvalidPointer(filterData)) { return false; }
            
            double val;
            if(filterData.getRawValue(val)) {
                outVal = val*loc.factor;
                return true;
            } else { return false; }
        }
        
        default: return false;
    }
}

void OrderManager::setLastTimePoint(int symbolIdx, bool isLastTrade, uint millisecondsIn = 0, datetime dateTimeIn = 0, uint cyclesIn = 0) {
    if(isLastTrade) {
        if(TradeBetweenDelay <= 0) { return; }
        if(!Common::IsInvalidPointer(lastTradeBetween[symbolIdx])) { lastTradeBetween[symbolIdx].update(); }
        else { lastTradeBetween[symbolIdx] = new TimePoint(); }
    } else {
        if(ValueBetweenDelay <= 0) { return; }
        if(!Common::IsInvalidPointer(lastValueBetween[symbolIdx])) { lastValueBetween[symbolIdx].update(); }
        else { lastValueBetween[symbolIdx] = new TimePoint(); }
    }
}

bool OrderManager::getLastTimeElapsed(int symbolIdx, bool isLastTrade, TimeUnits compareUnit, int delayCompare) {
    if(delayCompare <= 0) { return true; }
    
    if(isLastTrade) {
        if(Common::IsInvalidPointer(lastTradeBetween[symbolIdx])) { return true; } // probably uninit'd timepoint, meaning no record, meaning unlimited time passed
    } else {
        if(Common::IsInvalidPointer(lastValueBetween[symbolIdx])) { return true; }
    }
    
    switch(compareUnit) {
        case UnitMilliseconds: 
            if(isLastTrade) { return Common::GetTimeDuration(GetTickCount(), lastTradeBetween[symbolIdx].milliseconds) >= delayCompare; } 
            else { return Common::GetTimeDuration(GetTickCount(), lastValueBetween[symbolIdx].milliseconds) >= delayCompare; }
            
        case UnitSeconds:
            if(isLastTrade) { return Common::GetTimeDuration(TimeCurrent(), lastTradeBetween[symbolIdx].dateTime) >= delayCompare; } 
            else { return Common::GetTimeDuration(TimeCurrent(), lastValueBetween[symbolIdx].dateTime) >= delayCompare; }
            
        case UnitTicks:
            if(isLastTrade) { return lastTradeBetween[symbolIdx].cycles >= delayCompare; } 
            else { return lastValueBetween[symbolIdx].cycles >= delayCompare; }
            
        default: return false;
    }
}

//+------------------------------------------------------------------+

double OrderManager::calculateStopLoss() {
    return 0;
}

double OrderManager::calculateTakeProfit() {
    return 0;
}

double OrderManager::calculateLotSize() {
    return 0;
}

double OrderManager::calculateMaxSpread() {
    return 0;
}

double OrderManager::calculateMaxSlippage() {
    return 0;
}

OrderManager *MainOrderMan;