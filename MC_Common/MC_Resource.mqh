//+------------------------------------------------------------------+
//|                                                  MAR_Scripts.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include "MC_Common.mqh"

enum ResourceType {
    ResText,
    ResByte
};

class ResourceFile {
    public:
    ResourceFile(string fileName, ResourceType fileType);
    string name;
    ResourceType type;
    string data[];
};

class ResourceStore {
    private:
    string fileNames[];
    ResourceFile *files[];
    
    public:
    ~ResourceStore();
    bool loadTextResource(string fileName);
    bool loadTextResource(string fileName, const string &dataIn[]);
    bool getTextResource(string fileName, string &dataOut[]);
    
    // bool loadByteResource(string fileName);
    // bool loadByteResource(string fileName, short &dataIn[]);
    // bool getByteResource(string fileName, short &dataOut[]);
};

void ResourceFile::ResourceFile(string fileName, ResourceType fileType) {
    name = fileName;
    type = fileType;
}

void ResourceStore::~ResourceStore() {
    int filesCount = ArraySize(files);
    
    for(int i = 0; i < filesCount; i++) {
        if(CheckPointer(files[i]) == POINTER_DYNAMIC) { delete(files[i]); }
    }
}

bool ResourceStore::loadTextResource(string fileName) {
    int loc = Common::ArrayTsearch(fileNames, fileName);
    
    if(loc < 0) {
        loc = -1 + Common::ArrayPush(fileNames, fileName);
        Common::ArrayPush(files, new ResourceFile(fileName, ResText));
    }
    
    ArrayFree(files[loc].data);
    
    int fileHandle = FileOpen(fileName, FILE_READ|FILE_TXT);
    if(fileHandle != INVALID_HANDLE) {
        while(!FileIsEnding(fileHandle)) {
            Common::ArrayPush(files[loc].data, FileReadString(fileHandle));
        }
        
        FileClose(fileHandle);
        return true;
    }
    else { return false; }
}

bool ResourceStore::loadTextResource(string fileName, const string &dataIn[]) {
    int loc = Common::ArrayTsearch(fileNames, fileName);
    
    if(loc < 0) {
        loc = -1 + Common::ArrayPush(fileNames, fileName);
        Common::ArrayPush(files, new ResourceFile(fileName, ResText));
    }

    ArrayFree(files[loc].data);
    ArrayCopy(files[loc].data, dataIn);
    return true;
}

bool ResourceStore::getTextResource(string fileName, string &dataOut[]) {
    int loc = Common::ArrayTsearch(fileNames, fileName);
    
    if(loc < 0) {
        if(!loadTextResource(fileName)) { return false; }
        else { loc = Common::ArrayTsearch(fileNames, fileName); }
    }
    
    if(loc > -1) {
        ArrayFree(dataOut);
        ArrayCopy(dataOut, files[loc].data);
        return true;
    }
    else { return false; }
}

ResourceStore ResourceMan = NULL;
