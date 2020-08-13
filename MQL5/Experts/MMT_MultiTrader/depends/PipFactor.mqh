//+------------------------------------------------------------------+
//|                                                    PipFactor.mq4 |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//#property library
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+

//+-------------------------------------------------------------------------------------+
//| Description : Calculates the point value to of the number of decimal places for the |
//|             : symbol.                                                               |      
//|                                                                                     |   
//| Parameters  : symbol    - Sympol that is checked                                    |
//|                                                                                     |   
//| Returns     : returns the point value for the number of decimal places that the     |
//|             : symbol uses                                                           |
//+-------------------------------------------------------------------------------------+
int GetPipFactor(string symbol) export
{
  int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  return MathPow(10, digits-BrokerPipDecimal);
}

int PipsToPoints(double pips) {
    return MathRound(pips*MathMax(1, 10*BrokerPipDecimal));
}

double PointsToPips(double points) {
    return points/MathMax(1, 10*BrokerPipDecimal);
}

//+-------------------------------------------------------------------------------------+
//| Description : Calculate the price value for a given number of pips                  |  
//|                                                                                     |   
//| Parameters  : symbol    - Sympol that is checked                                    |
//|             : pips     - The number of pips in the calculation                     | 
//|             :                                                                  |   
//| Returns     : returnVal - Price value                            |
//+-------------------------------------------------------------------------------------+
double PipsToPrice(string symbol, double pips) export
{
  double returnVal=0;
  double pipfactor = GetPipFactor(symbol);
  int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);

  returnVal = NormalizeDouble(pips/pipfactor, digits);   

  return returnVal;
}


//+-------------------------------------------------------------------------------------+
//| Description : Convert a price value to pips                       |  
//|                                                                                     |   
//| Parameters  : symbol    - Sympol that is checked                                    |
//|             : price     - The price to convert                             | 
//|             :                                                                  |   
//| Returns     : returnVal - pips                                       |
//+-------------------------------------------------------------------------------------+
double PriceToPips(string symbol, double price) export
{
  int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  double returnVal=0;
  double pipfactor = GetPipFactor(symbol);

  returnVal =  NormalizeDouble(price * pipfactor,  digits);   

  return returnVal;
}

int PriceToPoints(string symbol, double price) {
    return PipsToPoints(PriceToPips(symbol, price));
}

double PointsToPrice(string symbol, double points) {
    return PipsToPrice(symbol, PointsToPips(points));
}

