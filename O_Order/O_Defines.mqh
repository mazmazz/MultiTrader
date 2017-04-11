#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

// In MQL4 and MQL5, values 0-5 are actually the same.

#define OrderTypeBuy 0
#define OrderTypeSell 1
#define OrderTypeBuyLimit 2
#define OrderTypeSellLimit 3
#define OrderTypeBuyStop 4
#define OrderTypeSellStop 5
#ifdef __MQL4__
#define OrderTypeBuyStopLimit -1
#define OrderTypeSellStopLimit -1
#define OrderTypeCloseBy -1
#else
#ifdef __MQL5__
#define OrderTypeBuyStopLimit 6
#define OrderTypeSellStopLimit 7
#define OrderTypeCloseBy 8
#endif
#endif

enum StopLossMode {
    StopModeNormal
    , StopModeValue
    , StopModeTrailing
    , StopModeJumping
    , StopModeBreakeven
};

class OrderManager {
    public:
    int basketDay;
    int basketLosses;
    int basketWins;
    double basketProfit;
    double basketLongProfit;
    double basketShortProfit;
    double basketBookedProfit;
    
    double basketProfitSymbol[];
    double basketLongProfitSymbol[];
    double basketShortProfitSymbol[];
    double basketBookedProfitSymbol[];
    
    int openPendingLongCount[];
    int openMarketLongCount[];
    int openPendingShortCount[];
    int openMarketShortCount[];
    
    // we need these to distinguish for grid counts: these technically count as the opposite positioning
    // these subtract from the total of Pending/Market
    int openPendingLongLimitCount[];
    int openPendingShortLimitCount[];
    
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
    ValueLocation *gridDistanceLoc;
    ValueLocation *breakEvenJumpDistanceLoc;
    ValueLocation *trailingStopLoc;
    ValueLocation *jumpingStopLoc;
    
    TimePoint *lastTradeBetween[]; // keyed by symbolId
    TimePoint *lastValueBetween[];
    
    void initValueLocations();
    ValueLocation *fillValueLocation(string location);
    ValueLocation *fillValueLocation(CalcSource calcSourceIn, double setValIn, string filterNameIn, CalcOperation opIn, double operandIn);
    
    double getValue(ValueLocation *loc, int symbolIdx);
    template <typename T>
    bool getValue(T &outVal, ValueLocation *loc, int symbolIdx);
    template <typename T>
    bool getValuePrice(T &outVal, ValueLocation *loc, int symIdx);
    template <typename T>
    bool getValuePoints(T &outVal, ValueLocation *loc, int symIdx);
    
    void setLastTimePoint(int symbolIdx, bool isLastTrade, uint millisecondsIn = 0, datetime dateTimeIn = 0, uint cyclesIn = 0);
    bool getLastTimeElapsed(int symbolIdx, bool isLastTrade, TimeUnits compareUnit, int delayCompare);
    
    double offsetValue(double value, double offset, string symName = NULL, bool offsetIsPips = true);
    double unOffsetValue(double value, double offset, string symName = NULL, bool offsetIsPips = true);
    
    //+------------------------------------------------------------------+
    // Broker
    
#ifdef __MQL4__
    int sendOpen(string posSymName, int posCmd, double posVolume, double posPrice, double posSlippage, double posStoploss, double posTakeprofit, string posComment = "", int posMagic = 0, datetime posExpiration = 0);
    bool sendModify(int ticket, double price, double stoploss, double takeprofit, datetime expiration, bool isPosition);
    bool sendClose(int ticket, int symIdx, bool isPosition);
    bool checkDoSelect(int ticket, bool isPosition);
    
    int getOrderType(bool isPosition);
    int getOrderTicket(bool isPosition);
    double getOrderStopLoss(bool isPosition);
    double getOrderTakeProfit(bool isPosition);
    int getOrderMagicNumber(bool isPosition);
    string getOrderSymbol(bool isPosition);
    double getOrderLots(bool isPosition);
    double getOrderOpenPrice(bool isPosition);
    datetime getOrderExpiration(bool isPosition);
    bool getOrderSelect(int index, int select, int pool, bool isPosition);
    double getOrderProfit(bool isPosition);
    int getOrdersTotal(bool isPosition);
#else
#ifdef __MQL5__
    ulong sendOpen(string posSymName, int posCmd, double posVolume, double posPrice, double posSlippage, double posStoploss, double posTakeprofit, string posComment = "", int posMagic = 0, datetime posExpiration = 0);
    bool sendModify(ulong ticket, double price, double stoploss, double takeprofit, datetime expiration, bool isPosition);
    bool sendClose(ulong ticket, int symIdx, bool isPosition);
    bool checkDoSelect(ulong ticket, bool isPosition);
    
    long getOrderType(bool isPosition);
    long getOrderTicket(bool isPosition);
    double getOrderStopLoss(bool isPosition);
    double getOrderTakeProfit(bool isPosition);
    long getOrderMagicNumber(bool isPosition);
    string getOrderSymbol(bool isPosition);
    double getOrderLots(bool isPosition);
    double getOrderOpenPrice(bool isPosition);
    datetime getOrderExpiration(bool isPosition);
    bool getOrderSelect(int index, int select, int pool, bool isPosition);
    double getOrderProfit(bool isPosition);
    int getOrdersTotal(bool isPosition);
#endif
#endif
    
    //+------------------------------------------------------------------+
    // Cycle
    
    void doCurrentPositions(bool firstRun, bool isPosition);
    void evaluateFulfilledFromOrder(int ticket, int symbolIdx, bool isPosition);
    void resetOpenCount();
    void addOrderToOpenCount(int ticket, int symIdx, bool isPosition, bool subtract);
    void addOrderToOpenCount(int symIdx, int orderType, bool subtract);
    
    //+------------------------------------------------------------------+
    // Exit
    
    bool isExitSafe(int symIdx);
    bool checkDoExitSignals(int ticket, int symIdx, bool isPosition);
    
    //+------------------------------------------------------------------+
    // Modify
    
    void doModifyPosition(int ticket, int symIdx, bool isPosition);
    
    //+------------------------------------------------------------------+
    // Entry
    
    bool isEntrySafe(int symIdx);
    int checkDoEntrySignals(int symIdx);
    int prepareSingleOrder(int symIdx, SignalType signal, bool isPending);
    
    //+------------------------------------------------------------------+
    // Grid
    
    bool gridSetLong[];
    bool gridSetShort[];
    bool gridExit[];
    bool gridExitBySignal[];
    bool gridExitByOpposite[];
    
    int prepareGrid(int symIdx, SignalType signal);
    int prepareGridOrder(SignalType signal, bool isHedge, bool isDual, bool isMarket, int gridIndex, string posSymName, double posVolume, double posPriceDist, int posSlippage, double stoplossOffset, double takeprofitOffset, string posComment = "", int posMagic = 0, datetime posExpiration = 0);
    void fillGridExitFlags(int symbolIdx);
    bool isGridOpen(int symIdx, bool checkPendingsOnly);
    bool isGridOpen(int symIdx, bool isLong, bool checkPendingsOnly);
    bool isTradeModeGrid();
    
    //+------------------------------------------------------------------+
    // Schedule
    
    bool checkDoExitSchedule(int symIdx, int ticket, bool isPosition);
    bool getCloseByMarketSchedule(int symIdx, int ticket = -1, bool isPosition = false);
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
    
    bool checkBasketSafe();
    void checkDoBasketExit();
    void sendBasketClose(bool isPosition);

    void fillBasketFlags();
    
    double getProfitPips(int ticket, bool isPosition);
    bool getProfitPips(int ticket, bool isPosition, double &profitOut);
    double getProfitPips(double openPrice, int opType, string symName);
    
    //+------------------------------------------------------------------+
    // Stop Levels
    
    bool getInitialStopLevels(bool isLong, int symIdx, double &stoplossOut, double &takeprofitOut);
    bool checkDoExitStopLevels(int ticket, int symIdx, bool isPosition);
    
    bool getModifiedStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition);
    bool getTrailingStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition);
    bool getJumpingStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition);
    bool getBreakEvenStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition);
    bool isBreakEvenPassed(int ticket, int symIdx, bool isPosition);
    bool isStopLossProgressed(int ticket, double newStopLoss, bool isPosition);
    
    bool unOffsetStopLevelsFromOrder(int ticket, string symName, double &stoplossOut, double &takeprofitOut, bool isPosition);
    bool unOffsetStopLossFromOrder(int ticket, string symName, double &stoplossOut, bool isPosition);
    bool unOffsetTakeProfitFromOrder(int ticket, string symName, double &takeprofitOut, bool isPosition);
    void offsetStopLevels(bool isShort, string symName, double &stoploss, double &takeprofit);
    void offsetStopLoss(bool isShort, string symName, double &stoploss);
    void offsetTakeProfit(bool isShort,string symName,double &takeprofit);
};
