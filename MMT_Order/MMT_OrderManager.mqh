//+------------------------------------------------------------------+
//|                                                    MMT_Order.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

#include "../MC_Common/MC_Common.mqh"
#include "../MMT_Symbols.mqh"
#include "../MMT_Filters/MMT_FilterManager.mqh"
#include "../MMT_Data/MMT_DataHistory.mqh"

#include "MMT_Order_Defines.mqh"

#include "MMT_Order_Modify.mqh"
#include "MMT_Order_Entry.mqh"
#include "MMT_Order_Exit.mqh"

void OrderManager::OrderManager() {
    int symCount = ArraySize(MainSymbolMan.symbols);
    ArrayResize(positionOpenCount, symCount);
    ArrayInitialize(positionOpenCount, 0);
    if(TradeModeType == TradeGrid) { 
        ArrayResize(gridDirection, symCount);
        ArrayInitialize(gridDirection, SignalNone);
        ArrayResize(gridExit, symCount);
        ArrayResize(gridExitByOpposite, symCount);
    }
    if(TradeBetweenDelay > 0 ) { ArrayResize(lastTradeBetween, symCount); }
    if(ValueBetweenDelay > 0 ) { ArrayResize(lastValueBetween, symCount); }
    
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
        if(TradeModeType == TradeGrid && gridExit[i]) {
            if(!gridExitByOpposite[i]) {
                SignalUnit *checkUnit = MainDataMan.symbol[i].getSignalUnit(false);
                if(!Common::IsInvalidPointer(checkUnit)) { 
                    checkUnit.fulfilled = true;
                }
            } else { gridExitByOpposite[i] = false; }
            
            positionOpenCount[i]--;
            gridDirection[i] = SignalNone;
            gridExit[i] = false;
        }
    
        doEnterPosition(i);
    }
}

void OrderManager::doCurrentPositions(bool firstRun) {
    for(int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderMagicNumber() != MagicNumber) { 
            continue; 
        }
        int symbolIdx = MainSymbolMan.getSymbolId(OrderSymbol());
        
        if(firstRun) { // if signal already exists for open order, raise fulfilled flag so no repeat is opened
            if(TradeModeType != TradeGrid) { positionOpenCount[symbolIdx]++; }
            else { positionOpenCount[symbolIdx] = 1; }
            int orderAct = OrderType();
            SignalUnit *checkEntrySignal = MainDataMan.symbol[symbolIdx].getSignalUnit(true);
            if(!Common::IsInvalidPointer(checkEntrySignal)) {
                if(TradeModeType != TradeGrid) {
                    if(
                        ((orderAct % 2 == 0)/*buy*/ && checkEntrySignal.type == SignalLong)
                        || ((orderAct % 2 > 0)/*sell*/ && checkEntrySignal.type == SignalShort)
                    ) { checkEntrySignal.fulfilled = true; }
                } else if(checkEntrySignal.type == SignalLong || checkEntrySignal.type == SignalShort) { checkEntrySignal.fulfilled = true; }
                    // todo: grid - better firstRun rules. set gridDirection by checking if all buy stops are above current price point, etc. ???
            }
        }
        
        // todo: cache pending value and exit updates?
        bool exitResult = doExitPosition(OrderTicket(), symbolIdx);
        if(!exitResult) {
            doChangePosition(OrderTicket(), symbolIdx);
        } else {
            i--; // deleting a position mid-loop changes the index, attempt same index as orders shift
        }
    }
    
    // grid - set symbol exit signal fulfilled and positionOpenCount[symIdx] in doPositions loop so we don't loop an extra time
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
        
        case CalcFilterFactor:
        case CalcFilterExact: {
            DataHistory *filterHist = MainDataMan.getDataHistory(symbolIdx, loc.filterIdx, loc.subIdx);
            if(Common::IsInvalidPointer(filterHist)) { return false; }
            
            DataUnit* filterData = filterHist.getData();
            if(Common::IsInvalidPointer(filterData)) { return false; }
            
            double val;
            if(filterData.getRawValue(val)) {
                if(loc.calcType == CalcFilterFactor) { outVal = val*loc.factor; }
                else { outVal = val; }
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
