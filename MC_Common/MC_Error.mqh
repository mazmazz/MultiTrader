//+------------------------------------------------------------------+
//|                                                     MC_Error.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict


#define FunctionTrace __FILE__+"("+__LINE__+") "+ __FUNCTION__

enum ErrorLevel {
    ErrorNone,
    ErrorFatal,
    ErrorNormal,
    ErrorInfo,
    ErrorMinor
};

enum ErrorPrintLocation {
    ErrorDoDefault,
    ErrorForceFile,
    ErrorForceTerminal
};

class Error {
    private:
    static int FileHandle;
    
    public:
    static string FilePath;
    static bool LogAllErrorsToFile;
    static bool LogAllErrorsToTerminal;
    static bool PrintAllFatalErrors;
    static int FatalCounter;
    static int DebugLevel;
    
    static bool PrintErrorToFile(string message = "");
    static void PrintError(int level, string message = "", string funcTrace = "", bool fatal = false, bool info = false, string params = "", ErrorPrintLocation location = ErrorDoDefault);
    static void ThrowError(int level, string message = "", string funcTrace = "", string params = "", bool fatal = false, ErrorPrintLocation location = ErrorDoDefault);
    static void ThrowFatalError(int level, string message = "", string funcTrace = "", string params = "", ErrorPrintLocation location = ErrorDoDefault);
    static void PrintInfo(int level, string message = "", string funcTrace = "", string params = "", ErrorPrintLocation location = ErrorDoDefault);
};

//#include "MMT_Settings.mqh"

int Error::FileHandle = -1;
string Error::FilePath = "";
bool Error::PrintAllFatalErrors = false; // because ExpertRemove() does not exit an EA right away, further error messages will print when only the first one is useful.
int Error::FatalCounter = 0;
int Error::DebugLevel = 2; // user configurable
bool Error::LogAllErrorsToFile = false; // user configurable
bool Error::LogAllErrorsToTerminal = true; // user configurable

bool Error::PrintErrorToFile(string message = "") {
    // todo: how to close upon program exit?
    
    if((FileHandle == INVALID_HANDLE) || FileHandle == -1) {
        if(StringLen(FilePath) <= 0) { FilePath = "Log_" + (int)TimeLocal() + "_" + (int)GetMicrosecondCount() + ".txt"; }
        FileHandle = FileOpen(FilePath, FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE);
        if(FileHandle == INVALID_HANDLE) { 
            ThrowError(ErrorNormal, "MC_Error could not open log file for printing: " + GetLastError(), FunctionTrace, FilePath);
            return false; 
        }
    }
    
    message = TimeLocal() + " - " + message + "\n";
    
    if(FileSeek(FileHandle, 0, SEEK_END)) {
        return FileWriteString(FileHandle, message);
    } else { return false; }
}

void Error::PrintError(int level, string message = "", string funcTrace = "", bool fatal = false, bool info=false, string params = "", ErrorPrintLocation location = ErrorDoDefault) {
    // todo: alerts
    if(fatal && FatalCounter > 0 && !PrintAllFatalErrors) { return; } // if fatal, only print an error message once. 
    
    string errorMsg = 
        (fatal ? (FatalCounter + " FATAL ") : "")
        + (level == ErrorInfo ? "INFO: " : level == ErrorMinor ? "MINOR: " : "ERROR: ")
        + funcTrace 
        + (StringLen(funcTrace) > 0 ? " - " : "")
        + message
        + (StringLen(params) > 0 ? (" - PARAMS: " + params) : "")
        ;
    
    if(DebugLevel >= level || fatal) { 
        if(LogAllErrorsToTerminal || !LogAllErrorsToFile || location == ErrorForceTerminal) { Print(errorMsg); }
        if(location == ErrorForceFile || LogAllErrorsToFile) { if(!Error::PrintErrorToFile(errorMsg)) { Print(errorMsg); } }
    } 
}

void Error::ThrowError(int level, string message = "", string funcTrace = "", string params = "", bool fatal = false, ErrorPrintLocation location = ErrorDoDefault) {
    PrintError(level, message, funcTrace, fatal, false, params, location);
    if(fatal) { FatalCounter++; ExpertRemove(); } // this calls OnDeinit then exits. this won't exit right away; event handler will finish processing.
}

void Error::ThrowFatalError(int level, string message = "", string funcTrace = "", string params = "", ErrorPrintLocation location = ErrorDoDefault) {
    ThrowError(level, message, funcTrace, params, true, location);
}

void Error::PrintInfo(int level, string message = "", string funcTrace = "", string params = "", ErrorPrintLocation location = ErrorDoDefault) {
    PrintError(level, message, funcTrace, false, true, params, location);
}
