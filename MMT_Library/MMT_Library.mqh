#define ExtLib_Symbols
#define ExtLib_OrderReliable
#define ExtLib_PipFactor

#ifdef ExtLib_PipFactor
    #import "MMT_Library/PipFactor.ex4"
    int PipFactor(string symbol);
    #import
#endif

#ifdef ExtLib_Symbols
    #import "MMT_Library/Symbols.ex4"
    int Symbols(string& sSymbols[]);
    #import
#endif

#ifdef ExtLib_OrderReliable
    #import "MMT_Library/OrderReliable.ex4"
    void O_R_SetRetries(int retries);
    
    void O_R_SetVerbosity(int v);

    int OrderSendReliable(string symbol, int cmd, double volume, double price,
                            int slippage, double stoploss, double takeprofit,
                            string comment, int magic, datetime expiration = 0,
                            color arrow_color = CLR_NONE);
                            
    int OrderSendReliableMKT(string symbol, int cmd, double volume, double price,
                            int slippage, double stoploss, double takeprofit,
                            string comment, int magic, datetime expiration = 0,
                            color arrow_color = CLR_NONE);

    int OrderSendReliable1Step(string symbol, int cmd, double volume, double price,
                              int slippage, double stoploss, double takeprofit,
                              string comment, int magic, datetime expiration = 0,
                              color arrow_color = CLR_NONE);

    int OrderSendReliable2Step(string symbol, int cmd, double volume, double price,
                              int slippage, double stoploss, double takeprofit,
                              string comment, int magic, datetime expiration = 0,
                              color arrow_color = CLR_NONE);

    int OrderSendReliableMKT1Step(string symbol, int cmd, double volume, double price,
                              int slippage, double stoploss, double takeprofit,
                              string comment, int magic, datetime expiration = 0,
                              color arrow_color = CLR_NONE);

    int OrderSendReliableMKT2Step(string symbol, int cmd, double volume, double price,
                              int slippage, double stoploss, double takeprofit,
                              string comment, int magic, datetime expiration = 0,
                              color arrow_color = CLR_NONE);
                            
    bool OrderModifyReliable(int ticket, double price, double stoploss,
                            double takeprofit, datetime expiration,
                            color arrow_color = CLR_NONE);

    bool OrderCloseReliable(int ticket, double volume, double price,
                            int slippage, color arrow_color = CLR_NONE);
                            
    bool OrderCloseReliableMKT(int ticket, double volume, double price,
                  int slippage, color arrow_color = CLR_NONE);
                  
    bool OrderDeleteReliable(int ticket);

    int GetLastErrorReliable();

    void O_R_Config_use2step(bool use2step); 

    void O_R_Config_UseInBacktest(bool use);

    void O_R_Config_FinetuneEntries(bool use);

    void O_R_Sleep(double mean_time, double max_time);

    #import
#endif
