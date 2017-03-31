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
    
    //+------------------------------------------------------------------+
    // General
    
    ValueLocation *stopLossLoc;
    ValueLocation *takeProfitLoc;
    ValueLocation *maxSpreadLoc;
    ValueLocation *maxSlippageLoc;
    ValueLocation *lotSizeLoc;
    ValueLocation *breakEvenLoc;
    ValueLocation *gridDistanceLoc;
    
    TimePoint *lastTradeBetween[]; // keyed by symbolId
    TimePoint *lastValueBetween[];
    
    void initValueLocations();
    ValueLocation *fillValueLocation(CalcMethod calcTypeIn, double setValIn, string filterNameIn, double factorIn);
    
    double getValue(ValueLocation *loc, int symbolIdx);
    template <typename T>
    bool getValue(T &outVal, ValueLocation *loc, int symbolIdx);
    void setLastTimePoint(int symbolIdx, bool isLastTrade, uint millisecondsIn = 0, datetime dateTimeIn = 0, uint cyclesIn = 0);
    bool getLastTimeElapsed(int symbolIdx, bool isLastTrade, TimeUnits compareUnit, int delayCompare);
    
    //double calculateStopLoss();
    //double calculateTakeProfit();
    //double calculateLotSize();
    //double calculateMaxSpread();
    //double calculateMaxSlippage();
    
    //+------------------------------------------------------------------+
    // Cycle
    
    int openPendingCount[];
    int openMarketCount[];
    
    SignalType gridDirection[];
    bool gridExit[];
    bool gridExitBySignal[];
    bool gridExitByOpposite[];
    
    void doCurrentPositions(bool firstRun);
    void evaluateFulfilledFromOrder(int ticket, int symbolIdx);
    bool checkDoSelectOrder(int ticket);
    void resetOpenCount();
    void addOrderToOpenCount(int ticket, int symIdx = -1);
    
    //+------------------------------------------------------------------+
    // Exit
    
    bool isExitSafe(int symIdx);
    bool checkDoExitSignals(int ticket, int symIdx);
    bool sendClose(int ticket, int symIdx);
    
    //+------------------------------------------------------------------+
    // Modify
    
    void doModifyPosition(int ticket, int symIdx);
    
    //+------------------------------------------------------------------+
    // Entry
    
    bool isEntrySafe(int symIdx);
    int checkDoEntrySignals(int symIdx);
    int prepareSingleOrder(int symIdx, SignalType signal, bool isPending);
    int sendOpenOrder(string posSymName, int posCmd, double posVolume, double posPrice, double posSlippage, double posStoploss, double posTakeprofit, string posComment = "", int posMagic = 0, datetime posExpiration = 0);
    
    //+------------------------------------------------------------------+
    // Grid
    
    int prepareGrid(int symIdx, SignalType signal);
    int prepareGridOrder(SignalType signal, bool isHedge, bool isDual, bool isMarket, int gridIndex, string posSymName, double posVolume, double posPriceDist, int posSlippage, double stoplossOffset, double takeprofitOffset, string posComment = "", int posMagic = 0, datetime posExpiration = 0);
    void fillGridExitFlags(int symbolIdx);
    bool isGridOpen(int symIdx, bool checkPendingsOnly = false);
    bool isTradeModeGrid();
    
    //+------------------------------------------------------------------+
    // Schedule
    
    bool getCloseByMarketSchedule(int ticket, int symIdx);
    bool getCloseDaily(int symIdx);
    bool getClose3DaySwap(int symIdx);
    bool getCloseWeekend(int symIdx);
    bool getCloseOffSessions(int symIdx);
    
    bool getOpenByMarketSchedule(int symIdx);

    int getCurrentSessionIdx(int symIdx, datetime dt = 0, int weekday = -1);
    int getCurrentSessionIdx(int symIdx, datetime &fromOut, datetime &toOut, datetime dt = 0, int weekday = -1);
    int getSessionCountByWeekday(int symIdx, int weekday);
    
    //+------------------------------------------------------------------+
    // Basket
    
    int basketDay;
    int basketLosses;
    int basketWins;
    double basketProfit;
    double basketBookedProfit;
    
    bool checkBasketSafe();
    void checkDoBasketExit();
    void sendBasketClose();

    void fillBasketFlags();
    
    double getProfitAmount(BalanceUnits type, int ticket);
    double getProfitAmountPips(double openPrice, int opType, string symName);
    bool getProfitAmountPips(int ticket, double &profitOut);
    bool getProfitAmountCurrency(int ticket, double &profitOut);
};
