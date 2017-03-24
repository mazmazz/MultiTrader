// MC_Error Library
// v0.2
// 2017/03/24
//
// Copyright (c) 2017 Marco Z
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Changelog
//
// v0.2
// * Added printCurrentTime option to public calls
// * Changed severity triggers from less-than-equals to bitwise
//   * User-facing settings should use ErrorLevelConfig enum instead of ErrorLevel
//   * Param settings should be changed to an ErrorLevelConfig value or a
//     bitwise OR of ErrorLevels (e.g., ErrorNormal | ErrorInfo; )
//   * Public calls remain the same, except you can combine error levels and locations

#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#define FunctionTrace __FILE__+"("+__LINE__+") "+ __FUNCTION__

enum ErrorLevel { // Specify these in error calls
    ErrorNone = 0 // Hide all errors
    , ErrorFatal = 1 // Fatal errors
    , ErrorNormal = 2 // Normal level only
    , ErrorInfo = 4 // Info level only
    , ErrorMinor = 8 // Minor level only
};

enum ErrorLevelConfig { // Use these to set config settings
    ErrorConfigNone = 0 // Hide all errors
    , ErrorConfigFatal = 1 // Fatal errors
    , ErrorConfigFatalNormal = 3 // Normal errors
    , ErrorConfigFatalNormalInfo = 7 // All errors and normal info
    , ErrorConfigAll = 15 // All errors and all info
};

enum ErrorLocation {
    ErrorDefault = 0
    , ErrorFile = 1
    , ErrorTerminal = 2
    , ErrorAlert = 4
};

class Error {
    public:
    static string ProjectName;
    static string FilePath;
    static int TerminalLevel;
    static int AlertLevel;
    static int FileLevel;
    static int FatalStateLevel;

    static void ThrowError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static void ThrowFatalError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static void PrintInfo(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static void CloseErrorFile();
    
    private:
    static int FileHandle;
    static int FatalCounter;
    
    static void ThrowErrorInternal(int level, string message = "", string funcTrace = "", string extraInfo = "", bool fatal = false, bool printCurrentTime = false, int location = ErrorDefault);
    static void PrintError(int level, string message = "", string funcTrace = "", bool fatal = false, bool info=false, string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static bool PrintErrorToFile(string message = "");
    static void PrintErrorToAlert(string message = "");
};

string Error::ProjectName = "";
string Error::FilePath = "";
int Error::TerminalLevel = ErrorConfigFatalNormal;
int Error::AlertLevel = ErrorConfigFatal;
int Error::FileLevel = ErrorConfigNone;
int Error::FatalStateLevel = ErrorConfigNone; // because ExpertRemove() does not exit an EA right away, further error messages will print when only the first one is useful.

int Error::FileHandle = -1;
int Error::FatalCounter = 0;

//+------------------------------------------------------------------+

void Error::ThrowError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    ThrowErrorInternal(level, message, funcTrace, extraInfo, false, printCurrentTime, location);
}

void Error::ThrowFatalError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    ThrowErrorInternal(level, message, funcTrace, extraInfo, true, printCurrentTime, location);
}

void Error::PrintInfo(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    PrintError(level, message, funcTrace, false, true, extraInfo, printCurrentTime, location);
}

void Error::CloseErrorFile() {
    if(FileHandle != INVALID_HANDLE) { FileClose(FileHandle); }
}

//+------------------------------------------------------------------+

void Error::ThrowErrorInternal(int level, string message = "", string funcTrace = "", string extraInfo = "", bool fatal = false, bool printCurrentTime = false, int location = ErrorDefault) {
    PrintError(level, message, funcTrace, fatal, false, extraInfo, printCurrentTime, location);
    if(fatal) { FatalCounter++; ExpertRemove(); } // this calls OnDeinit then exits. this won't exit right away; event handler finishes processing.
}

void Error::PrintError(int level, string message = "", string funcTrace = "", bool fatal = false, bool info=false, string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    if(FatalCounter > 0 && (FatalStateLevel & level) == level) { return; } // if fatal, only print necessary errors
    
    string errorMsg = 
        (printCurrentTime ? TimeCurrent() + " - " : "")
        + ProjectName + " "
        + (fatal ? "FATAL " : "")
        + (level == ErrorInfo ? "INFO: " : level == ErrorMinor ? "MINOR: " : "ERROR: ")
        + funcTrace 
        + (StringLen(funcTrace) > 0 ? " - " : "")
        + message
        + (StringLen(extraInfo) > 0 ? (" - INFO: " + extraInfo) : "")
        ;
    
    if(
        (TerminalLevel & level) == level
        || (location & ErrorTerminal) == ErrorTerminal
        || fatal
    ) { 
        Print(errorMsg);
    }
    
    if(
        (FileLevel & level) == level
        || (location & ErrorFile) == ErrorFile
    ) {
        if(!Error::PrintErrorToFile(errorMsg)) { Print(errorMsg); } 
    }
    
    if(
        (AlertLevel & level) == level
        || (location & ErrorAlert) == ErrorAlert
    ) {
        PrintErrorToAlert(errorMsg);
    }
}

bool Error::PrintErrorToFile(string message = "") {
    if((FileHandle == INVALID_HANDLE) || FileHandle == -1) {
        if(StringLen(FilePath) <= 0) { 
            FilePath = ProjectName + "Log_" + (int)TimeLocal() + "_" + (int)GetMicrosecondCount() + ".txt"; 
        }
        FileHandle = FileOpen(FilePath, FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE);
        if(FileHandle == INVALID_HANDLE) { 
            //ThrowError(ErrorNormal, "MC_Error could not open log file for printing: " + GetLastError(), FunctionTrace, FilePath, ErrorTerminal);
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
