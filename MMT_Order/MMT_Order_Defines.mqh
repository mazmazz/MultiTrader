#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

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
    bool gridExitBySignal[];
    bool gridExitByOpposite[];
    
    int basketDay;
    int basketLosses;
    int basketWins;
    double basketProfit;
    double basketBookedProfit;
    
    void initValueLocations();
    ValueLocation *fillValueLocation(CalcMethod calcTypeIn, double setValIn, string filterNameIn, double factorIn);
    
    void doCurrentPositions(bool firstRun);
    void evaluateFulfilledFromOrder(int ticket, int symbolIdx);
    void fillGridExitFlags(int symbolIdx);
    void doChangePosition(int ticket, int symIdx);
    bool doExitPosition(int ticket, int symIdx);
    int doEnterPosition(int symIdx);
    bool sendClose(int ticket, int symIdx);
    int sendOrder(int symIdx, SignalType signal, bool isPending);
    int sendGrid(int symIdx, SignalType signal);
    
    bool isEntrySafe(int symIdx);
    bool isExitSafe(int symIdx);
    
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
    
    bool getCloseByMarketSchedule(int ticket, int symIdx);
    bool getCloseDaily(int symIdx);
    bool getClose3DaySwap(int symIdx);
    bool getCloseOffSessions(int symIdx);
    bool getCloseWeekend(int symIdx);
    
    int getCurrentSessionIdx(int symIdx, datetime dt = 0, int weekday = -1);
    int getCurrentSessionIdx(int symIdx, datetime &fromOut, datetime &toOut, datetime dt = 0, int weekday = -1);
    int getSessionCountByWeekday(int symIdx, int weekday);
    
    bool getOpenByMarketSchedule(int symIdx);
    
    bool checkSelectOrder(int ticket);
    
    double getProfitAmount(BalanceUnits type, int ticket);
    double getProfitAmountPips(double openPrice, int opType, string symName);
    bool getProfitAmountPips(int ticket, double &profitOut);
    bool getProfitAmountCurrency(int ticket, double &profitOut);
    void fillBasketFlags();
    void doBasketCheckExit();
    void doBasketExit();
    bool checkBasketSafe();
};
