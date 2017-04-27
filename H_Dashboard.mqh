//+------------------------------------------------------------------+
//|                                                H_Dashboard.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#ifndef _ProjectName
#define _ProjectName ""
#define _ProjectShortName ""
#define _ProjectVersion ""
#endif

#ifndef _FontColorDefault
#define _FontColorDefault C'145,145,145'
#endif

#include "S_Symbol.mqh"
#include "F_Filter/F_FilterManager.mqh"
#include "D_Data/D_Data.mqh"

class DashboardManager {
    public:
    DashboardManager();
    ~DashboardManager();
    
    void initDashboard();
    void updateDashboard();
    void deleteAllObjects();

    private:
    string objPrefix;
    string fontFace;
    int fontSize;

    color fontColorDefault;
    color fontColorBuy;
    color fontColorSell;
    color fontColorAction;
    color fontColorCounterAction;
    
    // col: logical table column, pos: text column
    int row;
    int col;
    int pos;
    int rowSize;
    int colSize;
    int posSize;
    int dataRowStart;
    int dataPosStart;
    int colOffset;
    
    string sepChar;
    string spacedSepChar; // spaces both ends
    string endSpacedSepChar; // space at end
    
    int drawText(string objName, string text); 
    int drawText(string objName, string text, color textColor);
    
    string prefixName(string subPrefix, string name = NULL);
    string truncText(string text, int length);
    string padText(string text, int length);
    
    void updateResults();
    void updateData(int symbolId, int filterId, int subfilterId, bool exists = false);
    void updateSymbolSignal(int symbolId, SubfilterType subType, bool exists = false);
    string signalToString(SignalType signal, bool shortCode = true, bool alwaysStable = false);
    string signalToString(SignalType signal, int duration, SubfilterType type, bool shortCode = true, bool alwaysStable = false);
    
    void drawHeader();
    void drawLegend();
    void drawSymbols();
    void drawSubfilterColData(int symbolIdx, SubfilterType subType, bool writeSep = true);
    void drawSubfilterColLegend(string &legendText, SubfilterType subType, bool writeSep = true);
    void drawSubfilterCol(string &legendText, int symbolIdx, SubfilterType subType, bool isLegend, bool writeSep = true);
    void drawData(int symbolId, int filterId, int subfilterId);
    void drawSymbolSignal(int symbolId, SubfilterType subType);
    
    string getDataSuffix(int filterId, int subfilterId);
};

void DashboardManager::DashboardManager() {
    initDashboard();
}

void DashboardManager::~DashboardManager() {
    deleteAllObjects();
}

void DashboardManager::initDashboard() {
    objPrefix = _ProjectShortName + "_";
    
    fontFace = DisplayFont;
    fontSize = 11+(DisplayScale < 1 ? -4 : (DisplayScale-1)*4); //DisplayFontSize;
    
    fontColorDefault = DisplayFontColorDefault;
    if(DisplayColor) {
        fontColorBuy = C'0,178,0';
        fontColorSell = clrRed;
        fontColorAction = C'0,154,255';
        fontColorCounterAction = C'255,100,0';
    } else {
        fontColorBuy = fontColorSell = fontColorAction = fontColorCounterAction = fontColorDefault;
        // todo: underline/italic styles for buy/sell?
    }
    
    rowSize = fontSize*2.5;
    posSize = fontSize*1.2;//posSize = getPosSize(); // // guessing at fixed font width
        // http://stackoverflow.com/questions/19113725/what-dependency-between-font-size-and-width-of-char-in-monospace-font
    
    colSize = 10;
    //if(DisplayStyle == ValueAndSignal) { colSize = 10; }
    //else { colSize = 8; } // expressed in pos units
    
    row = 1;
    col = 1;
    pos = 1;
    
    sepChar = "|";
    spacedSepChar = " " + sepChar + " ";
    endSpacedSepChar = sepChar + " ";
    
    deleteAllObjects();
    
    if(!DisplayShow) { return; }
    
    if(!DisplayShowTable) {
        drawHeader(); row=0; pos=0;
    } else {
        pos=1;
        drawHeader(); row++; pos=1;
        drawLegend(); row++; pos=1;
        drawSymbols(); //row++; pos=1;
        row=0; pos=0;
    }
}

void DashboardManager::drawHeader() {
    int maxTextPos = 7; // "Symbols " minus 1

    string headerText = IntegerToString(MagicNumber) + (StringLen(ConfigComment) > 0 ? " " + ConfigComment : "") + spacedSepChar;
    
    string statusText = 
        (TradeEntryEnabled ? "Entry/": "") 
        + (TradeExitEnabled ? "Exit/" : "") 
        + (TradeValueEnabled ? "Value" : "")
        + (!TradeEntryEnabled && !TradeExitEnabled && !TradeValueEnabled ? "Viewing Only" : "")
        + spacedSepChar
        ;
        
    headerText += statusText + _ProjectName + " " + _ProjectVersion;
    
    // insert results here
    pos += drawText(prefixName("results_total_label"), padText("Total", maxTextPos+1));
    pos += drawText(prefixName("results_total"), "       ");
    
    if(DisplayShowBasketStopLevels && BasketMasterStopLossMode != BasketStopDisable) {
        pos += drawText(prefixName("results_stoploss_label"), "SL ");
        pos += drawText(prefixName("results_stoploss"), "       ");
    }
    
    if(DisplayShowBasketStopLevels && BasketMasterTakeProfitMode != BasketStopDisable) {
        pos += drawText(prefixName("results_takeprofit_label"), "TP ");
        pos += drawText(prefixName("results_takeprofit"), "       ");
    }
    
    pos += drawText(prefixName("results_longs_label"), "Longs ");
    pos += drawText(prefixName("results_long"), "       ");
    pos += drawText(prefixName("results_shorts_label"), "Shorts ");
    pos += drawText(prefixName("results_short"), "       ");
    
    if(BasketTotalPerDay) {
        pos += drawText(prefixName("results_booked_label"), "Closed ");
        pos += drawText(prefixName("results_booked"), "       ");
    }
    
    pos += drawText(prefixName("header"), spacedSepChar + headerText);
    
    updateResults();
}

void DashboardManager::drawLegend() {
    int maxLabelPos = colSize-1;
    int maxTextPos = 7; // "Symbols " minus 1
    string legendText = "";
    string filterText = "";
    
    string basketLegendText = " Total";
    
    if(DisplayShowBasketStopLevels && BasketSymbolEnableStopLoss) {
        basketLegendText += sepChar+"SL   ";
    }
    
    if(DisplayShowBasketStopLevels && BasketSymbolEnableTakeProfit) {
        basketLegendText += sepChar+"TP   ";
    }
    
    if(TradeModeType == TradeGrid || DisplayShowBasketSymbolLongShort) {
        basketLegendText += sepChar+"Long "+sepChar+"Short" + (BasketTotalPerDay ? sepChar+"Close" : "");
    }
    
    legendText += padText("Symbols", maxTextPos) + basketLegendText + spacedSepChar;
    
    dataPosStart = StringLen(legendText)+1;
    
    drawSubfilterColLegend(legendText, SubfilterEntry);
    drawSubfilterColLegend(legendText, SubfilterExit);
    drawSubfilterColLegend(legendText, SubfilterValue);
    
    legendText += "Symbols";
    
    drawText(prefixName("legend"), legendText);
}

void DashboardManager::drawSymbols() {
    dataRowStart = row;
    int firstSymRow = row;
    int maxLabelPos = colSize-1;
    int maxTextPos = 7; // "Symbols " minus 1
    int size = MainSymbolMan.getSymbolCount();
    
    int j = 0; int k = 0;
    for(int i = 0; i < size; i++) {
        col = 0; colOffset = 0; pos = 1;
        pos += drawText(prefixName(IntegerToString(i)), padText(truncText(MainSymbolMan.symbols[i].name, maxTextPos), maxTextPos) + " ");
        
        pos += drawText(prefixName(i+"_total"), "     " + (TradeModeType == TradeGrid || DisplayShowBasketSymbolLongShort ? " " : ""));
        
        if(DisplayShowBasketStopLevels && BasketSymbolEnableStopLoss) {
            pos += drawText(prefixName(i+"_stoploss"), "      ");
        }
        
        if(DisplayShowBasketStopLevels && BasketSymbolEnableTakeProfit) {
            pos += drawText(prefixName(i+"_takeprofit"), "      ");
        }
        
        if(TradeModeType == TradeGrid || DisplayShowBasketSymbolLongShort) {
            pos += drawText(prefixName(i+"_long"), "      ");
            pos += drawText(prefixName(i+"_short"), "     " + (BasketTotalPerDay ? " " : ""));
            if(BasketTotalPerDay) { pos += drawText(prefixName(i+"_booked"), "     "); }
        }
        
        pos += drawText(prefixName(i+"_symSep"), spacedSepChar);
        
        drawSubfilterColData(i, SubfilterEntry);
        drawSubfilterColData(i, SubfilterExit);
        drawSubfilterColData(i, SubfilterValue, false);
        
        pos = dataPosStart + (colSize*col) + colOffset-1;
        drawText(prefixName(i+"_end"), spacedSepChar + truncText(MainSymbolMan.symbols[i].name, maxTextPos));
        
        row++;
    }
}

void DashboardManager::drawSubfilterColData(int symbolIdx, SubfilterType subType, bool writeSep = true) {
    string emptyString = NULL;
    drawSubfilterCol(emptyString, symbolIdx, subType, false, writeSep);
}

void DashboardManager::drawSubfilterColLegend(string &legendText, SubfilterType subType, bool writeSep = true) { // legend
    drawSubfilterCol(legendText, -1, subType, true, writeSep);
}

void DashboardManager::drawSubfilterCol(string &legendText, int symbolIdx, SubfilterType subType, bool isLegend, bool writeSep = true) {
    int maxLabelPos = colSize-1;
    
    int filterCount = MainFilterMan.getFilterCount();
    
    switch(subType) {
        case SubfilterEntry:
            if(isLegend) {
                legendText += "O ";
            } else {
                pos = dataPosStart + (colSize*col) + colOffset;
                drawSymbolSignal(symbolIdx, subType);
                colOffset += 2;
            }
            break;
            
        case SubfilterExit:
            if(isLegend) {
                legendText += "C ";
            } else {
                pos = dataPosStart + (colSize*col) + colOffset;
                drawSymbolSignal(symbolIdx, subType);
                colOffset += 2;
            }
            break;
    }
    
    for(int i = 0; i < filterCount; i++) {
        int subCount = MainFilterMan.filters[i].getSubfilterCount(subType);
        
        for(int j = 0; j < subCount; j++) {
            int subIdx = -1;
            switch(subType) {
                case SubfilterValue: subIdx = MainFilterMan.filters[i].valueSubfilterId[j]; break;
                case SubfilterEntry: subIdx = MainFilterMan.filters[i].entrySubfilterId[j]; break;
                case SubfilterExit:  subIdx = MainFilterMan.filters[i].exitSubfilterId[j];  break;
                default: return;
            }
            
            if(MainFilterMan.filters[i].subfilterMode[subIdx] == SubfilterDisabled) { continue; }
            if(MainFilterMan.filters[i].subfilterHidden[subIdx]) { continue; }
            
            if(isLegend) { 
                legendText += padText(truncText(MainFilterMan.filters[i].shortName, maxLabelPos-2) + "-" + MainFilterMan.filters[i].subfilterName[subIdx], colSize);
            }
            else { 
                drawData(symbolIdx, i, subIdx);
                col++;
            }
        }
    }
    
    if(!writeSep) { return; }
    
    if(isLegend) { 
        legendText += endSpacedSepChar;
    } else {
        pos = dataPosStart + (colSize*col) + colOffset;
        drawText(
            prefixName(symbolIdx + "_" + EnumToString(subType) + "_sep")
            , endSpacedSepChar
            );
        colOffset += StringLen(endSpacedSepChar);
    }
}

void DashboardManager::drawData(int symbolId, int filterId, int subfilterId) {
    string dataObjName = prefixName(symbolId + "_" + filterId + "_" + subfilterId, getDataSuffix(filterId, subfilterId));
    if(ObjectFind(dataObjName) >= 0 || ObjectCreate(0, dataObjName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, dataObjName, OBJPROP_XDISTANCE, posSize * (dataPosStart + (col*colSize) + colOffset));
        ObjectSetInteger(0, dataObjName, OBJPROP_YDISTANCE, rowSize * row);
        ObjectSetInteger(0, dataObjName, OBJPROP_CORNER, 0);
        updateData(symbolId, filterId, subfilterId, true);
    }
}

void DashboardManager::drawSymbolSignal(int symbolId,SubfilterType subType) {
    string dataObjName = prefixName(symbolId + "_" + EnumToString(subType) + "_signal");
    if(ObjectFind(dataObjName) >= 0 || ObjectCreate(0, dataObjName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, dataObjName, OBJPROP_XDISTANCE, posSize * (dataPosStart + (col*colSize) + colOffset));
        ObjectSetInteger(0, dataObjName, OBJPROP_YDISTANCE, rowSize * row);
        ObjectSetInteger(0, dataObjName, OBJPROP_CORNER, 0);
        updateSymbolSignal(symbolId, subType, true);
    }
}

void DashboardManager::updateDashboard() {
    if(!DisplayShow) { return; }
    
    updateResults();
    
    if(!DisplayShowTable) { return; }
    
    int filterCount = MainFilterMan.getFilterCount();
    int subfilterCount = 0;
    int size = MainSymbolMan.getSymbolCount();
    
    int j = 0; int k = 0;
    for(int i = 0; i < size; i++) {
        // todo: order by filter type, or custom
        updateSymbolSignal(i, SubfilterEntry);
        updateSymbolSignal(i, SubfilterExit);
        
        for(j = 0; j < filterCount; j++) {
            subfilterCount = MainFilterMan.filters[j].getSubfilterCount();
            for(k = 0; k < subfilterCount; k++) { 
                updateData(i, j, k);
            }
        }
        
        // results
        string basketTotal = " ", basketStoploss = " ", basketTakeprofit = " ", basketLong = " ", basketShort = " ", basketBooked = " ";
        if(MainOrderMan.openMarketLongCount[i] + MainOrderMan.openMarketShortCount[i] > 0) {
            basketTotal = padText(StringFormat("%.1f", (MainOrderMan.basketProfitSymbol[i]+(BasketTotalPerDay ? MainOrderMan.basketBookedProfitSymbol[i] : 0))), 5) + (TradeModeType == TradeGrid || DisplayShowBasketSymbolLongShort ? sepChar : "");
            basketStoploss = padText(StringFormat("%.1f", MainOrderMan.basketSymbolStopLoss[i]), 5) + sepChar;
            basketTakeprofit = padText(StringFormat("%.1f", MainOrderMan.basketSymbolTakeProfit[i]), 5) + sepChar;
            basketLong = padText(StringFormat("%.1f", MainOrderMan.basketLongProfitSymbol[i]), 5) + sepChar;
            basketShort = padText(StringFormat("%.1f", MainOrderMan.basketShortProfitSymbol[i]), 5) + (BasketTotalPerDay ? sepChar : " ");
            if(BasketTotalPerDay) { basketBooked = StringFormat("%f.2", MainOrderMan.basketBookedProfitSymbol[i]); }
        } else if(BasketTotalPerDay && MainOrderMan.basketBookedProfitSymbol[i] != 0 && MainOrderMan.basketProfitSymbol[i] == 0 && MainOrderMan.basketLongProfitSymbol[i] == 0 && MainOrderMan.basketShortProfitSymbol[i] == 0) {
            basketTotal = "     "+sepChar; basketStoploss = "     "+sepChar; basketTakeprofit = "     "+sepChar; basketLong = "     "+sepChar; basketShort = "     "+sepChar;
            if(BasketTotalPerDay) { basketBooked = StringFormat("%f.2", MainOrderMan.basketBookedProfitSymbol[i]); }
        }
        
        ObjectSetText(prefixName(i+"_total"), basketTotal, fontSize, fontFace, fontColorDefault);
        
        if(DisplayShowBasketStopLevels && BasketSymbolEnableStopLoss) {
            ObjectSetText(prefixName(i+"_stoploss"), basketStoploss, fontSize, fontFace, fontColorDefault);
        }
        
        if(DisplayShowBasketStopLevels && BasketSymbolEnableTakeProfit) {
            ObjectSetText(prefixName(i+"_takeprofit"), basketTakeprofit, fontSize, fontFace, fontColorDefault);
        }
        
        if(TradeModeType == TradeGrid || DisplayShowBasketSymbolLongShort) {
            ObjectSetText(prefixName(i+"_long"), basketLong, fontSize, fontFace, fontColorDefault);
            ObjectSetText(prefixName(i+"_short"), basketShort, fontSize, fontFace, fontColorDefault);
            if(BasketTotalPerDay) { ObjectSetText(prefixName(i+"_booked"), basketBooked, fontSize, fontFace, fontColorDefault); }
        }
    }
}

void DashboardManager::updateResults() {
    if(!DisplayShow) { return; }
    ObjectSetText(prefixName("results_total"), StringFormat("%.1f", (MainOrderMan.basketProfit+MainOrderMan.basketBookedProfit)), fontSize, fontFace, fontColorDefault);
    
    if(DisplayShowBasketStopLevels && BasketMasterStopLossMode != BasketStopDisable) {
        ObjectSetText(prefixName("results_stoploss"), StringFormat("%.1f", MainOrderMan.basketMasterStopLoss, fontSize, fontFace, fontColorDefault));
    }
    
    if(DisplayShowBasketStopLevels && BasketMasterTakeProfitMode != BasketStopDisable) {
        ObjectSetText(prefixName("results_takeprofit"), StringFormat("%.1f", MainOrderMan.basketMasterTakeProfit, fontSize, fontFace, fontColorDefault));
    }
    
    ObjectSetText(prefixName("results_long"), StringFormat("%.1f", MainOrderMan.basketLongProfit), fontSize, fontFace, fontColorDefault);
    ObjectSetText(prefixName("results_short"), StringFormat("%.1f", MainOrderMan.basketShortProfit), fontSize, fontFace, fontColorDefault);
    if(BasketTotalPerDay) { ObjectSetText(prefixName("results_booked"), StringFormat("%f.2", MainOrderMan.basketBookedProfit), fontSize, fontFace, fontColorDefault); }
}

void DashboardManager::updateData(int symbolId, int filterId, int subfilterId, bool exists = false) {
    // mmt_data_[symbolId]_[filterId]_[subfilterId]
    string objName = NULL;
    string dataResult = NULL;

    string suffixName = getDataSuffix(filterId, subfilterId);

    objName = prefixName(symbolId + "_" + filterId + "_" + subfilterId, suffixName);
    
    if(!exists) { exists = (ObjectFind(0, objName) >= 0); }
    
    if(exists) {
        DataHistory *history = MainDataMan.getDataHistory(symbolId, filterId, subfilterId);
        DataUnit *data = history.getData();
        color fontColor = fontColorDefault;
        
        if(data == NULL) { dataResult = "-"; }
        else {
            SignalType signal = data.signal;
            bool isExit = MainFilterMan.filters[filterId].subfilterType[subfilterId] == SubfilterExit;
            // negate signal for display purposes since this is an exit
            if(!DisplaySignalInternal) {
                switch(signal) {
                    case SignalBuy: signal = isExit ? SignalShort : SignalLong; break;
                    case SignalSell: signal = isExit ? SignalLong : SignalShort; break;
                }
            }
        
            dataResult = 
                data.getStringValue(MainSymbolMan.symbols[symbolId].digits) 
                + " " 
                + signalToString(signal, history.getSignalDuration(TimeSettingUnit), MainFilterMan.filters[filterId].subfilterType[subfilterId], true, MainFilterMan.filters[filterId].alwaysStable);
                ;
            
            switch(data.signal) {
                case SignalBuy: fontColor = fontColorBuy; break;
                case SignalSell: fontColor = fontColorSell; break;
                case SignalOpen: fontColor = fontColorAction; break;
                case SignalClose: fontColor = fontColorCounterAction; break;
                default: fontColor = fontColorDefault; break;
            }
        }
    
        ObjectSetText(objName, dataResult, fontSize, fontFace, fontColor);
    }
}

void DashboardManager::updateSymbolSignal(int symbolId,SubfilterType subType, bool exists = false) {
    string objName = prefixName(symbolId + "_" + EnumToString(subType) + "_signal");
    if(!exists) { exists = (ObjectFind(0, objName) >= 0); }
    
    if(exists) {
        SignalType signal = SignalNone;
        string dataResult = NULL;
        color fontColor = 0;
        
        SignalUnit *signalUnit = NULL;
        signalUnit = MainDataMan.symbol[symbolId].getSignalUnit(subType == SubfilterEntry);
        if(!Common::IsInvalidPointer(signalUnit)) { signal = signalUnit.type; }
        else { signal = SignalNone; }
        
        switch(subType) {
            case SubfilterEntry: 
                fontColor = fontColorAction;
                break;
            case SubfilterExit:  
                fontColor = fontColorCounterAction;
                // negate signal for display purposes since this is an exit
                if(!DisplaySignalInternal) {
                    switch(signal) {
                        case SignalLong: signal = SignalShort; break;
                        case SignalShort: signal = SignalLong; break;
                    }
                }
                break;
            default: return;
        }
        
        dataResult = signalToString(signal);
    
        ObjectSetText(objName, dataResult, fontSize, fontFace, fontColor);
    }
}

string DashboardManager::getDataSuffix(int filterId, int subfilterId) {
    return MainFilterMan.filters[filterId].subfilterType[subfilterId] == SubfilterEntry ? "_entry"
        : MainFilterMan.filters[filterId].subfilterType[subfilterId] == SubfilterExit ? "_exit"
        : MainFilterMan.filters[filterId].subfilterType[subfilterId] == SubfilterValue ? "_value"
        : ""
        ;
}

string DashboardManager::signalToString(SignalType signal, bool shortCode = true, bool alwaysStable = false) {
    return signalToString(signal, -1, SubfilterAllTypes, shortCode, alwaysStable);
}

string DashboardManager::signalToString(SignalType signal, int duration, SubfilterType type, bool shortCode = true, bool alwaysStable = false) {
    if(signal == SignalNone) { return " "; }

    switch(type) {
        case SubfilterEntry:
            if(!alwaysStable && (duration < EntryStableTime)) { return IntegerToString(EntryStableTime - duration); }
            break;
            
        case SubfilterExit:
            if(!alwaysStable && (duration < ExitStableTime)) { return IntegerToString(ExitStableTime - duration); }
            break;
            
        case SubfilterValue:
            return " "; // value filters don't have signals
    }
    
    switch(signal) {
        case SignalBuy: return shortCode ? "B" : "Buy"; break;
        case SignalSell: return shortCode ? "S" : "Sell"; break;
        //case SignalHold: return shortCode ? "H" : "Hold"; break;
        case SignalOpen: return shortCode ? "O" : "Open"; break;
        case SignalClose: return shortCode ? "C" : "Close"; break;
        case SignalLong: return shortCode ? "L" : "Long"; break;
        case SignalShort: return shortCode ? "S" : "Short"; break;
        default: return " "; break;
    }
}

string DashboardManager::truncText(string text, int length) {
    return StringSubstr(text, 0, length);
}

string DashboardManager::padText(string text,int length) {
    while(StringLen(text) < length) {
        text += " ";
    }
    
    return text;
}

string DashboardManager::prefixName(string subPrefix, string name = NULL) {
    if(name == NULL) { return objPrefix + subPrefix; }
    else { return objPrefix + subPrefix + "_" + name; }
}

int DashboardManager::drawText(string objName, string text) {
    return drawText(objName, text, fontColorDefault);
}

int DashboardManager::drawText(string objName, string text, color textColor) {
    // objects only take 63 characters. split text and create multiple objs if needed
    int maxSize = 63;
    int multiple = MathFloor(StringLen(text) / maxSize) + 1;
    string finalObjName = "";
    
    for(int i = 0; i < multiple; i++) {
        finalObjName = objName + (i <= 0 ? "" : i+1);
        if(ObjectFind(finalObjName) >= 0 || ObjectCreate(0, finalObjName, OBJ_LABEL, 0, 0, 0)) {
            ObjectSetText(finalObjName, StringSubstr(text, i*maxSize, maxSize+1), fontSize, fontFace, textColor);
            ObjectSetInteger(0, finalObjName, OBJPROP_XDISTANCE, posSize*(pos+(i*maxSize)));
            ObjectSetInteger(0, finalObjName, OBJPROP_YDISTANCE, rowSize*row);
            ObjectSetInteger(0, finalObjName, OBJPROP_CORNER, 0);
        }
    }
    
    return StringLen(text);
}

void DashboardManager::deleteAllObjects()
{
    int i = 0;
    while(i<ObjectsTotal())
    {
        string objName=ObjectName(0, i);
        ObjectDelete(0, objName);
    }
}

DashboardManager *MainDashboardMan = NULL;
