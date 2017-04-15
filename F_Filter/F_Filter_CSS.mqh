//+------------------------------------------------------------------+
//|                                                            F_Filter_Stoch.mqh |
//|                                                        Copyright 2017, Marco Z |
//|                                                            https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link        "https://www.mql5.com"
#property strict

#include "F_Filter.mqh"
#include "../MC_Common/MC_MultiSettings.mqh"
#include "../D_Data/D_DataUnit.mqh"
#include "../S_Symbol.mqh"
#include "../depends/PipFactor.mqh"
#include "depends/LibCSS.mqh"

class FilterCss : public Filter {
    private:
    bool isInit;
    int timeFrame[];
    int shift[];
    int maPeriod[];
    int atrPeriod[];
    int calcMethod[];
    
    public:
    void init();
    
    void addSubfilter(int mode, string name, bool hidden, SubfilterType type
        , int timeFrameIn
        , int shiftIn
        , int maPeriodIn
        , int atrPeriodIn
        , int calcMethodIn
    );
    void addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
        , string timeFrameList
        , string shiftList
        , string maPeriodList
        , string atrPeriodList
        , string calcMethodList
        , bool addToExisting = false
    );
    
    bool calculate(int subfilterId, int symbolIndex, DataUnit *dataOut);
};

//+------------------------------------------------------------------+

void FilterCss::init() {
     if(isInit) { return; }
     
     shortName = "CSS";
     
     libCSS_symbolsToWeigh = CSS_SymbolsToWeigh;
     libCSS_init();
          
     isInit = true;
}

//+------------------------------------------------------------------+

void FilterStdDev::addSubfilter(int mode, string name, bool hidden, SubfilterType type
    , int timeFrameIn
    , int shiftIn
    , int maPeriodIn
    , int atrPeriodIn
    , int calcMethodIn
) {
    setupSubfilters(mode, name, hidden, type);
    
    Common::ArrayPush(timeFrame, timeFrameIn);
    Common::ArrayPush(shift, shiftIn);
    Common::ArrayPush(maPeriod, maPeriodIn);
    Common::ArrayPush(atrPeriod, atrPeriodIn);
    Common::ArrayPush(calcMethod, calcMethodIn);
}

void FilterStdDev::addSubfilter(string modeList, string nameList, string hiddenList, SubfilterType typeName
    , string timeFrameList
    , string shiftList
    , string maPeriodList
    , string atrPeriodList
    , string calcMethodList
    , bool addToExisting = false
) {
    setupSubfilters(modeList, nameList, hiddenList, typeName);
    
    int count = getSubfilterCount(typeName);
    if(count > 0) {
        MultiSettings::Parse(timeFrameList, timeFrame, count, addToExisting);
        MultiSettings::Parse(shiftList, shift, count, addToExisting);
        MultiSettings::Parse(maPeriodList, maPeriod, count, addToExisting);
        MultiSettings::Parse(atrPeriodList, atrPeriod, count, addToExisting);
        MultiSettings::Parse(calcMethodList, calcMethod, count, addToExisting);
    }
}

//+------------------------------------------------------------------+

bool FilterCss::calculate(int subfilterId, int symbolIndex, DataUnit *dataOut) {
     if(!checkSafe(subfilterId)) { return false; }
     string symbol = MainSymbolMan.symbols[symbolIndex].name;
     
     libCSS_useCalcMethod = calcMethod[subfilterId];
     double value = libCSS_getCSSCurrency(
        symbol
        , MainSymbolMan.symbols[symbolIndex].baseCurName
        , timeFrame[subfilterId]
        , maPeriod[subfilterId]
        , atrPeriod[subfilterId]
        , shift[subfilterId]
        );
     
     dataOut.setRawValue(value, 0, DoubleToString(value, 2));
     
     return true;
}
