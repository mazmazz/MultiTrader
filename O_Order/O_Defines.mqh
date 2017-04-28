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
// all negatives are different because if identical values are used in switch/case, compile fails
#define OrderTypeBuyStopLimit -1
#define OrderTypeSellStopLimit -2
#define OrderTypeCloseBy -3

#define SwapModeDisabled -4
#define SwapModePoints 0
#define SwapModeSymbolBase 1
#define SwapModeInterest 2
#define SwapModeSymbolMargin 3
#define SwapModeDepositCurrency -5
#define SwapModeInterestOpenPrice -6
#define SwapModeReopenCurrent -7
#define SwapModeReopenBid -8
#else
#ifdef __MQL5__
#define OrderTypeBuyStopLimit 6
#define OrderTypeSellStopLimit 7
#define OrderTypeCloseBy 8

#define SwapModeDisabled 0
#define SwapModePoints 1
#define SwapModeSymbolBase 2
#define SwapModeInterest 5
#define SwapModeSymbolMargin 3
#define SwapModeDepositCurrency 4
#define SwapModeInterestOpenPrice 6
#define SwapModeReopenCurrent 7
#define SwapModeReopenBid 8
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
    
    double basketSymbolStopLoss[];
    double basketSymbolTakeProfit[];
    double basketMasterStopLoss;
    double basketMasterTakeProfit;
    
    bool basketSymbolClose[];
    int basketSymbolLosses[];
    int basketSymbolWins[];
    
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
    ValueLocation *swapThresholdLoc;
    ValueLocation *gridCloseDistanceLoc;
    
    ValueLocation *basketSymbolStopLossLoc;
    ValueLocation *basketSymbolTakeProfitLoc;
    ValueLocation *basketSymbolBreakEvenJumpDistanceLoc;
    ValueLocation *basketSymbolTrailingStopLoc;
    ValueLocation *basketSymbolJumpingStopLoc;
    
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
    datetime getOrderOpenTime(bool isPosition);
#else
#ifdef __MQL5__
    ulong sendOpen(string posSymName, int posCmd, double posVolume, double posPrice, double posSlippage, double posStoploss, double posTakeprofit, string posComment = "", int posMagic = 0, datetime posExpiration = 0);
    bool sendModify(ulong ticket, double price, double stoploss, double takeprofit, datetime expiration, bool isPosition);
    bool sendClose(ulong ticket, int symIdx, bool isPosition);
    bool checkDoSelect(ulong ticket, bool isPosition);
    
    long getOrderType(bool isPosition);
    long getOrderTicket(bool isPosition); // OrderGetTicket is ulong, which is correct?
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
    datetime getOrderOpenTime(bool isPosition);
#endif
#endif
    
    //+------------------------------------------------------------------+
    // Cycle
    
    void doCurrentPositions(bool firstRun, bool isPosition);
    void evaluateFulfilledFromOrder(int ticket, int symbolIdx, bool isPosition);
    void resetOpenCount();
    void addOrderToOpenCount(int ticket, int symIdx, bool isPosition, bool subtract);
    void addOrderToOpenCount(int symIdx, int orderType, bool subtract);
    void addOrderToProfitCount(int symbolIdx, int type, double profit, bool doBooked, bool subtract);
    
    //+------------------------------------------------------------------+
    // Exit
    
    bool isExitSafe(int symIdx);
    bool checkDoExitSignals(int ticket, int symIdx, bool isPosition);
    bool checkDoExitByDistance(int ticket, int symIdx, double distancePips, bool byGrid, bool isPosition);
    bool getDistanceFromOpen(int ticket, int symIdx, double &distanceOut, bool byGrid, bool isPosition);
    
    //+------------------------------------------------------------------+
    // Modify
    
    void doModifyPosition(int ticket, int symIdx, bool isPosition);
    
    //+------------------------------------------------------------------+
    // Entry
    
    bool isEntrySafe(int symIdx);
    bool isEntrySafeByDirection(int symIdx, bool isLong);
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
    int prepareGridOrder(SignalType signal, bool isHedge, bool isDual, bool isMarket, int gridIndex, int symIdx, string posSymName, double posVolume, double posPriceDist, int posSlippage, string posComment = "", int posMagic = 0, datetime posExpiration = 0);
    void getGridOrderType(SignalType signal, bool isHedge, bool isDual, bool isMarket, int &cmdOut, int &gridIndexOut);
    int getGridOrderType(SignalType signal, bool isHedge, bool isDual, bool isMarket);
    SignalType getGridOrderDirection(int orderType);
    bool isGridOrderTypeLong(int orderType);
    bool isGridOrderTypeShort(int orderType);
    void fillGridExitFlags(int symbolIdx);
    bool isGridOpen(int symIdx, bool checkPendingsOnly);
    bool isGridOpen(int symIdx, bool isLong, bool checkPendingsOnly);
    int getGridCount(int symIdx, bool isLong, bool checkPendings, bool checkPositions, bool checkLimitOrders);
    int getGridNewTradeCount(int symIdx, bool isLong);
    bool isTradeModeGrid();
    void checkDoExitGrid(int symIdx, bool closeLong, bool force);
    
    //+------------------------------------------------------------------+
    // Schedule
    
    ScheduleUnit *customScheduleUnits[]; 
    int customSchedulePrevIdx;
    int customScheduleNextIdx;
    
    bool checkDoExitSchedule(int symIdx, int ticket, bool isPosition);
    bool getCloseByMarketSchedule(int symIdx, int ticket = -1, bool isPosition = false);
    bool getCloseByMarketSchedule(int symIdx, int ticket, bool isLong, bool isPosition);
    bool getCloseDaily(int symIdx);
    bool getClose3DaySwap(int symIdx);
    bool getCloseWeekend(int symIdx);
    bool getCloseOffSessions(int symIdx);
    
    bool getOpenByMarketSchedule(int symIdx);

    int getCurrentSessionIdx(int symIdx, datetime dt = 0, int weekday = -1);
    int getCurrentSessionIdx(int symIdx, datetime &fromOut, datetime &toOut, datetime dt = 0, int weekday = -1);
    int getSessionCountByWeekday(int symIdx, int weekday);
    
    void initCustomSchedule();
    bool getCloseCustom(int symIdx);
    
    double getSymbolSwap(bool isLong, int symIdx);
    bool isSwapThresholdBroken(bool isLong, int symIdx, bool isThreeDay = false);
    bool isSwapThresholdBroken(double swap, int symIdx, bool isThreeDay = false);
    
    //+------------------------------------------------------------------+
    // Basket
    
    bool checkBasketSafe(int symIdx);
    bool checkBasketMasterSafe();
    bool checkBasketSymbolSafe(int symIdx);
    void checkDoBasketExit();
    void checkDoBasketMasterExit();
    void checkDoBasketSymbolExit();
    void checkDoBasketSymbolExit(int symIdx);
    void sendBasketClose(bool isPosition);
    void sendBasketClose(int symIdx, bool isPosition);

    void fillBasketFlags();
    
    double getProfitPips(int ticket, bool isPosition);
    bool getProfitPips(int ticket, bool isPosition, double &profitOut);
    double getProfitPips(double openPrice, int opType, string symName);
    
    void updateBasketStopLevels();
    void updateBasketMasterStopLevels();
    void updateBasketMasterStopLevel(bool isStopLoss);
    void updateBasketSymbolStopLevels();
    void updateBasketSymbolStopLevel(int symIdx, bool isStopLoss);
    
    double getBasketMasterInitialStopLevel(bool isStopLoss);
    bool getBasketSymbolInitialStopLevel(int symIdx, bool isStopLoss, double &stopLevelOut);
    bool getBasketModifiedStopLevel(int symIdx, double &stopLevelOut);
    bool getBasketBreakEvenStopLevel(int symIdx, double &stopLevelOut);
    bool getBasketTrailingStopLevel(int symIdx, double &stopLevelOut);
    bool getBasketJumpingStopLevel(int symIdx, double &stopLevelOut);
    bool isBasketBreakEvenPassed(int symIdx);
    bool isBasketStopLossProgressed(int symIdx, double newStopLoss);
    
    //+------------------------------------------------------------------+
    // Stop Levels
    
    bool getInitialStopLevels(bool isLong, int symIdx, bool doStoploss, bool doTakeprofit, double &stoplossOut, double &takeprofitOut, bool &doDropOut);
    bool checkDoExitStopLevels(int ticket, int symIdx, bool isPosition);
    
    bool getModifiedStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition);
    bool getTrailingStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition);
    bool getJumpingStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition);
    bool getBreakEvenStopLevel(int ticket, int symIdx, double &stopLevelOut, bool isPosition);
    bool isBreakEvenPassed(int ticket, int symIdx, bool isPosition);
    bool isStopLossProgressed(int ticket, double newStopLoss, bool isPosition);
    
    void unOffsetStopLevels(string symName, bool isLong, double &stoplossOut, double &takeprofitOut);
    double unOffsetStopLoss(string symName, bool isLong, double stoploss);
    double unOffsetTakeProfit(string symName, bool isLong, double takeprofit);
    bool unOffsetStopLevelsFromOrder(int ticket, string symName, double &stoplossOut, double &takeprofitOut, bool isPosition);
    bool unOffsetStopLossFromOrder(int ticket, string symName, double &stoplossOut, bool isPosition);
    bool unOffsetTakeProfitFromOrder(int ticket, string symName, double &takeprofitOut, bool isPosition);
    
    void getStopLevelOffset(string symName, bool checkMinimum, double &stoplossOffset, double &takeprofitOffset);
    void getStopLossOffset(string symName, bool checkMinimum, double &stoplossOffset);
    
    void getStopLevelDrop(string symName, double stoplossOffset, double takeprofitOffset, bool &dropSlOut, bool &dropTpOut);
    bool dropOrderByStopLoss(string symName, double stoplossOffset);
    bool dropOrderByTakeProfit(string symName, double takeprofitOffset);
    
    void logInternalStopLevels(long ticket, double stoploss, double takeprofit, bool isPosition);
};
