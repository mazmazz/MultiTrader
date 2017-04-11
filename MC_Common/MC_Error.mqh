// MC_Error Library
// v0.3
// 2017/03/26
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

    static void ThrowFatal(string message, bool printCurrentTime, int location = ErrorDefault);
    static void PrintNormal(string message, bool printCurrentTime, int location = ErrorDefault);
    static void PrintInfo(string message, bool printCurrentTime, int location = ErrorDefault);
    static void PrintMinor(string message, bool printCurrentTime, int location = ErrorDefault);
    static void PrintError(int level, string message, bool printCurrentTime, int location = ErrorDefault);

    static void ThrowFatal(string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static void PrintNormal(string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static void PrintInfo(string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static void PrintMinor(string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static void PrintError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static void ThrowFatalError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault); // kept for back compat
    static void ThrowError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault); // kept for back compat
    static void PrintInfo_v02(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault); // kept for back compat
    static void CloseErrorFile();
    
    static bool HasLevel(int level, int location = ErrorTerminal);
    
    private:
    static int FileHandle;
    static int FatalCounter;
    
    static void OutputError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault);
    static bool OutputErrorToFile(string message = "");
    static void OutputErrorToAlert(string message = "");
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

void Error::ThrowFatal(string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    OutputError(ErrorFatal, message, funcTrace, extraInfo, printCurrentTime, location);
    FatalCounter++; 
    ExpertRemove();
}

void Error::PrintNormal(string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    OutputError(ErrorNormal, message, funcTrace, extraInfo, printCurrentTime, location);
}

void Error::PrintInfo(string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    OutputError(ErrorInfo, message, funcTrace, extraInfo, printCurrentTime, location);
}

void Error::PrintMinor(string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    OutputError(ErrorMinor, message, funcTrace, extraInfo, printCurrentTime, location);
}

void Error::PrintError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    OutputError(level, message, funcTrace, extraInfo, printCurrentTime, location);
}

void Error::ThrowFatal(string message, bool printCurrentTime, int location = ErrorDefault) {
    ThrowFatal(message, NULL, NULL, printCurrentTime, location);
}

void Error::PrintNormal(string message, bool printCurrentTime, int location = ErrorDefault) {
    PrintNormal(message, NULL, NULL, printCurrentTime, location);
}

void Error::PrintInfo(string message, bool printCurrentTime, int location = ErrorDefault) {
    PrintInfo(message, NULL, NULL, printCurrentTime, location);
}

void Error::PrintMinor(string message, bool printCurrentTime, int location = ErrorDefault) {
    PrintMinor(message, NULL, NULL, printCurrentTime, location);
}

void Error::PrintError(int level, string message, bool printCurrentTime, int location = ErrorDefault) {
    PrintError(level, message, NULL, NULL, printCurrentTime, location);
}


// kept for back compat
void Error::ThrowFatalError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    OutputError(level, message, funcTrace, extraInfo, printCurrentTime, location);
    FatalCounter++; 
    ExpertRemove();
}

// kept for back compat
void Error::ThrowError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    OutputError(level, message, funcTrace, extraInfo, printCurrentTime, location);
}

// kept for back compat, can't overload so must be renamed
void Error::PrintInfo_v02(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    OutputError(level, message, funcTrace, extraInfo, printCurrentTime, location);
}

void Error::CloseErrorFile() {
    if(FileHandle != INVALID_HANDLE) { FileClose(FileHandle); }
}

//+------------------------------------------------------------------+

void Error::OutputError(int level, string message = "", string funcTrace = "", string extraInfo = "", bool printCurrentTime = false, int location = ErrorDefault) {
    if(FatalCounter > 0 && (FatalStateLevel & level) != level) { return; } // if fatal, only print necessary errors
    
    string errorMsg = 
        (printCurrentTime ? TimeCurrent() + " - " : "")
        + ProjectName + " "
        + (level == ErrorFatal ? "FATAL " : "")
        + (level == ErrorInfo ? "INFO: " : level == ErrorMinor ? "MINOR: " : "ERROR: ")
        + funcTrace 
        + (StringLen(funcTrace) > 0 ? " - " : "")
        + message
        + (StringLen(extraInfo) > 0 ? (" - INFO: " + extraInfo) : "")
        ;
    
    if(
        (TerminalLevel & level) == level
        || (location & ErrorTerminal) == ErrorTerminal
        || level == ErrorFatal
    ) { 
        Print(errorMsg);
    }
    
    if(
        (FileLevel & level) == level
        || (location & ErrorFile) == ErrorFile
    ) {
        if(!Error::OutputErrorToFile(errorMsg)) { Print(errorMsg); } 
    }
    
    if(
        (AlertLevel & level) == level
        || (location & ErrorAlert) == ErrorAlert
    ) {
        OutputErrorToAlert(errorMsg);
    }
}

bool Error::OutputErrorToFile(string message = "") {
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

void Error::OutputErrorToAlert(string message="") {
    Alert(message);
}

bool Error::HasLevel(int level, int location = ErrorTerminal) {
    switch(location) {
        case ErrorTerminal: return (TerminalLevel & level) == level;
        case ErrorAlert: return (AlertLevel & level) == level;
        case ErrorFile: return (FileLevel & level) == level;
        default: return false;
    }
}

// Changelog
//
// v0.3
// * Minor refactoring: simplified public calls to not require error level as first param
//   * New public calls are shortcuts for error level: ThrowFatal, PrintNormal, PrintInfo, PrintMinor
//   * Old calls will work, but PrintInfo calls must be renamed to PrintInfo_v02, or changed to new call pattern
//
// v0.2
// * Added printCurrentTime option to public calls
// * Changed severity triggers from less-than-equals to bitwise
//   * User-facing settings should use ErrorLevelConfig enum instead of ErrorLevel
//   * Param settings should be changed to an ErrorLevelConfig value or a
//     bitwise OR of ErrorLevels (e.g., ErrorNormal | ErrorInfo; )
//   * Public calls remain the same, except you can combine error levels and locations
