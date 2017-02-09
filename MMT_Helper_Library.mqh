//+------------------------------------------------------------------+
//|                                           MMT_Helper_Library.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

int ArrayPushString(string &array[], string unit) {
    int size = ArraySize(array); // assuming 1-based
    ArrayResize(array, size+1);
    array[size] = unit;
    
    return size+1;
}

string StringTrim(string inputStr) {
    return StringTrimLeft(StringTrimRight(inputStr));
}

bool StrToBool(string inputStr) {
    StringToLower(inputStr);
    string testStr = StringTrim(inputStr);
    
    if(StringCompare(testStr,"true") == 0) { return true; }
    else if(StringCompare(testStr,"false") == 0) { return false; }
    else return (bool)StrToInteger(testStr);
}

bool IsAddrAbcValid (string addrAbc) {
    return AddrAbcToInt(addrAbc) >= 0; // todo: this overflows eventually with zzzzzzz etc, how to check?
}

int AddrAbcToInt(string addrAbc, bool zeroBased=true) {
    // http://stackoverflow.com/questions/9905533/convert-excel-column-alphabet-e-g-aa-to-number-e-g-25
    
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

string AddrIntToAbc(int addrInt, bool zeroBased=true) {
    // http://stackoverflow.com/questions/181596/how-to-convert-a-column-number-eg-127-into-an-excel-column-eg-aa

    int dividend = addrInt + (int)zeroBased; // make 0 based, not 1 based
    string columnName ="";
    int modulo;

    while (dividend > 0)
    {
        modulo = (dividend - 1) % 26;
        columnName = CharToString((uchar)(97 + modulo)) + columnName;
        dividend = (int)((dividend - modulo) / 26);
    } 

    return columnName;
}

string ConcatStringFromArray(string& strArray[], string delimiter = ";") {
    int strCount = ArraySize(strArray);
    
    string finalString = "";
    for(int i = 0; i < strCount; i++) {
        finalString = StringConcatenate(finalString, strArray[i], delimiter);
    }
    
    return finalString;
}

enum StringType {
    Type_Alphanumeric,
    Type_Uppercase,
    Type_Lowercase,
    Type_Alpha,
    Type_Numeric,
    Type_Symbol
};

StringType GetStringType(string test) {
    int len = StringLen(test);
    bool uppercase; bool lowercase; bool numeric;
    ushort code;
    
    for(int i= 0; i < len; i++) {
        code = StringGetChar(test, i);
        if(code >= 65 && code <= 90) { uppercase = true; }
        else if(code >= 97 && code <= 122) { lowercase = true; }
        else if(code >= 48 && code <= 57) { numeric = true; }
    }

    if((uppercase||lowercase)&&numeric){ return Type_Alphanumeric; }
    else if(uppercase||lowercase) { return Type_Alpha; }
    else if(numeric) { return Type_Numeric; }
    else return Type_Symbol;
}