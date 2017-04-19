//+------------------------------------------------------------------+
//|                                                 T_Validation.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#include "depends/mql4-http.mqh"
#include "depends/mql4-systemdatetime.mqh"

//#define _ApiLocal

//+------------------------------------------------------------------+

// api subkey: current version + string, see mc-rest-validate
int ApiVersion = 1;
#ifdef _ApiLocal
string ApiBasePath = "http://localhost:8080/";
#else
string ApiBasePath = "https://mc-validation.appspot.com/";
#endif
string ApiSubkeyRequest = "815476971d3fb14be87f39336c2cef9ef7c923ccf22c790bb5470fa923223409";
string ApiSubkeyResult = "d6636dcbccc186882aef68f6594ff78b8fd809a69632d4f3b846cdccce5c8ab4";
int ApiTimeout = 5;
// api key: unix time, most recent minute, + "|" + apiSubkey

int GetApiDatetime() {
    return TimeSystemGMT()-MathMod(TimeSystemGMT(), 60);
}

string MakeApiKey(int apiDatetime, bool isRequest) {
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

bool ValidateKey(string testKey, bool isRequest) {
    int apiDatetimeBase = GetApiDatetime();
    for(int i = ApiTimeout * -1; i < ApiTimeout+1; i++) {
        int apiDatetime = apiDatetimeBase+(i*60);
        string apiKey = MakeApiKey(apiDatetime, isRequest);
        if(apiKey == testKey) { return true; }
    }

    return false;
}

//+------------------------------------------------------------------+

int GetServerDatetime() {
    string result = NULL;
    if(httpGet(ApiBasePath + "date", "mc-validate-key: " + MakeApiKey(GetApiDatetime(), true) + "\r\nmc-api-version: " + ApiVersion, result) 
        && Common::GetStringType(result) == Type_Numeric
    ) {
        return StringToInteger(result);
    } else {
        Error::PrintNormal("GetServerDatetime error: " + result);
        return -1;
    }
}

//+------------------------------------------------------------------+

int ValidateRetryLimit = 3;
int ValidateRetryLimitDelay = 60;
datetime ValidateRetryDelayDatetime = 0;
int ValidateRetryCounter = 0;
datetime LastValidateCurrentDate = 0;
datetime LastValidateSystemDate = 0;
bool SessionValidated = false;

#ifdef _NoExpiration
bool ValidateSession(bool firstRun = false) { return true; }
#else
bool ValidateSession(bool firstRun = false) {
    return ValidateExpirationDate(firstRun);
}

bool ValidateExpirationDate(bool firstRun = false) {
    if(!firstRun && SessionValidated && (IsTesting() || IsOptimization())) { return SessionValidated; }
    
    if(ValidateRetryCounter == ValidateRetryLimit-1) { // throttling
        if(TimeLocal() - ValidateRetryDelayDatetime < 60) { return SessionValidated; }
        else { 
            ValidateRetryDelayDatetime = 0;
            ValidateRetryCounter = 0;
        }
    }

    if(Common::StripTimeFromDatetime(TimeCurrent()) <= LastValidateCurrentDate && Common::StripTimeFromDatetime(TimeSystemGMT()) <= LastValidateSystemDate) {
        return SessionValidated;
    }
    
    if(true || !IsTesting() && !IsOptimization()) {
        if(TimeCurrent() >= ProjectExpiration) { 
            Error::ThrowFatal("EA expired on " + ProjectExpiration + " and broker time is " + TimeCurrent());
            LastValidateCurrentDate = 0;
            LastValidateSystemDate = 0;
            SessionValidated = false;
            return false; 
        } else { // if(TimeCurrent() >= TimeSystemGMT()-(3*86400) && TimeCurrent() <= TimeSystemGMT()+(3*86400)) {
            // Controlling for requote delay (weekends) would be nice, but because of said delay,
            // it's not easy to figure broker timezone offset.
            // Just set expiration date on Mondays.
            
            // As long as it's not testing, broker time may be good enough
            // This doesn't preclude an unscrupulous entity from ghosting their own server and feeding a fake time
            // But chances of that happening are slim.
            ValidateRetryCounter = 0;
            LastValidateCurrentDate = Common::StripTimeFromDatetime(TimeCurrent());
            LastValidateSystemDate = Common::StripTimeFromDatetime(TimeSystemGMT());
            SessionValidated = true;
            return true;
        }
    }
    
    if(TimeSystemGMT() >= ProjectExpiration) { 
        // System time is not trustworthy because it can be faked
        // Just use as a quick falsifier.
        Error::ThrowFatal("EA expired on " + ProjectExpiration + " and system time is " + TimeSystemGMT());
        LastValidateCurrentDate = 0;
        LastValidateSystemDate = 0;
        SessionValidated = false;
        return false; 
    }
    
    if(!IsConnected()) { // if this is false, checking server time will likely fail too
        if(firstRun) {
            Error::ThrowFatal("Cannot validate expiration date due to connection error: " + ProjectExpiration);
            LastValidateCurrentDate = 0;
            LastValidateSystemDate = 0;
            SessionValidated = false;
            return false;
        } else {
            Error::PrintNormal("Cannot validate expiration date due to connection error: " + ProjectExpiration);
            if(ValidateRetryCounter++ == ValidateRetryLimit-1) { 
                Error::PrintNormal("Trying again in " + ValidateRetryLimitDelay + " seconds"); 
                ValidateRetryDelayDatetime = TimeLocal();
            }
            LastValidateCurrentDate = 0;
            LastValidateSystemDate = 0;
            SessionValidated = false;
            return false;
        }
    }
    
    int serverTime = GetServerDatetime();
    if(serverTime <= 0) {
        if(firstRun) {
            Error::ThrowFatal("Cannot validate expiration date due to connection error: " + ProjectExpiration);
            LastValidateCurrentDate = 0;
            LastValidateSystemDate = 0;
            SessionValidated = false;
            return false;
        } else {
            Error::PrintNormal("Cannot validate expiration date due to connection error: " + ProjectExpiration);
            if(ValidateRetryCounter++ == ValidateRetryLimit-1) { 
                Error::PrintNormal("Trying again in " + ValidateRetryLimitDelay + " seconds"); 
                ValidateRetryDelayDatetime = TimeLocal();
            }
            LastValidateCurrentDate = 0;
            LastValidateSystemDate = 0;
            SessionValidated = false;
            return false;
        }
    } else if(serverTime >= ProjectExpiration) { 
        Error::ThrowFatal("EA has expired on " + ProjectExpiration + " and internet time is " + ((datetime)serverTime));
        LastValidateCurrentDate = 0;
        LastValidateSystemDate = 0;
        SessionValidated = false;
        return false; 
    } 
    
    ValidateRetryCounter = 0;
    LastValidateCurrentDate = Common::StripTimeFromDatetime(TimeCurrent());
    LastValidateSystemDate = Common::StripTimeFromDatetime(TimeSystemGMT());
    SessionValidated = true;
    return true;
}
#endif