//+------------------------------------------------------------------+
//|                                                MMT_Dashboard.mqh |
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

#include "MMT_Symbols.mqh"
#include "MMT_Filters/MMT_Filters.mqh"
#include "MMT_Data/MMT_Data.mqh"

class DashboardManager {
    public:
    DashboardManager();
    ~DashboardManager();
    
    void initDashboard();
    void updateDashboard();
    void updateData(int symbolId, int filterId, int subfilterId, bool exists = false);
    void deleteAllObjects();

    private:
    string objPrefix;
    string fontFace;
    int fontSize;
    color fontColorDefault;
    
    color fontColorBuy;
    color fontColorSell;
    color fontColorHold;
    
    // col: logical table column, pos: text column
    int row;
    int col;
    int pos;
    int rowSize;
    int colSize;
    int posSize;
    int dataRowStart;
    int dataPosStart;
    int dataExitPosStart;
    
    string sepChar;
    string spacedSepChar;
    
    void drawText(string objName, string text); 
    void drawText(string objName, string text, color textColor);
    
    string prefixName(string subPrefix, string name = NULL);
    string truncText(string text, int length);
    string padText(string text, int length);
    int getPosSize();
    string signalToString(SignalType signal, bool shortCode = false);
    
    void drawHeader();
    void drawLegend();
    void drawSymbols();
    void drawData(int symbolId, int filterId, int subfilterId);
    
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
    fontColorDefault = clrSilver;
    fontColorBuy = clrGreen;
    fontColorSell = clrRed;
    fontColorHold = fontColorDefault;
    
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
    
    deleteAllObjects();
    
    drawHeader(); row++; pos=1;
    drawLegend(); row++;
    drawSymbols(); row=0; pos=0;
}

void DashboardManager::drawHeader() {
    string headerText = _ProjectName + " " + _ProjectVersion +
        spacedSepChar + IntegerToString(MagicNumber) + " " + ConfigComment + spacedSepChar;
    
    string statusText = 
        "Control: "
        + (TradeEntryEnabled ? "Entry/": "") 
        + (TradeExitEnabled ? "Exit/" : "") 
        + (TradeValueEnabled ? "Value" : "")
        + spacedSepChar
        ;
    
    /* list of filters
    for(int i = 0; i < MainFilterMan.filterCount; i++) {
        headerText += MainFilterMan.filterShortNames[i] + 
            "(" + MainFilterMan.getSubfilterCount(i, false) + 
            "," + MainFilterMan.getSubfilterCount(i, true) +
            ") ";
    }*/
    
    drawText(prefixName("header"), headerText);
    pos += StringLen(headerText);
    drawText(prefixName("status"), statusText);
    pos += StringLen(statusText);
    
    // insert results here
    drawText(prefixName("results"), "Results");
}

void DashboardManager::drawLegend() {
    int maxLabelPos = colSize-1;
    string legendText = "";
    string filterText = "";
    int subfilterCount = 0;
    
    legendText += "Symbols" + spacedSepChar;
    // SL (if not 0)
    // TP (if not 0)
    // Lots (if variable)
    // ATR (if used)
    // STDEV (if used)
    // other central tendency (if used)
    
    dataPosStart = StringLen(legendText)+1;
    
    int filterCount = MainFilterMan.getFilterCount();
    
    // entries
    for(int i = 0; i < filterCount; i++) {
        subfilterCount = MainFilterMan.filters[i].getSubfilterCount();
        for(int j = 0; j < subfilterCount; j++) { 
            legendText += padText(truncText(MainFilterMan.filters[i].shortName, maxLabelPos-2) + "-" + MainFilterMan.filters[i].subfilterName[j], colSize);
        }
    }
    
    //legendText += sepChar + " ";
    dataExitPosStart = StringLen(legendText)+1;
    
    // exits
    //for(int i = 0; i < MainFilterMan.filterCount; i++) {
    //    subfilterCount = MainFilterMan.getSubfilterCount(i, true);
    //    for(int j = 1; j <= subfilterCount; j++) { 
    //        legendText += padText(StringConcatenate(truncText(MainFilterMan.filterShortNames[i], maxLabelPos-1), j), colSize);
    //    }
    //}
    
    drawText(prefixName("legend"), legendText);
}

void DashboardManager::drawSymbols() {
    dataRowStart = row;
    int firstSymRow = row;
    int maxLabelPos = colSize-1;
    int maxTextPos = 7; // "Symbols " minus 1
    int subfilterCount = 0;
    int size = MainSymbolMan.getSymbolCount();
    
    int j = 0; int k = 0;
    for(int i = 0; i < size; i++) {
        col = 0;
        drawText(prefixName(IntegerToString(i)), truncText(MainSymbolMan.symbols[i].name, maxTextPos));
        
        int filterCount = MainFilterMan.getFilterCount();
        
        // todo: order by filter type, or custom
        for(j = 0; j < filterCount; j++) {
            subfilterCount = MainFilterMan.filters[j].getSubfilterCount();
            for(k = 0; k < subfilterCount; k++) { 
                drawData(i, j, k);
                col++;
            }
        }
        
        row++;
    }
}

void DashboardManager::drawData(int symbolId, int filterId, int subfilterId) {
    string dataObjName = prefixName(symbolId + "_" + filterId + "_" + subfilterId, getDataSuffix(filterId, subfilterId));
    if(ObjectCreate(0, dataObjName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, dataObjName, OBJPROP_XDISTANCE, posSize * (dataPosStart + col*colSize));
        ObjectSetInteger(0, dataObjName, OBJPROP_YDISTANCE, rowSize * row);
        ObjectSetInteger(0, dataObjName, OBJPROP_CORNER, 0);
        updateData(symbolId, filterId, subfilterId, true);
    }
}

void DashboardManager::updateDashboard() {
    int filterCount = MainFilterMan.getFilterCount();
    int subfilterCount = 0;
    int size = MainSymbolMan.getSymbolCount();
    
    int j = 0; int k = 0;
    for(int i = 0; i < size; i++) {
        // todo: order by filter type, or custom
        for(j = 0; j < filterCount; j++) {
            subfilterCount = MainFilterMan.filters[j].getSubfilterCount();
            for(k = 0; k < subfilterCount; k++) { 
                updateData(i, j, k);
            }
        }
    }
}

void DashboardManager::updateData(int symbolId, int filterId, int subfilterId, bool exists = false) {
    // mmt_data_[symbolId]_[filterId]_[subfilterId]
    string objName;
    string dataResult;

    string suffixName = getDataSuffix(filterId, subfilterId);

    objName = prefixName(symbolId + "_" + filterId + "_" + subfilterId, suffixName);
    
    if(!exists) { exists = (ObjectFind(0, objName) >= 0); }
    
    if(exists) {
        DataUnit *data = MainDataMan.getDataHistory(symbolId, filterId, subfilterId).getData();
        color fontColor = fontColorDefault;
        
        if(data == NULL) { dataResult = "-"; }
        else {
            //switch(DisplayStyle) {
            //    case ValueAndSignal:
                    dataResult = data.getStringValue(MainSymbolMan.symbols[symbolId].digits) + " " + signalToString(data.signal, true);
//                    break;
//                    
//                case SignalOnly:
//                    dataResult = signalToString(data.signal, false);
//                    break;
//                    
//                default: // value only
//                    dataResult = data.getStringValue(MainSymbolMan.symbols[symbolId].digits);
//                    break;
//            }
            
            fontColor = 
                data.signal == SignalBuy ? fontColorBuy : 
                data.signal == SignalSell ? fontColorSell : 
                data.signal == SignalHold ? fontColorHold : fontColorDefault
                ;
        }
    
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

string DashboardManager::signalToString(SignalType signal, bool shortCode = false) {
    switch(signal) {
        case SignalBuy: return shortCode ? "B" : "Buy"; break;
        case SignalSell: return shortCode ? "S" : "Sell"; break;
        case SignalHold: return shortCode ? "H" : "Hold"; break;
        default: return ""; break;
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

int DashboardManager::getPosSize() {
    string objName = prefixName("test");
    int size = 0;
    if(ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetText(objName, "W", fontSize, fontFace, clrWhite);
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 0);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, 0);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, 0);
        size = ObjectGetInteger(0, objName, OBJPROP_XSIZE);
        ObjectDelete(0, objName);
    }
    
    return size;
}

string DashboardManager::prefixName(string subPrefix, string name = NULL) {
    if(name == NULL) { return objPrefix + subPrefix; }
    else { return objPrefix + subPrefix + "_" + name; }
}

void DashboardManager::drawText(string objName, string text) {
    drawText(objName, text, fontColorDefault);
}

void DashboardManager::drawText(string objName, string text, color textColor) {
    // objects only take 63 characters. split text and create multiple objs if needed
    int maxSize = 63;
    int multiple = MathFloor(StringLen(text) / maxSize) + 1;
    string finalObjName = "";
    
    for(int i = 0; i < multiple; i++) {
        finalObjName = objName + (i <= 0 ? "" : i+1);
        if(ObjectCreate(0, finalObjName, OBJ_LABEL, 0, 0, 0)) {
            ObjectSetText(finalObjName, StringSubstr(text, i*maxSize, maxSize+1), fontSize, fontFace, textColor);
            ObjectSetInteger(0, finalObjName, OBJPROP_XDISTANCE, posSize*(pos+(i*maxSize)));
            ObjectSetInteger(0, finalObjName, OBJPROP_YDISTANCE, rowSize*row);
            ObjectSetInteger(0, finalObjName, OBJPROP_CORNER, 0);
        }
    }
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

DashboardManager *MainDashboardMan;
