//+------------------------------------------------------------------+
//|                                                      CsvFile.mqh |
//|                                                          mazmazz |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "mazmazz"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
class CsvFile
{
private:
   string            m_delimiter;
   int               m_handle;
   int               m_error;
public:
   //--- flags: FILE_READ | FILE_WRITE | FILE_SHARED_READ | FILE_SHARED_WRITE | FILE_COMMON | FILE_UNICODE
                     CsvFile(string name,int flags,ushort delimiter=',',int codepage=CP_ACP)
     {
      reopen(name, flags, delimiter, codepage);
      StringSetCharacter(m_delimiter,0,delimiter);
     }

   void              reopen(string name,int flags,ushort delimiter=',',int codepage=CP_ACP)
     {
      close();
      m_handle=FileOpen(name,flags,delimiter,codepage);
      m_error=GetLastError();
      StringSetCharacter(m_delimiter,0,delimiter);
     }
     
   void              close() {if(m_handle!=INVALID_HANDLE)FileClose(m_handle);}
                     CsvFile() {m_handle = INVALID_HANDLE; m_delimiter=",";}
                    ~CsvFile() {close();}

   ulong             tell()               {return FileTell(m_handle); }
   bool              seek(int pos, ENUM_FILE_POSITION origin = SEEK_SET) { return FileSeek(m_handle, pos, origin); }

   bool              isFileEnding() {return FileIsEnding(m_handle); }
   bool              isLineEnding(bool seekIfEnd = false) {
      return FileIsLineEnding(m_handle); // after a line ending, FileRead* must be called or this will still return true
      //ulong pos = FileTell(m_handle);
      //uchar posChar[];
      //if(FileReadArray(m_handle, posChar, 0, 1) > 0) {
      //  if(posChar[0] == '\r' || posChar[0] == '\n') {
      //    if(!seekIfEnd) { FileSeek(m_handle, pos, SEEK_SET); } // seek to previous, as we don't want to skip over
      //    return true;
      //  } else {
      //    FileSeek(m_handle, pos, SEEK_SET);
      //    return false;
      //  }
      //} else { return true; }
     }

   string            readString() const {return FileReadString(m_handle);}
   double            readNumber() const {return FileReadNumber(m_handle);}
   datetime          readDateTime() const {return FileReadDatetime(m_handle);}
   bool              readBool() const {return FileReadBool(m_handle);}

   uint              writeString(string value) {return FileWriteString(m_handle,value);}
   uint              writeDateTime(datetime value) {return FileWriteString(m_handle,TimeToString(value));}
   uint              writeNumber(double value) {return FileWriteString(m_handle,DoubleToString(value,8));}
   uint              writeBool(bool value) {return FileWriteString(m_handle,value?"true":"false");}

   uint              writeLine(string value) {return FileWriteString(m_handle,value+"\n");}

   uint              writeDelimiter() {return FileWriteString(m_handle,m_delimiter);}
   uint              writeNewline() {return FileWriteString(m_handle,"\n");}

   uint              writeFields(const string &fields[])
     {
      return FileWrite(m_handle,StringJoin(fields,m_delimiter));
     }
};
//+------------------------------------------------------------------+
//| Join a string array                                              |
//+------------------------------------------------------------------+
string StringJoin(const string &a[],string sep=" ")
  {
   int size=ArraySize(a);
   string res="";
   if(size>0)
     {
      res+=a[0];
      for(int i=1; i<size; i++)
        {
         res+=sep+a[i];
        }
     }
   return res;
  }