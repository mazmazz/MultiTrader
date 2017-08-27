//+------------------------------------------------------------------+
//|                                                    CsvString.mqh |
//|                                                          mazmazz |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "mazmazz"
#property link      "https://github.com/mazmazz"
#property strict

//#include <Mql/Utils/File.mqh>
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CsvString//: public File
  {
private:
   char              m_delimiter; // todo: allow multi-char delimiters
   char              m_char[];
   int               m_charIndex;
   int               m_codepage;
   bool              m_cr;
   
   uint StringToCharArrayNoNull(const string text_string, uchar &char_array[], int start_pos = 0, int count=WHOLE_ARRAY, uint codepage = CP_ACP)
     {
        return StringToCharArray(text_string, char_array, 0, count == WHOLE_ARRAY ? StringLen(text_string) : count, codepage); // StringLen does not include null terminator
     }
public:
   //--- flags: FILE_READ | FILE_WRITE | FILE_SHARED_READ | FILE_SHARED_WRITE | FILE_COMMON | FILE_UNICODE
                     CsvString(string content,int flags,ushort delimiter=',',int codepage=CP_ACP) //:File(name,flags|FILE_CSV|FILE_ANSI,delimiter,codepage)
     {
        reopen(content, flags, delimiter, codepage);
     }

   void              reopen(string content,int flags,ushort delimiter=',',int codepage=CP_ACP)
     {
        //File::reopen(name,flags|FILE_CSV|FILE_ANSI,delimiter,codepage);
        m_delimiter = delimiter;
        ArrayFree(m_char);
        StringToCharArrayNoNull(content, m_char);
        m_charIndex = 0;
        m_codepage = codepage;
        m_cr = StringFind(content, "\r\n");
     }
     
   string              getValue() const
     {
        return CharArrayToString(m_char, 0, WHOLE_ARRAY, m_codepage);
     }
     
   bool              toFile(string filename, int flags, int codepage=CP_ACP) 
     {
        int handle = FileOpen(filename, flags, ',', codepage);
        if(handle == INVALID_HANDLE) { return false; }
        
        uint writeBytes = FileWriteString(handle, getValue());
        FileClose(handle);
        return true;
     }

   bool              isLineEnding(bool seekIfEnding = false)
     {
        if(m_charIndex >= ArraySize(m_char)) { return true; }
        if(m_char[m_charIndex] == '\r' || m_char[m_charIndex] == '\n') {
            if(seekIfEnding) {
                if(m_char[m_charIndex] == '\r') { m_charIndex++; }
                if(m_charIndex < ArraySize(m_char) && m_char[m_charIndex] == '\n') { m_charIndex++; }
            }
            return true;
        } else { return false; }
     }
     
   bool              isDataEnding()
     {
        return m_charIndex >= ArraySize(m_char) - 1 - (isLineEnding() ? 1 + (int)m_cr : 0);
     }

   string            readString()
     {
        char resultChar[]; bool breakLoop = false;
        for(int i = 0; m_charIndex < ArraySize(m_char); i++, m_charIndex++) {
            switch(m_char[m_charIndex]) {
                case '\r':
                    if(ArraySize(m_char) > m_charIndex+1 && m_char[m_charIndex+1] == '\n') { m_charIndex++; } // Account for \r\n
                    // fall through
                case '\n':
                    if(i <= 0) { // skip first new line
                        continue;
                    } else { breakLoop = true; } // break on the next newline
                    break;
                default:
                    if(m_char[m_charIndex] == m_delimiter) { // we don't support delimiter escaping
                        breakLoop = true;
                        m_charIndex++;
                        break;
                    }
                    ArrayResize(resultChar, ArraySize(resultChar)+1);
                    resultChar[ArraySize(resultChar)-1] = m_char[m_charIndex];
                    break;
            }
            if(breakLoop) { break; }
        }
        string resultString = CharArrayToString(resultChar, 0, WHOLE_ARRAY, m_codepage);
        StringTrimLeft(resultString);
        StringTrimRight(resultString);
        return resultString;
     }
   double            readNumber() 
     {
        string resultString = readString();
        return StringToDouble(resultString);
     }
   datetime          readDateTime() 
     { 
        // only supports MQL format (yyyy.mm.dd hh:mi)
        string resultString = readString();
        return StringToTime(resultString);
     }
   bool              readBool() 
     {
        string resultString = readString();
        StringToLower(resultString);
        if(resultString == "true") { return true; }
        else if(resultString == "false") { return false; }
        else { return StringToInteger(resultString) > 0; }
     }

   uint              writeString(string value) 
     {
        if(ArraySize(m_char) > 0 && m_char[ArraySize(m_char)-1] != '\r' && m_char[ArraySize(m_char)-1] != '\n') { 
            value = CharToString(m_delimiter) + value; // add previous entry's delimiter if m_char does not already end in newline
        }
        
        char valueChar[];
        StringToCharArrayNoNull(value, valueChar);
        int newEntryStart = ArraySize(m_char);
        ArrayResize(m_char, newEntryStart+ArraySize(valueChar));
        return MathMin(0, ArrayCopy(m_char, valueChar, newEntryStart));
     }
   uint              writeDateTime(datetime value) 
     {
        string valueString = TimeToString(value);
        return writeString(valueString);
     }
   uint              writeNumber(double value) 
     {
        string valueString = DoubleToString(value,8);
        return writeString(valueString);
     }
   uint              writeBool(bool value) 
     {
        string valueString = value?"true":"false";
        return writeString(valueString);  
     }

   uint              writeLine(string value) 
     {
        return writeString(value+(m_cr?"\r\n":"\n"));
     }

   uint              writeDelimiter() 
     {
        // todo: allow multi-char delimiters
        ArrayResize(m_char, ArraySize(m_char)+1);
        m_char[ArraySize(m_char)-1] = m_delimiter;
        return 1;
     }
   uint              writeNewline() 
     {
        ArrayResize(m_char, ArraySize(m_char)+1+(int)m_cr);
        if(m_cr) { m_char[ArraySize(m_char)-2] = '\r'; }
        m_char[ArraySize(m_char)-1] = '\n';
        return 1 + (int)m_cr;
     }

   uint              writeFields(const string &fields[])
     {
        uint result = 0;
        for(int i = 0; i < ArraySize(fields); i++) {
            result += writeString(fields[i]);
        }
        // result += writeNewline();
        return result;
     }
  };