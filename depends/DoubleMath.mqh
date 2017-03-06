//+------------------------------------------------------------------+
//|                                                   DoubleMath.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//#property library
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
// functions for normalizing and comparing, see also http://forum.mql4.com/45425#564188 / http://articles.mql4.com/866

int BrokerPoint(string symbol = "") {
  if(StringLen(symbol) < 1) { symbol = Symbol(); }

  return MarketInfo(symbol, MODE_POINT);
}

//Open price for pending order must be adjusted to be a multiple of ticksize, not point, and on metals they are not the same.
//see also http://forum.mql4.com/45425#564188
double NormalizePrice(string symbol, double p) export {
  double ts = MarketInfo(symbol, MODE_TICKSIZE);
 return(MathRound(p/ts)*ts );
}

//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also http://forum.mql4.com/45425#564188
double NormalizeLots(string symbol, double lots) export {
  double ls = MarketInfo(symbol,MODE_LOTSTEP);
 return( MathRound(lots/ls)*ls );
}

//NormalizeDouble(x) != x will occur even for Bid/Ask. If you need to compare to equality (or greater or equal) and the equal is important
//you must take extra stepsif (price >= trigger) ... may or may not work at trigger. If the trigger on the exact value is important then use this form
//see also http://forum.mql4.com/45425#564188
bool IsGreater(double value,double trigger, string symbolForPoint = "") export {
  double point2val = BrokerPoint(symbolForPoint) / 2;
  if (value + point2val > trigger) return(true);
 return(false);
}

//see also http://forum.mql4.com/45425#564188
bool IsSmaller(double value,double trigger, string symbolForPoint = "") export {
  double point2val = BrokerPoint(symbolForPoint) / 2;
  if (value + point2val < trigger) return(true);
 return(false);
}

//taken from the shell ea code by Steve Hopwood
bool IsEqual(double num1, double num2) export
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

bool IsGreaterOrEqual(double val1, double val2) export {
 if (!IsEqual(val1,val2) && !IsGreater(val1,val2)) return(false);
 return(true);
}

bool IsSmallerOrEqual(double val1, double val2) export {
 if (!IsEqual(val1,val2) && !IsSmaller(val1,val2)) return(false);
return(true);
}

// end functions for normalizing and comparing
