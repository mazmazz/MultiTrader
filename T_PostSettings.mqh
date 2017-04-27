//+------------------------------------------------------------------+
//|                                               T_PostSettings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
//+------------------------------------------------------------------+
//| defines                                                          |

#define _FontColorDefault C'145,145,145'

enum CycleType {
    CycleTimerSeconds           // Seconds: Run on a second-based interval
    , CycleTimerMilliseconds    // Milliseconds: Run on a millisecond-based interval
#ifdef _EmulatedTicks
    , CycleTimerTicks           // Average ticks: Run on an average tick interval
#endif
    , CycleRealTicks            // Real ticks: Run on every tick; applies only in Single Symbol Mode
};

input string LblRuntime="********** Runtime Settings **********"; // :
input string Lbl_ErrorSettings="---- Error Settings ----"; // :
input ErrorLevelConfig ErrorTerminalLevel=ErrorConfigFatalNormal; // ErrorTerminalLevel: Errors to show in terminal
input ErrorLevelConfig ErrorFileLevel=ErrorConfigNone; // ErrorFileLevel: Errors to write to log file (Hide=Disable)
input ErrorLevelConfig ErrorAlertLevel=ErrorConfigFatal; // ErrorAlertLevel: Errors to trigger an alert
input string ErrorLogFileName=""; // ErrorLogFileName: Leave blank to generate a filename    
//input int HistoryLevel=1; // HistoryLevel: Number of filter values to keep in memory
int DataHistoryLevel=1; // not convinced this should be a user setting
int SignalHistoryLevel=3;

//
//input string Lbl_Notification="---- Notification Settings ----";
//input bool PopupAlert=false;
//input bool EmailAlert=false;
//input bool PushAlert=false;

input string LblDisplay="---- Display Settings ----"; // :
input bool DisplayShow=true;
input bool DisplayShowTable=true;
input bool DisplayShowBasketStopLevels=true;
input bool DisplayShowBasketSymbolLongShort=false;
input bool DisplaySignalInternal=false;
input bool DisplayColor=true;
//input bool DisplayShowOrders=true;
//input string DisplayFont="Lucida Console";
input color DisplayFontColorDefault = _FontColorDefault;
string DisplayFont="Lucida Console"; // Integral font to monospace layout and scaling, should not be user setting
input int DisplayScale=1; // DisplayScale: 0 = Small, 1+ = Large
//input int DisplayFontSize=11;
//input int DisplaySpacing=13;
//input DisplayStyleEnum DisplayStyle=ValueAndSignal;

input string Lbl_CycleSettings="---- Cycle Settings ----"; // :
input CycleType CycleMode=CycleTimerSeconds;
input int CycleLength=1; // CycleLength: Length between cycles (seconds or milliseconds)
#ifdef _EmulatedTicks
input int AverageTickStartMil = 500;
input int AverageTickLowestMil = 250;
input int AverageTickHighestMil = 1000;
#endif