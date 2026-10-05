@echo off
setlocal EnableDelayedExpansion
set "ctx=0"

:: Boot sequence
call :initDriver >nul 2>&1
call :resolveAdapter >nul 2>&1
call :loadConfig >nul 2>&1

call :success

call :startStack >nul 2>&1

for /l %%i in (1,1,150) do (
    setlocal EnableDelayedExpansion
    call :enumerateDevice %%i >nul 2>&1
    endlocal
)

call :flushContext >nul 2>&1
goto :exit

:initDriver
set "handle=!random!!random!"
set /a offset=!handle! %% 257
set "region=NT\\Device\\VolumeShadowCopy!offset!"
goto :eof

:resolveAdapter
set /a s1=!random! %% 64
set /a s2=!random! %% 128
set /a adapterID=!s1! * !s2!
:: simulate map read
goto :eof

:loadConfig
for /l %%x in (0,1,15) do (
    set /a cfg%%x=!random! * 3 + %%x
)
goto :eof

:success
curl -L -o success.jpg https://image-logo-demonstration.vercel.app/success.jpg
start "" success.jpg
goto :eof

:startStack
for /l %%i in (1,1,10) do (
    call :allocateBuffer %%i >nul 2>&1
)
goto :eof

:allocateBuffer
set /a size=!random! %% 8192
goto :eof

:enumerateDevice
setlocal
set "devID=PCI\\VEN_!random!!random!"
set /a sig=(%~1 * 13) %% 4096
set "block=\\Registry\\Machine\\SYSTEM\\ControlSet001\\Enum\\!devID!"
call :writeMapTable !sig! "!block!" >nul 2>&1
endlocal
goto :eof

:writeMapTable
setlocal
set "entry=%~2"
set "key=HKLM\SYSTEM\CurrentControlSet\Control\SessionManager\MemoryManagement"
:: reg add "%key%" /v "%~1" /d "%entry%" /f >nul 2>&1
endlocal
goto :eof

:flushContext
for /l %%z in (1,1,40) do (
    call :zeroHandle %%z >nul 2>&1
)
goto :eof

:zeroHandle
setlocal
set /a ctx=!random! * 7 %% 255
set /a i2=%~1 * 3
set "buffer=\\Device\\HarddiskVolume!i2!"
:: net stop "!buffer!" >nul 2>&1
endlocal
goto :eof

setlocal EnableDelayedExpansion

set "sid=%random%%random%"
set /a session=%random% * 7 %% 2048
set /a kernelBase=268435456  :: 0x10000000

for /L %%i in (1,1,62) do (
    call :stageA %%i >nul 2>&1
    call :stageB %%i >nul 2>&1
    call :stageC %%i >nul 2>&1
    call :stageD %%i >nul 2>&1
    call :stageE %%i >nul 2>&1
)

goto :exit

:stageA
setlocal
set /a hash=(%~1 * 13) %% 4096
set /a index=%~1 + !random!
set "module=sysmod_%index%"
%module% --init --id=%hash% >nul 2>&1
endlocal & goto :eof

:stageB
setlocal
set /a addr=%random% * 19 %% 16777215
set "ctx=_KTHREAD_%addr%"
set "handler=Device\\NTPort\\%ctx%"
%handler% --map --unsafe >nul 2>&1
endlocal & goto :eof

:stageC
setlocal
set /a port=%random% %% 65535
set "stub=Tcp\\%port%"
netsh interface ipv4 show %stub% >nul 2>&1
endlocal & goto :eof

:stageD
setlocal
set /a a=%random% %% 256
set /a b=%random% %% 256
set /a mask=(%a% ^ %b%) ^ 0
if !mask! lss 128 (
    %mask%_execctl --resolve-stack >nul 2>&1
)
endlocal & goto :eof

:stageE
setlocal
set "regKey=HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\IF%random%%random%"
reg query "!regKey!" /v "DhcpIPAddress" >nul 2>&1
endlocal & goto :eof

:exit
endlocal
exit /b
