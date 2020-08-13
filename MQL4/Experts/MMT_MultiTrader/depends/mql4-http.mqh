//+----------------------------------------------------------------------------+
//|                                                              mql4-http.mqh |
//+----------------------------------------------------------------------------+
//|                                                      Built by Sergey Lukin |
//|                                                    contact@sergeylukin.com |
//|                                                                            |
//| This libarry is highly based on following:                                 |
//|                                                                            |
//| - HTTP Wininet sample: http://codebase.mql4.com/8115                       |
//| - EasyXML parser: http://www.mql5.com/code/1998                            |
//|                                                                            |
//+----------------------------------------------------------------------------+

//#define _Mql4HttpShell32

#ifdef _Mql4HttpShell32
#import "shell32.dll"
int ShellExecuteW(
    int hwnd,
    string Operation,
    string File,
    string Parameters,
    string Directory,
    int ShowCmd
);
#import
#endif

#import "wininet.dll"
int InternetOpenW(
    string     sAgent,
    int        lAccessType,
    string     sProxyName="",
    string     sProxyBypass="",
    int     lFlags=0
);
int InternetOpenUrlW(
    int     hInternetSession,
    string     sUrl, 
    string     sHeaders="",
    int     lHeadersLength=0,
    uint     lFlags=0,
    int     lContext=0 
);
int InternetReadFile(
    int     hFile,
    uchar  &   sBuffer[],
    int     lNumBytesToRead,
    int&     lNumberOfBytesRead
);
int HttpQueryInfoW(
  int hRequest,
  int dwInfoLevel,
  uchar &lpvBuffer[],
  int &lpdwBufferLength,
  int &lpdwIndex
);
int HttpQueryInfoW(
  int hRequest,
  int dwInfoLevel,
  int &lpvBuffer,
  int &lpdwBufferLength,
  int &lpdwIndex
);
int InternetCloseHandle(
    int     hInet
);       
#import

#define INTERNET_FLAG_RELOAD            0x80000000
#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000
#define INTERNET_FLAG_PRAGMA_NOCACHE    0x00000100

#define HTTP_QUERY_FLAG_NUMBER          0x20000000
#define HTTP_QUERY_STATUS_CODE          19

int hSession_IEType;
int hSession_Direct;
int Internet_Open_Type_Preconfig = 0; // system proxy
int Internet_Open_Type_Direct = 1; // no proxy

int hSession(bool Direct = false) // proxy switch - false = use system settings
{
    string InternetAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";
    
    if (Direct) 
    { 
        if (hSession_Direct == 0)
        {
            hSession_Direct = InternetOpenW(InternetAgent, Internet_Open_Type_Direct, "0", "0", 0);
        }
        
        return(hSession_Direct); 
    }
    else 
    {
        if (hSession_IEType == 0)
        {
           hSession_IEType = InternetOpenW(InternetAgent, Internet_Open_Type_Preconfig, "0", "0", 0);
        }
        
        return(hSession_IEType); 
    }
}

string httpGet(string strUrl, string strHeaders = NULL)
{
    string toStr = NULL;
    httpGet(strUrl, strHeaders, toStr);
    return toStr;
}

bool httpGet(string strUrl, string strHeaders, string &resultOut) {
    int handler = hSession(false);
    int response = InternetOpenUrlW(handler, strUrl, strHeaders, 0,
        INTERNET_FLAG_NO_CACHE_WRITE |
        INTERNET_FLAG_PRAGMA_NOCACHE |
        INTERNET_FLAG_RELOAD, 0);
    if(response == 0) { return false; }
    
    int statusCode = httpGetStatusCodeFromHandle(response);
    
    uchar ch[100]; string toStr=""; int dwBytes, h=-1;
    while(InternetReadFile(response, ch, 100, dwBytes)) {
        if(dwBytes<=0) { break; } 
        resultOut += CharArrayToString(ch, 0, dwBytes);
    }
    
    InternetCloseHandle(response);
    
    return isHttpOk(statusCode);
}

int httpGetStatusCodeFromHandle(int hRequest) {
    // https://msdn.microsoft.com/en-us/library/windows/desktop/aa384238(v=vs.85).aspx
    // http://stackoverflow.com/questions/6777236/wininet-httpquery-info-returning-invalid-status-codes
    
    int statusCode = 0, index = 0;
    int length = sizeof(int); // int size
    HttpQueryInfoW(
        hRequest,
        HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER,
        statusCode,
        length,
        index
    );
    
    return statusCode;
}

bool isHttpOk(int statusCode) {
    int cat = MathFloor(MathMod(MathAbs(statusCode)/100, 10));
    return cat == 2; // 1 = info, 3 = redirect
}

#ifdef _Mql4HttpShell32
void httpOpen(string strUrl)
{
  Shell32::ShellExecuteW(0, "open", strUrl, "", "", 3);
}
#endif
