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
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "../D_Data/D_Data.mqh"
#include "../S_Symbol.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "O_Defines.mqh"

bool OrderManager::checkDoExitSchedule(int symIdx, long ticket, bool isPosition) {
    if(getCloseByMarketSchedule(symIdx, ticket, isPosition)) {
        return sendClose(ticket, symIdx, isPosition);
    } else { return false; }
}

bool OrderManager::getCloseByMarketSchedule(int symIdx, long ticket = 0, bool isPosition = false) {
    bool isLong = false;
    
    if(ticket > 0) {
        if(!checkDoSelect(ticket, isPosition)) { return false; }
        isLong = Common::OrderIsLong(getOrderType(isPosition));
    }
    
    return getCloseByMarketSchedule(symIdx, ticket, isLong, isPosition);
}

bool OrderManager::getCloseByMarketSchedule(int symIdx, long ticket, bool isLong, bool isPosition) {
    if(!SchedCloseCustom && !SchedCloseDaily && !SchedCloseSession && !SchedClose3DaySwap && !SchedCloseWeekend) { return false;}

    if(ticket > 0) {
        if(!checkDoSelect(ticket, isPosition)) { return false; }
        
        int orderOp = getOrderType(isPosition);
        
        if(!SchedClosePendings && Common::OrderIsPending(orderOp)) { return false; }
        if(SchedCloseOrderOp == OrderOnlyLong && !Common::OrderIsLong(orderOp)) { return false; }
        if(SchedCloseOrderOp == OrderOnlyShort && !Common::OrderIsShort(orderOp)) { return false; }
        if(SchedCloseOrderProfit == OrderOnlyProfitable && getProfitPips(ticket, isPosition) < 0) { return false; } // todo: do this properly: refer to pips? include swaps?
        if(SchedCloseOrderProfit == OrderOnlyLoss && getProfitPips(ticket, isPosition) >= 0) { return false; }
    }
    
    if(SchedCloseCustom && getCloseCustom(symIdx)) {
        if(ticket > 0) { Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Schedule custom", true); }
        return true; 
    }
    else if(SchedClose3DaySwap && getClose3DaySwap(symIdx)) {
        if(ticket > 0) { 
            if(SchedCloseBySwap3DaySwap && !isSwapThresholdBroken(isLong, symIdx, true)) { return false; }
            Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Schedule 3-day swap", true); 
        } else {
            if(SchedCloseBySwap3DaySwap) { return false; } // allow checkDoEntrySignals to call isSwapThresholdBroken separately
        }
        return true; 
    }
    else if(SchedCloseDaily && getCloseDaily(symIdx)) {
        if(ticket > 0) { 
            if(SchedCloseBySwapDaily && !isSwapThresholdBroken(isLong, symIdx, false)) { return false; }
            Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Schedule daily", true); 
        } else {
            if(SchedCloseBySwapDaily) { return false; } // allow checkDoEntrySignals to call isSwapThresholdBroken separately
        }
        return true; 
    }
    else if(SchedCloseWeekend && getCloseWeekend(symIdx)) {
        if(ticket > 0) { Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Schedule weekend", true); }
        return true; 
    }
    else if(SchedCloseSession && getCloseOffSessions(symIdx)) { 
        if(ticket > 0) { Error::PrintInfo("Close " + (isPosition ? "position " : "order ") + ticket + ": Schedule end of session", true); }
        return true; 
    }
    else { 
        return false; 
    }
}

bool OrderManager::getCloseDaily(int symIdx) {
    int sessCount = getSessionCountByWeekday(symIdx, DayOfWeek());
    if(sessCount <= 0) { return false; }

    // if current session is last of the day, check if we're within SchedCloseMinutes of closing
    datetime from, to, dt = Common::StripDateFromDatetime(TimeCurrent());
    int sessCurrent = getCurrentSessionIdx(symIdx, from, to, dt);
    if(sessCurrent == (sessCount-1)) {
        return (dt >= to-(MathMax(1, SchedCloseMinutes)*60)); // todo: what if cycle length does not hit this check?
    } else { return false; }
}

bool OrderManager::getClose3DaySwap(int symIdx) {
    if(DayOfWeek() == SymbolInfoInteger(MainSymbolMan.symbols[symIdx].name, SYMBOL_SWAP_ROLLOVER3DAYS)) { 
        return getCloseDaily(symIdx);
    } else { return false; }
}

bool OrderManager::getCloseWeekend(int symIdx) {
    // weekend: tomorrow has no sessions at all
    
    // if today has sessions and tomorrow has no sessions, do getCloseDaily
    int curDay = DayOfWeek();
    int nextDay = (curDay == SATURDAY) ? SUNDAY : curDay + 1;

    if(getSessionCountByWeekday(symIdx, curDay) > 0 && getSessionCountByWeekday(symIdx, nextDay) <= 0) {
        return getCloseDaily(symIdx);
    } else { return false; }
}

bool OrderManager::getCloseOffSessions(int symIdx) {
    int sessCount = getSessionCountByWeekday(symIdx, DayOfWeek());
    if(sessCount <= 0) { return false; }

    // off session: current day (or midnight) has a session gap exceeding SchedGapIgnoreMinutes
    datetime dt = Common::StripDateFromDatetime(TimeCurrent());
    datetime fromCurrent = 0, toCurrent = 0; 
    int weekdayCurrent = DayOfWeek();
    int sessCurrent = getCurrentSessionIdx(symIdx, fromCurrent, toCurrent, dt, weekdayCurrent);
    if(sessCurrent < 0) { return false; }
    
    datetime fromNext = 0, toNext = 0; 
    int weekdayNext = -1, sessNext = -1;
    if(sessCurrent == (sessCount - 1)) { 
        sessNext = 0;
        weekdayNext = (weekdayCurrent == SATURDAY) ? SUNDAY : weekdayCurrent + 1; 
    }
    else { 
        sessNext = sessCurrent + 1;
        weekdayNext = weekdayCurrent; 
    }
    
    if(SchedGapIgnoreMinutes > 0 && SymbolInfoSessionTrade(MainSymbolMan.symbols[symIdx].name, (ENUM_DAY_OF_WEEK)weekdayNext, sessNext, fromNext, toNext)) {
        int gap = fromNext - toCurrent;
        if(gap <= SchedGapIgnoreMinutes*60) { return false; }
    }
    
    return (dt >= toCurrent-(MathMax(1, SchedCloseMinutes)*60)); // todo: what if cycle length does not hit this check?
}

//+------------------------------------------------------------------+

bool OrderManager::getOpenByMarketSchedule(int symIdx) {
    if(getCloseByMarketSchedule(symIdx)) { return false; }
    
    // Custom schedule needs no processing: entry delays do not apply to custom opening times
    // Custom schedule only governs when entries need to be closed
    
    if(SchedOpenMinutesWeekend <= 0 && SchedOpenMinutesDaily <= 0 && SchedOpenMinutesSession <= 0) { return true; }
    
    datetime fromCur = 0, toCur = 0, dt = Common::StripDateFromDatetime(TimeCurrent()); int dayCur = DayOfWeek();
    int sessCount = getSessionCountByWeekday(symIdx, dayCur);
    int sessCur = getCurrentSessionIdx(symIdx, fromCur, toCur, dt, dayCur);
    if(sessCur < 0) { return false; }
    
    
    int dayPrev = 0, sessPrev = 0, sessCountPrev = 0;
    if(sessCur == 0) { 
        if(SchedOpenMinutesWeekend <= 0 && SchedOpenMinutesDaily <= 0) { return true; }
        
        dayPrev = (dayCur == SUNDAY) ? SATURDAY : dayCur - 1;
        sessCountPrev = getSessionCountByWeekday(symIdx, dayPrev); // weekend: are we in first session of today AND yesterday had no sessions?
        
        int minutesOffset = sessCountPrev <= 0 ? SchedOpenMinutesWeekend : SchedOpenMinutesDaily; 
        return (dt >= fromCur + (minutesOffset*60));
    } else { 
        if(SchedOpenMinutesSession <= 0) { return true; }
        sessPrev = sessCur - 1;
        dayPrev = dayCur;
        
        int fromCompare = fromCur;
        datetime fromPrev = 0, toPrev = 0;
        if(SchedGapIgnoreMinutes > 0 && sessCountPrev > 0 && SymbolInfoSessionTrade(MainSymbolMan.symbols[symIdx].name, (ENUM_DAY_OF_WEEK)dayPrev, sessPrev, fromPrev, toPrev)) {
            int gap = fromCur - toPrev;
            if(gap <= SchedGapIgnoreMinutes*60) { return true; } 
                // todo: ideally we set fromCompare = fromPrev so we can compare from last session open, but this doesn't work because of wraparound. we need to compare dates as part of datetime
                // for now, just return true
        }
        
        return (dt >= fromCompare + (SchedOpenMinutesSession*60));
    }
}

//+------------------------------------------------------------------+

int OrderManager::getCurrentSessionIdx(int symIdx, datetime dt = 0, int weekday = -1) {
    datetime from = 0, to = 0;
    return getCurrentSessionIdx(symIdx, from, to, dt, weekday);
}

int OrderManager::getCurrentSessionIdx(int symIdx, datetime &fromOut, datetime &toOut, datetime dt = 0, int weekday = -1) {
    if(dt <= 0) { dt = TimeCurrent(); }
    dt = Common::StripDateFromDatetime(dt);
    if(weekday < 0 || weekday >= 7) { weekday = DayOfWeek(); }
    
    datetime from, to; int sessCount = -1; string symName = MainSymbolMan.symbols[symIdx].name;
    while(SymbolInfoSessionTrade(symName, (ENUM_DAY_OF_WEEK)weekday, ++sessCount, from, to)) { 
        if(dt >= from && dt < to) { 
            fromOut = from;
            toOut = to;
            return sessCount; 
        }
    }
    
    return -1;
}

int OrderManager::getSessionCountByWeekday(int symIdx, int weekday) {
    datetime from, to; int sessCount = -1; string symName = MainSymbolMan.symbols[symIdx].name;
    while(SymbolInfoSessionTrade(symName, (ENUM_DAY_OF_WEEK)weekday, ++sessCount, from, to)) { }
    
    return sessCount;
}

//+------------------------------------------------------------------+

void OrderManager::initCustomSchedule() {
    if(!SchedCloseCustom) { return; }
    
    customScheduleNextIdx = -1;
    customSchedulePrevIdx = -1;
    
    if(!MultiSettings::ParseScheduleList(SchedCustom, customScheduleUnits)) { return; }
}

bool OrderManager::getCloseCustom(int symIdx) {
    // symIdx can be used in future for symbol-specific closes
    int size = ArraySize(customScheduleUnits);
    if(!SchedCloseCustom || size <= 0) { return false; }
    
    datetime currentDatetime = -1; int currentDayOfWeek = -1; datetime currentDate = -1, currentTime = -1;
    switch(SchedCustomType) {
        case TimeTypeGmt: currentDatetime = TimeGMT(); break;
        case TimeTypeLocal: currentDatetime = TimeLocal(); break;
        case TimeTypeBroker:
        default: currentDatetime = TimeCurrent(); break;
    }
    currentDayOfWeek = TimeDayOfWeek(currentDatetime);
    currentDate = Common::StripTimeFromDatetime(currentDatetime);
    currentTime = Common::StripDateFromDatetime(currentDatetime);
    
    //+------------------------------------------------------------------+
    // determine if recalc is needed
    
    bool recalc = false;
    if(customSchedulePrevIdx >= 0) {
        switch(customScheduleUnits[customSchedulePrevIdx].type) {
            case ScheduleDayOfWeek:
                if(customScheduleUnits[customSchedulePrevIdx].dayOfWeek != currentDayOfWeek) { recalc = true; }
                break;
                
            case ScheduleExactDatetime:
                if(customScheduleUnits[customSchedulePrevIdx].getDate() != currentDate) { recalc = true; }
                break;
        }
        
        if(!recalc) {
            if(customScheduleUnits[customSchedulePrevIdx].getTime() > currentTime) { recalc = true; }
        }
    } else { recalc = true; }
    
    if(!recalc) {
        if(customScheduleNextIdx >= 0) {
            switch(customScheduleUnits[customScheduleNextIdx].type) {
                case ScheduleDayOfWeek:
                    if(customScheduleUnits[customScheduleNextIdx].dayOfWeek != currentDayOfWeek) { recalc = true; }
                    break;
                    
                case ScheduleExactDatetime:
                    if(customScheduleUnits[customScheduleNextIdx].getDate() != currentDate) { recalc = true; }
                    break;
            }
            
            if(!recalc) {
                if(customScheduleUnits[customScheduleNextIdx].getTime() <= currentTime) { recalc = true; }
            }
        } else { recalc = true; }
    }
    
    //+------------------------------------------------------------------+
    // iterate through schedule units, determine closest next and prev units
    
    int nextIdx = -1, prevIdx = -1;
    if(!recalc) { 
        nextIdx = customScheduleNextIdx; 
        prevIdx = customSchedulePrevIdx; 
    }
    else {
        nextIdx = -1;
        prevIdx = -1;
        
        for(int i = 0; i < size; i++) {
            // rule out units by date
            switch(customScheduleUnits[i].type) {
                case ScheduleDayOfWeek:
                    if(customScheduleUnits[i].dayOfWeek != currentDayOfWeek) { continue; }
                    break;
                    
                case ScheduleExactDatetime:
                    if(customScheduleUnits[i].getDate() != currentDate) { continue; }
                    break;
                    
                // else, is ScheduleDaily and should proceed
            }
            
            // is next time equal or greater than current time? is it open or close?
            // is previous time open or close?
            if(customScheduleUnits[i].getTime() > currentTime) {
                if(nextIdx >= 0) {
                    if(customScheduleUnits[i].getTime() >= customScheduleUnits[nextIdx].getTime()) { continue; }
                }
                nextIdx = i;
            } else {
                if(prevIdx >= 0) {
                    if(customScheduleUnits[i].getTime() <= customScheduleUnits[prevIdx].getTime()) { continue; }
                }
                prevIdx = i;
            }
        }
        
        customScheduleNextIdx = nextIdx; 
        customSchedulePrevIdx = prevIdx;
    }
    
    //+------------------------------------------------------------------+
    // make determination
    
    if(prevIdx >= 0) {
        if(customScheduleUnits[prevIdx].definedAsClose) { return true; }
        // else, assume open
    }
    
    return false;
}

//+------------------------------------------------------------------+

double OrderManager::getSymbolSwap(bool isLong, int symIdx) {
    string symName = MainSymbolMan.symbols[symIdx].name;
    int swapMode = SymbolInfoInteger(symName, SYMBOL_SWAP_MODE);
    
    switch(swapMode) { // https://www.mql5.com/en/docs/constants/environment_state/marketinfoconstants#enum_symbol_swap_mode
        case SwapModePoints:
        case SwapModeReopenCurrent:
        case SwapModeReopenBid:
            if(isLong) { return PointsToPips(SymbolInfoDouble(symName, SYMBOL_SWAP_LONG)); }
            else { return PointsToPips(SymbolInfoDouble(symName, SYMBOL_SWAP_SHORT)); }
        
        case SwapModeSymbolMargin:
            if(isLong) { return PriceToPips(symName, SymbolInfoDouble(symName, SYMBOL_SWAP_LONG)); }
            else { return PriceToPips(symName, SymbolInfoDouble(symName, SYMBOL_SWAP_SHORT)); }
            
        // we can't translate the others to pips for now, so return 0
        // case SwapModeSymbolBase:
        // case SwapModeInterest:
        // case SwapModeCurrencyDeposit:
        // case SwapModeInterestOpen:
        default:
            return 0;
    }
}

bool OrderManager::isSwapThresholdBroken(bool isLong, int symIdx, bool isThreeDay = false) {
    double swap = getSymbolSwap(isLong, symIdx);
    
    return isSwapThresholdBroken(swap, symIdx, isThreeDay);
}

bool OrderManager::isSwapThresholdBroken(double swap, int symIdx, bool isThreeDay = false) {
    double threshold = 0;
    if(!getValue(threshold, swapThresholdLoc, symIdx)) { return false; }

    if(threshold <= 0) { return (isThreeDay ? swap*3 : swap) <= threshold; }
    else { return (isThreeDay ? swap*3 : swap) >= threshold; }
}
