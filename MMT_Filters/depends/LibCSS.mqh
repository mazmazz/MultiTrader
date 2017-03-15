//+------------------------------------------------------------------+
//|                                                       libCSS_mq4 |
//|                      Copyright 2013, Deltabron - Paul Geirnaerdt |
//|                                          http://www.deltabron.nl |
//+------------------------------------------------------------------+

#define libCSS_version            "v1.1.2"
#define libCSS_EPSILON            0.00000001
#define libCSS_CURRENCYCOUNT      8

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

string libCSS_currentSymbol             = "";
string libCSS_currentBase               = "";
string libCSS_currentQuote              = "";

libCSS_versions libCSS_useCalcMethod  = VerLibCSS;
bool    libCSS_ignoreFuture             = true;
bool    libCSS_sundayCandlesDetected    = false;
bool    libCSS_addSundayToMonday        = false;
bool    libCSS_useOnlySymbolOnChart     = false;
string  libCSS_cacheSymbol              = "EURUSD";
int     libCSS_cacheTimeframe           = PERIOD_M1;
double  libCSS_cacheVolume              = 0;
bool    libCSS_cacheFirstRunComplete    = false;
string  libCSS_symbolsToWeigh           = "GBPNZD,EURNZD,GBPAUD,GBPCAD,GBPJPY,GBPCHF,CADJPY,EURCAD,EURAUD,USDCHF,GBPUSD,EURJPY,NZDJPY,AUDCHF,AUDJPY,USDJPY,EURUSD,NZDCHF,CADCHF,AUDNZD,NZDUSD,CHFJPY,AUDCAD,USDCAD,NZDCAD,AUDUSD,EURCHF,EURGBP";
int     libCSS_symbolCount;
string  libCSS_symbolNames[];
string  libCSS_currencyNames[libCSS_CURRENCYCOUNT]        = { "USD", "EUR", "GBP", "CHF", "JPY", "AUD", "CAD", "NZD" };
double  libCSS_currencyValues[libCSS_CURRENCYCOUNT];      // Currency slope strength
double  libCSS_currencyOccurrences[libCSS_CURRENCYCOUNT]; // Holds the number of occurrences of each currency in symbols
int libCSS_maPeriod = 21; // SuperSlope = 7
int libCSS_atrPeriod = 100; // SuperSlope = 50
int libCSS_rsiWorkPeriod = 17;
int libCSS_rsiPeriod = 2; 

//+------------------------------------------------------------------+
//| libCSS_init()                                                    |
//+------------------------------------------------------------------+
void libCSS_init()
{
   libCSS_initSymbols();

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
   
   // Get extra characters on this crimmal's symbol names
   string symbolExtraChars = StringSubstr(Symbol(), 6, 4);

   // Trim user input
   libCSS_symbolsToWeigh = StringTrimLeft(libCSS_symbolsToWeigh);
   libCSS_symbolsToWeigh = StringTrimRight(libCSS_symbolsToWeigh);

   // Add extra comma
   if (StringSubstr(libCSS_symbolsToWeigh, StringLen(libCSS_symbolsToWeigh) - 1) != ",")
   {
      libCSS_symbolsToWeigh = StringConcatenate(libCSS_symbolsToWeigh, ",");   
   }   

   // Split user input
   i = StringFind( libCSS_symbolsToWeigh, "," ); 
   while ( i != -1 )
   {
      int size = ArraySize(libCSS_symbolNames);
      string newSymbol = StringConcatenate(StringSubstr(libCSS_symbolsToWeigh, 0, i), symbolExtraChars);
      if ( MarketInfo( newSymbol, MODE_TRADEALLOWED ) > libCSS_EPSILON )
      {
         ArrayResize( libCSS_symbolNames, size + 1 );
         // Set array
         libCSS_symbolNames[size] = newSymbol;
      }
      // Trim symbols
      libCSS_symbolsToWeigh = StringSubstr(libCSS_symbolsToWeigh, i + 1);
      i = StringFind(libCSS_symbolsToWeigh, ","); 
   }
   
   // Kill unwanted symbols from array
   if ( libCSS_useOnlySymbolOnChart )
   {
      libCSS_symbolCount = ArraySize(libCSS_symbolNames);
      string tempNames[];
      for ( i = 0; i < libCSS_symbolCount; i++ )
      {
         for ( int j = 0; j < libCSS_CURRENCYCOUNT; j++ )
         {
            if ( StringFind( Symbol(), libCSS_currencyNames[j] ) == -1 )
            {
               continue;
            }
            if ( StringFind( libCSS_symbolNames[i], libCSS_currencyNames[j] ) != -1 )
            {  
               int size = ArraySize( tempNames );
               ArrayResize( tempNames, size + 1 );
               tempNames[size] = libCSS_symbolNames[i];
               break;
            }
         }
      }
      for ( i = 0; i < ArraySize( tempNames ); i++ )
      {
         ArrayResize( libCSS_symbolNames, i + 1 );
         libCSS_symbolNames[i] = tempNames[i];
      }
   }
   
   libCSS_symbolCount = ArraySize(libCSS_symbolNames);
   // Print("symbolCount: ", symbolCount);

   ArrayInitialize( libCSS_currencyOccurrences, 0.0 );
   for ( i = 0; i < libCSS_symbolCount; i++ )
   {
      // Increase currency occurrence
      int currencyIndex = libCSS_getCurrencyIndex(StringSubstr(libCSS_symbolNames[i], 0, 3));
      libCSS_currencyOccurrences[currencyIndex]++;
      currencyIndex = libCSS_getCurrencyIndex(StringSubstr(libCSS_symbolNames[i], 3, 3));
      libCSS_currencyOccurrences[currencyIndex]++;
   }
}

//+------------------------------------------------------------------+
//| getCurrencyIndex(string currency)                                |
//+------------------------------------------------------------------+
int libCSS_getCurrencyIndex(string currency)
{
   for (int i = 0; i < libCSS_CURRENCYCOUNT; i++)
   {
      if (libCSS_currencyNames[i] == currency)
      {
         return(i);
      }   
   }   
   return (-1);
}

void libCSS_setCurrentSymbol(string symbol) {
    if(symbol != libCSS_currentSymbol) {
        libCSS_currentBase = StringSubstr(symbol, 0, 3);
        libCSS_currentQuote = StringSubstr(symbol, 3, 3);
        libCSS_currentSymbol = symbol;
    }
}

string libCSS_getSymbolBase(string symbol)
{
    libCSS_setCurrentSymbol(symbol);
    return libCSS_currentBase;
}

string libCSS_getSymbolQuote(string symbol)
{
    libCSS_setCurrentSymbol(symbol);
    return libCSS_currentQuote;
}

//+------------------------------------------------------------------+
//| getSlope()                                                       |
//+------------------------------------------------------------------+
double libCSS_getSlope( string symbol, int tf, int maperiod, int atrperiod, int shift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = shift;
   if ( libCSS_addSundayToMonday && libCSS_sundayCandlesDetected && tf == PERIOD_D1 )
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
         
         //case CalcLibCSS:
         //default:
         //  dblTma = libCSS_calcTmaTrue( symbol, tf, maperiod, shiftWithoutSunday );
         //  dblPrev = libCSS_calcPrevTrue( symbol, tf, maperiod, shiftWithoutSunday );
         //  break;
      }

      gadblSlope = ( dblTma - dblPrev ) / atr;
   }

   return ( gadblSlope );
}
////+------------------------------------------------------------------+
////| calcTmaTrue()                                                    |
////+------------------------------------------------------------------+
//double libCSS_calcTmaTrue( string symbol, int tf, int maperiod, int inx )
//{
//   return ( iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, inx ) );
//}

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

////+------------------------------------------------------------------+
////| calcPrevTrue()                                                   |
////+------------------------------------------------------------------+
//double libCSS_calcPrevTrue( string symbol, int tf, int maperiod, int inx )
//{
//   int maperiodLess = maperiod-1;
//   double dblSum  = iClose( symbol, tf, inx + 1 ) * maperiod;
//   double dblSumw = maperiod;
//   int jnx, knx;
//   
//   dblSum  += iClose( symbol, tf, inx ) * maperiodLess;
//   dblSumw += maperiodLess;
//         
//   for ( jnx = 1, knx = maperiodLess; jnx <= maperiodLess; jnx++, knx-- )
//   {
//      dblSum  += iClose( symbol, tf, inx + 1 + jnx ) * knx;
//      dblSumw += knx;
//   }
//   
//   return ( dblSum / dblSumw );
//}
 
//+------------------------------------------------------------------+
//| getCSS( double& CSS[], int tf, int shift )                       |
//+------------------------------------------------------------------+
void libCSS_getCSS( double &css[], int tf, int maperiod, int atrperiod, int shift, string symbol = "", bool flushCache = false )
{
   libCSS_getCSS(css, "", maperiod, atrperiod, shift, flushCache);
}

void libCSS_getCSS( double &css[], string symbol, int tf, int maperiod, int atrperiod, int shift, bool flushCache = false )
{
   int i;

   if ( !libCSS_cacheFirstRunComplete || flushCache || libCSS_cacheVolume != iVolume(libCSS_cacheSymbol, libCSS_cacheTimeframe, 0) )
   {
      ArrayInitialize(libCSS_currencyValues, 0.0);
      double slope = 0;

      switch(libCSS_useCalcMethod) {
         case VerSuperSlope:
            slope = libCSS_getSlope(symbol, tf, maperiod, atrperiod, shift);
            libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_getSymbolBase(symbol))] += slope;
            libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_getSymbolQuote(symbol))] -= slope;
            break;

         case VerLibCSS:
         case VerCSSv3_8:
         default:
            // Get Slope for all symbols and totalize for all currencies   
            for ( i = 0; i < libCSS_symbolCount; i++ )
            {
               slope = libCSS_getSlope(libCSS_symbolNames[i], tf, maperiod, atrperiod, shift);
               libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_getSymbolBase(libCSS_symbolNames[i]))] += slope;
               libCSS_currencyValues[libCSS_getCurrencyIndex(libCSS_getSymbolQuote(libCSS_symbolNames[i]))] -= slope;
            }
            for ( i = 0; i < libCSS_CURRENCYCOUNT; i++ )
            {
               // average
               if ( libCSS_currencyOccurrences[i] > 0 ) libCSS_currencyValues[i] /= libCSS_currencyOccurrences[i]; else libCSS_currencyValues[i] = 0;
            }
            break;
      }

      libCSS_cacheVolume = iVolume( libCSS_cacheSymbol, libCSS_cacheTimeframe, 0 );
      libCSS_cacheFirstRunComplete = true;
   }

   ArrayFree(css);
   ArrayCopy(css, libCSS_currencyValues);
}
//+------------------------------------------------------------------+
//| getCSSCurrency(string currency, int tf, int shift)               |
//+------------------------------------------------------------------+
double libCSS_getCSSCurrency( string currency, int tf, int maperiod, int atrperiod, int shift, bool flushCache = true ) {
   return libCSS_getCSSCurrency("", currency, tf, maperiod, atrperiod, shift, flushCache);
}

double libCSS_getCSSCurrency( string symbol, string currency, int tf, int maperiod, int atrperiod, int shift, bool flushCache = true )
{
   double css[];
   libCSS_getCSS( css, symbol, tf, maperiod, atrperiod, shift, flushCache );
   return ( css[libCSS_getCurrencyIndex(currency)] );
}

//+------------------------------------------------------------------+
//| getCSSdiff(int tf, int shift)                                    |
//+------------------------------------------------------------------+
double libCSS_getCSSDiff( string symbol, int tf, int maperiod, int atrperiod, int shift )
{
   double css[];
   libCSS_getCSS( css, tf, maperiod, atrperiod, shift );
   double diffLong = css[libCSS_getCurrencyIndex(libCSS_getSymbolBase(symbol))];
   double diffShort = css[libCSS_getCurrencyIndex(libCSS_getSymbolQuote(symbol))];
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
double libCSS_getGlobalMarketTrend( int tf, int maperiod, int atrperiod, int shift ) 
{
   double buffer[libCSS_CURRENCYCOUNT];
   libCSS_getCSS( buffer, tf, maperiod, atrperiod, shift );
      
   double gmt = 0;
   for ( int i = 0; i < libCSS_CURRENCYCOUNT; i++ )
   {
      gmt += MathPow(buffer[i], 2);
   }
   
   return ( gmt );
}

