//+------------------------------------------------------------------+
//|                                                 T_Validation.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#include "depends/internetlib.mqh"
#include "depends/mql4-systemdatetime.mqh"

#include "MC_Common/MC_Common.mqh"

//#define _ApiLocal
#ifdef _ApiLocal
string ApiBasePath = "localhost";
int ApiBasePort = 8080;
#else
string ApiBasePath = "mc-validation.appspot.com";
int ApiBasePort = 80;
#endif

//+------------------------------------------------------------------+

int GetServerDatetime() {
    string result = NULL;
    
    MqlNet net;
    tagRequest request;
    
    request.stVerb = "GET";
    request.stObject = "/date";
    //request.stHead = "Content-Type: application/x-www-form-urlencoded";
    request.stData = NULL;
    
    request.fromFile = false;
    request.toFile = false;
    Common::ArrayPush(request.stHeaderNamesIn, "Mmc-Api-Version");
    Common::ArrayPush(request.stHeaderDataIn, "1");
    Common::ArrayPush(request.stHeaderNamesOut, "Mmc-Api-Success");
    Common::ArrayPush(request.stHeaderDataOut, "");

#ifndef _ApiDev
    Common::ArrayPush(request.stHeaderNamesIn, "Mmc-Api-Request-Key");
    Common::ArrayPush(request.stHeaderDataIn, MakeApiKey(GetApiDatetime(), true));
    Common::ArrayPush(request.stHeaderNamesOut, "Mmc-Api-Response-Key");
    Common::ArrayPush(request.stHeaderDataOut, "");
#endif
    
    if(net.Open(ApiBasePath, ApiBasePort, NULL, NULL, INTERNET_SERVICE_HTTP)) {
        net.Request(request);
        if(request.stHeaderDataOut[0] != "true") { return -1; }
#ifndef _ApiDev
        if(request.stHeaderDataOut[1] == NULL || !ValidateApiKey(request.stHeaderDataOut[1], false)) { return false; }
#endif
    }
    
    if(Common::GetStringType(request.stOut) == Type_Numeric) {
        return StringToInteger(request.stOut);
    } else {
        Error::PrintNormal("GetServerDatetime error");
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

bool ValidateSession(bool firstRun = false) {
    bool validated = false;
    
#ifndef _NoExpiration
    validated = ValidateExpirationDate(firstRun);
#else
#ifdef _NoExpiration
    validated = true;
#endif
#endif

    if(!validated) { return false; }

#ifndef _NoLiveRestriction
    validated = (((ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE)) != ACCOUNT_TRADE_MODE_REAL);
    if(!validated) {
        Error::ThrowFatal("Live trading is currently not enabled.");
        return false;
    }
#else
#ifdef _NoLiveRestriction
    validated = true;
#endif
#endif

    return validated;
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
    
    if(!IsTesting() && !IsOptimization()) {
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
