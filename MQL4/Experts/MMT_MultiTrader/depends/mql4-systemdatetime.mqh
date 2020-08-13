/* https://www.mql5.com/en/forum/106240
TimeCallsScript.mq4
   Script to demonstrate making kernel32.dll time related calls in MT4 Build 600+

GetSystemTime() and GetLocalTime()
-------------       ------------
From http://msdn.microsoft.com/en-us/library/ms724390%28v=vs.85%29.aspx
void WINAPI GetSystemTime(
  _Out_  LPSYSTEMTIME lpSystemTime
);

From http://msdn.microsoft.com/en-us/library/ms724338%28v=vs.85%29.aspx
void WINAPI GetLocalTime(
  _Out_  LPSYSTEMTIME lpSystemTime
);

Windows structure for a GetSystemTime() or GetLocalTime() call from http://msdn.microsoft.com/en-us/library/ms724950%28v=vs.85%29.aspx
typedef struct _SYSTEMTIME {
  WORD wYear;
  WORD wMonth;
  WORD wDayOfWeek;
  WORD wHour;
  WORD wMinute;
  WORD wSecond;
  WORD wDay;
  WORD wMilliseconds;
} SYSTEMTIME, *PSYSTEMTIME;
*/

// MT4 equivalent struct:
struct SYSTEMTIME {
  ushort wYear;         // 2014 etc
  ushort wMonth;        // 1 - 12
  ushort wDayOfWeek;    // 0 - 6 with 0 = Sunday
  ushort wDay;          // 1 - 31
  ushort wHour;         // 0 - 23
  ushort wMinute;       // 0 - 59
  ushort wSecond;       // 0 - 59
  ushort wMilliseconds; // 0 - 999
};

/*
GetTimeZoneInformation()
----------------------
From http://msdn.microsoft.com/en-us/library/ms724421%28v=vs.85%29.aspx

DWORD WINAPI GetTimeZoneInformation(
  _Out_  LPTIME_ZONE_INFORMATION lpTimeZoneInformation
);

Windows struct for a GetTimeZoneInformation() call from http://msdn.microsoft.com/en-us/library/ms725481%28v=vs.85%29.aspx
typedef struct _TIME_ZONE_INFORMATION {
  LONG       Bias;
  WCHAR      StandardName[32];
  SYSTEMTIME StandardDate;
  LONG       StandardBias;
  WCHAR      DaylightName[32];
  SYSTEMTIME DaylightDate;
  LONG       DaylightBias;
} TIME_ZONE_INFORMATION, *PTIME_ZONE_INFORMATION;
*/

// MT4 equivalent struct
struct TIME_ZONE_INFORMATION {
  int        Bias;
  ushort     StandardName[32];
  SYSTEMTIME StandardDate;
  int        StandardBias;
  ushort     DaylightName[32];
  SYSTEMTIME DaylightDate;
  int        DaylightBias;
};

#import "kernel32.dll"
void GetSystemTime(SYSTEMTIME &SystemTimeStruct);
void  GetLocalTime(SYSTEMTIME &LocalTimeStruct);
int  GetTimeZoneInformation(TIME_ZONE_INFORMATION &TimeZoneInformationStruct);
#import

#define TIME_ZONE_ID_UNKNOWN   0
#define TIME_ZONE_ID_STANDARD  1
#define TIME_ZONE_ID_DAYLIGHT  2

datetime TimeSystemGMT() {
    SYSTEMTIME rawTime = {0};
    GetSystemTime(rawTime);
    return ProcessRawTime(rawTime);
}

datetime TimeSystem() {
    SYSTEMTIME rawTime = {0};
    GetLocalTime(rawTime);
    return ProcessRawTime(rawTime);
}

datetime ProcessRawTime(SYSTEMTIME &rawTime) {
    MqlDateTime mqlTime = {0};
    mqlTime.year = rawTime.wYear;
    mqlTime.mon = rawTime.wMonth;
    mqlTime.day = rawTime.wDay;
    mqlTime.hour = rawTime.wHour;
    mqlTime.min = rawTime.wMinute;
    mqlTime.sec = rawTime.wSecond;
    mqlTime.day_of_week = rawTime.wDayOfWeek;
    //mqlTime.day_of_year
    
    return StructToTime(mqlTime);
}

//s += StringFormat("\n\nTime Zone Information\nReturn: %s\nBias: %d\nStandard Name: %s\nStandardDate Month: %d\nStandard Bias: %d\nDaylight Name: %s\nDaylightDate Month: %d\nDaylight Bias: %d",
//                   retS, tzi.Bias, ShortArrayToString(tzi.StandardName), tzi.StandardDate.wMonth, tzi.DaylightBias, ShortArrayToString(tzi.DaylightName), tzi.DaylightDate.wMonth, tzi.DaylightBias);
