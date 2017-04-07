//+------------------------------------------------------------------+
//|                                                     InitMQL4.mqh |
//|                                                 Copyright DC2008 |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "keiji"
#property copyright "DC2008"
#property link      "http://www.mql5.com"

#ifdef __MQL5__

//+------------------------------------------------------------------+
//| Constants

//#define OP_BUY 0           //Buy 
//#define OP_SELL 1          //Sell 
//#define OP_BUYLIMIT 2      //Pending order of BUY LIMIT type 
//#define OP_SELLLIMIT 3     //Pending order of SELL LIMIT type 
//#define OP_BUYSTOP 4       //Pending order of BUY STOP type 
//#define OP_SELLSTOP 5      //Pending order of SELL STOP type 
//---
#define MODE_OPEN 0
#define MODE_CLOSE 3
#define MODE_VOLUME 4 
#define MODE_REAL_VOLUME 5
#define MODE_TRADES 0
#define MODE_HISTORY 1
#define SELECT_BY_POS 0
#define SELECT_BY_TICKET 1
//---
#define DOUBLE_VALUE 0
#define FLOAT_VALUE 1
#define LONG_VALUE INT_VALUE
//---
#define CHART_BAR 0
#define CHART_CANDLE 1
//---
#define MODE_ASCEND 0
#define MODE_DESCEND 1
//---
#define MODE_LOW 1
#define MODE_HIGH 2
#define MODE_TIME 5
#define MODE_BID 9
#define MODE_ASK 10
#define MODE_POINT 11
#define MODE_DIGITS 12
#define MODE_SPREAD 13
#define MODE_STOPLEVEL 14
#define MODE_LOTSIZE 15
#define MODE_TICKVALUE 16
#define MODE_TICKSIZE 17
#define MODE_SWAPLONG 18
#define MODE_SWAPSHORT 19
#define MODE_STARTING 20
#define MODE_EXPIRATION 21
#define MODE_TRADEALLOWED 22
#define MODE_MINLOT 23
#define MODE_LOTSTEP 24
#define MODE_MAXLOT 25
#define MODE_SWAPTYPE 26
#define MODE_PROFITCALCMODE 27
#define MODE_MARGINCALCMODE 28
#define MODE_MARGININIT 29
#define MODE_MARGINMAINTENANCE 30
#define MODE_MARGINHEDGED 31
#define MODE_MARGINREQUIRED 32
#define MODE_FREEZELEVEL 33
//---
#define EMPTY -1

ENUM_TIMEFRAMES GetMql5TimeFrame(int tf)
  {
   switch(tf)
     {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);      
      default: return(PERIOD_CURRENT);
     }
  }

//+------------------------------------------------------------------+
//| Time

int TimeDayOfWeek(datetime date) {
    MqlDateTime tm;
    TimeToStruct(date, tm);
    return tm.day_of_week;
}

int DayOfWeek() {
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.day_of_week);
}
  
int TimeHour(datetime date)
  {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.hour);
  }

//+------------------------------------------------------------------+
//| Market Info
  
string AccountServer()
  {
   return AccountInfoString(ACCOUNT_SERVER);
  }

double MarketInfo(string symbol,
                      int type)
  {
   switch(type)
     {
      case MODE_LOW:
         return(SymbolInfoDouble(symbol,SYMBOL_LASTLOW));
      case MODE_HIGH:
         return(SymbolInfoDouble(symbol,SYMBOL_LASTHIGH));
      case MODE_TIME:
         return(SymbolInfoInteger(symbol,SYMBOL_TIME));
      case MODE_BID: {
         MqlTick last_tick;
         SymbolInfoTick(symbol,last_tick);
         double Bid=last_tick.bid;
         return(Bid);
      }
      case MODE_ASK: {
         MqlTick last_tick;
         SymbolInfoTick(symbol,last_tick);
         double Ask=last_tick.ask;
         return(Ask);
      }
      case MODE_POINT:
         return(SymbolInfoDouble(symbol,SYMBOL_POINT));
      case MODE_DIGITS:
         return(SymbolInfoInteger(symbol,SYMBOL_DIGITS));
      case MODE_SPREAD:
         return(SymbolInfoInteger(symbol,SYMBOL_SPREAD));
      case MODE_STOPLEVEL:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL));
      case MODE_LOTSIZE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE));
      case MODE_TICKVALUE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE));
      case MODE_TICKSIZE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE));
      case MODE_SWAPLONG:
         return(SymbolInfoDouble(symbol,SYMBOL_SWAP_LONG));
      case MODE_SWAPSHORT:
         return(SymbolInfoDouble(symbol,SYMBOL_SWAP_SHORT));
      case MODE_STARTING:
         return(0);
      case MODE_EXPIRATION:
         return(0);
      case MODE_TRADEALLOWED:
         return(0);
      case MODE_MINLOT:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN));
      case MODE_LOTSTEP:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP));
      case MODE_MAXLOT:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX));
      case MODE_SWAPTYPE:
         return(SymbolInfoInteger(symbol,SYMBOL_SWAP_MODE));
      case MODE_PROFITCALCMODE:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_CALC_MODE));
      case MODE_MARGINCALCMODE:
         return(0);
      case MODE_MARGININIT:
         return(0);
      case MODE_MARGINMAINTENANCE:
         return(0);
      case MODE_MARGINHEDGED:
         return(0);
      case MODE_MARGINREQUIRED:
         return(0);
      case MODE_FREEZELEVEL:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL));

      default: return(0);
     }
   return(0);
  }

//+------------------------------------------------------------------+
//| Objects

int ObjectFind(const string object_name) {
    return ObjectFind(0, object_name);
}

bool ObjectSetText(
   string   object_name,         // object name
   string   text,                // description
   int      font_size=0,         // font size
   string   font_name=NULL,      // font name
   color    text_color=clrNONE   // text color
) {
    bool result1 = ObjectSetString(0, object_name, OBJPROP_TEXT, text);
    bool result2 = font_name != NULL ? ObjectSetString(0, object_name, OBJPROP_FONT, font_name) : true;
    bool result3 = font_size > 0 ? ObjectSetInteger(0, object_name, OBJPROP_FONTSIZE, font_size) : true;
    bool result4 = text_color != clrNONE ? ObjectSetInteger(0, object_name, OBJPROP_COLOR, text_color) : true;
    
    return result1 && result2 && result3 && result4;
}

int ObjectsTotal() {
    return ObjectsTotal(0);
}

//string ObjectName(int object_index) {
//    return ObjectName(0, object_index);
//}
//
//bool ObjectDelete(const string object_name) {
//    return ObjectDelete(0, object_name);
//}

//bool  ObjectCreate(
//   string        object_name,   // object name
//   ENUM_OBJECT   object_type,   // object type
//   int           sub_window,    // window index
//   datetime      time1,         // time of the first anchor point
//   double        price1,        // price of the first anchor point
//   datetime      time2=0,       // time of the second anchor point
//   double        price2=0,      // price of the second anchor point
//   datetime      time3=0,       // time of the third anchor point
//   double        price3=0       // price of the third anchor point
//) {
//   return ObjectCreate(0, object_name, object_type, sub_window, time1, price1, time2, price2, time3, price3);
//}
  
//+------------------------------------------------------------------+
//| Terminal Info

bool IsConnected()
  {
   return TerminalInfoInteger(TERMINAL_CONNECTED);
  }
  
bool IsTesting() {
    return MQLInfoInteger(MQL_TESTER);
}

bool IsTradeAllowed() {
    return MQLInfoInteger(MQL_TRADE_ALLOWED);
}

bool IsVisualMode() {
    return MQLInfoInteger(MQL_VISUAL_MODE);
}

bool IsOptimization() {
    return MQLInfoInteger(MQL_OPTIMIZATION);
}

//+------------------------------------------------------------------+
//| Order Trade Processing


#endif