//+------------------------------------------------------------------+
//|                                             MMT_Helper_Error.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

#define ErrorFunctionTrace StringConcatenate(__FILE__,"(",__LINE__,") ", __FUNCTION__)

#include "MMT_Main_Settings.mqh"

bool ErrorPrintAllFatalErrors = false; // because ExpertRemove() does not exit an EA right away, further error messages will print when only the first one is useful.
int ErrorFatalCounter = 0;

void PrintError(int level, string code, string message, bool fatal, bool info=false) {
    // todo: alerts
    if(fatal && ErrorFatalCounter > 0 && !ErrorPrintAllFatalErrors) { return; } // if fatal, only print an error message once. 
    
    if(DebugLevel >= level || fatal) { Print(fatal ? StringConcatenate(ErrorFatalCounter, " FATAL ") : "", info ? "INFO: " : "ERROR: ", code, " - ", message); } 
}

void ThrowError(int level, string code, string message, bool fatal=false) {
    PrintError(level, code, message, fatal);
    if(fatal) { ErrorFatalCounter++; ExpertRemove(); } // this calls OnDeinit then exits. this won't exit right away; event handler will finish processing.
}

void ThrowFatalError(int level, string code, string message) {
    ThrowError(level, code, message, true);
}

void PrintInfo(int level, string code, string message) {
    PrintError(level, code, message, false, true);
}
