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

bool OrderManager::getCloseByMarketSchedule(int ticket, int symIdx) {
    if(!SchedCloseDaily && !SchedCloseOffSessions && !SchedClose3DaySwap && !SchedCloseWeekend) { return false;}
    if(!checkSelectOrder(ticket)) { return false; }
    
    int orderOp = OrderType();
    
    if(!SchedClosePendings && Common::OrderIsPending(orderOp)) { return false; }
    if(SchedCloseOrderOp == OrderOnlyLong && !Common::OrderIsLong(orderOp)) { return false; }
    if(SchedCloseOrderOp == OrderOnlyShort && !Common::OrderIsShort(orderOp)) { return false; }
    if(SchedCloseOrderProfit == OrderOnlyProfitable && OrderProfit() < 0) { return false; } // todo: do this properly: refer to pips? include swaps?
    if(SchedCloseOrderProfit == OrderOnlyLoss && OrderProfit() >= 0) { return false; }
    
    // todo: swap - if minimum swap trigger set, check swap: if it's greater than the negative swap value, return false
    
    if(SchedCloseDaily && getCloseDaily(symIdx)) { return true; }
    else if(SchedClose3DaySwap && getClose3DaySwap(symIdx)) { return true; }
    else if(SchedCloseWeekend && getCloseWeekend(symIdx)) { return true; }
    else if(SchedCloseOffSessions && getCloseOffSessions(symIdx)) { return true; }
    else { return false; }
}

bool OrderManager::getCloseDaily(int symIdx) {
    int sessCount = getSessionCountByWeekday(DayOfWeek(), symIdx);
    if(sessCount <= 0) { return false; }

    // if current session is last of the day, check if we're within SchedCloseMinutes of closing
    datetime from, to, dt = TimeCurrent();
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

    if(getSessionCountByWeekday(curDay, symIdx) > 0 && getSessionCountByWeekday(nextDay, symIdx) <= 0) {
        return getCloseDaily(symIdx);
    } else { return false; }
}

bool OrderManager::getCloseOffSessions(int symIdx) {
    int sessCount = getSessionCountByWeekday(DayOfWeek(), symIdx);
    if(sessCount <= 0) { return false; }

    // off session: current day (or midnight) has a session gap exceeding SchedGapIgnoreMinutes
    datetime dt = Common::StripDateFromDatetime(TimeCurrent());
    datetime fromCurrent, toCurrent; 
    int weekdayCurrent = DayOfWeek();
    int sessCurrent = getCurrentSessionIdx(symIdx, fromCurrent, toCurrent, dt, weekdayCurrent);
    if(sessCurrent < 0) { return false; }
    
    datetime fromNext, toNext; 
    int weekdayNext, sessNext;
    if(sessCurrent == (sessCount - 1)) { 
        sessNext = 0;
        weekdayNext = (weekdayCurrent == SATURDAY) ? SUNDAY : weekdayCurrent + 1; 
    }
    else { 
        sessNext = sessCurrent + 1;
        weekdayNext = weekdayCurrent; 
    }
    
    if(SchedGapIgnoreMinutes > 0 && SymbolInfoSessionTrade(MainSymbolMan.symbols[symIdx].name, weekdayNext, sessNext, fromNext, toNext)) {
        int gap = fromNext - toCurrent;
        if(gap <= SchedGapIgnoreMinutes*60) { return false; }
    }
    
    return (dt >= toCurrent-(MathMax(1, SchedCloseMinutes)*60)); // todo: what if cycle length does not hit this check?
}

//+------------------------------------------------------------------+

bool OrderManager::getOpenByMarketSchedule(int symIdx) {
    //extern int SchedOpenMinutesDaily = 0; // are we in first session of today? are we at least X minutes from open?
    //extern int SchedOpenMinutesWeekend = 180; // are we in first session of today AND yesterday had no sessions? are we at least X minutes from open?
    //extern int SchedOpenMinutesOffSessions = 0; // whichever session we are in, are we at least X minutes from open? ignore gaps
    //extern int SchedGapIgnoreMinutes = 15; // SchedGapIgnoreMinutes: Ignore session gaps of X mins
    
    if(SchedOpenMinutesWeekend <= 0 && SchedOpenMinutesDaily <= 0 && SchedOpenMinutesOffSessions <= 0) { return true; }
    
    datetime fromCur, toCur, dt = Common::StripDateFromDatetime(TimeCurrent()); int dayCur = DayOfWeek();
    int sessCount = getSessionCountByWeekday(symIdx, dayCur);
    int sessCur = getCurrentSessionIdx(symIdx, fromCur, toCur, dt, dayCur);
    if(sessCur < 0) { return false; }
    
    
    int dayPrev, sessPrev, sessCountPrev;
    if(sessCur == 0) { 
        if(SchedOpenMinutesWeekend <= 0 && SchedOpenMinutesDaily <= 0) { return true; }
        
        dayPrev = (dayCur == SUNDAY) ? SATURDAY : dayCur - 1;
        sessCountPrev = getSessionCountByWeekday(symIdx, dayPrev); // weekend: are we in first session of today AND yesterday had no sessions?
        
        int minutesOffset = sessCountPrev <= 0 ? SchedOpenMinutesWeekend : SchedOpenMinutesDaily; 
        return (dt >= fromCur + (minutesOffset*60));
    } else { 
        if(SchedOpenMinutesOffSessions <= 0) { return true; }
        sessPrev = sessCur - 1;
        dayPrev = dayCur;
        
        int fromCompare = fromCur;
        datetime fromPrev, toPrev;
        if(SchedGapIgnoreMinutes > 0 && sessCountPrev > 0 && SymbolInfoSessionTrade(MainSymbolMan.symbols[symIdx].name, dayPrev, sessPrev, fromPrev, toPrev)) {
            int gap = fromCur - toPrev;
            if(gap <= SchedGapIgnoreMinutes*60) { return true; } 
                // todo: ideally we set fromCompare = fromPrev so we can compare from last session open, but this doesn't work because of wraparound. we need to compare dates as part of datetime
                // for now, just return true
        }
        
        return (dt >= fromCompare + (SchedOpenMinutesOffSessions*60));
    }
}

//+------------------------------------------------------------------+

int OrderManager::getCurrentSessionIdx(int symIdx, datetime dt = 0, int weekday = -1) {
    datetime from, to;
    return getCurrentSessionIdx(symIdx, from, to, dt, weekday);
}

int OrderManager::getCurrentSessionIdx(int symIdx, datetime &fromOut, datetime &toOut, datetime dt = 0, int weekday = -1) {
    if(dt <= 0) { dt = TimeCurrent(); }
    dt = Common::StripDateFromDatetime(dt);
    if(weekday < 0 || weekday >= 7) { weekday = DayOfWeek(); }
    
    datetime from, to; int sessCount = -1; string symName = MainSymbolMan.symbols[symIdx].name;
    while(SymbolInfoSessionTrade(symName, weekday, ++sessCount, from, to)) { 
        if(dt >= from && dt < to) { 
            fromOut = from;
            toOut = to;
            return sessCount; 
        }
    }
    
    return -1;
}

//bool OrderManager::isInsideOfSession(int symIdx, datetime dt = 0, int weekday = -1) {
//    return (getCurrentSessionIdx(symIdx, from, to dt, weekday) > -1);
//}
//
//int OrderManager::getLastSessionIdx(int symIdx, datetime dt = 0, int weekday = -1) {
//    if(dt <= 0) { dt = TimeCurrent(); }
//    dt = dt - (86400*MathFloor(dt/86400)); // strip date, just get time
//    
//    datetime from, to; int sessCount = -1; int weekday = DayOfWeek(); string symName = MainSymbolMan.symbols[symIdx].name;
//    while(SymbolInfoSessionTrade(symName, weekday, ++sessCount, from, to)) { 
//        
//    }
//    
//    return -1;
//}
//
//int OrderManager::getNextSessionIdx(int symIdx, datetime dt = 0, int weekday = -1) {
//    if(dt <= 0) { dt = TimeCurrent(); }
//    dt = dt - (86400*MathFloor(dt/86400)); // strip date, just get time
//    
//    datetime from, to; int sessCount = -1; int weekday = DayOfWeek(); string symName = MainSymbolMan.symbols[symIdx].name;
//    while(SymbolInfoSessionTrade(symName, weekday, ++sessCount, from, to)) { 
//        
//    }
//    
//    return -1;
//}

int OrderManager::getSessionCountByWeekday(int symIdx, int weekday) {
    datetime from, to; int sessCount = -1; string symName = MainSymbolMan.symbols[symIdx].name;
    while(SymbolInfoSessionTrade(symName, weekday, ++sessCount, from, to)) { }
    
    return sessCount;
}