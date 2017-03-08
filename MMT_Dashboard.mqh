//+------------------------------------------------------------------+
//|                                                MMT_Dashboard.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#include "MMT_Symbols.mqh"
#include "MMT_Filters/MMT_Filters.mqh"
#include "MMT_Data/MMT_Data.mqh"

class DashboardManager {
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
    
    void deleteAllObjects();
    
    public:
    DashboardManager();
    ~DashboardManager();
    
    void drawData(int symbolId, int filterId, int subfilterId, bool subfilterIsExit, bool exists = false);
};

void DashboardManager::DashboardManager() {
    objPrefix = MMT_EaShortName + "_";
    fontFace = DisplayFont;
    fontSize = 11+(DisplayScale < 1 ? -4 : (DisplayScale-1)*4); //DisplayFontSize;
    fontColorDefault = clrSilver;
    fontColorBuy = clrGreen;
    fontColorSell = clrRed;
    fontColorHold = fontColorDefault;
    
    rowSize = fontSize*2.5;
    posSize = fontSize*1.2;//posSize = getPosSize(); // // guessing at fixed font width
        // http://stackoverflow.com/questions/19113725/what-dependency-between-font-size-and-width-of-char-in-monospace-font
    
    if(DisplayStyle == ValueAndSignal) { colSize = 10; }
    else { colSize = 8; } // expressed in pos units
    
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
    string headerText = MMT_EaName + " " + MMT_Version +
        spacedSepChar + IntegerToString(MagicNumber) + " " + ConfigComment + spacedSepChar;
    
    string statusText = "DoTrade: " + (DoTrade ? "True" : "False") + " DoExit: " + (DoExit ? "True" : "False") + spacedSepChar;
    
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
    
    int filterCount = MainFilterMan.filterCount();
    
    // entries
    for(int i = 0; i < filterCount; i++) {
        subfilterCount = MainFilterMan.filters[i].subfilterCount();
        for(int j = 1; j <= subfilterCount; j++) { 
            legendText += padText(StringConcatenate(truncText(MainFilterMan.filters[i].shortName, maxLabelPos-1), j), colSize);
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
    int size = MainSymbolMan.symbolCount();
    
    int j = 0; int k = 0;
    for(int i = 0; i < size; i++) {
        col = 0;
        drawText(prefixName(IntegerToString(i)), truncText(MainSymbolMan.symNames[i], maxTextPos));
        
        int filterCount = MainFilterMan.filterCount();
        
        // todo: order by filter type, or custom
        for(j = 0; j < filterCount; j++) {
            subfilterCount = MainFilterMan.filters[j].subfilterCount();
            for(k = 0; k < subfilterCount; k++) { 
                string dataObjName = prefixName(StringConcatenate(i, "_", j, "_", k, "_entry"));
                if(ObjectCreate(dataObjName, OBJ_LABEL, 0, 0, 0)) {
                    ObjectSet(dataObjName, OBJPROP_XDISTANCE, posSize * (dataPosStart + col*colSize));
                    ObjectSet(dataObjName, OBJPROP_YDISTANCE, rowSize * row);
                    ObjectSet(dataObjName, OBJPROP_CORNER, 0);
                    drawData(i, j, k, false, true);
                }
                col++;
            }
        }
        
        row++;
    }
}

void DashboardManager::drawData(int symbolId, int filterId, int subfilterId, bool subfilterIsExit, bool exists = false) {
    // mmt_data_[symbolId]_[filterId]_[subfilterId]
    string objName;
    string dataResult;
    
    if(subfilterIsExit) { objName = prefixName(StringConcatenate(symbolId, "_", filterId, "_", subfilterId, "_exit")); }
    else { objName = prefixName(StringConcatenate(symbolId, "_", filterId, "_", subfilterId, "_entry")); }
    
    if(!exists) { exists = (ObjectFind(objName) >= 0); }
    
    if(exists) {
        DataUnit *data = MainDataMan.getDataHistory(symbolId, filterId, subfilterId).getData();
        color fontColor = fontColorDefault;
        
        if(data == NULL) { dataResult = "-"; }
        else {
            switch(DisplayStyle) {
                case ValueAndSignal:
                    dataResult = data.getStringValue() + " " + signalToString(data.signal, true);
                    break;
                    
                case SignalOnly:
                    dataResult = signalToString(data.signal, false);
                    break;
                    
                default: // value only
                    dataResult = data.getStringValue();
                    break;
            }
            
            fontColor = 
                data.signal == SignalBuy ? fontColorBuy : 
                data.signal == SignalSell ? fontColorSell : 
                data.signal == SignalHold ? fontColorHold : fontColorDefault
                ;
        }
    
        ObjectSetText(objName, dataResult, fontSize, fontFace, fontColor);
    }
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
    if(ObjectCreate(objName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetText(objName, "W", fontSize, fontFace, clrWhite);
        ObjectSet(objName, OBJPROP_XDISTANCE, 0);
        ObjectSet(objName, OBJPROP_YDISTANCE, 0);
        ObjectSet(objName, OBJPROP_CORNER, 0);
        size = ObjectGet(objName, OBJPROP_XSIZE);
        ObjectDelete(objName);
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
    if(ObjectCreate(objName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetText(objName, text, fontSize, fontFace, textColor);
        ObjectSet(objName, OBJPROP_XDISTANCE, posSize*pos);
        ObjectSet(objName, OBJPROP_YDISTANCE, rowSize*row);
        ObjectSet(objName, OBJPROP_CORNER, 0);
    }
}

void DashboardManager::deleteAllObjects()
{
    // This could be static, but instantiating it in case we want to do more later
    // Borrowed from jlcgarcia, MyFriendEA
    int i = 0;
    while(i<ObjectsTotal())
    {
        string objName=ObjectName(i);
        ObjectDelete(objName);
    }
}

void DashboardManager::~DashboardManager() {
    deleteAllObjects();
}

DashboardManager *MainDashboardMan;
