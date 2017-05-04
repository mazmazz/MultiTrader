//+-----------------------------------------------------------------------+
//|                                                    LibCSS5 for MQL4/5 |
//| Copyright 2013, Deltabron - Paul Geirnaerdt - http://www.deltabron.nl |
//|                2017, Modified by mazmazz - https://github.com/mazmazz |
//+-----------------------------------------------------------------------+

#define libCSS_version            "v5.0.0"
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
// v5.0.0, 5/1/2017, modified by mazmazz - https://github.com/mazmazz
// * Added MQL5 compatibility
// * Added SuperSlope calculation
// * Added getCSSDelta, getCSSCross, getCSSTradeDirection, getGlobalMarketTrendDelta

//+------------------------------------------------------------------+
//| Internalize dependencies MC_Common and SymbolManager             |
//+------------------------------------------------------------------+

//#define _LibCSSInternal

#ifndef _LibCSSInternal
#include "../MC_Common/MC_Common.mqh"
#else

#ifdef _LibCSSInternal

//+------------------------------------------------------------------+
//| MQL4->MQL5 compatibility                                         |
//+------------------------------------------------------------------+

#ifdef __MQL5__
int TimeDayOfWeek(datetime date) {
    MqlDateTime tm;
    TimeToStruct(date, tm);
    return tm.day_of_week;
}

#define MODE_ASCEND 0

// for iStochastic, MQL5 equivalent is SIGNAL_LINE
#define MODE_SIGNAL 1

// for iBands, MQL5 equivalent is UPPER_BAND and LOWER_BAND
#define MODE_UPPER 1
#define MODE_LOWER 2
#endif // __MQL5__

#endif // else ifdef _LibCSSInternal

#endif // ifndef _LibCSSInternal

//+------------------------------------------------------------------+
//| Begin LibCSS Core                                                |
//+------------------------------------------------------------------+

enum TRADE_DIRECTION {
    TRADE_DIRECTION_NONE
    , TRADE_DIRECTION_LONG
    , TRADE_DIRECTION_SHORT
};

enum CSS_VERSION {
    CSS_VERSION_NONE, // None
    CSS_VERSION_CSS, // LibCSS
    CSS_VERSION_3_8, // CSS v3.8
    CSS_VERSION_SUPERSLOPE // SuperSlope
};

class CLibCSS {
    public:
    CSS_VERSION calcMethod;
    bool ignoreFuture;
    bool useOnlySymbolOnChart;
    
    int symbolCount;
    int currencyCount;
    string  symbolNames[];
    string  currencyNames[];        // = { "USD", "EUR", "GBP", "CHF", "JPY", "AUD", "CAD", "NZD" };
    int     currencyOccurrences[]; // Holds the number of occurrences of each currency in symbols
    
    CLibCSS();
    ~CLibCSS();
    void initSymbols(string symbolsToWeigh = NULL, bool addToExisting = false);
    void setPeriods(int maPeriodIn, int atrPeriodIn);
    
    double getSlope( string symbol, ENUM_TIMEFRAMES tf, int shift );
    
    void getCSS( double &css[], ENUM_TIMEFRAMES tf, int shift, string symbol = "" );
    void getCSS( double &css[], string symbol, ENUM_TIMEFRAMES tf, int shift );
    
    double getCSSCurrency( string currency, ENUM_TIMEFRAMES tf, int shift );
    double getCSSCurrency( string symbol, string currency, ENUM_TIMEFRAMES tf, int shift );
    
    double getCSSDiff( string symbol, ENUM_TIMEFRAMES tf, int shift, bool absolute = false );
    double getCSSDelta( string symbol, ENUM_TIMEFRAMES tf, int shift, int candles, bool absolute = false );
    TRADE_DIRECTION getCSSCross(string symbol, ENUM_TIMEFRAMES tf, int shift, int candles);
    bool getCSSTradeLevelCrossed(string symbol, ENUM_TIMEFRAMES tf, int shift, double tradeLevel);
    TRADE_DIRECTION getCSSTradeDirection(string symbol, ENUM_TIMEFRAMES tf, int shift, double differenceThreshold);
    
#ifdef __MQL4__
    double getSlopeRSI( string symbol, int workPeriod, int rsiPeriodIn, ENUM_TIMEFRAMES tf, int shift );
#endif
    double getGlobalMarketTrend( string symbol, ENUM_TIMEFRAMES tf, int shift ); 
    double getGlobalMarketTrendDelta( string symbol, ENUM_TIMEFRAMES tf, int shift, int candles );
    
    int getCurrencyIndex(string currency);

    private:
    bool sundayCandlesDetected;
    int maperiod;
    int atrperiod;
    double  currencyValues[];      // Currency slope strength
    
    string lastSymbol;
    ENUM_TIMEFRAMES lastTf;
    int lastMaperiod;
    int lastAtrperiod;
    int lastShift;
    datetime lastDatetime;
    bool firstRun;
    string lastSymbolsToWeigh;
    
#ifdef __MQL5__
    int iAtrHandles[];
    int iMaHandles[];
#endif

    void initCurrencies(int newSymbolCount);

    void calcCSS( string symbol, ENUM_TIMEFRAMES tf, int shift );
    bool isCSSParamsNew(string symbol, ENUM_TIMEFRAMES tf, int shift);
    
    bool isSundayCandle(string symbol = NULL, int shift = -1);
    int calcBarOpenTime(string symbol, ENUM_TIMEFRAMES tf, int shift);
    double calcTma(string symbol, ENUM_TIMEFRAMES tf, int ma_period, int shift);
    double calcBarClose(string symbol, ENUM_TIMEFRAMES tf, int shift);
    double calcAtr(string symbol, ENUM_TIMEFRAMES tf, int atr_period, int shift);
    double calcMa(string symbol, ENUM_TIMEFRAMES tf, int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, int applied_price, int shift);
    double calcRsiByArray(double &array[], int total, int period, int shift);
};

void CLibCSS::CLibCSS() {
    calcMethod = CSS_VERSION_CSS;
    maperiod=21;
    atrperiod=100;
    ignoreFuture = true;
    sundayCandlesDetected = false;
    useOnlySymbolOnChart = false;
    symbolCount = 0;
    currencyCount = 0;
    
    firstRun = true;
    lastSymbol = "";
    lastTf = NULL;
    lastMaperiod = 0;
    lastAtrperiod = 0;
    lastShift = 0;
    lastDatetime = 0;
    lastSymbolsToWeigh = NULL;
    
    sundayCandlesDetected = isSundayCandle();
}

void CLibCSS::~CLibCSS() {
#ifdef __MQL5__
    int size = ArraySize(iAtrHandles);
    for(int i = 0; i < size; i++) {
        if(iAtrHandles[i] != INVALID_HANDLE) { IndicatorRelease(iAtrHandles[i]); }
    }
    
    size = ArraySize(iMaHandles);
    for(int i = 0; i < size; i++) {
        if(iMaHandles[i] != INVALID_HANDLE) { IndicatorRelease(iMaHandles[i]); }
    }
#endif
}

//+------------------------------------------------------------------+
// Init

void CLibCSS::initSymbols(string symbolsToWeigh = NULL, bool addToExisting = false) {
    symbolsToWeigh = Common::StringTrim(symbolsToWeigh);
    
    if(!addToExisting) {
        ArrayFree(symbolNames);
        symbolCount = 0;
    } else {
        if(symbolsToWeigh == lastSymbolsToWeigh) { return; }
        if(calcMethod != CSS_VERSION_SUPERSLOPE && StringLen(symbolsToWeigh) <= 0) { return; }
    }
    
    string symbolsToWeighIn[];
    int newSymbolCount = 0;
    
    if(useOnlySymbolOnChart || (calcMethod == CSS_VERSION_SUPERSLOPE && StringLen(symbolsToWeigh) <= 0)) {
        if(SymbolManager::isSymbolTradable(Symbol())) { 
            if(!addToExisting || Common::ArrayFind(symbolNames, Symbol()) < 0) { 
                Common::ArrayPush(symbolNames, Symbol()); 
                newSymbolCount++;
            }
        }
    } else if(!addToExisting && StringLen(symbolsToWeigh) <= 0) {
        newSymbolCount = SymbolManager::getAllSymbols(symbolNames);
    } else {
        StringSplit(
            symbolsToWeigh
            , ','
            , symbolsToWeighIn
        );

        // load symbolNames
        Common::ArrayReserve(symbolNames, ArraySize(symbolsToWeighIn));

        for(int i = 0; i < ArraySize(symbolsToWeighIn); i++) {
            string symName = SymbolManager::fixSymbolName(symbolsToWeighIn[i]);
            if(SymbolManager::isSymbolTradable(symName)) { 
                if(!addToExisting || Common::ArrayFind(symbolNames, symName) < 0) { 
                    Common::ArrayPush(symbolNames, symName); 
                    newSymbolCount++;
                }
            }
        }
    }

    symbolCount = ArraySize(symbolNames);
    
    initCurrencies(newSymbolCount);
    
    firstRun = (!firstRun ? !addToExisting : true);
    lastSymbolsToWeigh = symbolsToWeigh;
}

void CLibCSS::initCurrencies(int newSymbolCount) {
    if(newSymbolCount >= symbolCount) { // !addToExisting
       ArrayFree(currencyNames);
       ArrayFree(currencyOccurrences);
       ArrayFree(currencyValues);
       currencyCount = 0;
    }
   
    for ( int i = MathMax(symbolCount-newSymbolCount, 0); i < symbolCount; i++ ) {
        // If currency not in array, then add to currencyNames
        string baseCur = SymbolManager::getSymbolBaseCurrency(symbolNames[i]);
        string quoteCur = SymbolManager::getSymbolQuoteCurrency(symbolNames[i]);
        
        if(Common::ArrayFind(currencyNames, baseCur) < 0) {
            int newSize = Common::ArrayPush(currencyNames, baseCur);
            if(ArrayResize(currencyOccurrences, newSize) == newSize) { currencyOccurrences[newSize-1] = 0; }
            if(ArrayResize(currencyValues, newSize) == newSize) { currencyValues[newSize-1] = 0; }
            currencyCount = newSize;
        }
        
        if(Common::ArrayFind(currencyNames, quoteCur) < 0) {
            int newSize = Common::ArrayPush(currencyNames, quoteCur);
            if(ArrayResize(currencyOccurrences, newSize) == newSize) { currencyOccurrences[newSize-1] = 0; }
            if(ArrayResize(currencyValues, newSize) == newSize) { currencyValues[newSize-1] = 0; }
            currencyCount = newSize;
        }
        
        // Increase currency occurrence
        currencyOccurrences[getCurrencyIndex(baseCur)]++;
        currencyOccurrences[getCurrencyIndex(quoteCur)]++;
    }
}


void CLibCSS::setPeriods(int maPeriodIn, int atrPeriodIn) {
    if(maPeriodIn == maperiod && atrPeriodIn == atrperiod) { return; }
    
    ArrayFill(currencyValues, 0, ArraySize(currencyValues), 0);
    
    maperiod = maPeriodIn;
    atrperiod = atrPeriodIn;
    firstRun = true; // force CSS re-calc
}

//+------------------------------------------------------------------+
//| getSlope()                                                       |
//+------------------------------------------------------------------+
double CLibCSS::getSlope( string symbol, ENUM_TIMEFRAMES tf, int shift )
{
    double dblTma = 0, dblPrev = 0;
    if ( sundayCandlesDetected && tf == PERIOD_D1 ) {
        if ( isSundayCandle(symbol, shift)  ) shift++;
    }
    
    double atr = calcAtr(symbol, tf, atrperiod, shift + 10) / 10;
    double gadblSlope = 0.0;
    if (atr != 0) {
        if(!ignoreFuture && calcMethod != CSS_VERSION_SUPERSLOPE) { // doesn't appear to be an option in LibCSS and SuperSlope, just CSSv3.8
            dblTma=calcTma(symbol,tf,maperiod,shift);
            dblPrev=calcTma(symbol,tf,maperiod,shift+1);
        } else {
            // This is used in SuperSlope and CSSv3.8 (ignoreFuture = true), and is equivalent to LibCSS's method
                // 231, 251, and 20(?) are hardcoded to the original maPeriod=21 and atrPeriod=100
                // But I don't know how they're determined. SuperSlope uses these same values for its own ma/atrPeriod
                // so just do the same
            
            dblTma=calcMa(symbol,tf,maperiod,0,MODE_LWMA,PRICE_CLOSE,shift);
            if(dblTma == 0) { return 0; } // this means iMA failed in MT5 because it hasn't finished loading, so return 0
            
            dblPrev=
                ((calcMa(symbol,tf,maperiod,0,MODE_LWMA,PRICE_CLOSE,shift+1)*231)
                + (calcBarClose(symbol,tf,shift)*20)
                )
                /251
                ;
        }
        gadblSlope = ( dblTma - dblPrev ) / atr;
    }

   return ( gadblSlope );
}

void CLibCSS::calcCSS( string symbol, ENUM_TIMEFRAMES tf, int shift ) {
   int i;

   if (isCSSParamsNew(symbol, tf, shift)) {
      ArrayInitialize(currencyValues, 0.0);
      double slope = 0;

      switch(calcMethod) {
         case CSS_VERSION_SUPERSLOPE:
            slope = getSlope(symbol, tf, shift);
            currencyValues[getCurrencyIndex(SymbolManager::getSymbolBaseCurrency(symbol))] += slope;
            currencyValues[getCurrencyIndex(SymbolManager::getSymbolQuoteCurrency(symbol))] -= slope;
            break;

         case CSS_VERSION_3_8:
         case CSS_VERSION_CSS:
         default:
            // Get Slope for all symbols and totalize for all currencies   
            for ( i = 0; i < symbolCount; i++ )
            {
               slope = getSlope(symbolNames[i], tf, shift);
               currencyValues[getCurrencyIndex(SymbolManager::getSymbolBaseCurrency(symbolNames[i]))] += slope;
               currencyValues[getCurrencyIndex(SymbolManager::getSymbolQuoteCurrency(symbolNames[i]))] -= slope;
            }
            for ( i = 0; i < currencyCount; i++ )
            {
               // average
               if ( currencyOccurrences[i] > 0 ) currencyValues[i] /= currencyOccurrences[i]; else currencyValues[i] = 0;
            }
            break;
      }
   }
}

bool CLibCSS::isCSSParamsNew(string symbol,ENUM_TIMEFRAMES tf,int shift) {
    datetime newDatetime = shift == 0 ? TimeCurrent() : calcBarClose(symbol, tf, shift);
    
    if((calcMethod == CSS_VERSION_SUPERSLOPE ? symbol != lastSymbol : false) // don't check for symbol with CSS
        || tf != lastTf
        || maperiod != lastMaperiod
        || atrperiod != lastAtrperiod
        || shift != lastShift // todo: shift multidim array to store currencyValues if shift is the only change
        || newDatetime != lastDatetime
        || firstRun
    ) {
        lastSymbol = symbol;
        lastTf = tf;
        lastMaperiod = maperiod;
        lastAtrperiod = atrperiod;
        lastShift = shift;
        lastDatetime = newDatetime;
        firstRun = false;
        return true;
    } else { return false; }
}
 
//+------------------------------------------------------------------+
//| getCSS and getCSSCurrency
//+------------------------------------------------------------------+
void CLibCSS::getCSS( double &css[], ENUM_TIMEFRAMES tf, int shift, string symbol = "" )
{
   getCSS(css, "", tf, shift);
}

void CLibCSS::getCSS( double &css[], string symbol, ENUM_TIMEFRAMES tf, int shift )
{
   calcCSS(symbol, tf, shift);

   ArrayFree(css);
   ArrayCopy(css, currencyValues);
}

double CLibCSS::getCSSCurrency( string currency, ENUM_TIMEFRAMES tf, int shift ) {
   return getCSSCurrency("", currency, tf, shift);
}

double CLibCSS::getCSSCurrency( string symbol, string currency, ENUM_TIMEFRAMES tf, int shift )
{
    int curIdx = getCurrencyIndex(currency);
    if(curIdx < 0) { return TRADE_DIRECTION_NONE; }
    calcCSS( symbol, tf, shift );
    
    return ( currencyValues[curIdx] );
}

//+------------------------------------------------------------------+
//| getCSSDiff, Delta, Cross, TradeLevelCrossed, TradeDirection
//+------------------------------------------------------------------+
double CLibCSS::getCSSDiff( string symbol, ENUM_TIMEFRAMES tf, int shift, bool absolute = false )
{
    int curIdx = getCurrencyIndex(SymbolManager::getSymbolBaseCurrency(symbol));
    int curQuoteIdx = getCurrencyIndex(SymbolManager::getSymbolQuoteCurrency(symbol));
    if(curIdx < 0 || curQuoteIdx < 0) { return 0; }
    calcCSS( symbol, tf, shift );
    
    double slopeBase = currencyValues[curIdx];
    double slopeQuote = currencyValues[curQuoteIdx];
    
    if(absolute) {
        if(calcMethod == CSS_VERSION_SUPERSLOPE) { return MathAbs(slopeBase); }
        else { return MathAbs(slopeBase-slopeQuote)/2; } // MCH does this for CSS
    }
    else { return ( slopeBase - slopeQuote ); }
}

double CLibCSS::getCSSDelta( string symbol, ENUM_TIMEFRAMES tf, int shift, int candles, bool absolute = false ) {
    if(candles == 0 || shift+candles < 0) { return 0; }
    double diffA = getCSSDiff(symbol, tf, shift, absolute);
    double diffB = getCSSDiff(symbol, tf, shift+candles, absolute);
    
    return diffA-diffB;
}

TRADE_DIRECTION CLibCSS::getCSSCross(string symbol, ENUM_TIMEFRAMES tf, int shift, int candles) {
    if(candles == 0 || shift+candles < 0) { return TRADE_DIRECTION_NONE; }
    double diffB = getCSSDiff(symbol, tf, shift+candles);
    double diffA = getCSSDiff(symbol, tf, shift);
    
    if(diffB < 0 && diffA > 0) { return TRADE_DIRECTION_LONG; }
    else if(diffA < 0 && diffB > 0) { return TRADE_DIRECTION_SHORT; }
    else { return TRADE_DIRECTION_NONE; }
}

bool CLibCSS::getCSSTradeLevelCrossed(string symbol, ENUM_TIMEFRAMES tf, int shift, double tradeLevel) {
    if(tradeLevel == 0) { return true; }
    
    double slope = getCSSCurrency(symbol, SymbolManager::getSymbolBaseCurrency(symbol), tf, shift);
    
    return MathAbs(slope) > MathAbs(tradeLevel);
}

TRADE_DIRECTION CLibCSS::getCSSTradeDirection(string symbol, ENUM_TIMEFRAMES tf, int shift, double differenceThreshold) {
    int curIdx = getCurrencyIndex(SymbolManager::getSymbolBaseCurrency(symbol));
    if(curIdx < 0) { return TRADE_DIRECTION_NONE; }
    calcCSS(symbol, tf, shift);
    
    if(currencyValues[curIdx] > differenceThreshold * (calcMethod == CSS_VERSION_SUPERSLOPE ? 0.5 : 1)) { return TRADE_DIRECTION_LONG; }
    else if(currencyValues[curIdx] < differenceThreshold * (calcMethod == CSS_VERSION_SUPERSLOPE ? -0.5 : -1)) { return TRADE_DIRECTION_SHORT; }
    else { return TRADE_DIRECTION_NONE; }
}

//+------------------------------------------------------------------+
//| getSlopeRSI( string symbol, ENUM_TIMEFRAMES tf, int shift )                  |
//+------------------------------------------------------------------+
#ifdef __MQL4__
double CLibCSS::getSlopeRSI( string symbol, int workPeriod, int rsiPeriod, ENUM_TIMEFRAMES tf, int shift )
{
   double slope[];
   //int workPeriod = 17;
   ArrayResize( slope, workPeriod );
   ArraySetAsSeries( slope, true );
   for ( int i = 0; i < workPeriod; i++ )
   {
      slope[i] = getSlope( symbol, tf, shift + i );
   }
   return( calcRsiByArray( slope, workPeriod, rsiPeriod, 0 ) );
}
#endif

//+------------------------------------------------------------------+
//| getGlobalMarketTrend( ENUM_TIMEFRAMES tf, int shift )                        |
//+------------------------------------------------------------------+
double CLibCSS::getGlobalMarketTrend( string symbol, ENUM_TIMEFRAMES tf, int shift ) 
{
   calcCSS( symbol, tf, shift );
      
   double gmt = 0;
   for ( int i = 0; i < currencyCount; i++ )
   {
      gmt += MathPow(currencyValues[i], 2);
   }
   
   return ( gmt );
}

double CLibCSS::getGlobalMarketTrendDelta( string symbol, ENUM_TIMEFRAMES tf, int shift, int candles ) 
{
    if(candles == 0 || shift+candles < 0) { return 0; }
    double gmtA = getGlobalMarketTrend(symbol, tf, shift);
    double gmtB = getGlobalMarketTrend(symbol, tf, shift+candles);
    
    return gmtA - gmtB;
}

//+------------------------------------------------------------------+
//| getCurrencyIndex(string currency)                                |
//+------------------------------------------------------------------+
int CLibCSS::getCurrencyIndex(string currency)
{
   for (int i = 0; i < currencyCount; i++)
   {
      if (currencyNames[i] == currency)
      {
         return(i);
      }   
   }   
   return (-1);
}

//+------------------------------------------------------------------+
// Calc Helpers                                                      |
//+------------------------------------------------------------------+

bool CLibCSS::isSundayCandle(string symbol = NULL, int shift = -1) {
    if(shift < 0) {
        for ( int i = 0; i < 8; i++ ) {
            if ( TimeDayOfWeek( calcBarOpenTime( symbol, PERIOD_D1, i ) ) == 0 ) {
                return true;
            }
        }
        return false;
    } else {
        return TimeDayOfWeek( calcBarOpenTime( symbol, PERIOD_D1, shift ) ) == 0;
    }
}

int CLibCSS::calcBarOpenTime(string symbol, ENUM_TIMEFRAMES tf,int shift) {
    datetime barUnits[];
    if(CopyTime(symbol, tf, shift, 1, barUnits) >=1) {
        return barUnits[0];
    } else { return -1; }
}

double CLibCSS::calcBarClose(string symbol, ENUM_TIMEFRAMES tf, int shift) {
    double barUnits[];
    if(CopyClose(symbol, tf, shift, 1, barUnits) >=1) {
        return barUnits[0];
    } else { return 0; }
}

double CLibCSS::calcMa(string symbol, ENUM_TIMEFRAMES tf, int ma_period, int ma_shift, ENUM_MA_METHOD ma_method, int applied_price, int shift) {
#ifdef __MQL4__
    return iMA(symbol, tf, ma_period, ma_shift, ma_method, applied_price, shift);
#else
#ifdef __MQL5__
    int handle = iMA(symbol, tf, ma_period, ma_shift, ma_method, applied_price);
    if(Common::ArrayFind(iMaHandles, handle) < 0) { Common::ArrayPush(iMaHandles, handle); }
    return Common::GetSingleValueFromBuffer(handle, shift, 0);
#endif
#endif
}

double CLibCSS::calcAtr(string symbol, ENUM_TIMEFRAMES tf, int atr_period, int shift) {
#ifdef __MQL4__
    return iATR(symbol, tf, atr_period, shift);
#else
#ifdef __MQL5__
    int handle = iATR(symbol, tf, atr_period);
    if(Common::ArrayFind(iAtrHandles, handle) < 0) { Common::ArrayPush(iAtrHandles, handle); }
    return Common::GetSingleValueFromBuffer(handle, shift, 0);
#endif
#endif
}

double CLibCSS::calcTma(string symbol, ENUM_TIMEFRAMES tf, int ma_period, int shift)
{
   double dblSum  = calcBarClose( symbol, tf, shift ) * ma_period;
   double dblSumw = ma_period;
   int maperiodLess = ma_period-1;
   int jnx,knx;

   for(jnx=1,knx=maperiodLess; jnx<=maperiodLess; jnx++,knx--)
     {
      dblSum  += calcBarClose(symbol, tf, shift + jnx) * knx;
      dblSumw += knx;

      if(jnx<=shift)
        {
         dblSum  += calcBarClose(symbol, tf, shift - jnx) * knx;
         dblSumw += knx;
        }
     }

   return ( dblSum / dblSumw );
}

double CLibCSS::calcRsiByArray(double &array[], int total, int period, int shift) {
    // todo: implement for MT5: https://www.mql5.com/en/code/47
    
#ifdef __MQL4__
    return iRSIOnArray(array, total, period, shift);
#else
#ifdef __MQL5__
    return 0;
#endif
#endif
}

//+------------------------------------------------------------------+
//| Dependencies -- MC_Common and SymbolManager                      |
//+------------------------------------------------------------------+

#ifdef _LibCSSInternal

class Common {
    public:
    template<typename T>
    static void ArrayDelete(T &array[],int index, int diff=1, bool resize=true);
    template<typename T>
    static int ArrayPush(T &array[], T unit, int maxSize = -1);
    template<typename T>
    static int ArrayReserve(T &array[], int reserveSize);
    static string StringTrim(string inputStr);
    static int ArrayTsearch(string &array[], string value, int count=-1, int start=0, int direction=MODE_ASCEND, bool caseSensitive=true);
    template <typename T>
    static int ArrayFind(T &array[], T needle);
    
#ifdef __MQL5__
    static double GetSingleValueFromBuffer(int indiHandle, int shift=0, int bufferNum=0);
#endif
};

// https://github.com/dingmaotu/mql4-lib
template<typename T>
void Common::ArrayDelete(T &array[],int index, int diff=1, bool resize=true) {
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
int Common::ArrayPush(T &array[], T unit, int maxSize = -1) {
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
        Common::ArrayDelete(array, 0, maxDiff, false);
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
int Common::ArrayReserve(T &array[], int reserveSize) {
    int size = ArraySize(array);
    ArrayResize(array, size, reserveSize);
    
    return size + reserveSize;
}

string Common::StringTrim(string inputStr) {
#ifdef __MQL5__
    string workStr = inputStr;
    StringTrimRight(workStr);
    StringTrimLeft(workStr);
    
    return workStr;
#else
    return StringTrimLeft(StringTrimRight(inputStr));
#endif  
}

int Common::ArrayTsearch(string &array[], string value, int count=-1, int start=0, int direction=MODE_ASCEND, bool caseSensitive=true) {
    if(count < 0) { count = ArraySize(array)-start; }
    if(start >= ArraySize(array)) { return -1; }
    
    for(int i = start; i < start+count; i++) {
        if(StringCompare(array[i], value, caseSensitive) == 0) { return i; }
    }

    return -1;
}

template<typename T>
int Common::ArrayFind(T &array[], T needle) {
    int size = ArraySize(array);
    for(int i = 0; i < size; i++) {
        if(array[i] == needle) { return i; }
    }
    return -1;
}

#ifdef __MQL5__

//+---
//| WINAPI Sleep import for indicators - Use only for testing        |
//| See Common::GetSingleValueFromBuffer                             |
//+---

//#define _LibCSSTestSleep
//
//#ifdef _LibCSSTestSleep
//#import "kernel32.dll"
//void Sleep(uint milliseconds);
//#import
//#endif

double Common::GetSingleValueFromBuffer(int indiHandle, int shift=0, int bufferNum=0) {
    if(indiHandle == INVALID_HANDLE) { return -1; }
    if(shift < 0) { shift = 0; }
    if(bufferNum < 0) { bufferNum = 0; }
    
    // Retry if indi is slow to load (BarsCalculated returns -1)
//    bool isLoading = false, checkShift = false; int lastCalculated = 0;
//    for(int i = 0; i < 20; i++) {
//        int newCalculated = BarsCalculated(indiHandle);
//        if(newCalculated < (checkShift ? shift+1 : 1)) {
//            isLoading = true;
//            if(checkShift) {
//                if(newCalculated == lastCalculated) { 
//                    break; 
//                } // we may not be loading any more bars, so break.
//                else { lastCalculated = newCalculated; }
//            }
//        } else {
//            // If we've been loading, calculation may not have yet reached shift, so keep waiting
//            // If we're not loading, we don't check for shift because shift may be invalid
//            if(isLoading) {
//                if(!checkShift && i == 19) { i--; } // run one more time to check for shift
//                else if(checkShift) { 
//                    break; 
//                } // we reach here once we check BarsCalculated for shift and it succeeds
//                checkShift = true; 
//            } else { break; }
//        }
//#ifdef _LibCSSTestSleep
//        kernel32::Sleep(50);
//#else
//        Sleep(50);
//#endif
//    }
    
    double buffer[1];
    int result = CopyBuffer(indiHandle, bufferNum, shift, 1, buffer);
    if(result < 1) { return 0; }
    else { return buffer[0]; }
}
#endif

//+------------------------------------------------------------------+
//| Symbol Helpers                                                   |
//+------------------------------------------------------------------+

class SymbolManager {
    public:
    static int getAllSymbols(string &allSymBuffer[]);
    static string getCompareSymbol(int symType=0);
    static string getSymbolPrefix(string symName);
    static string getSymbolSuffix(string symName);
    static string fixSymbolName(string symName, string compareName = NULL);
    static string stripSymbolName(string symName);
    static string getSymbolBaseCurrency(string symName);
    static string getSymbolQuoteCurrency(string symName);
    static bool isSymbolTradable(string symName);
};

int SymbolManager::getAllSymbols(string &allSymBuffer[]) {
    int count = SymbolsTotal(false);
    Common::ArrayReserve(allSymBuffer, count);
    
    for(int i = 0; i < count; i++) {
        string symName = SymbolName(i, false);
        if(isSymbolTradable(symName)) {
            Common::ArrayPush(allSymBuffer, symName);
        }
    }
    
    return ArraySize(allSymBuffer);
}

string SymbolManager::getCompareSymbol(int symType=0) {
    int count = SymbolsTotal(false);
    
    for(int i = 0; i < count; i++) {
        string symName = SymbolName(i, false);
        if(SymbolInfoInteger(symName, SYMBOL_TRADE_CALC_MODE) == symType) { return symName; }
    }
    
    return "";
}

string SymbolManager::getSymbolPrefix(string symName) {
    string baseCur = getSymbolBaseCurrency(symName);
    string quoteCur = getSymbolQuoteCurrency(symName);
    
    if(StringLen(symName) > StringLen(baseCur) + StringLen(quoteCur)) {
        int basePos = StringFind(symName, baseCur);
        if(basePos > 0) {
            return StringSubstr(symName, 0, basePos);
        }
    }
    
    return "";
}

string SymbolManager::getSymbolSuffix(string symName) {
    string baseCur = getSymbolBaseCurrency(symName);
    string quoteCur = getSymbolQuoteCurrency(symName);
    
    if(StringLen(symName) > StringLen(baseCur) + StringLen(quoteCur)) {
        int quotePos = StringFind(symName, quoteCur);
        if(quotePos >= StringLen(baseCur)) {
            return StringSubstr(symName, quotePos+StringLen(quoteCur));
        }
    }
    
    return "";
}

string SymbolManager::fixSymbolName(string symName, string compareName = NULL) {
    // todo: remove nonexistant -fixes if necessary

    // we need to compare given symName to a market-provided symName, and add prefix and suffix if necessary
    if(StringLen(compareName) <= 0) { compareName = getCompareSymbol(); }
    
    string prefix = getSymbolPrefix(compareName);
    string suffix = getSymbolSuffix(compareName);
    
    if(StringLen(suffix) > 0 && StringFind(symName, suffix) != StringLen(symName)-StringLen(suffix)) { symName = symName + suffix; }
    if(StringLen(prefix) > 0 && StringFind(symName, prefix) != 0) { symName = prefix + symName; }
    
    return symName;
}

string SymbolManager::stripSymbolName(string symName) {
    string prefix = getSymbolPrefix(symName);
    string suffix = getSymbolSuffix(symName);

    if(StringLen(prefix) > 0) { StringReplace(symName, prefix, ""); }
    if(StringLen(suffix) > 0) { StringReplace(symName, suffix, ""); }
    
    return symName;    
}

string SymbolManager::getSymbolBaseCurrency(string symName) {
    string baseCur = NULL;
    string quoteCur = NULL;
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

string SymbolManager::getSymbolQuoteCurrency(string symName) {
    string result = NULL;
    SymbolInfoString(symName, SYMBOL_CURRENCY_PROFIT, result);
    return result;
}

bool SymbolManager::isSymbolTradable(string symName) {
    return (
        //SymbolInfoInteger(symName, SYMBOL_TRADE_CALC_MODE) == 0 // forex type
        SymbolInfoInteger(symName, SYMBOL_TRADE_MODE) > 0 // not disabled for trading
        && SymbolSelect(symName, true) // attempt add or select in Market Watch
        );
}
#endif
