//+------------------------------------------------------------------+
//|                                                     H_Alerts.mqh |
//|                                                          mazmazz |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "mazmazz"
#property link      "https://github.com/mazmazz"
//+------------------------------------------------------------------+

#include "T_PostSettings.mqh"
#include "S_Symbol.mqh"
#include "D_Data/D_DataUnit.mqh"

class AlertManager {
    public:
    AlertManager();
    void updateAlerts();
    void alertBySymbolSignal(int symIdx, bool isEntry);
    void alertByTradeAction(int symIdx, bool isEntry);
    
    private:
    SignalType lastSignalEntry[];
    SignalType lastSignalExit[];
};

void AlertManager::AlertManager() {
    ArrayResize(lastSignalEntry, MainSymbolMan.getSymbolCount());
    ArrayInitialize(lastSignalEntry, SignalNone);
    ArrayResize(lastSignalExit, MainSymbolMan.getSymbolCount());
    ArrayInitialize(lastSignalExit, SignalNone);
}

void AlertManager::updateAlerts() {
    if(!EnableSignalAlerts) { return; }
    
    int symCount = MainSymbolMan.getSymbolCount();
    for(int i = 0; i < symCount; i++) {
        alertBySymbolSignal(i, true);
        alertBySymbolSignal(i, false);
    }
}

void AlertManager::alertBySymbolSignal(int symIdx, bool isEntry) {
    string alertMsg = NULL;

    SignalType signal = SignalNone;
    SignalUnit *signalUnit = NULL;
    signalUnit = MainDataMan.symbol[symIdx].getSymbolSignalUnit(isEntry);
    if(!Common::IsInvalidPointer(signalUnit)) { signal = signalUnit.type; }
    else { signal = SignalNone; }
    
    if(isEntry) {
        if(signal == lastSignalEntry[symIdx]) { return; }
        else { lastSignalEntry[symIdx] = signal; }
        alertMsg += MainSymbolMan.symbols[symIdx].name + " Entry: ";
    } else {
        if(!DisplaySignalInternal) {
            switch(signal) {
                case SignalLong: signal = SignalShort; break;
                case SignalShort: signal = SignalLong; break;
            }
        }
        
        if(signal == lastSignalExit[symIdx]) { return; }
        else { lastSignalExit[symIdx] = signal; }
        
        alertMsg += MainSymbolMan.symbols[symIdx].name + " Exit: ";
    }
    
    alertMsg += EnumToString(signal);
    Alert(alertMsg);
}

void AlertManager::alertByTradeAction(int symIdx, bool isEntry) {
    if(!EnableActionAlerts) { return; }
    
    string alertMsg = MainSymbolMan.symbols[symIdx].name + " ";
    alertMsg += isEntry ? "Entered" : "Exited";
    Alert(alertMsg);
}

AlertManager *MainAlertMan;