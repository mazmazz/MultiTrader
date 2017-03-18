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
#include "MMT_Filters/MMT_FilterManager.mqh"
#include "MMT_Data/MMT_Data.mqh"

class DashboardManager {
    public:
    DashboardManager();
    ~DashboardManager();
    
    void initDashboard();
    void updateDashboard();
    void updateData(int symbolId, int filterId, int subfilterId, bool exists = false);
    void updateSymbolSignal(int symbolId, SubfilterType subType, bool exists = false);
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
    int getPosSize();
    string signalToString(SignalType signal, bool shortCode = true);
    string signalToString(SignalType signal, int duration, SubfilterType type, bool shortCode = true);
    
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
    fontColorDefault = C'145,145,145';
    fontColorBuy = C'0,178,0';
    fontColorSell = clrRed;
    fontColorAction = C'0,154,255';
    fontColorCounterAction = C'255,100,0';
    
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
        + (!TradeEntryEnabled && !TradeExitEnabled && !TradeValueEnabled ? "None" : "")
        + spacedSepChar
        ;
    
    pos += drawText(prefixName("header"), headerText);
    pos += drawText(prefixName("status"), statusText);
    
    // insert results here
    //drawText(prefixName("results"), "Results");
}

void DashboardManager::drawLegend() {
    int maxLabelPos = colSize-1;
    string legendText = "";
    string filterText = "";
    
    legendText += "Symbols" + spacedSepChar;
    
    dataPosStart = StringLen(legendText)+1;
    
    drawSubfilterColLegend(legendText, SubfilterValue);
    drawSubfilterColLegend(legendText, SubfilterEntry);
    drawSubfilterColLegend(legendText, SubfilterExit);
    
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
        drawText(prefixName(IntegerToString(i)), truncText(MainSymbolMan.symbols[i].name, maxTextPos) + spacedSepChar);
        
        drawSubfilterColData(i, SubfilterValue);
        drawSubfilterColData(i, SubfilterEntry);
        drawSubfilterColData(i, SubfilterExit, false);
        
        pos = dataPosStart + (colSize*col) + colOffset-1;
        drawText(prefixName(IntegerToString(i)+"_end"), spacedSepChar + truncText(MainSymbolMan.symbols[i].name, maxTextPos));
        
        row++;
    }
}

void DashboardManager::drawSubfilterColData(int symbolIdx, SubfilterType subType, bool writeSep = true) {
    string emptyString;
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
            int subIdx;
            switch(subType) {
                case SubfilterValue: subIdx = MainFilterMan.filters[i].valueSubfilterId[j]; break;
                case SubfilterEntry: subIdx = MainFilterMan.filters[i].entrySubfilterId[j]; break;
                case SubfilterExit:  subIdx = MainFilterMan.filters[i].exitSubfilterId[j];  break;
                default: return;
            }
            
            if(MainFilterMan.filters[i].subfilterMode[subIdx] == SubfilterDisabled) { continue; }
            
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
    if(ObjectCreate(0, dataObjName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, dataObjName, OBJPROP_XDISTANCE, posSize * (dataPosStart + (col*colSize) + colOffset));
        ObjectSetInteger(0, dataObjName, OBJPROP_YDISTANCE, rowSize * row);
        ObjectSetInteger(0, dataObjName, OBJPROP_CORNER, 0);
        updateData(symbolId, filterId, subfilterId, true);
    }
}

void DashboardManager::drawSymbolSignal(int symbolId,SubfilterType subType) {
    string dataObjName = prefixName(symbolId + "_" + EnumToString(subType) + "_signal");
    if(ObjectCreate(0, dataObjName, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, dataObjName, OBJPROP_XDISTANCE, posSize * (dataPosStart + (col*colSize) + colOffset));
        ObjectSetInteger(0, dataObjName, OBJPROP_YDISTANCE, rowSize * row);
        ObjectSetInteger(0, dataObjName, OBJPROP_CORNER, 0);
        updateSymbolSignal(symbolId, subType, true);
    }
}

void DashboardManager::updateDashboard() {
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
        DataHistory *history = MainDataMan.getDataHistory(symbolId, filterId, subfilterId);
        DataUnit *data = history.getData();
        color fontColor = fontColorDefault;
        
        if(data == NULL) { dataResult = "-"; }
        else {
            dataResult = 
                data.getStringValue(MainSymbolMan.symbols[symbolId].digits) 
                + " " 
                + signalToString(data.signal, history.getSignalDuration(TimeSettingUnit), MainFilterMan.filters[filterId].subfilterType[subfilterId]);
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
        SignalType signal;
        string dataResult;
        color fontColor;
        
        switch(subType) {
            case SubfilterEntry: 
                signal = MainOrderMan.tradeSignals[symbolId].entryAction; 
                fontColor = fontColorAction;
                break;
            case SubfilterExit: 
                signal = MainOrderMan.tradeSignals[symbolId].entryAction; 
                fontColor = fontColorCounterAction;
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

string DashboardManager::signalToString(SignalType signal, bool shortCode = true) {
    return signalToString(signal, -1, SubfilterAllTypes, shortCode);
}

string DashboardManager::signalToString(SignalType signal, int duration, SubfilterType type, bool shortCode = true) {
    if(signal == SignalNone) { return ""; }

    switch(type) {
        case SubfilterEntry:
            if(duration < EntryStableTime) { return IntegerToString(EntryStableTime - duration); }
            break;
            
        case SubfilterExit:
            if(duration < ExitStableTime) { return IntegerToString(ExitStableTime - duration); }
            break;
            
        case SubfilterValue:
            return ""; // value filters don't have signals
    } 
    
    switch(signal) {
        case SignalBuy: return shortCode ? "B" : "Buy"; break;
        case SignalSell: return shortCode ? "S" : "Sell"; break;
        //case SignalHold: return shortCode ? "H" : "Hold"; break;
        case SignalOpen: return shortCode ? "O" : "Open"; break;
        case SignalClose: return shortCode ? "C" : "Close"; break;
        case SignalLong: return shortCode ? "L" : "Long"; break;
        case SignalShort: return shortCode ? "H" : "Short"; break;
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
        if(ObjectCreate(0, finalObjName, OBJ_LABEL, 0, 0, 0)) {
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

DashboardManager *MainDashboardMan;
