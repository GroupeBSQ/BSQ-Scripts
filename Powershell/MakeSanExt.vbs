Option Explicit

Dim oArgs
Dim oShell
Dim oFileSystem
Dim oFile
Dim iFile
Dim iLine
Dim sLine
Dim aASNsubstring()
Dim i
Dim n
Dim sASN
Dim bDbg

Const HEX_DATA_LENGTH = 1 
Const ASCIIDATA = 2 
Const HEXDATA = 3 
Const HEX_BLOB_LENGTH = 4 
Const HEX_TYPE = 5 

bDbg = False

Set oArgs = WScript.Arguments 
Set oShell = WScript.CreateObject("WScript.Shell")
Set oFilesystem = CreateObject("Scripting.FileSystemObject")


if oArgs.Count = 0 Then

    WScript.Echo "Usage"

Else

    Redim aASNsubstring(oArgs.Count-1,5)

    For i = 0 to oArgs.Count - 1
        aASNsubstring(i, ASCIIDATA) = Trim(oArgs(i))
        aASNsubstring(i, HEX_TYPE) = "82" 
If bDbg Then WScript.Echo "aASNsubstring(" & i & ",2) = " & aASNsubstring(i, ASCIIDATA)
    Next

End If


'############################################################################## 
' 
' Create the ASN.1 file 
' 
'############################################################################## 



If bDbg Then WScript.Echo "UBound(aASNsubstring,1) = " & UBound(aASNsubstring,1)

For n = 0 to UBound(aASNsubstring,1)

    If bDbg Then WScript.Echo "Len(aASNsubstring(n, ASCIIDATA)) = " & Len(aASNsubstring(n, ASCIIDATA))

    For i = 1 to Len(aASNsubstring(n, ASCIIDATA)) 
        aASNsubstring(n, HEXDATA) = aASNsubstring(n, HEXDATA) & _ 
                                    Hex(Asc(Mid(aASNsubstring(n, ASCIIDATA), i, 1))) 
    Next 

    If bDbg Then WScript.Echo "aASNsubstring(n, HEXDATA) = " & aASNsubstring(n, HEXDATA)

    aASNsubstring(n, HEX_DATA_LENGTH) = ComputeASN1 (Len(aASNsubstring(n, HEXDATA)) / 2) 

    If bDbg Then WScript.Echo "aASNsubstring(n, HEX_DATA_LENGTH) = " & aASNsubstring(n, HEX_DATA_LENGTH)


' 
' Build the ASN.1 blob for DNS name 
' 

    sASN = sASN & _
           aASNsubstring(n, HEX_TYPE) & _ 
           aASNsubstring(n, HEX_DATA_LENGTH) & _ 
           aASNsubstring(n, HEXDATA) 

    If bDbg Then WScript.Echo "sASN = " & sASN

Next

If bDbg Then WScript.Echo "sASN = " & sASN



' 
' Write the ASN.1 blob into a file 
' 

Set oFile = oFilesystem.CreateTextFile(aASNsubstring(0, ASCIIDATA) & ".asn") 

' 
' Put sequence, total length and ASN1 blob into the file 
' 

oFile.WriteLine "30" & ComputeASN1 (Len(sASN) / 2) & sASN 

oFile.Close 

'  
' Use certutil to convert the hexadecimal string into bin 
' 

oShell.Run "certutil -f -decodehex " & aASNsubstring(0, ASCIIDATA) & ".asn " & _  
                                       aASNsubstring(0, ASCIIDATA) & ".bin", 0, True 

'  
' Use certutil to convert the bin into base64 
' 
oShell.Run "certutil -f -encode " & aASNsubstring(0, ASCIIDATA) & ".bin " & _ 
                                    aASNsubstring(0, ASCIIDATA) & ".b64", 0, True 



'############################################################################## 
' 
' Create the INF file 
' 
'############################################################################## 
Set iFile = oFilesystem.OpenTextFile(aASNsubstring(0, ASCIIDATA) & ".b64") 
Set oFile = oFilesystem.CreateTextFile(aASNsubstring(0, ASCIIDATA) & ".txt") 

WScript.Echo "" 
iLine = 0 
Do While iFile.AtEndOfStream <> True 
    sLine = iFile.Readline 
    If sLine = "-----END CERTIFICATE-----" then 
        Exit Do 
    end if 
    if sLine <> "-----BEGIN CERTIFICATE-----" then 
        if iLine = 0 then 
            WScript.Echo "2.5.29.17=" & sLine 
        else 
            WScript.Echo "_continue_=" & sLine 
        end if 
        iLine = iLine + 1 
    end if 
Loop 
WScript.Echo "Critical=2.5.29.17" 
WScript.Echo ""

oFile.Close 
iFile.Close 


'############################################################################## 
' 
' Compute the ASN1 string 
' 
'############################################################################## 

Function ComputeASN1 (iStrLen) 
    Dim sLength
    If Len(Hex(iStrLen)) Mod 2 = 0 then 
        sLength = Hex(iStrLen) 
    else 
        sLength = "0" & Hex(iStrLen) 
    end if 
    if iStrLen > 127 then 
        ComputeASN1 = Hex (128 + (Len(sLength) / 2)) & sLength 
    else 
        ComputeASN1 = sLength 
    End If 
End Function