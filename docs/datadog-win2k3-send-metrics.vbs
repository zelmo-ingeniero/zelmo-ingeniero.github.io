Option Explicit
Dim objWMIService, colItems, objItem, strComputer
Dim strCPU, strMemory, strDisk, objFSO, objTextFile, objShell
Dim strAPIKey, strURL, strJson, strCurlCommand
Dim strLogURL, strLogJson, strLogCurlCommand

' Datadog configuration
' In this case the DD_SITE is US1
strAPIKey = "your-datadog-api-key"
strURL = "https://api.datadoghq.com/api/v1/series" 
strLogURL = "https://http-intake.logs.datadoghq.com/api/v2/logs"

' Initializing variables
Dim WShell, hostname
Set WShell = CreateObject("WScript.Network")
hostname = WShell.ComputerName
strComputer = hostname
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objTextFile = objFSO.CreateTextFile("C:\metrics.json", True)
Set objShell = CreateObject("WScript.Shell")

' To log the start of this script in the Windows Events Viewer
'objShell.LogEvent 4, "Script de monitoreo iniciado en " & strComputer & "."

' Collecting CPU metrics from WMI 
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_PerfFormattedData_PerfOS_Processor WHERE Name='_Total'")
For Each objItem in colItems
    strCPU = objItem.PercentProcessorTime
    If Not IsNumeric(strCPU) Then
        strCPU = 0
        objShell.LogEvent 1, "Error: strCPU is not a number"
    End If
Next
'objShell.LogEvent 4, "CPU Métric collected: " & strCPU & "%"

' Memory monitoring
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem")
For Each objItem in colItems
    Dim totalMemory, freeMemory, usedMemoryPercent
    totalMemory = objItem.TotalVisibleMemorySize / 1024
    freeMemory = objItem.FreePhysicalMemory / 1024
    usedMemoryPercent = Round(((totalMemory - freeMemory) / totalMemory) * 100, 2)
    strMemory = usedMemoryPercent
    If Not IsNumeric(strMemory) Then
        strMemory = 0
        objShell.LogEvent 1, "Error: strMemory is not a number"
    End If
Next
'objShell.LogEvent 4, "Memory Métric collected: " & strMemory & "%"

' Disk Monitoring
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_LogicalDisk WHERE DeviceID='C:'")
For Each objItem in colItems
    Dim totalDisk, freeDisk, usedDiskPercent
    totalDisk = objItem.Size / (1024^3)
    freeDisk = objItem.FreeSpace / (1024^3)
    usedDiskPercent = Round(((totalDisk - freeDisk) / totalDisk) * 100, 2)
    strDisk = usedDiskPercent
    If Not IsNumeric(strDisk) Then
        strDisk = 0
        objShell.LogEvent 1, "Error: strDisk is not a number"
    End If
Next
'objShell.LogEvent 4, "Disk Métric collected: " & strDisk & "%"

' Printing values for debugging
'WScript.Echo "CPU: " & strCPU & "%"
'WScript.Echo "Memory: " & strMemory & "%"
'WScript.Echo "Disk: " & strDisk & "%"

' Creating JSON
Dim timestamp, utcTime, mexicoTime2025

' Setting the correct UTC timezone
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem")
For Each objItem in colItems
    Dim timezoneOffset
    timezoneOffset = objItem.CurrentTimeZone / 60 ' Converting minutes to hours
    utcTime = DateAdd("h", -timezoneOffset, Now)
Next

' Converting timestamp from the seconds since 1970-01-01 to UTC
mexicoTime2025 = DateAdd("h", +0, utcTime)
timestamp = CLng(DateDiff("s", "1970-01-01 00:00:00", mexicoTime2025))
'timestamp = CLng(DateDiff("s", "1970-01-01 00:00:00", utcTime))
'objShell.LogEvent 4, "Generated Timestamp (UTC): " & timestamp

' Ensuring that the variables contain metrics data and are compatible with the JSON format
' Replace comma for period for decimal numbers
strCPU = Replace(strCPU, ",", ".") 
strMemory = Replace(strMemory, ",", ".")
strDisk = Replace(strDisk, ",", ".")
strJson = "{""series"": [" & _
          "{""metric"": ""hello.system.cpu.percent"", ""points"": [[" & timestamp & ", " & strCPU & "]], ""type"": ""gauge"", ""host"": """ & strComputer & """, ""tags"": [""env:win2k3"", ""service:win2k3""]}," & _
          "{""metric"": ""hello.system.memory.percent"", ""points"": [[" & timestamp & ", " & strMemory & "]], ""type"": ""gauge"", ""host"": """ & strComputer & """, ""tags"": [""env:win2k3"", ""service:win2k3""]}," & _
          "{""metric"": ""hello.system.disk.percent"", ""points"": [[" & timestamp & ", " & strDisk & "]], ""type"": ""gauge"", ""host"": """ & strComputer & """, ""tags"": [""env:win2k3"", ""service:win2k3""]}]}" 

'objShell.LogEvent 4, "JSON generado para envío a Datadog"

' Print JSON for debugging
'WScript.Echo "Generated JSON: " & strJson

' Writing JSON in a file
objTextFile.WriteLine strJson
objTextFile.Close

' Creating curl command
strCurlCommand = "C:\curl\curl.exe -X POST -H ""Content-Type: application/json"" -H ""DD-API-KEY: " & strAPIKey & """ --cacert C:\curl\curl-ca-bundle.crt --data @C:\metrics.json " & strURL & " -o C:\curl_response.txt"

' Running curl command
Dim execResult
execResult = objShell.Run(strCurlCommand, 0, True)

' Verifying curl response
Dim objResponseFile, strResponse
Set objResponseFile = objFSO.OpenTextFile("C:\curl_response.txt", 1, False)
If Not objResponseFile.AtEndOfStream Then
    strResponse = objResponseFile.ReadAll
Else
    strResponse = "No response received from Datadog"
    objShell.LogEvent 1, "Error: No response received from Datadog"
End If
objResponseFile.Close

' Logging in the Event Viewer the response
If execResult = 0 Then
    'objShell.LogEvent 4, "Métrics sent to Datadog successfully. Respponse: " & strResponse
Else
    objShell.LogEvent 1, "Error sending the metrics using curl. Exit code: " & execResult & ". Resppose: " & strResponse
End If
'WScript.Echo "Métrics sent to Datadog successfully"
'WScript.Echo "Datadog response: " & strResponse

' Function to remove especial characters in JSON
Function EscapeJsonString(strInput)
    Dim strOutput, i, c, unicode
    strOutput = ""
    For i = 1 To Len(strInput)
        c = Mid(strInput, i, 1)
        Select Case AscW(c)
            Case 34 ' Quote
                strOutput = strOutput & "\"""
            Case 92 ' Backslash
                strOutput = strOutput & "\\"
            Case 8 ' Delete
                strOutput = strOutput & "\b"
            Case 12 ' Page break
                strOutput = strOutput & "\f"
            Case 10 ' Newline
                strOutput = strOutput & "\n"
            Case 13 ' Carriage return
                strOutput = strOutput & "\r"
            Case 9 ' Tab
                strOutput = strOutput & "\t"
            Case Else
                If AscW(c) >= 128 Then ' non-ASCII Characters
                    unicode = Hex(AscW(c))
                    strOutput = strOutput & "\u" & Right("0000" & unicode, 4)
                Else
                    strOutput = strOutput & c
                End If
        End Select
    Next
    EscapeJsonString = strOutput
End Function

' ============================
' *** Send logs to Datadog ***
' ============================

' Creating a log file
Set objTextFile = objFSO.CreateTextFile("C:\logs.json", True)

' Getting recent events from the Event Viewer
Dim colLogItems, objLogItem, logMessage, logJsonArray, logCount, maxLogs
maxLogs = 5 ' Limit to just the last 5 events (to avoid overflow)
logCount = 0
logJsonArray = ""

Set colLogItems = objWMIService.ExecQuery("SELECT * FROM Win32_NTLogEvent WHERE Logfile='System' AND TimeGenerated >= '" & FormatDateTime(DateAdd("n", -60, Now), 0) & "'")
For Each objLogItem in colLogItems
    If logCount < maxLogs Then
        ' Formatting the log message
		logMessage = objLogItem.Message
        If Len(logMessage) = 0 Then logMessage = "No menssage"
        logMessage = Replace(logMessage, vbCrLf, " ") ' removing newlines
        logMessage = EscapeJsonString(logMessage) ' removing special characters
        
        ' Gettng timestamp from the event
        Dim logTime, logTimestamp
        logTime = objLogItem.TimeGenerated

        ' Converting timestamp to Unix (WMI format: yyyymmddHHMMSS)
        Dim year, month, day, hour, minute, second
        year = Left(logTime, 4)
        month = Mid(logTime, 5, 2)
        day = Mid(logTime, 7, 2)
        hour = Mid(logTime, 9, 2)
        minute = Mid(logTime, 11, 2)
        second = Mid(logTime, 13, 2)
        logTime = year & "-" & month & "-" & day & " " & hour & ":" & minute & ":" & second
        logTimestamp = CLng(DateDiff("s", "1970-01-01 00:00:00", DateAdd("h", -timezoneOffset, logTime))) * 1000

        ' Creating the JSON for the log
        Dim logJson
        logJson = "{""ddsource"": ""windows.events"", ""service"": ""win2k3"", ""host"": """ & strComputer & """, ""message"": """ & logMessage & """, ""timestamp"": """ & logTimestamp & """, ""ddtags"": [""env:win2k3"", ""type:" & objLogItem.Type & """]}"
        
        ' Append log to array JSON
        If logCount > 0 Then
            logJsonArray = logJsonArray & ","
        End If
        logJsonArray = logJsonArray & logJson
        logCount = logCount + 1
    End If
Next

' Creating the final log JSON
strLogJson = "[" & logJsonArray & "]"

' Print JSON for debugging
'WScript.Echo "Generated JSON (logs): " & strLogJson

' Write JSON in the log file
objTextFile.WriteLine strLogJson
objTextFile.Close

' Creating curl command to send logs
strLogCurlCommand = "C:\curl\curl.exe -X POST -H ""Accept: application/json"" -H ""Content-Type: application/json"" -H ""DD-API-KEY: " & strAPIKey & """ --cacert C:\curl\curl-ca-bundle.crt --data @C:\logs.json " & strLogURL & " -o C:\curl_log_response.txt"

' Running curl command
execResult = objShell.Run(strLogCurlCommand, 0, True)

' Verifying curl command response
Set objResponseFile = objFSO.OpenTextFile("C:\curl_log_response.txt", 1, False)
If Not objResponseFile.AtEndOfStream Then
    strResponse = objResponseFile.ReadAll
Else
    strResponse = "Error: The log was not send"
End If
objResponseFile.Close

' Verifying response
If execResult = 0 Then
    'WScript.Echo "Logs sent to Datadog successfully"
Else
    WScript.Echo "Error sending logs using curl. Response code: " & execResult
End If
'WScript.Echo "Datadog Response (logs): " & strResponse
''''''''''''''''''''

' Cleaning objects
Set objFSO = Nothing
Set objTextFile = Nothing
Set objShell = Nothing
Set objWMIService = Nothing
Set colItems = Nothing
Set WShell = Nothing