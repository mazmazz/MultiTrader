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
// A structure to be used with the GetPipFactor method
struct CurrencyFactor
{
  string m_symbol;
  double m_factor;
};


// An array of CurrencyFactors to be used with the getPipFactor method
const CurrencyFactor PipFactors[] = 
{
  { "JPY",    100.0 },
  { "XAG",    100.0 },
  { "SILVER", 100.0 },
  { "BRENT",  100.0 },
  { "WTI",    100.0 },
  { "XAU",    10.0  },
  { "GOLD",   10.0  },
  { "SP500",  10.0  },
  { "S&P",    10.0  },
  { "UK100",  1.0   },
  { "WS30",   1.0   },
  { "DAX30",  1.0   },
  { "DJ30",   1.0   },
  { "NAS100", 1.0   },
  { "CAC400", 1.0   },
};


//+-------------------------------------------------------------------------------------+
//| Description : Calculates the point value to of the number of decimal places for the |
//|             : symbol. From Pascalx at http://www.bunkerforexforum.com/              |      
//|                                                                                     |   
//| Parameters  : symbol    - Sympol that is checked                                    |
//|                                                                                     |   
//| Returns     : returns the point value for the number of decimal places that the     |
//|             : symbol uses                                                           |
//+-------------------------------------------------------------------------------------+
int GetPipFactor(string symbol) export
{
  for (int i = 0, count = ArraySize(PipFactors); i < count; ++i)
  {
    if (StringFind(symbol, PipFactors[i].m_symbol, 0) >= 0)
    {
       return (int)PipFactors[i].m_factor;
    }
  }
  return 10000;
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
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);

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
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
  double returnVal=0;
  double pipfactor = GetPipFactor(symbol);

  returnVal =  NormalizeDouble(price * pipfactor,  digits);   

  return returnVal;
}
