//+------------------------------------------------------------------+
//|                                           MMT_Helper_Library.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#ifdef __MQL5__
#include "Mql4Shim.mqh"
#endif

enum StringType {
    Type_Empty,
    Type_Alphanumeric,
    Type_Uppercase,
    Type_Lowercase,
    Type_Alpha,
    Type_Numeric,
    Type_Symbol
};

class TimePoint {
    public:
    uint milliseconds;
    datetime dateTime;
    uint cycles;
    TimePoint(uint millisecondsIn = 0, datetime dateTimeIn = 0, uint cyclesIn = 0) { 
        update(millisecondsIn, dateTimeIn, cyclesIn);
    }
    
    void update (uint millisecondsIn = 0, datetime dateTimeIn = 0, uint cyclesIn = 0) { 
        milliseconds = millisecondsIn > 0 ? millisecondsIn : GetTickCount(); 
        dateTime = dateTimeIn > 0 ? dateTimeIn : TimeCurrent(); 
        cycles = cyclesIn; 
    }
};

template<typename T>
class ArrayDim {
    public:
    T _[];
};

string StringZeroArray[1];
bool BoolZeroArray[1];
int IntZeroArray[1];
double DoubleZeroArray[1];

class Common {
    public:
    //array
    template<typename T>
    static void ArrayDelete(T &array[],int index, int diff=1, bool resize=true);
    template<typename T>
    static int ArrayPush(T &array[], T unit, int maxSize = -1);
    
    template<typename T>
    static int ArrayReserve(T &array[], int reserveSize);
    
    static int ArrayTsearch(string &array[], string value, int count=-1, int start=0, int direction=MODE_ASCEND, bool caseSensitive=true);
    
    template <typename T>
    static int ArrayFind(T &array[], T needle);
    
    template <typename T>
    static void ResetArrayBySize(T &arr[], int size);
    template <typename T>
    static void ResetArrayBySize(bool force, T &arr[], int size);
    template <typename T>
    static void ResetArrayBySize(T &arr[], int size, T defaultVal);
    template <typename T>
    static void ResetArrayBySize(bool force, T &arr[], int size, T defaultVal);
    
    // string
    static string StringTrim(string inputStr);
    //template<typename T>
    //static bool ConvertToBool(T in);
    static bool StrToBool(string inputStr);
    static bool IsAddrAbcValid (string addrAbc);
    static int AddrAbcToInt(string addrAbc, bool zeroBased=true);
    static string AddrIntToAbc(int addrInt, bool zeroBased=true);
    static string ConcatStringFromArray(string& strArray[], string delimiter = ";");
    static StringType GetStringType(string test);
    
    //uuid
    static string GetUuid();
    
    static int GetGcd(int a, int b);
    
    static bool IsDatetimeInRange(datetime subject, int startDayOfWeek, int startHour, int endDayOfWeek, int endHour);
    
    template<typename T>
    static int GetTimeDuration(T cur, T prev);
    
    static string GetSqlDatetime(datetime source, bool appendTimeOffset=false, string timeOffset=""/*, bool calcBrokerOffset=false*/);
    
    static bool EventSetTimerReliable(int seconds);
    static bool EventSetMillisecondTimerReliable(int milliseconds);
    
    static string GetRandomFileName(string prefix = "Log_", string ext = ".txt");
    
    template<typename T>
    static void SafeDeletePointerArray(T &array[]);
    
    template<typename T>
    static void SafeDelete(T *pointer);
    template<typename T>
    static void SafeDelete(T pointer);
    template<typename T>
    static bool IsPointer(const T &value);
    template<typename T>
    static bool IsInvalidPointer(T *pointer);
    
    static double PriceToPips(double price, string symbol);
    
    static bool OrderIsLong(int opType);
    static bool OrderIsShort(int opType);
    static bool OrderIsPending(int opType);
    static bool OrderIsMarket(int opType);
    
    static datetime StripDateFromDatetime(datetime target);
    static datetime StripTimeFromDatetime(datetime target);
    static datetime OffsetDatetimeByZone(datetime value, int offsetHours);
    static datetime UnoffsetDatetimeByZone(datetime value, int offsetHours);
    static datetime AlignCandleDatetimeByOffset(datetime value, ENUM_TIMEFRAMES period, int alignOffsetHours=0);
    static datetime AlignCandleDatetimeByOffset(datetime value, int periodMinutes, int alignOffsetHours=0);
    
#ifdef __MQL5__
    static double GetSingleValueFromBuffer(int indiHandle, int shift=0, int bufferNum=0);
    static bool IsAccountHedging();
    static bool IsOrderRetcodeSuccess(int retcode, bool checkNoChange = true);
#endif
    
    static color InvertColor(color target);
    
    static ENUM_TIMEFRAMES GetTimeFrameFromMinutes(int minutes);
    static int GetMinutesFromTimeFrame(ENUM_TIMEFRAMES tf);
    static ENUM_TIMEFRAMES GetTimeFrameFromString(string tfStr);
    static string GetStringFromTimeFrame(ENUM_TIMEFRAMES tf);
};

// https://github.com/dingmaotu/mql4-lib
template<typename T>
void Common::ArrayDelete(T &array[],int index, int diff=1, bool resize=true) {
   int size=ArraySize(array);
   if(index<0 || index>=size) { return; }

   bool isSeries = ArrayGetAsSeries(array);
    
   if(isSeries) { ArraySetAsSeries(array, false); }

   if(index == size-diff) { SafeDelete(array[index]); }
   else {
      for(int i=index; i<size-diff; i++)
        {
         SafeDelete(array[i]); // in case this is a pointer
         array[i]=array[i+diff];
        }
   }
   
   if(resize) { ArrayResize(array,size-diff); }
   
   if(isSeries) { ArraySetAsSeries(array, true); }
}

template<typename T>
int Common::ArrayPush(T &array[], T unit, int maxSize = -1) {
    int size = ArraySize(array);
    if(!ArrayIsDynamic(array)) { return size; }
    int target = size; //int target = (isSeries ? 0 : size);
    bool isSeries = ArrayGetAsSeries(array);
    
    if(isSeries) { ArraySetAsSeries(array, false); }
        // When ArraySetAsSeries, ArrayResize does not shift elements rightward
        // as theory ought to be (new blank elements at index 0). Simplest workaround
        // is to temporarily set to non-series, resize and add, then set back to series.
        // Theory: https://www.forexfactory.com/showthread.php?p=2878455#post2878455
        // Workaround: https://www.forexfactory.com/showthread.php?p=4686709#post4686709

    int callResult = -1;
    if(maxSize > 0 && target >= maxSize) {
        int maxDiff = target-maxSize+1;
        ArrayDelete(array, 0, maxDiff, false);
        ArrayResize(array, maxSize);
        target = maxSize-1;
    } else {
        callResult = ArrayResize(array, size+1);
    }
    
    array[target] = unit;
    
    if(isSeries) { ArraySetAsSeries(array, true); }
    
    return size + 1;
}

template<typename T>
int Common::ArrayFind(T &array[], T needle) {
    int size = ArraySize(array);
    for(int i = 0; i < size; i++) {
        if(array[i] == needle) { return i; }
    }
    return -1;
}

template<typename T>
int Common::ArrayReserve(T &array[], int reserveSize) {
    int size = -1;
    
    size = ArraySize(array);
    ArrayResize(array, size, reserveSize);
    
    return size + reserveSize;
}

int Common::ArrayTsearch(string &array[], string value, int count=-1, int start=0, int direction=MODE_ASCEND, bool caseSensitive=true) {
    if(count < 0) { count = ArraySize(array)-start; }
    if(start >= ArraySize(array)) { return -1; }
    
    for(int i = start; i < start+count; i++) {
        if(StringCompare(array[i], value, caseSensitive) == 0) { return i; }
    }

    return -1;
}

template<typename T>
void Common::ResetArrayBySize(T &arr[], int size) {
    ResetArrayBySize(false, arr, size);
}

template<typename T>
void Common::ResetArrayBySize(T &arr[], int size, T defaultVal) {
    ResetArrayBySize(false, arr, size, defaultVal);
}

template<typename T>
void Common::ResetArrayBySize(bool force, T &arr[], int size) {
    if(force || ArraySize(arr) != size) {
        ArrayFree(arr);
        ArrayResize(arr, size);
    }
}

template<typename T>
void Common::ResetArrayBySize(bool force, T &arr[], int size, T defaultVal) {
    if(force || ArraySize(arr) != size) {
        ArrayFree(arr);
        ArrayResize(arr, size);
        ArrayInitialize(arr, defaultVal);
    }
}


string Common::StringTrim(string inputStr) {
#ifdef __MQL5__
    string workStr = inputStr;
    StringTrimRight(workStr);
    StringTrimLeft(workStr);
    
    return workStr;
#else
    return StringTrimLeft(StringTrimRight(inputStr));
#endif  
}

//template<typename T>
//bool Common::ConvertToBool(T in) {
//    if(typename(T) == "string") { return StrToBool(in); }
//    else { return (bool)in; }
//}

bool Common::StrToBool(string inputStr) {
    StringToLower(inputStr);
    string testStr = StringTrim(inputStr);
    
    if(StringCompare(testStr,"true") == 0 || StringCompare(testStr,"t") == 0) { return true; }
    else if(StringCompare(testStr,"false") == 0 || StringCompare(testStr,"f") == 0) { return false; }
    else return (bool)StringToInteger(testStr);
}

bool Common::IsAddrAbcValid (string addrAbc) {
    return AddrAbcToInt(addrAbc) >= 0; // todo: this overflows eventually with zzzzzzz etc, how to check?
}

int Common::AddrAbcToInt(string addrAbc, bool zeroBased=true) {
    // http://stackoverflow.com/questions/9905533/convert-excel-column-alphabet-e-g-aa-to-number-e-g-25
    if(GetStringType(addrAbc) == Type_Numeric) { return StringToInteger(addrAbc); }
    
    StringToLower(addrAbc);
    int addrAbcLength = StringLen(addrAbc);
    
    string letters = "abcdefghijklmnopqrstuvwxyz";
    int lettersLength = StringLen(letters);
    
    int sum = 0;
    int j = 0;
    for (int i = addrAbcLength-1; i >= 0; i--) {
        sum += MathPow(lettersLength, j) * (StringFind(letters, StringSubstr(addrAbc, i, 1))+1);
        j++;
    }
    return sum - (int)zeroBased; //make 0-based, not 1-based
}

string Common::AddrIntToAbc(int addrInt, bool zeroBased=true) {
    // http://stackoverflow.com/questions/181596/how-to-convert-a-column-number-eg-127-into-an-excel-column-eg-aa

    int dividend = addrInt + (int)zeroBased; // make 0 based, not 1 based
    string columnName ="";
    int modulo = 0;

    while (dividend > 0)
    {
        modulo = (dividend - 1) % 26;
        columnName = CharToString((uchar)(97 + modulo)) + columnName;
        dividend = (int)((dividend - modulo) / 26);
    } 

    return columnName;
}

string Common::ConcatStringFromArray(string& strArray[], string delimiter = ";") {
    int strCount = ArraySize(strArray);
    
    string finalString = "";
    for(int i = 0; i < strCount; i++) {
        finalString = StringConcatenate(finalString, strArray[i], delimiter);
    }
    
    return finalString;
}

StringType Common::GetStringType(string test) {
    test = StringTrim(test);
    int len = StringLen(test);
    if(len <= 0) { return Type_Empty; }
    
    bool uppercase = false; bool lowercase = false; bool numeric = false;
    ushort code = 0;
    
    for(int i= 0; i < len; i++) {
        code = StringGetCharacter(test, i);
        if(code >= 65 && code <= 90) { uppercase = true; }
        else if(code >= 97 && code <= 122) { lowercase = true; }
        else if(code >= 48 && code <= 57) { numeric = true; }
    }

    if((uppercase||lowercase)&&numeric){ return Type_Alphanumeric; }
    else if(uppercase||lowercase) { return Type_Alpha; }
    else if(numeric) { return Type_Numeric; }
    else return Type_Symbol;
}

// http://cs.stackexchange.com/questions/1447/what-is-most-efficient-for-gcd
int Common::GetGcd(int a, int b)
{
    while(b) b ^= a ^= b ^= a %= b;
    return a;
}

// https://github.com/femtotrader/rabbit4mt4/blob/master/emit/MQL4/Include/uuid.mqh
//http://en.wikipedia.org/wiki/Universally_unique_identifier
//RFC 4122
//  A Universally Unique IDentifier (UUID) URN Namespace
//  http://tools.ietf.org/html/rfc4122.html

//+------------------------------------------------------------------+
//|UUID Version 4 (random)                                           |
//|Version 4 UUIDs use a scheme relying only on random numbers.      |
//|This algorithm sets the version number (4 bits) as well as two    |
//|reserved bits. All other bits (the remaining 122 bits) are set    |
//|using a random or pseudorandom data source. Version 4 UUIDs have  |
//|the form xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx                     |
//|where x is any hexadecimal digit and y is one of 8, 9, A, or B    |
//|(e.g., f47ac10b-58cc-4372-a567-0e02b2c3d479).                                                               |
//+------------------------------------------------------------------+
string Common::GetUuid()
  {
   string alphabet_x="0123456789abcdef";
   string alphabet_y="89ab";
   string id="xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"; // 36 char = (8-4-4-4-12)
   ushort character = 0;
   for(int i=0; i<36; i++)
     {
      if(i==8 || i==13 || i==18 || i==23)
        {
         character='-';
        }
      else if(i==14)
        {
         character='4';
        }
      else if(i==19)
        {
         character = (ushort) MathRand() % 4;
         character = StringGetCharacter(alphabet_y, character);
        }
      else
        {
         character = (ushort) MathRand() % 16;
         character = StringGetCharacter(alphabet_x, character);
        }
      StringSetCharacter(id,i,character);
     }
   return id;
  }
//+------------------------------------------------------------------+

bool Common::IsDatetimeInRange(datetime subject, int startDayOfWeek, int startHour, int endDayOfWeek, int endHour) {
    int fixedEndDayOfWeek = endDayOfWeek;
    int currentDayOfWeek = TimeDayOfWeek(subject);
    int currentHour = TimeHour(subject);
    if(endDayOfWeek < startDayOfWeek) { fixedEndDayOfWeek += 7; }
    
    return currentDayOfWeek == startDayOfWeek ? currentHour >= startHour
        : currentDayOfWeek == endDayOfWeek ? currentHour < endHour
        : currentDayOfWeek > startDayOfWeek && currentDayOfWeek < fixedEndDayOfWeek
        ;
}

template<typename T>
int Common::GetTimeDuration(T cur, T prev) {
    // todo: long and ulong handling?
    if(typename(T) == "int" || typename(T) == "datetime") {
        return (cur >= prev) || cur >=0 && prev >= 0 ? cur-prev : INT_MAX-prev+cur+1;
    } else if(typename(T) == "uint") {
        return (cur >= prev) ? cur-prev : UINT_MAX-prev+cur+1;
    } else {
        return -1;
    }
}

string Common::GetSqlDatetime(datetime source, bool appendTimeOffset=false, string timeOffset=""/*, bool calcBrokerOffset=false*/) {
    // todo: microseconds?
    
    string result = TimeToString(source, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    
    // Format: yyyy/mm/dd hh:mm:ss[-+]xx:xx (timezone)
    // replace first .'s with //
    StringReplace(result, ".", "-");
    
    double timeOffsetNum=0;
    if(appendTimeOffset) {
        /*if(calcBrokerOffset) {
            // attempt autocalc first, if fail, then fallback on supplied time offset
            // which may be empty. if it's empty, nothing is added to string -- timestamp passed
            // without offset
            
            // E.g. if difference between TimeCurrent and TimeLocal is less than one minute, then drop the seconds and do TimeCurrent-TimeGMT to calc offset
        } else */
        if(StringLen(timeOffset) <= 0) {
            timeOffsetNum = (TimeLocal()-TimeGMT())/3600;
            
            result += StringFormat("%+03.f:%02.f"
                , MathFloor(timeOffsetNum)
                , MathAbs((timeOffsetNum-MathFloor(timeOffsetNum))*60)
                );
        }
        else { result += timeOffset; }
        
    }
    
    return result;
}

bool Common::EventSetTimerReliable(int seconds) {
    int delayMilliseconds = 255;
    int delayRetries = 5;
    
    for(int attempts = 0; attempts < delayRetries; attempts++) {
        if(!EventSetTimer(seconds)) {
            Sleep(delayMilliseconds);
            continue;
        } else { return true; }
    }
    
    return false;
}

bool Common::EventSetMillisecondTimerReliable(int milliseconds) {
    int delayMilliseconds = 255;
    int delayRetries = 5;
    
    for(int attempts = 0; attempts < delayRetries; attempts++) {
        if(!EventSetMillisecondTimer(milliseconds)) {
            Sleep(delayMilliseconds);
            continue;
        } else { return true; }
    }
    
    return false;
}

string Common::GetRandomFileName(string prefix = "Log_", string ext = ".txt") {
    return prefix + (int)TimeLocal() + "_" + (int)GetMicrosecondCount() + ext;
}

template<typename T>
void Common::SafeDeletePointerArray(T &array[]) {
    int size = ArraySize(array);
    
    for(int i = 0; i < size; i++) {
        Common::SafeDelete(array[i]);
    }
}

//+------------------------------------------------------------------+
// https://github.com/dingmaotu/mql4-lib
//+------------------------------------------------------------------+
//| Generic safe pointer delete                                      |
//+------------------------------------------------------------------+
template<typename T>
void Common::SafeDelete(T *pointer)
  {
   if(CheckPointer(pointer)==POINTER_DYNAMIC)
     {
      delete pointer;
     }
  }
//+------------------------------------------------------------------+
//| If pointer is actually a value type                              |
//+------------------------------------------------------------------+
template<typename T>
void Common::SafeDelete(T pointer) {}
//+------------------------------------------------------------------+
//| Check if the value is a pointer type                             |
//+------------------------------------------------------------------+
template<typename T>
bool Common::IsPointer(const T &value)
  {
   string tn=typename(value);
// Note that a typename is at least of length > 0
   return StringGetCharacter(tn, StringLen(tn) - 1) == '*';
  }
//+------------------------------------------------------------------+
//| Generic pointer check                                            |
//+------------------------------------------------------------------+
template<typename T>
bool Common::IsInvalidPointer(T *pointer)
  {
   return CheckPointer(pointer)==POINTER_INVALID;
  }
//+------------------------------------------------------------------+

double Common::PriceToPips(double price, string symbol) {
    int digits = MarketInfo(symbol, MODE_DIGITS);
    
    return NormalizeDouble(digits % 2 <= 0 ? price*MathPow(10, digits) : price*MathPow(10, digits-1), digits % 2);
        // if digits is even (4, 2, ...), do digits as is. If digits is odd (3, 5, ...), assume one decimal place.
        // digits % 2 = 0 means even, 1 means odd
        // TODO: How about 6 digit brokers? And do they quote JPY in 4 digits, too?
}

#ifdef __MQL5__
double Common::GetSingleValueFromBuffer(int indiHandle, int shift=0, int bufferNum=0) {
    if(indiHandle == INVALID_HANDLE) { return -1; }
    if(shift < 0) { shift = 0; }
    if(bufferNum < 0) { bufferNum = 0; }
    
    double buffer[1];
    int result = CopyBuffer(indiHandle, bufferNum, shift, 1, buffer);
    
    if(result < 1) { return 0; }
    else { return buffer[0]; }
}
#endif

bool Common::OrderIsLong(int opType) {
    switch(opType) {
#ifdef __MQL4__
        case OP_BUY:
        case OP_BUYLIMIT:
        case OP_BUYSTOP:
#else
#ifdef __MQL5__
        case ORDER_TYPE_BUY:
        case ORDER_TYPE_BUY_LIMIT:
        case ORDER_TYPE_BUY_STOP:
        case ORDER_TYPE_BUY_STOP_LIMIT:
#endif
#endif
            return true;
        default:
            return false;
    }
}

bool Common::OrderIsShort(int opType) {
    switch(opType) {
#ifdef __MQL4__
        case OP_SELL:
        case OP_SELLLIMIT:
        case OP_SELLSTOP:
#else
#ifdef __MQL5__
        case ORDER_TYPE_SELL:
        case ORDER_TYPE_SELL_LIMIT:
        case ORDER_TYPE_SELL_STOP:
        case ORDER_TYPE_SELL_STOP_LIMIT:
#endif
#endif
            return true;
        default:
            return false;
    }
}

bool Common::OrderIsPending(int opType) {
    switch(opType) {
#ifdef __MQL4__
        case OP_BUYLIMIT:
        case OP_BUYSTOP:
        case OP_SELLLIMIT:
        case OP_SELLSTOP:
#else
#ifdef __MQL5__
        case ORDER_TYPE_BUY_LIMIT:
        case ORDER_TYPE_BUY_STOP:
        case ORDER_TYPE_BUY_STOP_LIMIT:
        case ORDER_TYPE_SELL_LIMIT:
        case ORDER_TYPE_SELL_STOP:
        case ORDER_TYPE_SELL_STOP_LIMIT:
#endif
#endif
            return true;
        default:
            return false;
    }
}

bool Common::OrderIsMarket(int opType) {
    switch(opType) {
#ifdef __MQL4__
        case OP_BUY:
        case OP_SELL:
#else
#ifdef __MQL5__
        case ORDER_TYPE_BUY:
        case ORDER_TYPE_SELL:
#endif
#endif
            return true;
        default:
            return false;
    }
}

datetime Common::StripDateFromDatetime(datetime target) {
    if(target >= 86400) {
        return target - (86400*MathFloor(target/86400));
    } else { return target; }
}

datetime Common::StripTimeFromDatetime(datetime target) {
    if(target < 86400) {
        // return today's date?
        return 0; // jan 1 1970
    } else {
        return 86400*MathFloor(target/86400);
    }
}

datetime Common::OffsetDatetimeByZone(datetime value, int offsetHours) {
    // todo: what if broker time is changed due to DST?
    int offset = -1*offsetHours * 60 * 60;
    return value += offset;
}

datetime Common::UnoffsetDatetimeByZone(datetime value, int offsetHours) {
    // todo: what if broker time is changed due to DST?
    int offset = offsetHours * 60 * 60;
    return value += offset;
}

datetime Common::AlignCandleDatetimeByOffset(datetime value, ENUM_TIMEFRAMES period, int alignOffsetHours=0) {
    return AlignCandleDatetimeByOffset(value, Common::GetMinutesFromTimeFrame(period), alignOffsetHours);
}

datetime Common::AlignCandleDatetimeByOffset(datetime value, int periodMinutes, int alignOffsetHours=0) {
    int adjustSeconds = MathMod(value, periodMinutes*60);
    int offsetSeconds = alignOffsetHours*60;
    datetime dtOffsetted = value-adjustSeconds+offsetSeconds;
    return dtOffsetted;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

#ifdef __MQL5__
bool Common::IsAccountHedging() {
    return AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
}

bool Common::IsOrderRetcodeSuccess(int retcode, bool checkNoChange = true) {
    return (
        (retcode >= TRADE_RETCODE_PLACED && retcode <= TRADE_RETCODE_DONE_PARTIAL) 
        || (!checkNoChange || retcode == TRADE_RETCODE_NO_CHANGES)
    );
}
#endif

color Common::InvertColor(color target) {
    return 0x00FFFFFF ^ target;
}

ENUM_TIMEFRAMES Common::GetTimeFrameFromMinutes(int minutes) {
    switch(minutes)
     {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
 #ifdef __MQL5__     
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: case 120: return(PERIOD_H2);
      case 16387: case 180: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: case 360: return(PERIOD_H6);
      case 16392: case 480: return(PERIOD_H8);
      case 16396: case 720: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1); 
 #endif     
      default: return(PERIOD_CURRENT);
     }
}

int Common::GetMinutesFromTimeFrame(ENUM_TIMEFRAMES tf) {
    switch(tf) {
        case PERIOD_M1: return 1;
        case PERIOD_M5: return 5;
        case PERIOD_M15: return 15;
        case PERIOD_M30: return 30;
        case PERIOD_H1: return 60;
        case PERIOD_H4: return 240;
        case PERIOD_D1: return 1440;
        case PERIOD_W1: return 10080;
        case PERIOD_MN1: return 43200;
#ifdef __MQL5__     
        case PERIOD_M2: return 2;
        case PERIOD_M3: return 3;
        case PERIOD_M4: return 4;
        case PERIOD_M6: return 6;
        case PERIOD_M10: return 10;
        case PERIOD_M12: return 12;
        case PERIOD_H2: return 120;
        case PERIOD_H3: return 180;
        case PERIOD_H6: return 360;
        case PERIOD_H8: return 480;
        case PERIOD_H12: return 720; 
        case PERIOD_CURRENT: return GetMinutesFromTimeFrame(_Period);
#endif
        default: return 0;
    }
}

string Common::GetStringFromTimeFrame(ENUM_TIMEFRAMES tf) {
    switch(tf)
    {
        case PERIOD_M1: return "M1";
        case PERIOD_M5: return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1: return "H1";
        case PERIOD_H4: return "H4";
        case PERIOD_D1: return "D1";
        case PERIOD_W1: return "W1";
        case PERIOD_MN1: return "MN1";
#ifdef __MQL5__     
        case PERIOD_M2: return "M2";
        case PERIOD_M3: return "M3";
        case PERIOD_M4: return "M4";
        case PERIOD_M6: return "M6";
        case PERIOD_M10: return "M10";
        case PERIOD_M12: return "M12";
        case PERIOD_H2: return "H2";
        case PERIOD_H3: return "H3";
        case PERIOD_H6: return "H6";
        case PERIOD_H8: return "H8";
        case PERIOD_H12: return "H12"; 
        case PERIOD_CURRENT: return GetStringFromTimeFrame(_Period);
#endif
        default: {
            string tfStr = EnumToString(tf);
            StringReplace(tfStr, "PERIOD_", "");
            return tfStr;
        }
    }
}

ENUM_TIMEFRAMES Common::GetTimeFrameFromString(string tfStr) {
    StringToUpper(tfStr);
    StringReplace(tfStr, "PERIOD_", "");
    if(tfStr == "M1") { return PERIOD_M1; }
    else if(tfStr == "M5") { return PERIOD_M5; }
    else if(tfStr == "M15") { return PERIOD_M15; }
    else if(tfStr == "M30") { return PERIOD_M30; }
    else if(tfStr == "H1") { return PERIOD_H1; }
    else if(tfStr == "H4") { return PERIOD_H4; }
    else if(tfStr == "D1") { return PERIOD_D1; }
    else if(tfStr == "W1") { return PERIOD_W1; }
    else if(tfStr == "MN1") { return PERIOD_MN1; }
#ifdef __MQL5__
    else if(tfStr == "M2") { return PERIOD_M2; }
    else if(tfStr == "M3") { return PERIOD_M3; }
    else if(tfStr == "M4") { return PERIOD_M4; }
    else if(tfStr == "M6") { return PERIOD_M6; }
    else if(tfStr == "M10") { return PERIOD_M10; }
    else if(tfStr == "M12") { return PERIOD_M12; }
    else if(tfStr == "H2") { return PERIOD_H2; }
    else if(tfStr == "H3") { return PERIOD_H3; }
    else if(tfStr == "H6") { return PERIOD_H6; }
    else if(tfStr == "H8") { return PERIOD_H8; }
    else if(tfStr == "H12") { return PERIOD_H12; }
#endif
    else { return PERIOD_CURRENT; }
}
