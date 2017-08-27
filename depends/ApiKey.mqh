//+------------------------------------------------------------------+
//|                                                       ApiKey.mqh |
//|                                                          mazmazz |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "mazmazz"
#property link      "https://github.com/mazmazz"
#property strict

#include "mql4-systemdatetime.mqh"
//+------------------------------------------------------------------+
// api subkey: current version + string, see mc-rest-validate
string ApiSubkeyRequest = "815476971d3fb14be87f39336c2cef9ef7c923ccf22c790bb5470fa923223409";
string ApiSubkeyResult = "d6636dcbccc186882aef68f6594ff78b8fd809a69632d4f3b846cdccce5c8ab4";
int ApiTimeout = 5;
// api key: unix time, most recent minute, + "|" + apiSubkey

datetime GetApiDatetime() {
    return TimeSystemGMT()-MathMod(TimeSystemGMT(), 60);
}

string MakeApiKey(datetime apiDatetime, bool isRequest) {
    uchar apiKeyBase[], apiKeyResult[], apiKeyKey[];
    
    // python hashlib takes a utf-8 string not null-terminated
    // also make sure apiDatetime is stringed as an int, not a double/float
    StringToCharArray(IntegerToString(apiDatetime) + "|" + (isRequest ? ApiSubkeyRequest : ApiSubkeyResult), apiKeyBase, 0, WHOLE_ARRAY, CP_UTF8);
    ArrayResize(apiKeyBase, ArraySize(apiKeyBase)-1); // drop null byte
    
    CryptEncode(CRYPT_HASH_SHA256, apiKeyBase, apiKeyKey, apiKeyResult);
    
    string apiKey = NULL;
    int apiKeyHashSize = ArraySize(apiKeyResult);
    for(int i = 0; i < apiKeyHashSize; i++) {
        apiKey += StringFormat("%.2x", apiKeyResult[i]); // lowercase
    }
    
    return apiKey;
}

bool ValidateApiKey(string testKey, bool isRequest) {
    int apiDatetimeBase = GetApiDatetime();
    for(int i = ApiTimeout * -1; i < ApiTimeout+1; i++) {
        int apiDatetime = apiDatetimeBase+(i*60);
        string apiKey = MakeApiKey(apiDatetime, isRequest);
        if(apiKey == testKey) { return true; }
    }

    return false;
}