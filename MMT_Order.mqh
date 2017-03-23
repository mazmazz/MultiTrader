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
    
    TimePoint *lastTradeBetween[]; // keyed by symbolId
    TimePoint *lastValueBetween[];
    int positionOpenCount[];
    
    void initValueLocations();
    ValueLocation *fillValueLocation(CalcMethod calcTypeIn, double setValIn, string filterNameIn, double factorIn);
    
    void doCurrentPositions(bool firstRun);
    void doChangePosition(int ticket, int symIdx);
    bool doExitPosition(int ticket, int symIdx);
    int doEnterPosition(int symIdx);
    
    double getValue(ValueLocation *loc, int symbolIdx);
    template <typename T>
    bool getValue(T outVal, ValueLocation *loc, int symbolIdx);
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
}

void OrderManager::initValueLocations() {
    maxSpreadLoc = fillValueLocation(MaxSpreadCalcMethod, MaxSpreadValue, MaxSpreadFilterName, MaxSpreadFilterFactor);
    maxSlippageLoc = fillValueLocation(MaxSlippageCalcMethod, MaxSlippageValue, MaxSlippageFilterName, MaxSlippageFilterFactor);
    lotSizeLoc = fillValueLocation(LotSizeCalcMethod, LotSizeValue, LotSizeFilterName, LotSizeFilterFactor);
    stopLossLoc = fillValueLocation(StopLossCalcMethod, StopLossValue, StopLossFilterName, StopLossFilterFactor);
    takeProfitLoc = fillValueLocation(TakeProfitCalcMethod, TakeProfitValue, TakeProfitFilterName, TakeProfitFilterFactor);
    breakEvenLoc = fillValueLocation(BreakEvenCalcMethod, BreakEvenValue, BreakEvenFilterName, BreakEvenFilterFactor);
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
                    (orderAct == OP_BUY && checkEntrySignal.type == SignalLong)
                    || (orderAct == OP_SELL && checkEntrySignal.type == SignalShort)
                ) { checkEntrySignal.fulfilled = true; }
            }
        }
        
        // todo: cache pending value and exit updates?
        doChangePosition(OrderTicket(), symbolIdx);
        doExitPosition(OrderTicket(), symbolIdx);
    }
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
    if(!TradeExitEnabled) { return true; }

    if(OrderTicket() != ticket) { 
        if(!OrderSelect(ticket, SELECT_BY_TICKET)) { return false; } 
    }
    string posSymName = OrderSymbol();
    //int symIdx = MainSymbolMan.getSymbolId(posSymName);
    
    SignalUnit *checkUnit = MainDataMan.symbol[symIdx].getSignalUnit(false);
    if(Common::IsInvalidPointer(checkUnit)) { return true; }
    else if(checkUnit.fulfilled) { return true; }
    
    if(checkUnit.type != SignalLong && checkUnit.type != SignalShort) { return true; }
    
    if(!MainDataMan.symbol[symIdx].getSignalStable(ExitStableTime, TimeSettingUnit, checkUnit)) { return true; }
    
    int posType = OrderType();
    if(posType == OP_BUY && checkUnit.type == SignalLong) { return true; } // signals are negated for exits -- "SignalLong" means Buy OK, close Shorts.
    else if(posType == OP_SELL && checkUnit.type == SignalShort) { return true; }
    
    double posLots = OrderLots();
    double posPrice = posType == OP_SELL ? MarketInfo(posSymName, MODE_ASK) : MarketInfo(posSymName, MODE_BID);
    int posSlippage = 40; // todo: get slippage from filter?
    
    bool result = OrderClose(ticket, posLots, posPrice, posSlippage);
    if(result) {
        checkUnit.fulfilled = true;
        positionOpenCount[symIdx]--;
    }
    return result;
}

//+------------------------------------------------------------------+

int OrderManager::doEnterPosition(int symIdx) {
    if(!TradeEntryEnabled) { return 0; }
    if(!getLastTimeElapsed(symIdx, true, TimeSettingUnit, TradeBetweenDelay)) { return 0; }
    if(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < TradeMinMarginLevel) { return 0; }
    if(MaxTradesPerSymbol > 0 && MaxTradesPerSymbol <= positionOpenCount[symIdx]) { return 0; }

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
    
    string posSymName = MainSymbolMan.symbols[symIdx].name;
    int posCmd = checkUnit.type == SignalLong ? OP_BUY : OP_SELL; // todo: pending orders?
    
    double posVolume = getValue(lotSizeLoc, symIdx);
    
    double posPrice = posCmd == OP_SELL ? MarketInfo(posSymName, MODE_BID) : MarketInfo(posSymName, MODE_ASK);
    
    int posSlippage = 40; // todo: get slippage
    double posStoploss = 0; // todo: get stop loss
    double posTakeprofit = 0; // todo: get take profit
    
    string posComment = OrderComment_;
    int posMagic = MagicNumber;
    // datetime posExpiration
    
    int result = OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic);
    if(result > -1) {
        checkUnit.fulfilled = true;
        setLastTimePoint(symIdx, true);
        positionOpenCount[symIdx]++;
    }
    return result;
}

//+------------------------------------------------------------------+

double OrderManager::getValue(ValueLocation *loc, int symbolIdx) {
    double finalVal;
    getValue(finalVal, loc, symbolIdx);
    return finalVal;
}

template <typename T>
bool OrderManager::getValue(T outVal, ValueLocation *loc, int symbolIdx) {
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