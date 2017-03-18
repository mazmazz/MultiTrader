//+------------------------------------------------------------------+
//|                                                       libCSS_mq4 |
//|                      Copyright 2013, Deltabron - Paul Geirnaerdt |
//|                                          http://www.deltabron.nl |
//+------------------------------------------------------------------+

#define libCSS_version            "v1.1.2"

#property strict

//+------------------------------------------------------------------+
//| Release Notes                                                    |
//+------------------------------------------------------------------+
// v1.0.0, 5/7/13
// * Initial release
// * NanningBob's 10.5 rules apply
// v1.1.0, 8/2/13
// * Added getSlopeRSI
// * Changed to original NB rules
// v1.1.1, 8/5/13
// * Added getGlobalMarketTrend
// * Added parameters for caching mechanism
// v1.1.2, 9/6/13
// * Added flushCache parameter

enum libCSS_versions {
    VerLibCSS,
    VerCSSv3_8,
    VerSuperSlope
};

libCSS_versions libCSS_useCalcMethod  = VerLibCSS;
bool    libCSS_ignoreFuture             = true;
bool    libCSS_sundayCandlesDetected    = false;
bool    libCSS_useOnlySymbolOnChart     = false;
bool    libCSS_doNotCache               = false;
string  libCSS_cacheSymbol              = "EURUSD";
int     libCSS_cacheLastTime            = 0; // this limits CSS updates to 1 second at shortest
bool    libCSS_cacheFirstRunComplete    = false;
void    libCSS_flushCache()             { libCSS_cacheFirstRunComplete = false; }
string  libCSS_symbolsToWeigh           = "GBPNZD,EURNZD,GBPAUD,GBPCAD,GBPJPY,GBPCHF,CADJPY,EURCAD,EURAUD,USDCHF,GBPUSD,EURJPY,NZDJPY,AUDCHF,AUDJPY,USDJPY,EURUSD,NZDCHF,CADCHF,AUDNZD,NZDUSD,CHFJPY,AUDCAD,USDCAD,NZDCAD,AUDUSD,EURCHF,EURGBP";
int     libCSS_symbolCount;
int     libCSS_currencyCount;
string  libCSS_symbolNames[];
string  libCSS_currencyNames[];        // = { "USD", "EUR", "GBP", "CHF", "JPY", "AUD", "CAD", "NZD" };
double  libCSS_currencyValues[];      // Currency slope strength
int     libCSS_currencyOccurrences[]; // Holds the number of occurrences of each currency in symbols
int libCSS_maPeriod = 21; // SuperSlope = 7
int libCSS_atrPeriod = 100; // SuperSlope = 50
int libCSS_rsiWorkPeriod = 17;
int libCSS_rsiPeriod = 2; 

//+------------------------------------------------------------------+
//| libCSS_init()                                                    |
//+------------------------------------------------------------------+
void libCSS_init()
{
   libCSS_cacheSymbol = libCSS_symbolHelper_fixSymbolName(libCSS_cacheSymbol);
    
   libCSS_initSymbols();
   libCSS_initCurrencies();

   libCSS_sundayCandlesDetected = false;
   for ( int i = 0; i < 8; i++ )
   {
      if ( TimeDayOfWeek( iTime( NULL, PERIOD_D1, i ) ) == 0 )
      {
         libCSS_sundayCandlesDetected = true;
         break;
      }
   }
  
   return;
}
//+------------------------------------------------------------------+
//| Initialize Symbols Array                                         |
//+------------------------------------------------------------------+
void libCSS_initSymbols()
{
   int i;

   ArrayFree(libCSS_symbolNames);

   string symbolsToWeighIn[];

   libCSS_symbolsToWeigh = libCSS_helper_StringTrim(libCSS_symbolsToWeigh);

   if(libCSS_useOnlySymbolOnChart || libCSS_useCalcMethod == VerSuperSlope) {
      if(libCSS_symbolHelper_getSymbolUsable(Symbol())) { libCSS_helper_ArrayPush(libCSS_symbolNames, Symbol()); }
   } else if(StringLen(libCSS_symbolsToWeigh) <= 0) {
      libCSS_symbolHelper_getAllSymbols(libCSS_symbolNames);
   } else {
      StringSplit(
         libCSS_symbolsToWeigh
         , ','
         , symbolsToWeighIn
      );

      // load libCSS_symbolNames
      libCSS_helper_ArrayReserve(libCSS_symbolNames, ArraySize(symbolsToWeighIn));

      for(i = 0; i < ArraySize(symbolsToWeighIn); i++) {
         string symName = libCSS_symbolHelper_fixSymbolName(symbolsToWeighIn[i]);
         if(libCSS_symbolHelper_getSymbolUsable(symName)) { libCSS_helper_ArrayPush(libCSS_symbolNames, symName); }
      }
   }

   libCSS_symbolCount = ArraySize(libCSS_symbolNames);
}

//+------------------------------------------------------------------+
//| getCurrencyIndex(string currency)                                |
//+------------------------------------------------------------------+
void libCSS_initCurrencies()
{
   ArrayFree(libCSS_currencyNames);
   ArrayFree(libCSS_currencyOccurrences);
   ArrayFree(libCSS_currencyValues);
   
   for ( int i = 0; i < libCSS_symbolCount; i++ )
   {
      // If currency not in array, then add to currencyNames
      string baseCur = libCSS_symbolHelper_getSymbolBaseCurrency(libCSS_symbolNames[i]);
      string quoteCur = libCSS_symbolHelper_getSymbolQuoteCurrency(libCSS_symbolNames[i]);

      if(libCSS_helper_ArrayTsearch(libCSS_currencyNames, baseCur) < 0) {
         int newSize = libCSS_helper_ArrayPush(libCSS_currencyNames, baseCur);
         ArrayResize(libCSS_currencyOccurrences, newSize);
         ArrayResize(libCSS_currencyValues, newSize);
         libCSS_currencyCount = newSize;
      }

      if(libCSS_helper_ArrayTsearch(libCSS_currencyNames, quoteCur) < 0) {
         int newSize = libCSS_helper_ArrayPush(libCSS_currencyNames, quoteCur);
         ArrayResize(libCSS_currencyOccurrences, newSize);
         ArrayResize(libCSS_currencyValues, newSize);
         libCSS_currencyCount = newSize;
      }
      
      // Increase currency occurrence
      libCSS_currencyOccurrences[libCSS_getCurrencyIndex(baseCur)]++;
      libCSS_currencyOccurrences[libCSS_getCurrencyIndex(quoteCur)]++;
   }
}

//+------------------------------------------------------------------+
//| getCurrencyIndex(string currency)                                |
//+------------------------------------------------------------------+
int libCSS_getCurrencyIndex(string currency)
{
   for (int i = 0; i < libCSS_currencyCount; i++)
   {
      if (libCSS_currencyNames[i] == currency)
      {
         return(i);
      }   
   }   
   return (-1);
}

//+------------------------------------------------------------------+
//| getSlope()                                                       |
//+------------------------------------------------------------------+
double libCSS_getSlope( string symbol, int tf, int maperiod, int atrperiod, int shift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = shift;
   if ( libCSS_sundayCandlesDetected && tf == PERIOD_D1 )
   {
      if ( TimeDayOfWeek( iTime( symbol, PERIOD_D1, shift ) ) == 0  ) shiftWithoutSunday++;
   }   
   double atr = iATR(symbol, tf, atrperiod, shiftWithoutSunday + 10) / 10;
   double gadblSlope = 0.0;
   if ( atr != 0 )
   {
      switch(libCSS_useCalcMethod) {
         case VerCSSv3_8:
            if(!libCSS_ignoreFuture) {
               dblTma=libCSS_calcTma(symbol,tf,maperiod,shiftWithoutSunday);
               dblPrev=libCSS_calcTma(symbol,tf,maperiod,shiftWithoutSunday+1);
               break;
            } // else, fall through

         case VerSuperSlope:
         case VerLibCSS:
         default:
            // This is used in SuperSlope and CSSv3.8 (ignoreFuture = true), and is equivalent to LibCSS's method
            // Not exactly sure how 231 or 251 make sense as operators
            // But SuperSlope keeps these values, even when the MA and ATR periods
            // are different from CSS
            dblTma=iMA(symbol,tf,maperiod,0,MODE_LWMA,PRICE_CLOSE,shiftWithoutSunday);
            dblPrev=
               ((iMA(symbol,tf,maperiod,0,MODE_LWMA,PRICE_CLOSE,shiftWithoutSunday+1)*231)
                  + (iClose(symbol,tf,shiftWithoutSunday)*20)
                  )
               /251
               ;
         break;
      }

      gadblSlope = ( dblTma - dblPrev ) / atr;
   }

   return ( gadblSlope );
}
////+------------------------------------------------------------------+
////| calcTmaTrue()                                                    |
////+------------------------------------------------------------------+

double libCSS_calcTma(string symbol, int tf, int maperiod, int shift)
{
   double dblSum  = iClose( symbol, tf, shift ) * maperiod;
   double dblSumw = maperiod;
   int maperiodLess = maperiod-1;
   int jnx,knx;

   for(jnx=1,knx=maperiodLess; jnx<=maperiodLess; jnx++,knx--)
     {
      dblSum  += iClose(symbol, tf, shift + jnx) * knx;
      dblSumw += knx;

      if(jnx<=shift)
        {
         dblSum  += iClose(symbol, tf, shift - jnx) * knx;
         dblSumw += knx;
        }
     }

   return ( dblSum / dblSumw );
}
 
//+------------------------------------------------------------------+
//| getCSS( double& CSS[], int tf, int shift )                       |
//+------------------------------------------------------------------+
void libCSS_getCSS( double &css[], int tf, int maperiod, int atrperiod, int shift, string symbol = "", bool flushCache = false )
{
   libCSS_getCSS(css, "", maperiod, atrperiod, shift, flushCache);
}

void libCSS_getCSS( double &css[], string symbol, int tf, int maperiod, int atrperiod, int shift, bool flushCache = false )
{
   libCSS_calcCSS(symbol, tf, maperiod, atrperiod, shift, flushCache);

   ArrayFree(css);
   ArrayCopy(css, libCSS_currencyValues);
}

void libCSS_calcCSS( string symbol, int tf, int maperiod, int atrperiod, int shift, bool flushCache = false ) {
   int i;

   if ( !libCSS_doNotCache 
      || flushCache 
      || !libCSS_cacheFirstRunComplete 
      || libCSS_cacheLastTime != SymbolInfoInteger(libCSS_cacheSymbol, SYMBOL_TIME) )
   {
      ArrayInitialize(libCSS_currencyValues, 0.0);
      double slope = 0;

      switch(libCSS_useCalcMethod) {
         case VerSuperSlope:
            slope = libCSS_getSlope(symbol, tf, maperiod, atrperiod, shift);
            libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_symbolHelper_getSymbolBaseCurrency(symbol))] += slope;
            libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_symbolHelper_getSymbolQuoteCurrency(symbol))] -= slope;
            break;

         case VerLibCSS:
         case VerCSSv3_8:
         default:
            // Get Slope for all symbols and totalize for all currencies   
            for ( i = 0; i < libCSS_symbolCount; i++ )
            {
               slope = libCSS_getSlope(libCSS_symbolNames[i], tf, maperiod, atrperiod, shift);
               libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_symbolHelper_getSymbolBaseCurrency(libCSS_symbolNames[i]))] += slope;
               libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_symbolHelper_getSymbolQuoteCurrency(libCSS_symbolNames[i]))] -= slope;
            }
            for ( i = 0; i < libCSS_currencyCount; i++ )
            {
               // average
               if ( libCSS_currencyOccurrences[i] > 0 ) libCSS_currencyValues[i] /= libCSS_currencyOccurrences[i]; else libCSS_currencyValues[i] = 0;
            }
            break;
      }

      libCSS_cacheLastTime = SymbolInfoInteger(libCSS_cacheSymbol, SYMBOL_TIME);
      libCSS_cacheFirstRunComplete = true;
   }
}
//+------------------------------------------------------------------+
//| getCSSCurrency(string currency, int tf, int shift)               |
//+------------------------------------------------------------------+
double libCSS_getCSSCurrency( string currency, int tf, int maperiod, int atrperiod, int shift ) {
   return libCSS_getCSSCurrency("", currency, tf, maperiod, atrperiod, shift);
}

double libCSS_getCSSCurrency( string symbol, string currency, int tf, int maperiod, int atrperiod, int shift )
{
   libCSS_calcCSS( symbol, tf, maperiod, atrperiod, shift );
   return ( libCSS_currencyValues[libCSS_getCurrencyIndex(currency)] );
}

//+------------------------------------------------------------------+
//| getCSSdiff(int tf, int shift)                                    |
//+------------------------------------------------------------------+
double libCSS_getCSSDiff( string symbol, int tf, int maperiod, int atrperiod, int shift )
{
   libCSS_calcCSS( symbol, tf, maperiod, atrperiod, shift );
   double diffLong = libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_symbolHelper_getSymbolBaseCurrency(symbol))];
   double diffShort = libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_symbolHelper_getSymbolQuoteCurrency(symbol))];
   return ( diffLong - diffShort );
}

//+------------------------------------------------------------------+
//| getSlopeRSI( string symbol, int tf, int shift )                  |
//+------------------------------------------------------------------+
double libCSS_getSlopeRSI( string symbol, int workPeriod, int rsiPeriod, int tf, int maperiod, int atrperiod, int shift )
{
   double slope[];
   //int workPeriod = 17;                                         // RSI period Bob's default = 2, + overhead
   ArrayResize( slope, workPeriod );
   ArraySetAsSeries( slope, true );
   for ( int i = 0; i < workPeriod; i++ )
   {
      slope[i] = libCSS_getSlope( symbol, tf, maperiod, atrperiod, shift + i );
   }
   return( iRSIOnArray( slope, workPeriod, rsiPeriod, 0 ) );            // Again, 2 is Bob's default
}

//+------------------------------------------------------------------+
//| getBBonStoch( string symbol, int tf, int shift )                 |
//+------------------------------------------------------------------+
void libCSS_getBBonStoch( double& bb[], string symbol, int tf, int shift )
{
   double buffer[];
   int workPeriod = 24;
   ArrayResize( buffer, workPeriod );
   ArraySetAsSeries( buffer, true );
   for ( int i = 0; i < workPeriod; i++ )
   {
      buffer[i] = iStochastic( symbol, tf, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, shift + i );
   }
   ArrayResize( bb, 3 );
   bb[MODE_UPPER] = iBandsOnArray( buffer, workPeriod, 20, 2, 0, MODE_UPPER, shift );
   bb[MODE_LOWER] = iBandsOnArray( buffer, workPeriod, 20, 2, 0, MODE_LOWER, shift );
}

//+------------------------------------------------------------------+
//| getGlobalMarketTrend( int tf, int shift )                        |
//+------------------------------------------------------------------+
double libCSS_getGlobalMarketTrend( string symbol, int tf, int maperiod, int atrperiod, int shift ) 
{
   libCSS_calcCSS( symbol, tf, maperiod, atrperiod, shift );
      
   double gmt = 0;
   for ( int i = 0; i < libCSS_currencyCount; i++ )
   {
      gmt += MathPow(libCSS_currencyValues[i], 2);
   }
   
   return ( gmt );
}

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+

// https://github.com/dingmaotu/mql4-lib
template<typename T>
void libCSS_helper_ArrayDelete(T &array[],int index, int diff=1, bool resize=true) {
   int size=ArraySize(array);
   if(index<0 || index>=size) { return; }

   bool isSeries = ArrayGetAsSeries(array);
    
   if(isSeries) { ArraySetAsSeries(array, false); }

   else {
      for(int i=index; i<size-diff; i++)
        {
         array[i]=array[i+diff];
        }
   }
   
   if(resize) { ArrayResize(array,size-diff); }
   
   if(isSeries) { ArraySetAsSeries(array, true); }
}

template<typename T>
int libCSS_helper_ArrayPush(T &array[], T unit, int maxSize = -1) {
    int size = ArraySize(array);
    int target = size; //int target = (isSeries ? 0 : size);
    bool isSeries = ArrayGetAsSeries(array);
    
    if(isSeries) { ArraySetAsSeries(array, false); }
        // When ArraySetAsSeries, ArrayResize does not shift elements rightward
        // as theory ought to be (new blank elements at index 0). Simplest workaround
        // is to temporarily set to non-series, resize and add, then set back to series.
        // Theory: https://www.forexfactory.com/showthread.php?p=2878455#post2878455
        // Workaround: https://www.forexfactory.com/showthread.php?p=4686709#post4686709

    if(maxSize > 0 && target >= maxSize) {
        int maxDiff = target-maxSize+1;
        libCSS_helper_ArrayDelete(array, 0, maxDiff, false);
        ArrayResize(array, maxSize);
        target = maxSize-1;
    } else {
        ArrayResize(array, size+1);
    }
    
    array[target] = unit;
    
    if(isSeries) { ArraySetAsSeries(array, true); }
    
    return size + 1;
}

template<typename T>
int libCSS_helper_ArrayReserve(T &array[], int reserveSize) {
    int size;
    
    size = ArraySize(array);
    ArrayResize(array, size, reserveSize);
    
    return size + reserveSize;
}

string libCSS_helper_StringTrim(string inputStr) {
#ifdef __MQL5__
    string workStr = inputStr;
    StringTrimRight(workStr);
    StringTrimLeft(workStr);
    
    return workStr;
#else
    return StringTrimLeft(StringTrimRight(inputStr));
#endif  
}

int libCSS_helper_ArrayTsearch(string &array[], string value, int count=-1, int start=0, int direction=MODE_ASCEND, bool caseSensitive=true) {
    if(count < 0) { count = ArraySize(array)-start; }
    if(start >= ArraySize(array)) { return -1; }
    
    for(int i = start; i < start+count; i++) {
        if(StringCompare(array[i], value, caseSensitive) == 0) { return i; }
    }

    return -1;
}

//+------------------------------------------------------------------+
//| Symbol Helpers                                                   |
//+------------------------------------------------------------------+

int libCSS_symbolHelper_getAllSymbols(string &allSymBuffer[]) {
    int count = SymbolsTotal(false);
    libCSS_helper_ArrayReserve(allSymBuffer, count);
    
    for(int i = 0; i < count; i++) {
        string symName = SymbolName(i, false);
        if(libCSS_symbolHelper_getSymbolUsable(symName)) {
            libCSS_helper_ArrayPush(allSymBuffer, symName);
        }
    }
    
    return ArraySize(allSymBuffer);
}

bool libCSS_symbolHelper_getSymbolUsable(string symName) {
   return (
      //SymbolInfoInteger(symName, SYMBOL_TRADE_CALC_MODE) == 0 // forex type
      /*&& */SymbolInfoInteger(symName, SYMBOL_TRADE_MODE) > 0 // not disabled for trading
   );
}

string libCSS_symbolHelper_getCompareSymbol(int symType=0) {
    int count = SymbolsTotal(false);
    
    for(int i = 0; i < count; i++) {
        string symName = SymbolName(i, false);
        if(SymbolInfoInteger(symName, SYMBOL_TRADE_CALC_MODE) == symType) { return symName; }
    }
    
    return "";
}

string libCSS_symbolHelper_getSymbolPrefix(string symName) {
    string baseCur = libCSS_symbolHelper_getSymbolBaseCurrency(symName);
    string quoteCur = libCSS_symbolHelper_getSymbolQuoteCurrency(symName);
    
    if(StringLen(symName) > StringLen(baseCur) + StringLen(quoteCur)) {
        int basePos = StringFind(symName, baseCur);
        if(basePos > 0) {
            return StringSubstr(symName, 0, basePos);
        }
    }
    
    return "";
}

string libCSS_symbolHelper_getSymbolSuffix(string symName) {
    string baseCur = libCSS_symbolHelper_getSymbolBaseCurrency(symName);
    string quoteCur = libCSS_symbolHelper_getSymbolQuoteCurrency(symName);
    
    if(StringLen(symName) > StringLen(baseCur) + StringLen(quoteCur)) {
        int quotePos = StringFind(symName, quoteCur);
        if(quotePos >= StringLen(baseCur)) {
            return StringSubstr(symName, quotePos+StringLen(quoteCur));
        }
    }
    
    return "";
}

string libCSS_symbolHelper_fixSymbolName(string symName, string compareName = NULL) {
    // todo: remove nonexistant -fixes if necessary

    // we need to compare given symName to a market-provided symName, and add prefix and suffix if necessary
    if(StringLen(compareName) <= 0) { compareName = libCSS_symbolHelper_getCompareSymbol(); }
    
    string prefix = libCSS_symbolHelper_getSymbolPrefix(compareName);
    string suffix = libCSS_symbolHelper_getSymbolSuffix(compareName);
    
    if(StringLen(suffix) > 0 && StringFind(symName, suffix) != StringLen(symName)-StringLen(suffix)) { symName = symName + suffix; }
    if(StringLen(prefix) > 0 && StringFind(symName, prefix) != 0) { symName = prefix + symName; }
    
    return symName;
}

string libCSS_symbolHelper_stripSymbolName(string symName) {
    string prefix = libCSS_symbolHelper_getSymbolPrefix(symName);
    string suffix = libCSS_symbolHelper_getSymbolSuffix(symName);

    if(StringLen(prefix) > 0) { StringReplace(symName, prefix, ""); }
    if(StringLen(suffix) > 0) { StringReplace(symName, suffix, ""); }
    
    return symName;    
}

string libCSS_symbolHelper_getSymbolBaseCurrency(string symName) {
    string baseCur;
    string quoteCur;
    SymbolInfoString(symName, SYMBOL_CURRENCY_BASE, baseCur);
    SymbolInfoString(symName, SYMBOL_CURRENCY_PROFIT, quoteCur);
    
    // For non-forex (gas, crude, etc.), base and quote may be reported as same (USD/USD)
    // In this case, return the entire symName as the base currency
    // fixSymName and stripSymName, prefixes and suffixes, should cooperate
    // by passing the original symName every time
    if(baseCur == quoteCur
        && SymbolInfoInteger(symName, SYMBOL_TRADE_CALC_MODE) != 0 // not forex
    ) { return symName; }
    else { return baseCur; }
}

string libCSS_symbolHelper_getSymbolQuoteCurrency(string symName) {
    string result;
    SymbolInfoString(symName, SYMBOL_CURRENCY_PROFIT, result);
    return result;
}
