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
    ErrorNone // Hide all errors
    , ErrorFatal // Fatal errors
    , ErrorNormal // Normal errors
    , ErrorInfo // All errors and normal info
    , ErrorMinor // All errors and all info
};

enum ErrorLocation {
    ErrorDefault
    , ErrorFile
    , ErrorTerminal
    , ErrorAlert
};

class Error {
    public:
    static string ProjectName;
    static ErrorLevel TerminalLevel;
    static ErrorLevel AlertLevel;
    static ErrorLevel FileLevel;
    static string FilePath;
    static bool PrintAllFatalErrors;

    static void ThrowError(int level, string message = "", string funcTrace = "", string extraInfo = "", ErrorLocation location = ErrorDefault);
    static void ThrowFatalError(int level, string message = "", string funcTrace = "", string extraInfo = "", ErrorLocation location = ErrorDefault);
    static void PrintInfo(int level, string message = "", string funcTrace = "", string extraInfo = "", ErrorLocation location = ErrorDefault);
    static void CloseErrorFile();
    
    private:
    static int FileHandle;
    static int FatalCounter;
    
    static void ThrowErrorInternal(int level, string message = "", string funcTrace = "", string extraInfo = "", bool fatal = false, ErrorLocation location = ErrorDefault);
    static void PrintError(int level, string message = "", string funcTrace = "", bool fatal = false, bool info = false, string extraInfo = "", ErrorLocation location = ErrorDefault);
    static bool PrintErrorToFile(string message = "");
    static void PrintErrorToAlert(string message = "");
};

string Error::ProjectName = "";
ErrorLevel Error::TerminalLevel = ErrorNormal;
ErrorLevel Error::AlertLevel = ErrorFatal;
ErrorLevel Error::FileLevel = ErrorNone;
string Error::FilePath = "";
bool Error::PrintAllFatalErrors = false; // because ExpertRemove() does not exit an EA right away, further error messages will print when only the first one is useful.

int Error::FileHandle = -1;
int Error::FatalCounter = 0;

//+------------------------------------------------------------------+

void Error::ThrowError(int level, string message = "", string funcTrace = "", string extraInfo = "", ErrorLocation location = ErrorDefault) {
    ThrowErrorInternal(level, message, funcTrace, extraInfo, false, location);
}

void Error::ThrowFatalError(int level, string message = "", string funcTrace = "", string extraInfo = "", ErrorLocation location = ErrorDefault) {
    ThrowErrorInternal(level, message, funcTrace, extraInfo, true, location);
}

void Error::PrintInfo(int level, string message = "", string funcTrace = "", string extraInfo = "", ErrorLocation location = ErrorDefault) {
    PrintError(level, message, funcTrace, false, true, extraInfo, location);
}

void Error::CloseErrorFile() {
    if(FileHandle != INVALID_HANDLE) { FileClose(FileHandle); }
}

//+------------------------------------------------------------------+

void Error::ThrowErrorInternal(int level, string message = "", string funcTrace = "", string extraInfo = "", bool fatal = false, ErrorLocation location = ErrorDefault) {
    PrintError(level, message, funcTrace, fatal, false, extraInfo, location);
    if(fatal) { FatalCounter++; ExpertRemove(); } // this calls OnDeinit then exits. this won't exit right away; event handler finishes processing.
}

void Error::PrintError(int level, string message = "", string funcTrace = "", bool fatal = false, bool info=false, string extraInfo = "", ErrorLocation location = ErrorDefault) {
    if(fatal && FatalCounter > 0 && !PrintAllFatalErrors) { return; } // if fatal, only print an error message once. 
    
    string errorMsg = 
        ProjectName + " "
        + (fatal ? "FATAL " : "")
        + (level == ErrorInfo ? "INFO: " : level == ErrorMinor ? "MINOR: " : "ERROR: ")
        + funcTrace 
        + (StringLen(funcTrace) > 0 ? " - " : "")
        + message
        + (StringLen(extraInfo) > 0 ? (" - INFO: " + extraInfo) : "")
        ;
    
    if(TerminalLevel >= level || location == ErrorTerminal || fatal) { 
        Print(errorMsg);
    }
    
    if(FileLevel >= level || location == ErrorFile) {
        if(!Error::PrintErrorToFile(errorMsg)) { Print(errorMsg); } 
    }
    
    if(AlertLevel >= level || location == ErrorAlert) {
        PrintErrorToAlert(errorMsg);
    }
}

bool Error::PrintErrorToFile(string message = "") {
    if((FileHandle == INVALID_HANDLE) || FileHandle == -1) {
        if(StringLen(FilePath) <= 0) { 
            FilePath = ProjectName +  "Log_" + (int)TimeLocal() + "_" + (int)GetMicrosecondCount() + ".txt"; 
        }
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

void Error::PrintErrorToAlert(string message="") {
    Alert(message);
}
