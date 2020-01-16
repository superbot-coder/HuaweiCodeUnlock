unit HuaweiCodeUnlock;

//****************************************************
//  HUAWEI CODE CALCULATOR "ALGO V1+V2+V3/201"
//  Autor by SUPERBOT
//  Conver from code PHP and Python modules
//  Requirement for compiling modul: DCPcrypt2-2010
//  Source PHP: https://github.com/yanderemoe/huawei_modem_code_calculator
//  Source Python: https://gist.github.com/DonnchaC/09c9de3a73b0fd29c699d4f3ce038074
//****************************************************}

interface

uses SysUtils, StrUtils, Dialogs, DCPconst, DCPmd5, DCPSha1;

Type TTypeCode = (tcUnlock, tcFlash);
Type TMD5bin = Array[0..15] of Byte;
Type TSha1bin = Array[0..19] of Byte;
Type PSha1bin = ^TSha1bin;
Type PMD5bin = ^TMD5bin;
type TDigest = array of Byte;

Var
  UnlockV1: AnsiString;
  UnlockV2: AnsiString;
  UnlockV3_201: AnsiString;
  Flash: AnsiString;


function MD5BinToAStr(MD5Digest: TMD5bin): AnsiString;
Function GetMD5(AStrData: AnsiString): TMD5bin;
function GetSha1(IMEI: AnsiString): TSha1bin;
function DigestToHex(Digest: array of Byte): AnsiString;
procedure log(StrVal: String);

function CalcV1(IMEI: AnsiString; TypeCode: TTypeCode): AnsiString;
function CalcV2(IMEI: AnsiString): AnsiString;
function CalcV3(IMEI: AnsiString): AnsiString;

//function fake_crc32_huawei(IMEI: AnsiString; mode: byte): LongWord;
//function algo_selector(IMEI: String; mode: Byte): ShortInt;
//function Algo0(IMEI: AnsiString; Mode: WORD): AnsiString;
//function Algo1(IMEI: AnsiString; Mode: WORD): AnsiString;
//function Algo2(IMEI: AnsiString; Mode: WORD): AnsiString;
//function Algo3(IMEI: AnsiString; Mode: WORD): AnsiString;
//function Algo4(IMEI: AnsiString; Mode: WORD): AnsiString;
//function Algo5(IMEI: AnsiString; Mode: WORD): AnsiString;
//function Algo6(IMEI: AnsiString; Mode: WORD): AnsiString;

procedure Test_Algos;


// --------------------- additional functions -----------------------------
procedure BinariPrint(AStrData: AnsiString);

implementation

USES UMain;

procedure log(StrVal: String);
begin
  // The debug message
  ShowMessage(StrVal);
  //FrmMain.mm.Lines.Add(StrVal);
end;

{------------------------------- BinariPrint ----------------------------------}
procedure BinariPrint(AStrData: AnsiString);
var i: SmallInt;
  s_temp : AnsiString;
begin
  for i:=1 to Length(AStrData) do
  begin
    s_temp := s_temp + IntToStr(Ord(AStrData[i])) +' ';
  end;
  log('BinariPrint: ' + Trim(s_temp));
end;

{--------------------------------- DigestToHex --------------------------------}
function DigestToHex(Digest: Array of Byte): AnsiString;
var i: Word;
begin
  Result := '';
  if Length(Digest) = 0 then Exit;
  for i := 0 to Length(Digest)-1 do Result := Result + IntToHex(Digest[i], 2);
end;

{-------------------------------- GetSha1 -------------------------------------}
function GetSha1(IMEI: AnsiString): TSha1bin;
var
  Sha1: TDCP_sha1; 
begin
  Sha1 := TDCP_sha1.Create(nil);
  try
    Sha1.Init;
    Sha1.UpdateStr(IMEI);
    Sha1.Final(Result);
  finally
    Sha1.free;
  end;
end;

{------------------------------ MD5BinToAStr ----------------------------------}
function MD5BinToAStr(MD5Digest: TMD5bin): AnsiString;
var i: Byte;
begin
  Result := '';
  for i:=0 to 15 do Result := Result + IntToHex(MD5Digest[i], 2);
  Result := AnsiLowerCase(Result);
end;

{--------------------------------- GetMD5 -------------------------------------}
Function GetMD5(AStrData: AnsiString): TMD5bin;
Var MD5: TDCP_md5;
begin
  MD5 := TDCP_md5.Create(Nil);
  try
    MD5.Init;
    MD5.UpdateStr(AStrData);
    MD5.Final(Result);
  finally
    MD5.Free;
  end;
end;

{----------------------------- fake_crc32_huawei ------------------------------}
function fake_crc32_huawei(IMEI: AnsiString; mode: byte): LongWord;
Type TCRCTable = array[0..255] of LongWord;
var i: SmallInt;
   crc: LongWord;
   CRCTable: TCRCTable;
Const
 crc_table201: Array[0..255] of LongWord = (
  $00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $196c3671, $6e6b06e7, $fed41b76,
  $89d32be0, $10da7a5a, $fbd44c65, $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2, $4adfa541,
  $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a, $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252,
  $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b, $d80d2bda, $af0a1b4c, $36034af6, $41047a60,
  $df60efc3, $a867df55, $316e8eef, $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de,
  $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7, $136c9856, $fa0f3d63, $8d080df5, $3b6e20c8,
  $4c69105e, $d56041e4, $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b, $646ba8c0,
  $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9, $45df5c75, $dcd60dcf, $abd13d59, $26d930ac,
  $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599, $706af48f, $e963a535,
  $9e6495a3, $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07,
  $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3, $b8bda50f, $2802b89e, $5f058808,
  $c60cd9b2, $b10be924, $2f6f7c87, $58684c11, $c1611dab, $b6662d3d, $76dc4190, $4969474d,
  $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f,
  $30b5ffe9, $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605, $03b6e20c, $74b1d29a,
  $ead54739, $9dd277af, $04db2615, $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
  $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457,
  $65b0d9c6, $12b7e950, $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $e40ecf0b,
  $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344, $4669be79, $cb61b38c, $bc66831a, $256fd2a0,
  $5268e236, $cc0c7795, $bb0b4703, $220216b9, $5505262f, $c5ba3bbe, $68ddb3f8, $1fda836e,
  $81be16cd, $f6b9265b, $6fb077e1, $18b74777, $88085ae6, $ff0f6a70, $66063bca, $11010b5c,
  $8f659eff, $f862ae69, $616bffd3, $166ccf45, $a00ae278, $b2bd0b28, $2bb45a92, $5cb36a04,
  $c2d7ffa7, $b5d0cf31, $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c, $026d930a,
  $9c0906a9, $eb0e363f, $72076785, $05005713, $346ed9fc, $ad678846, $da60b8d0, $44042d73,
  $33031de5, $aa0a4c5f, $dd0d7cc9, $5005713c, $270241aa, $be0b1010, $01db7106, $98d220bc,
  $efd5102a, $71b18589, $06b6b51f, $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e,
  $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f, $5edef90e, $29d9c998, $b0d09822,
  $c7d7a8b4, $59b33d17, $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8, $5d681b02,
  $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b, $2eb40d81, $b7bd5c3b, $c0ba6cad, $edb88320,
  $9abfb3b6, $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8, $67dd4acc, $f9b9df6f,
  $8ebeeff9, $17b7be43, $60b08ed5, $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb,
  $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21,
  $86d3d2d4, $f1d4e242, $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7, $2d02ef8d);

 crc_table2: Array[0..255] of LongWord = (
  $00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3,
  $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
  $1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
  $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
  $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
  $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
  $26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
  $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
  $76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
  $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
  $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
  $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
  $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
  $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
  $5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F,
  $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
  $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
  $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
  $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7,
  $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
  $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
  $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
  $CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F,
  $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
  $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713,
  $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
  $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
  $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
  $A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB,
  $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
  $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF,
  $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);

begin
  case mode of
     2: CRCTable := TCRCTable(crc_table2);
   201: CRCTable := TCRCTable(crc_table201);
  end;
  crc := $FFFFFFFF;
  for i:= 1 to Length(IMEI) do crc := CRCTable[(crc xor ord(IMEI[i])) and $FF] xor ((crc shr 8) and $FFFFFFFF);
  Result := crc xor $FFFFFFFF;
end;

{---------------------------------- CalcV1 ------------------------------------}
function CalcV1(IMEI: AnsiString; TypeCode: TTypeCode): AnsiString;
var
  bt: Byte;
  X: LongWord;
  salt: AnsiString;
  i: SmallInt;
  MD5bin: TMD5bin;
Const
  Salt0 = 'hwe620datacard'; // Unlok md5 hash "5e8dd316726b0335"
  Salt1 = 'e630upgrade';    // flash md5 hash "97B7BC6BE525AB44"
begin
 // Get salt
  case TypeCode of
    tcUnlock:  MD5bin := GetMD5(Salt0);
    tcFlash :  MD5bin := GetMD5(Salt1);
  end;

  // binary salt to HexStr
  salt := MD5BinToAStr(MD5bin);
  salt := copy(salt, 9, 16);

  // Get MD5 hash IMEI+salt
  MD5bin := GetMD5(IMEI+salt);

  X := 0;
  for i:=0 to 3 do
  begin
    bt := MD5bin[i] xor MD5bin[i+4] xor MD5bin[i+8] xor MD5bin[i+12];
    X := X or (($00000000 or bt) shl (24-(8*i)));
  end;
  X := X and $1ffffff or $2000000;
  Result := IntToStr(X);
end;

{------------------------------------ Algo1 -----------------------------------}
function Algo0(IMEI: AnsiString; Mode: WORD): AnsiString;
type TTable = array[0..15] of LongWord;
var sum: Int64;
    i: SmallInt;
    table: TTable;
Const
  table_v2: Array[0..15] of LongWord = (
  	$001966A9, $0021058F, $002AEDA9, $0037CE91, $00488C9F, $005E507D,
	  $007A9BE5, $009F644B, $00CF35A1, $010D5F55, $015E2F25, $01C73D6B,
	  $024FCFDD, $03015B47, $03E829E9, $05143685);

  table_201: Array[0..15] of LongWord = (
    $006E9C2A, $03CA2B3C, $001080DC, $30855EE, $03D3283A, $02F4F85A,
	  $01F8808E, $03147D10, $034BBBB5, $29EEADD, $02318616, $050F3ADC,
	  $00D11F38, $02123BD2, $04276C86, $355CAAD);
begin
  Result := '';
  sum := 0;
  case mode of
      2: table := TTable(table_v2);
    201: table := TTable(table_201);
  end;
  for i := 1 to Length(IMEI) do sum := sum + (StrToInt(IMEI[i]) + $30) * table[i-1];
  for i := 0 to 7 do Result := Result + IntToStr((sum shr (4 * i) and $0F) mod 10);
  if Result[1] = '0' then Result[1] := '1';
end;

{------------------------------------ Algo1 -----------------------------------}
function Algo1(IMEI: AnsiString; Mode: WORD): AnsiString;
var
  crc: LongInt;
  nsk : AnsiString;
begin
  crc :=fake_crc32_huawei(IMEI, mode);
  if crc < 0 then
  begin
     crc := crc * -1;
     crc := crc and $FFFFFFFF;
  end;
  nsk := IntToStr(crc);
  // nsk может быть 10 - 9 иногда 6 символов, но нужно скопировать 8 последних символов
  nsk := AnsiRightStr(nsk, 8);
  if Length(nsk) < 8 then nsk := StringOfChar('9', 8 - Length(nsk)) + nsk;
  if nsk[1] = '0' then nsk[1] := '9';
  Result := nsk;
end;

{----------------------------------- Algo2 ------------------------------------}
function Algo2(IMEI: AnsiString; Mode: WORD): AnsiString;
var
  digest: TMD5bin;
  digest_bytes: array[0..7] of byte;
  first_digit : LongWord;
  i: ShortInt;
  //s: String;
begin
  // ********* MD5 digest algorithim *********
  digest := GetMD5(IMEI);
  //log('digest = ' + DigestToHex(digest));

  case Mode of
      2: move(digest[0], digest_bytes, 8);
    201: move(digest[5], digest_bytes, 8);
  end;

 //for i:=0 to 7 do s := s + IntToHex(digest_bytes[i], 2) + ',';
 //log('digest_bytes[] = ' + s);

 // Replace first digit if it begins with zero
 first_digit := ord(digest_bytes[0]) mod 10;
 if first_digit = 0 then digest_bytes[0] := ord('5')
 else  digest_bytes[0] := Byte(first_digit);

 // Use suitable digits or base 10 bytes to get a single decimal digit
 for i := 0 to Length(digest_bytes) -1 do
 begin
   // Byte is already a single digit character, don't mod
   if (digest_bytes[i] >= ord('0')) and (digest_bytes[i] <= ord('9')) then
     Result := Result + AnsiChar(digest_bytes[i])
   else Result := Result + AnsiChar((digest_bytes[i] mod 10) + $30);
 end;

end;

{---------------------------------- Algo3 -------------------------------------}
function Algo3(IMEI: AnsiString; Mode: WORD): AnsiString;
var
  salt: Ansistring;
  MD5bin: TMD5bin;
  i: SmallInt;
  x: LongWord;
  bt: Byte;
const
  salt0 = 'hwideadatacard';
  salt1 = 'dfkdkfllekkodk';

begin
  // MD5 with version specific salt

  case mode of
     2: MD5bin := GetMD5(salt0);
   201: MD5bin := GetMD5(salt1);
  end;

  setlength(salt, Length(MD5bin));
  move(MD5bin, salt[1], Length(MD5bin));
  //BinariPrint(salt);

  MD5bin := GetMD5(IMEI + salt);

  x := 0;
  for i:=0 to 3 do
  begin
    bt := MD5bin[i] xor MD5bin[i+4] xor MD5bin[i+8] xor MD5bin[i+12];
    x := x or (($00000000 or bt) shl (24-(8*i)));
  end;
  x := x and $1ffffff or $2000000;
  Result := IntToStr(x);
end;

{-------------------------------- Algo4 ---------------------------------------}
function Algo4(IMEI: AnsiString; Mode: WORD): AnsiString;
var
  code: array[0..7] of Byte; //AnsiString;
  digit: SmallInt;
  str_imei: AnsiString;
  i:  ShortInt;
const
  magic = AnsiString('5739146280098765432112345678905');
begin
  str_imei := IMEI + 'Z';
  for i := 0 to 7 do
  begin
     digit := (Ord(str_imei[i+1]) xor ord(str_imei[(i+1) + 8])) and $FF;
     code[i] := StrToInt(magic[(digit shr 4) + (digit and $0f)+1]);
  end;

  if code[0] = 0 then
  begin
    for i := 0 to 7 do if code[i] <> 0 then Break;
    code[0] := i;
  end;

  Result := '';
  for i := 0 to 7 do Result := Result + IntToStr(code[i]);
end;

{-------------------------------- Algo5 ---------------------------------------}
function Algo5(IMEI: AnsiString; Mode: WORD): AnsiString;
var
  digest : TSha1bin;
  int_array: array[0..4] of LongWord;
  di: LongWord;
  i: ShortInt;
  s: AnsiString;
begin
  digest := GetSha1(IMEI);
  for i := 0 to 4 do
  begin 
    di := di xor di;
    di := ((((((di or digest[i*4]) shl 8) or digest[(i*4)+1]) shl 8) or digest[(i*4)+2]) shl 8) or digest[(i*4)+3];
    int_array[i] := di; 
  end;

  //Log('DigestToHex = '+DigestToHex(digest));

  case mode of
      2: Result := IntToStr(int_array[0]) + IntToStr(int_array[1]);
   2015: Result := IntToStr(int_array[1]) + IntToStr(int_array[4]);
   2016: Result := IntToStr(int_array[2]) + IntToStr(int_array[3]);
  end;

  Result := Copy(result, 1, 8);
end;

{-------------------------------- Algo6 ---------------------------------------}
function Algo6(IMEI: AnsiString; Mode: WORD): AnsiString;
type TMagic = array[0..11] of Byte;
var
  MagicKey   : Tmagic;
  ResultBuf  : Array of Byte;
  Buf128     : array[0..127] of Byte;
  byte_array : array[0..127] of AnsiChar;
  AResult    : Array of Byte;
  digest     : TMD5bin;
  digit      : Byte;
  extra_num  : string;
  ex_int     : Int64;
  s_temp     : string;
  hsum, csum : LongWord;
  offset     : LongWord;
  lr : Int64;
  cx : Int64;
  i, r0,r1,r2,r3,r4,r5,r6,r7,r8,r12 : LongWord;

// Keyed cipher and MD5 digest
const
  cb_2: array[0..11] of byte = ($01, $01, $02, $03, $05, $08, $0D, $15, $22, $37, $59, $90);
  cb_201: array[0..11] of Byte = ($0B, $0D, $11, $13, $17, $1D, $1F, $25, $29, $2B, $3B, $61);

function int_from_bytestream(digest: array of Byte; ofset: LongWord): Int64;
var i: ShortInt;
begin
  Result := 0;
  Result := (Result or digest[ofset+3]) shl 8;
  Result := (Result or digest[ofset+2]) shl 8;
  Result := (Result or digest[ofset+1]) shl 8;
  Result := (Result or digest[ofset]);
end;

begin

  Case Mode of
     2: MagicKey := TMagic(cb_2);
   201: MagicKey := TMagic(cb_201);
  End;

  for i := 0 to Length(IMEI) -1 do
  begin
    digit := ord(IMEI[i+1]);
    SetLength(ResultBuf, Length(ResultBuf) +1);
    case (i mod 3) of
      0: ResultBuf[Length(ResultBuf)-1] := ((digit shl 6) or (digit shr 2)) and $FF;
      1: ResultBuf[Length(ResultBuf)-1] := ((digit shl 5) or (digit shr 3)) and $FF;
      2: ResultBuf[Length(ResultBuf)-1] := ((digit shl 4) or (digit shr 4)) and $FF;
    end;
  end;

  hsum := 0;
  for i := 0 to 6 do hsum := hsum + ResultBuf[14-i] + (ResultBuf[i] shl 8);
  hsum := hsum + ResultBuf[8];
  //log('1. hsum = '+IntToStr(hsum) +' ResultBuf = '+ DigestToHex(ResultBuf));

  // Pad buffer with 0's
  for i := 0 to length(ResultBuf)-1 do Buf128[i] := ResultBuf[i];

  r0:=0; r1:=0; r2:=0; r3:=0; r4:=0; r5:=0; r6:=0; r7:=0; r8:=0; r12:=0; cx:=0; lr:=0;

  // TODO: Understand what this chunk of code does:
  // Appears to do divison by 6.
  for i := 15 to 127 do
  begin
    r6 := i;
    r3 := i shr 31;
    lr := $2AAAAAAB;            // des 715827883
    cx := int64($2AAAAAAB) * i; // des 10737418245
    r1 := cx shr 32;
    cx := lr * r8;
    lr := cx shr 32;

    r0  := r8 shr 31;
    r2  := r0;
    r5  := (r1 shr 1) - r3;
    r12 := r5 shl 4;
    r0  := (lr shr 1) - r0;
    r2  := (lr shr 1) - r2;
    r1  := r0 shl 4;
    r12 := r12 - (r5 shl 2);
    r3  := r2 shl 4;
    lr  := r6 - r12;
    r1  := r1 - (r0 shl 2);
    r7  := r5 + lr;
    r3  := r3 - (r2 shl 2);
    r1  := r8 - r1;
    r2  := r5 + r1;
    r3  := r8 - r3;

    r12 := r12 - $18;
    if r7 > $b then r7 := r7 - $c;
    r3  := r3 + r5;
    if r5 > 1 then r3 := r2 + r12;
    r0  := hsum;
    r1  := r6;

    if r8 = 0 then
    begin
      r4  := buf128[r3];
      r0  := r0 mod r1;
      r1  := MagicKey[r7];
      r4  := r4 and r1;
      r12 := buf128[r0];
      r3  := buf128[r0+1];
      r4  := r4 or r12;
    end
    else
    begin
      r1  := r6;
      r0  := hsum;
      r4  := buf128[r3];
      r0  := r0 mod r1;
      r1  := r8;
      r5  := buf128[r0];
      r0  := hsum;
      r0  := r0 mod r1;
      r3  := buf128[r0];
      r2  := Magickey[r7];
      r4  := r4 and r2;
      r4  := r4 or r5;
    end;

    r3 := not r3;       //?
    r3 := r3 or r4;
    r3 := r3 and $ff;  //?
    buf128[i] := r3;
    r8 := r8 + 1;      //?
  end;


  for i := 0 to 127 do byte_array[i] := AnsiChar(chr(buf128[i]));

  csum := 0;
  for i := 0 to 6 do
  begin
    csum := csum + (ord(IMEI[i+2]) or (ord(IMEI[i+1]) shl 8));
  end;
  csum := csum + ord(IMEI[15]);

  digest := GetMD5(AnsiString(byte_array));
  //log('digest = ' + DigestToHex(digest));

  for i := 0 to Length(digest) -1 do
  begin
    if (digest[i] >= ord('0')) and (digest[i] <= ord('9')) then
    begin
      SetLength(AResult, Length(AResult)+1);
      AResult[Length(AResult)-1] := (digest[i]);
    end;
    if Length(AResult) > 7 then Break;
  end;
  //log('Length = ' + IntToStr(Length(AResult)) + ' AResult = ' + DigestToHex(AResult));

  // Extract an integer from the hash
  offset := (csum and 3) shl 2;
  extra_num := IntToStr(int_from_bytestream(digest, offset));

  // Cycle 1
  if Length(AResult) < 8 then
    // Don't have enough numbers, read more digits from the end
    // of extra_number until we have 8 digits.
    while Length(AResult) < 8 do
    begin
      SetLength(AResult, Length(AResult) + 1);
      AResult[Length(AResult)-1] := Byte(extra_num[Length(extra_num)]);
      SetLength(extra_num, Length(extra_num)-1);
      // If still nor enough digits, pick a new integer from digest
      if  length(extra_num) = 0 then
      begin
        offset    := (3 - (csum and 3)) shl 2;
        extra_num := IntToStr(int_from_bytestream(digest, offset));
      end;
    end;

    // AResult[0] := ord('0'); for test block
    // Replace any leading zeros
    if AResult[0] = ord('0') then
    begin
      if csum <> 0 then offset := 1
      else offset := 0;
      // Add one to digit to ensure non zero
      // AResult[0] := Ord(IntToStr((digest[offset] and 7) + 1)[1]);
      AResult[0] := (digest[offset] and 7) + 1 + $30; // +$30 convet to ascii
    end;
	
   SetLength(Result, Length(AResult));
   move(Aresult[0], Result[1], Length(AResult));
end;

{-------------------------- function algo_selector ----------------------------}
function algo_selector(IMEI: String; mode: Byte): ShortInt;
Var i: ShortInt;
    x: integer;
begin
  x := 0;
  for i := 1 to Length(IMEI) do
  begin
    case mode of
        2: x := x + ((ord(IMEI[i]) + i) * i);
      201: x := x + ((ord(IMEI[i]) + i) * ord(IMEI[i])) * (ord(IMEI[i]) + 313);
    end;
    Result := x mod 7;
  end;
end;

{---------------------------- function CalcV2 ---------------------------------}
function CalcV2(IMEI: AnsiString): AnsiString;
begin
  case algo_selector(IMEI, 2) of
    0: Result := Algo0(IMEI, 2);
    1: Result := Algo1(IMEI, 2);
    2: Result := Algo2(IMEI, 2);
    3: Result := Algo3(IMEI, 2);
    4: Result := Algo4(IMEI, 2);
    5: Result := Algo5(IMEI, 2);
    6: Result := Algo6(IMEI, 2);
  else
    Result := ''
  end;
end;

{---------------------------- function CalcV3 ---------------------------------}
function CalcV3(IMEI: AnsiString): AnsiString;
begin
  Result := '';
  case algo_selector(IMEI, 201) of
    0: Result := Algo0(IMEI, 201);
    1: Result := Algo1(IMEI, 201);
    2: Result := Algo2(IMEI, 201);
    3: Result := Algo3(IMEI, 201);
    4: Result := Algo5(IMEI, 2015);
    5: Result := Algo5(IMEI, 2016);
    6: Result := Algo6(IMEI, 201);
  else
    Result := ''
  end;
end;

procedure Test_Algos;
var s, IMEI: String;

begin
  IMEI := '968480435684491';
  s := 'TEST IMEI for V1: ' + IMEI + #10#13;
  s := s + 'Unlock (V1): ' + CalcV1(IMEI, tcUnlock) + #10#13;
  s := s + 'Unlock (V2): ' + CalcV2(IMEI) + #10#13;
  s := s + 'Unlock (V3/201): ' + CalcV3(IMEI) + #10#13;
  s := s + 'Flash: ' + CalcV1(IMEI, tcFlash) + #10#13#10#13;

  s := s + 'algo0(''166794546749343'', 201) = 31572464 out = ' + algo0('166794546749343', 201) + #10#13#10#13;

  s := s + 'algo1(''867010022091625'', 2) = 89740701 out =' + algo1('867010022091625', 2) + #10#13;
  s := s + 'algo1(''867010022093346'', 2) = 90496577 out = ' + algo1('867010022093346', 2) + #10#13;
  s := s + 'algo1(''867010022091336'', 201) = 43479313 out = ' + algo1('867010022091336', 201) + #10#13;
  s := s + 'algo1(''486043736169958'', 201) = 20766653 out = ' + algo1('486043736169958', 201) + #10#13;
  s := s + 'algo1(''152782107774300'', 201) = 99353390 out = ' + algo1('152782107774300', 201) + #10#13#10#13;

  s := s + 'algo2(''867010022091626'', 2) = 55760904 out = ' + algo2('867010022091626', 2) + #10#13;
  s := s + 'algo2(''867010022091545'', 2) = 77395563 out = ' + algo2('867010022091545', 2) + #10#13;
  s := s + 'algo2(''867010022091566'', 201) = 98820346 out = ' + algo2('867010022091566', 201) + #10#13;
  s := s + 'algo2(''133887909865624'', 201) = 13553393 out = ' + algo2('133887909865624', 201) + #10#13#10#13;

  s := s + 'algo3(''867010022091677'', 2) = 50284150 out = ' + algo3('867010022091677', 2) + #10#13;
  s := s + 'algo3(''867010022091677'', 201) = 48425064 out = ' + algo3('867010022091677', 201) + #10#13#10#13;

  s := s + 'algo4(''867010022091661'', 2) = 16672676 out =' + algo4('867010022091661', 2) + #10#13;
  s := s + 'algo4(''867010022091698'', 2) = 16672086 out = ' + algo4('867010022091698', 2) + #10#13#10#13;

  s := s + 'algo5(''867010022091692'', 2) = 16678430 out = ' + algo5('867010022091692', 2) + #10#13;
  s := s + 'algo5(''867010022091696'', 2015) = 26958384 out = ' + algo5('867010022091696', 2015) + #10#13;
  s := s + 'algo5(''867010022091697'', 2016) = 11406485 out =' + algo5('867010022091697', 2016) + #10#13#10#13;

  s := s + 'algo6(''867010022093344'', 2) = 41232318 out = ' + algo6('867010022093344', 2) + #10#13;
  s := s + 'algo6(''234242342432305'', 2) = 68014899 out = ' + algo6('234242342432305', 2) + #10#13;
  s := s + 'algo6(''221724677371250'', 2) = 92023179 out = ' + algo6('221724677371250', 2) + #10#13;
  s := s + 'algo6(''867010022093350'', 201) = 13122759 out = ' + algo6('867010022093350', 201) + #10#13#10#13;


  s := s + 'algo_seletor(''667010022091624'', 201) ' + IntToStr(algo_selector('667010022091624', 201)) + #10#13;
  s := s + 'algo_seletor(''867010022091624'', 201) ' + IntToStr(algo_selector('867010022091624', 201)) + #10#13;
  s := s + 'algo_seletor(''867010022091624'', 2) ' + IntToStr(algo_selector('867010022091624', 2));

  ShowMessage(s);
  
end;

end.
