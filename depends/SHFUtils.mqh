//+------------------------------------------------------------------+
//|                                                     SHFUtils.mq4 |
//+------------------------------------------------------------------+
//#property library
#property copyright "Copyright 2012, Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property version   "1.00"
#property strict

#define  TpPrefix "Tp"
#define  SlPrefix "Sl"

//+------------------------------------------------------------------+
// TPSL - Breakeven, Jumping, Trailing
//+------------------------------------------------------------------+
void BreakEvenStopLoss(int ticket) // Move stop loss to breakeven
{

   //Security check
   if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
      
   double NewStop;
   bool result;
   bool modify=false;
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   double target = OrderOpenPrice();
   
   if (OrderType()==OP_BUY)
   {
      if (HiddenPips > 0) target-= (HiddenPips / factor);
      if (OrderStopLoss() >= target) return;
      if (Bid >= OrderOpenPrice () + (BreakEvenPips / factor))          
      {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()+(BreakEvenProfit / factor), Digits);
         if (HiddenPips > 0)
         {
            if (ObjectFind(LineName) == -1)
            {
               ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), 0);
               ObjectSet(LineName, OBJPROP_COLOR, Red);
               ObjectSet(LineName, OBJPROP_WIDTH, 1);
               ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
            }//if (ObjectFind(LineName == -1) )
         
            ObjectMove(LineName, 0, TimeCurrent(), NewStop);         
         }//if (HiddenPips > 0)
         modify = true;   
      }//if (Bid >= OrderOpenPrice () + (Point*BreakEvenPips) && 
   }//if (OrderType()==OP_BUY)               			         
    
   if (OrderType()==OP_SELL)
   {
     if (HiddenPips > 0) target+= (HiddenPips / factor);
      if (OrderStopLoss() <= target && OrderStopLoss() > 0) return;
     if (Ask <= OrderOpenPrice() - (BreakEvenPips / factor)) 
     {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()-(BreakEvenProfit / factor), Digits);
         if (HiddenPips > 0)
         {
            if (ObjectFind(LineName) == -1)
            {
               ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), 0);
               ObjectSet(LineName, OBJPROP_COLOR, Red);
               ObjectSet(LineName, OBJPROP_WIDTH, 1);
               ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
            }//if (ObjectFind(LineName == -1) )
         
            ObjectMove(LineName, 0, Time[0], NewStop);
         }//if (HiddenPips > 0)         
         modify = true;   
     }//if (Ask <= OrderOpenPrice() - (Point*BreakEvenPips) && (OrderStopLoss()>OrderOpenPrice()|| OrderStopLoss()==0))     
   }//if (OrderType()==OP_SELL)

   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      if (NewStop == OrderStopLoss() ) return;
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      
      while (IsTradeContextBusy() ) Sleep(100);
      if (PartCloseEnabled && OrderComment() == TradeComment) bool success = PartCloseOrder(OrderTicket() );
   }//if (modify)
   
} // End BreakevenStopLoss sub

void JumpingStopLoss(int ticket) 
{
   // Jump sl by pips and at intervals chosen by user .

   //Security check
   if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;

   //if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   
   //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
   double NewStop;
   bool modify=false;
   bool result;
   
   
    if (OrderType()==OP_BUY)
    {
       if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
       // Increment sl by sl + JumpingStopPips.
       // This will happen when market price >= (sl + JumpingStopPips)
       //if (Bid>= sl + ((JumpingStopPips*2) / factor) )
       if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
       if (Bid >=  sl + ((JumpingStopPips * 2) / factor) )//George{
       {
          NewStop = NormalizeDouble(sl + (JumpingStopPips / factor), Digits);
          if (AddBEP) NewStop = NormalizeDouble(NewStop + (BreakEvenProfit / factor), Digits);
          if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
          if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
       }// if (Bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())     
    }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - JumpingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (Bid<= sl - ((JumpingStopPips*2) / factor)) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (Bid <= sl - ((JumpingStopPips * 2) / factor) )//George
          {
             NewStop = NormalizeDouble(sl - (JumpingStopPips / factor), Digits);
             if (AddBEP) NewStop = NormalizeDouble(NewStop - (BreakEvenProfit / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }// close if (Bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())         
       }//if (OrderType()==OP_SELL)



   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);      
   }//if (modify)

} //End of JumpingStopLoss sub

void TrailingStopLoss(int ticket)
{

   //Security check
   if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   double NewStop;
   bool modify=false;
   bool result;
   
    if (OrderType()==OP_BUY)
       {
          if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
          // Increment sl by sl + TrailingStopPips.
          // This will happen when market price >= (sl + JumpingStopPips)
          //if (Bid>= sl + (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
          if (Bid >= sl + (TrailingStopPips / factor) )//George
          {
             NewStop = NormalizeDouble(sl + (TrailingStopPips / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
          }//if (Bid >= MathMax(sl,OrderOpenPrice()) + (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - TrailingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (Bid<= sl - (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (Bid <= sl  - (TrailingStopPips / factor))//George
          {
             NewStop = NormalizeDouble(sl - (TrailingStopPips / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }//if (Bid <= MathMin(sl, OrderOpenPrice() ) - (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_SELL)


   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
   }//if (modify)
      
} // End of TrailingStopLoss sub

//+------------------------------------------------------------------+
// Lot calculations
//+------------------------------------------------------------------+

void CalculateLotAsAmountPerCashDollops()
{

   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   double decimal = 0;
   if (CloseEnough(lotstep, 0.1) )
      decimal = 1;
   if (CloseEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 

   
   //Initial lot size
   Lot = NormalizeDouble((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash, decimal);
     
   //Min/max size check
   if (Lot > maxlot)
      Lot = maxlot;
      
   if (Lot < minlot)
      Lot = minlot;      


}//void CalculateLotAsAmountPerCashDollops()

double CalculateLotSize(double price1,double price2)
{
   //Calculate the lot size by risk. Code kindly supplied by jmw1970. Nice one jmw.

   if(price1==0 || price2==0) return(Lot);//Just in case

   double FreeMargin= AccountFreeMargin();
   double TickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
   double LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);

   double SLPts=MathAbs(price1-price2);
   //SLPts/=Point;//No idea why *= factor does not work here, but it doesn't
   SLPts = int(SLPts * factor * 10);//Code from Radar. Thanks Radar; much appreciated

   double Exposure=SLPts*TickValue; // Exposure based on 1 full lot

   double AllowedExposure=(FreeMargin*RiskPercent)/100;

   int TotalSteps = ((AllowedExposure / Exposure) / LotStep);
   double LotSize = TotalSteps * LotStep;

   double MinLots = MarketInfo(Symbol(), MODE_MINLOT);
   double MaxLots = MarketInfo(Symbol(), MODE_MAXLOT);

   if(LotSize < MinLots) LotSize = MinLots;
   if(LotSize > MaxLots) LotSize = MaxLots;
   return(LotSize);

}//double CalculateLotSize(double price1, double price1)

//+------------------------------------------------------------------+
// Order safety
//+------------------------------------------------------------------+

bool IsTradingAllowed()
{
   //Returns false if any of the filters should cancel trading, else returns true to allow trading
   
      
   //Maximum spread
   if (!IsTesting() )
   {
      double spread = (Ask - Bid) * factor;
      if (spread > AverageSpread * MultiplierToDetectStopHunt) return(false);
   }//if (!IsTesting() )
   
    
   //An individual currency can only be traded twice, so check for this
   CanTradeThisPair = true;
   if (OnlyTradeCurrencyTwice && OpenTrades == 0)
   {
      IsThisPairTradable();      
   }//if (OnlyTradeCurrencyTwice)
   if (!CanTradeThisPair) return(false);
   
   //Swap filter
   if (OpenTrades == 0) TradeDirectionBySwap();
   
   //Order close time safety feature
   if (TooClose()) return(false);

   return(true);


}//End bool IsTradingAllowed()


bool TooClose()
{
   //Returns false if the previously closed trade and the proposed new trade are sufficiently far apart, else return true. Called from IsTradeAllowed().
   
   SafetyViolation = false;//For chart feedback
         
   if (OrdersHistoryTotal() == 0) return(false);
   
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != Symbol() ) continue;
      
      //Examine the OrderCloseTime to see if it closed far enought back in time.
      if (TimeCurrent() - OrderCloseTime() < (MinMinutesBetweenTrades * 60))
      {
         SafetyViolation = true;
         return(true);//Too close, so disallow the trade
      }//if (OrderCloseTime() - TimeCurrent() < (MinMinutesBetweenTrades * 60))
      break;      
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   
   //Got this far, so there is no disqualifying trade in the history
   return(false);
   
}//bool TooClose()

bool MarginCheck()
{

   EnoughMargin = true;//For user display
   MarginMessage = "";
   if (UseScoobsMarginCheck && OpenTrades > 0)
   {
      if(AccountMargin() > (AccountFreeMargin()/100)) 
      {
         MarginMessage = "There is insufficient margin to allow trading. You might want to turn off the UseScoobsMarginCheck input.";
         return(false);
      }//if(AccountMargin() > (AccountFreeMargin()/100)) 
      
   }//if (UseScoobsMarginCheck)


   if (UseForexKiwi && AccountMargin() > 0)
   {
      
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < FkMinimumMarginPercent)
      {
         MarginMessage = StringConcatenate("There is insufficient margin percent to allow trading. ", DoubleToStr(ml, 2), "%");
         return(false);
      }//if (ml < FkMinimumMarginPercent)
   }//if (UseForexKiwi && AccountMargin() > 0)
   
  
   //Got this far, so there is sufficient margin for trading
   return(true);
}//End bool MarginCheck()

//+------------------------------------------------------------------+
// Spread decisions
//+------------------------------------------------------------------+

double AddSpreadToPrice(int type,double tpslPrice,int mode) {
//mode : 1: SL / mode : 2: TP
  //add spread to sl/tp, see also: http://forum.mql4.com/43396/page4
  RefreshRates();
  double spread = (Ask - Bid); //old: MarketInfo(symbol,MODE_SPREAD)*pips2dbl;
  double OldtpslPrice = tpslPrice;
  string stype,smode;
  if (type==OP_BUY) stype = "OP_BUY"; if (type==OP_SELL) stype = "OP_SELL";
  if (mode==1) smode = "SL"; if (mode==2) smode = "TP";
  
  if ((type==OP_BUY && mode==1) || (type==OP_SELL && mode==2))  // OP_BUY SL / OP_SELL TP
   {
    OldtpslPrice = tpslPrice;
    tpslPrice = tpslPrice - spread;
   }
   
  if ((type==OP_BUY && mode==2) || (type==OP_SELL && mode==1)) // OP_BUY TP / OP_SELL SL
   {
    OldtpslPrice = tpslPrice;
    tpslPrice = tpslPrice + spread;
   }
   
   doPrint("AddSpreadToPrice() - added "+DoubleToStr(spread*factor,0)+" pips spread for "+stype+", changed "+smode+" from "+DoubleToStr(OldtpslPrice,5)+" to "+DoubleToStr(tpslPrice,5)+"");

 return(NormalizePrice(tpslPrice));
}

void GetAverageSpread()
{

//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   static double SpreadTotal=0;
   AverageSpread=0;

   //Add spread to total and keep track of the ticks
   double Spread=(Ask-Bid)*factor;
   SpreadTotal+=Spread;
   CountedTicks++;

   //All ticks counted?
   if(CountedTicks>=TicksToCount)
   {
      AverageSpread=NormalizeDouble(SpreadTotal/TicksToCount,1);
      //Save the average for restarts.
      GlobalVariableSet(SpreadGvName,AverageSpread);
      RunInSpreadDetectionMode=false;
   }//if (CountedTicks >= TicksToCount)


}//void GetAverageSpread()

void CheckForSpreadWidening()
{
   if (CloseEnough(AverageSpread, 0)) return;
   //Detect a dramatic widening of the spread and pause the ea until this passes
   double TargetSpread = AverageSpread * MultiplierToDetectStopHunt;
   double spread = (Ask - Bid) * factor;
   
   if (spread >= TargetSpread)
   {
      if (OpenTrades == 0) Comment(Gap + "PAUSED DURING A MASSIVE SPREAD EVENT");
      if (OpenTrades > 0) Comment(Gap + "PAUSED DURING A MASSIVE SPREAD EVENT. STILL MONITORING TRADES.");
      while (spread >= TargetSpread)
      {
         RefreshRates();
         spread = (Ask - Bid) * factor;
         
         CountOpenTrades();
         //Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
         if (OldOpenTrades != OpenTrades)
         {
            if (IsClosedTradeRogue() )
            {
               RobotSuspended = true;
               return;
            }//if (IsClosedTradeRogue() )      
         }//if (OldOpenTrades != OpenTrades)
         if (ForceTradeClosure) return;//Emergency measure to force a retry at the next tick
         
         OldOpenTrades = OpenTrades;
         
         Sleep(1000);

      }//while (spread >= TargetSpread)      
   }//if (spread >= TargetSpread)
}//End void CheckForSpreadWidening()

//+------------------------------------------------------------------+
// Trading hours
//+------------------------------------------------------------------+

bool SundayMondayFridayStuff()
{

   //Friday/Saturday stop trading hour
   int d = TimeDayOfWeek(TimeLocal());
   int h = TimeHour(TimeLocal());
   if (d == 5)
      if (h >= FridayStopTradingHour)
         return(false);
         
   if (d == 4)
      if (!TradeThursdayCandle)
         return(false);
        
   
   if (d == 6)
      if (h >= SaturdayStopTradingHour)
         return(false);
  
   //Sunday candle
   if (d == 0)
      if (!TradeSundayCandle)
         return(false);
         
   //Monday start hour
   if (d == 1)
      if (h < MondayStartHour)      
         return(false);
         
   //Got this far, so we are in a trading period
   return(true);      
   
}//End bool  SundayMondayFridayStuff()

bool CheckTradingTimes() 
{

	// Trade 24 hours if no input is given
	if ( ArraySize( tradeHours ) == 0 ) return ( true );

	// Get local time in minutes from midnight
    int time = TimeHour( TimeLocal() ) * 60 + TimeMinute( TimeLocal() );
   
	// Don't you love this?
	int i = 0;
	while ( time >= tradeHours[i] ) 
	{	
		if ( i == ArraySize( tradeHours ) ) break;
		i++;		
	}
	if ( i % 2 == 1 ) return ( true );
	return ( false );
}//End bool CheckTradingTimes2() 
//+----------------------------------+
//| Initialize Trading Hours Array                                   |
//+----------------------------------+
bool initTradingHours() 
{
   // Called from init()
   
	// Assume 24 trading if no input found
	if ( tradingHours == "" )	
	{
		ArrayResize( tradeHours, 0 );
		return ( true );
	}

	int i;

	// Add 00:00 start time if first element is stop time
	if ( StringSubstrOld( tradingHours, 0, 1 ) == "-" ) 
	{
		tradingHours = StringConcatenate( "+0,", tradingHours );   
	}
	
	// Add delimiter
	if ( StringSubstrOld( tradingHours, StringLen( tradingHours ) - 1) != "," ) 
	{
		tradingHours = StringConcatenate( tradingHours, "," );   
	}
	
	string lastPrefix = "-";
	i = StringFind( tradingHours, "," );
	
	while (i != -1) 
	{

		// Resize array
		int size = ArraySize( tradeHours );
		ArrayResize( tradeHours, size + 1 );

		// Get part to process
		string part = StringSubstrOld( tradingHours, 0, i );

		// Check start or stop prefix
		string prefix = StringSubstrOld ( part, 0, 1 );
		if ( prefix != "+" && prefix != "-" ) 
		{
			Print("ERROR IN TRADINGHOURS INPUT (NO START OR CLOSE FOUND), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}

		if ( ( prefix == "+" && lastPrefix == "+" ) || ( prefix == "-" && lastPrefix == "-" ) )	
		{
			Print("ERROR IN TRADINGHOURS INPUT (START OR CLOSE IN WRONG ORDER), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}
		
		lastPrefix = prefix;

		// Convert to time in minutes
		part = StringSubstrOld( part, 1 );
		double time = StrToDouble( part );
		int hour = MathFloor( time );
		int minutes = MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = StringSubstrOld( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}//while (i != -1) 

	return ( true );
}//End bool initTradingHours() 

// DaynumberToString(5) : returns friday (converts daynumber to string name)
string DaynumberToString(int daynumber) {
   string DayName;
   switch(daynumber) {
      case 0 : DayName = "sunday";    break;
      case 1 : DayName = "monday";    break;
      case 2 : DayName = "tuesday";   break;
      case 3 : DayName = "wednesday"; break;
      case 4 : DayName = "thursday";  break;
      case 5 : DayName = "friday";    break;
      case 6 : DayName = "saturday";  break;
      default: DayName = "ERROR";
   }
   return(DayName);
}


bool TimeHasCome(int dayNumber,int triggerTime,int GMTshift) {
 if ((GmtTime(GMTshift,1) == dayNumber && GmtTime(GMTshift,0) > (triggerTime - 1))) return(true);
 return(false);
}

//+------------------------------------------------------------------+
//| function GmtTime: returns time or the day  in GMT time           |
//+------------------------------------------------------------------+  
// for gmtShift = 1 (timezone: Germany):
// gmtTime(6,0): returns current hour in gmt timezone (e.g. 14 for time 14:01 - 14:59)
// gmtTime(6,1): returns number of current day in gmt timezone (e.g. 5 for friday)
int GmtTime(int gmtShift, int hourOrDaynumber) {  
   // determine GMT day and hour
    
   int gmtHH = TimeHour(TimeLocal()) - gmtShift; // gmtShift = -5 for NYC without daylight savings, e.g.
   int gmtDayNumber = TimeDayOfWeek(TimeLocal());
   if (gmtHH < 0) {
      gmtHH += 24;
      gmtDayNumber -= 1;   
    }
    if (gmtHH > 23) {
      gmtHH -= 24;
      gmtDayNumber += 1;
    }
    if (gmtDayNumber < 0) gmtDayNumber += 7;
    if (gmtDayNumber > 6) gmtDayNumber -= 7; 

    // end determine GMT day and hour
    
    // return current day number in gmt timezone if requested
    if (hourOrDaynumber == 1) return(gmtDayNumber);

    // return current hour in gmt timezone if requested
    if (hourOrDaynumber == 0) return(gmtHH);  
}

// Doubles math

////////////////////////////////////////////////////////////////////////////////////////
// functions for normalizing and comparing, see also http://forum.mql4.com/45425#564188 / http://articles.mql4.com/866

//Open price for pending order must be adjusted to be a multiple of ticksize, not point, and on metals they are not the same.
//see also http://forum.mql4.com/45425#564188
double NormalizePrice(double p){
  double ts = MarketInfo(symbol, MODE_TICKSIZE);
 return(MathRound(p/ts)*ts );
}

//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also http://forum.mql4.com/45425#564188
double NormalizeLots(double lots){
  double ls = MarketInfo(symbol,MODE_LOTSTEP);
 return( MathRound(lots/ls)*ls );
}

//NormalizeDouble(x) != x will occur even for Bid/Ask. If you need to compare to equality (or greater or equal) and the equal is important
//you must take extra stepsif (price >= trigger) ... may or may not work at trigger. If the trigger on the exact value is important then use this form
//see also http://forum.mql4.com/45425#564188
bool IsGreater(double value,double trigger) {
  double point2val = Point / 2;
  if (value + point2val > trigger) return(true);
 return(false);
}

//see also http://forum.mql4.com/45425#564188
bool IsSmaller(double value,double trigger) {
  double point2val = Point / 2;
  if (value + point2val < trigger) return(true);
 return(false);
}

//taken from the shell ea code by Steve Hopwood
bool IsEqual(double num1, double num2)
{
   /*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */
   
   if (num1 == 0 && num2 == 0) return(true); //0==0
   if (MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);
   //old, was wrong, see: http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?p=28155#p28155
   //if (MathAbs(num1 - num2) / (num1 + num2) < 0.00000001) return(true);
   
   //Doubles are unequal
   return(false);

}//End bool IsEqual(double num1, double num2)

bool IsGreaterOrEqual(double val1, double val2) {
 if (!IsEqual(val1,val2) && !IsGreater(val1,val2)) return(false);
 return(true);
}

bool IsSmallerOrEqual(double val1, double val2) {
 if (!IsEqual(val1,val2) && !IsSmaller(val1,val2)) return(false);
return(true);
}

// end functions for normalizing and comparing