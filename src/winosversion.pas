unit winosversion;

interface
uses versionhelpers;

type
  TWin32OSType = (
    osUnknown,          // Unknown OS
    osWin32s,           // Win32s
    osWin95,            // Windows 95
    osWin95OSR2,        // Windows 95 OEM Service Release 2
    osWin98,            // Windows 98
    osWin98SE,          // Windows 98 Second Edition
    osWinMe,            // Windows Me
    osWinNT3Workstation,// Windows NT 3.0 Workstation
    osWinNT3Server,     // Windows NT 3.0 Server
    osWinNT4Workstation,// Windows NT 4.0 Workstation
    osWinNT4Server,     // Windows NT 4.0 Server
    osWin2000Workstation,// Windows 2000 Workstation
    osWin2000Server,    // Windows 2000 Server
    osWinXP,            // Windows XP
    osWinServer2003,    // Windows Server 2003
    osWinServer2003R2,  // Windows Server 2003 R2
    osWinVista,         // Windows Vista
    osWinServer2008,    // Windows Server 2008
    osWinServer2008R2,  // Windows Server 2008 R2
    osWin7,             // Windows 7
    osWinServer2012,    // Windows Server 2012
    osWin8,             // Windows 8
    osWinServer2012R2,  // Windows Server 2012 R2
    osWin8Point1,       // Windows 8.1
    osWin10,            // Windows 10
    osWinServer2016     //not released yet
  );
  TWin32NTType = (Unknown, NotApplicable, Workstation, Server, AdvancedServer);
  TWin32OSVersion = class(TObject)
  protected
    FOSType : TWin32OSType;
    FExtendedInfo : Boolean;
    FIsMediaCenter : Boolean;
    FIsStarterEdition : Boolean;
    FMajorVersion : Cardinal;
    FMinorVersion : Cardinal;
    FPlatformId : Cardinal;
    FSuiteMask : Word;
    FBuildNumber : Cardinal;
    FProductType : Byte;
    FProcessorArchitecture : Word;
    function Check(const AMajorVersion, AMinorVersion : Cardinal) : Boolean;
    function GetIsWOW64 : Boolean;

  public
    Constructor Create;
    function GetNTType : TWin32NTType;
    function EditionStr : String;
    function IsMediaCenter : Boolean;
    function IsStarterEdition : Boolean;
    property BuildNumber : Cardinal read FBuildNumber;
    property MajorVersion : Cardinal read FMajorVersion;
    property MinorVersion : Cardinal read FMinorVersion;
    property PlatformID : Cardinal read  FPlatformID;
    property SuiteMask : Word read FSuiteMask;
    property ProductType : Byte read FProductType;
    property IsWOW64 : Boolean read GetIsWOW64;
    property ProcessorArchitecture : Word read FProcessorArchitecture;
  end;

implementation
uses Windows, Registry, SysUtils;

constructor TWin32OSVersion.Create;
var
  LOSVE : TOSVersionInfoEx;
  LOSV : TOSVersionInfo absolute LOSVE;
  LP : versionhelpers._SYSTEM_INFO;
begin
  FillChar(LOSVE, SizeOf(TOSVersionInfoEx), 0);
  LOSVE.dwOSVersionInfoSize := SizeOf(TOSVersionInfoEx);
  FExtendedInfo := GetVersionEx(LOSVE);
  if not FExtendedInfo then begin
    LOSV.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
    GetVersionEx(LOSV);
  end;
  FMajorVersion := LOSV.dwMajorVersion;
  FMinorVersion := LOSV.dwMinorVersion;
  FPlatformId := LOSV.dwPlatformId;
  case FPlatformID of
    VER_PLATFORM_WIN32s : begin
      FOSType := osWin32s;
    end;
    VER_PLATFORM_WIN32_WINDOWS :
    begin
      FBuildNumber := LOSV.dwBuildNumber and $FFFF;
       if FMinorVersion >= 90 then begin
          FOSType := osWinMe;
        end else begin
         if FBuildNumber >= 10 then begin
            {Windows 98}
            if FBuildNumber >= 2222 then begin
              FOSType := osWin98SE
            end else begin
              FOSType := osWin98;
            end;
          end else begin {Windows 95}
            if FBuildNumber >= 1000 then begin
              FOSType := osWin95OSR2
            end else begin
              FOSType := osWin95;
            end;
          end;
        end;
    end;
    VER_PLATFORM_WIN32_NT :
    begin
      FBuildNumber  := LOSV.dwBuildNumber;
      if FExtendedInfo then  begin
        FSuiteMask := LOSVE.wSuiteMask;
        FProductType := LOSVE.wProductType;
      end;
      if Check(5,1) then begin
        VersionHelpers.GetNativeSystemInfo(LP);
        FProcessorArchitecture := LP.wProcessorArchitecture;
      end;
      {Note:

      In these case statements, I use the value of $FFFFFFFF to try
      to get something equivilant to a Greater than.  This is to prevent breaking
      on subsequent versions of the Windows Operating Systems. }
      case Self.FMajorVersion of
        6..$FFFFFFFF :
        begin
          case FMinorVersion of
            0 : begin
                  if ProductType = VER_NT_WORKSTATION then
                    FOSType := osWinVista
                  else
                    FOSType := osWinServer2008;
                end;
            1 : begin
                  if ProductType = VER_NT_WORKSTATION then
                    FOSType := osWin7
                  else
                    FOSType := osWinServer2008R2;
                end;
            2..$FFFFFFFF :
                begin
                  if IsWindows10OrGreater then begin
                    FMajorVersion := $A;
                    FMinorVersion := 0;
                    if IsWindowsServer then begin
                      FOSType := osWin10;
                    end else begin
                      FOSType := osWinServer2016;
                    end;
                  end else begin
                    if VersionHelpers.IsWindows8Point1OrGreater then begin
                      FMajorVersion := 6;
                      FMinorVersion := 3;
                      if FProductType = VER_NT_WORKSTATION then
                        FOSType := osWin8Point1
                      else
                        FOSType := osWinServer2012R2;
                    end else begin
                      if FProductType = VER_NT_WORKSTATION then
                        FOSType := osWin8
                      else
                        FOSType := osWinServer2012;
                    end;
                  end;
                end;
          end;
        end;
        5 :
        begin
          case FMinorVersion of
            2..$FFFFFFFF :
                begin
                  if GetSystemMetrics(SM_SERVERR2) <> 0 then
                    FOSType := osWinServer2003R2
                  else
                    FOSType := osWinServer2003;
                end;
            1 : begin
                  FOSType := osWinXP;
                end;
            0 : begin
                  if GetNTType in [Server, AdvancedServer] then
                    FOSType := osWin2000Server
                  else
                    FOSType := osWin2000Workstation;
                end;
          end;
        end;
        4 :
        begin
          if Self.GetNTType in [Server, AdvancedServer] then
            FOSType := osWinNT4Server
          else
            FOSType := osWinNT4Workstation;
        end;
        3 :
        begin
          if Self.GetNTType in [Server, AdvancedServer] then
            FOSType := osWinNT3Server
          else
            FOSType := osWinNT3Workstation;
        end;
      else
        FOSType := osUnknown;
      end;
    end;
  end;
end;

function TWin32OSVersion.GetNTType : TWin32NTType;
var
  Reg: TRegistry;
  LProductType: string;
begin
  Result := Unknown;
  if FExtendedInfo then begin
    case ProductType of
      VER_NT_SERVER, VER_NT_DOMAIN_CONTROLLER : Result := Server;
      VER_NT_WORKSTATION : Result := Workstation;
    end;
    exit;
  end;
  if Self.FPlatformId <> VER_PLATFORM_WIN32_NT then
  begin
    Result := NotApplicable;
    exit;
  end;

  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly(
      'SYSTEM\CurrentControlSet\Control\ProductOptions'
    ) then
    begin
      LProductType := Reg.ReadString('ProductType');
      if SameText(LProductType, 'WINNT') then
        Result := Workstation
      else if SameText(LProductType, 'LANMANNT') then
        Result := Server
      else if SameText(LProductType, 'SERVERNT') then
        Result := AdvancedServer;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;

end;

function TWin32OSVersion.IsMediaCenter : Boolean;
begin
  Result := Windows.GetSystemMetrics(SM_MEDIACENTER) <> 0;
end;

function TWin32OSVersion.IsStarterEdition : Boolean;
begin
  Result := Windows.GetSystemMetrics(SM_STARTER) <> 0;
end;

function TWin32OSVersion.EditionStr : String;
var LType : Cardinal;
begin
  Result := '';
  case FMajorVersion of
    5 : begin
          case FMinorVersion of
            0 : begin
                  if (ProductType = VER_NT_WORKSTATION) then
                  begin
                    Result := 'Professional';
                  end else begin
                    if (FSuiteMask and VER_SUITE_DATACENTER > 0) then begin
                      Result := 'Datacenter Server';
                    end else begin
                      if (FSuiteMask and VER_SUITE_ENTERPRISE > 0) then begin
                        Result := 'Advanced Server';
                      end else begin
                        Result := 'Server';
                      end;
                    end;
                  end;
                end;
            1 : begin
                  if FSuiteMask and VER_SUITE_PERSONAL > 0 then begin
                    Result := 'Home Edition';
                  end else begin
                    Result := 'Professional';
                  end;
                end;
            2 : begin
                   if ( FProductType <> VER_NT_WORKSTATION ) then begin
                     case FProcessorArchitecture of
                       PROCESSOR_ARCHITECTURE_IA64 :
                       begin
                         if (FSuiteMask and VER_SUITE_DATACENTER > 0 ) then begin
                           Result := 'Datacenter Edition for Itanium-based Systems';
                         end else begin
                           if (FSuiteMask and VER_SUITE_ENTERPRISE > 0) then  begin
                             Result := 'Enterprise Edition for Itanium-based Systems';
                           end;
                         end;
                       end;
                       PROCESSOR_ARCHITECTURE_AMD64 :
                       begin
                         if FSuiteMask and VER_SUITE_DATACENTER > 0 then begin
                            Result := 'Datacenter x64 Edition';
                         end else begin
                           if SuiteMask and VER_SUITE_ENTERPRISE > 0 then begin
                             Result := 'Enterprise x64 Edition';
                           end else begin
                             Result := 'Standard x64 Edition';
                           end;
                         end;
                       end;
                     else
                       if SuiteMask and VER_SUITE_COMPUTE_SERVER > 0 then begin
                         Result := 'Compute Cluster Edition';
                       end else begin
                         if SuiteMask and VER_SUITE_DATACENTER > 0 then begin
                            Result := 'Datacenter Edition';
                         end else begin
                            if SuiteMask and VER_SUITE_ENTERPRISE > 0 then begin
                              Result := 'Enterprise Edition';
                            end else begin
                              if SuiteMask and VER_SUITE_BLADE > 0 then begin
                                Result := 'Web Edition';
                              end else begin
                                Result := 'Standard Edition';
                              end;
                            end;
                         end;
                       end;
                     end;
                   end;
                end;
          end;
        end;
    4,3 : begin
           case Self.GetNTType of
             Server :
             begin
               Result := 'Server';
             end;
             AdvancedServer :
             begin
               Result := 'Advanced Server';
             end;
             Workstation :
             begin
               Result := 'Workstation';
             end;
           end;
         end;
  end;
  if Check(6, 0) then begin
    if GetProductInfo( FMajorVersion, FMinorVersion, 0, 0, LType) then begin
      case LType of
        PRODUCT_UNDEFINED : Result := 'Undefined';

        PRODUCT_ULTIMATE  : Result := 'Ultimate';
        PRODUCT_HOME_BASIC : Result := 'Home Basic';
        PRODUCT_HOME_PREMIUM : Result := 'Home Premium';
        PRODUCT_ENTERPRISE : Result := 'Enterprise';
        PRODUCT_HOME_BASIC_N : Result := 'Home Basic N';
        PRODUCT_BUSINESS : Result := 'Business';
        PRODUCT_STANDARD_SERVER : Result := 'Server Standard';
        PRODUCT_DATACENTER_SERVER : Result := 'Server Datacenter (full installation)';
        PRODUCT_SMALLBUSINESS_SERVER : Result := 'Windows Small Business Server';
        PRODUCT_ENTERPRISE_SERVER : Result := 'Server Enterprise (full installation)';
        PRODUCT_STARTER : Result := 'Starter';
        PRODUCT_DATACENTER_SERVER_CORE : Result := 'Server Datacenter (core installation)';
        PRODUCT_STANDARD_SERVER_CORE : Result := 'Server Standard (core installation)';
        PRODUCT_ENTERPRISE_SERVER_CORE : Result := 'Server Enterprise (core installation)';
        PRODUCT_ENTERPRISE_SERVER_IA64 : Result := 'Server Enterprise for Itanium-based Systems';
        PRODUCT_BUSINESS_N : Result := 'Business N';
        PRODUCT_WEB_SERVER : Result := 'Web Server (full installation)';
        PRODUCT_CLUSTER_SERVER : Result := 'HPC Edition';
        PRODUCT_HOME_SERVER : Result := 'Windows Storage Server 2008 R2 Essentials';
        PRODUCT_STORAGE_EXPRESS_SERVER : Result := 'Storage Server Express';
        PRODUCT_STORAGE_STANDARD_SERVER : Result := 'Storage Server Standard';
        PRODUCT_STORAGE_WORKGROUP_SERVER : Result := 'Storage Server Workgroup';
        PRODUCT_STORAGE_ENTERPRISE_SERVER : Result := 'Storage Server Enterprise';
        PRODUCT_SERVER_FOR_SMALLBUSINESS : Result := 'Windows Server 2008 for Windows Essential Server Solutions';
        PRODUCT_SMALLBUSINESS_SERVER_PREMIUM : Result := 'Small Business Server Premium';
        PRODUCT_HOME_PREMIUM_N : Result := 'Home Premium N';
        PRODUCT_ENTERPRISE_N : Result := 'Enterprise N';
        PRODUCT_ULTIMATE_N : Result := 'Ultimate N';
        PRODUCT_WEB_SERVER_CORE : Result := 'Web Server (core installation)';
        PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT : Result := 'Windows Essential Business Server Management Server';
        PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY  : Result := 'Windows Essential Business Server Security Server';
        PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING : Result := 'Windows Essential Business Server Messaging Server';
        PRODUCT_SERVER_FOUNDATION : Result := 'Server Foundation';
        PRODUCT_HOME_PREMIUM_SERVER : Result := 'Windows Home Server 2011';
        PRODUCT_SERVER_FOR_SMALLBUSINESS_V : Result := 'Windows Server 2008 without Hyper-V for Windows Essential Server Solutions';
        PRODUCT_STANDARD_SERVER_V : Result := 'Server Standard without Hyper-V';
        PRODUCT_DATACENTER_SERVER_V : Result := 'Server Datacenter without Hyper-V (full installation)';
        PRODUCT_ENTERPRISE_SERVER_V : Result := 'Server Enterprise without Hyper-V (full installation)';
        PRODUCT_DATACENTER_SERVER_CORE_V : Result := 'Server Datacenter without Hyper-V (core installation)';
        PRODUCT_STANDARD_SERVER_CORE_V : Result := 'Server Standard without Hyper-V (core installation)';
        PRODUCT_ENTERPRISE_SERVER_CORE_V : Result := 'Server Enterprise without Hyper-V (core installation)';
        PRODUCT_HYPERV : Result := 'Microsoft Hyper-V Server';
        PRODUCT_STORAGE_EXPRESS_SERVER_CORE : Result := 'Storage Server Express (core installation)';
        PRODUCT_STORAGE_STANDARD_SERVER_CORE : Result := 'Storage Server Standard (core installation)';
        PRODUCT_STORAGE_WORKGROUP_SERVER_CORE : Result := 'Storage Server Workgroup (core installation)';
        PRODUCT_STORAGE_ENTERPRISE_SERVER_CORE : Result := 'Storage Server Enterprise (core installation)';
        PRODUCT_STARTER_N : Result := 'Starter N';
        PRODUCT_PROFESSIONAL : Result := 'Professional';
        PRODUCT_PROFESSIONAL_N : Result := 'Professional N';
        PRODUCT_SB_SOLUTION_SERVER : Result := 'Windows Small Business Server 2011 Essentials';
        PRODUCT_SERVER_FOR_SB_SOLUTIONS : Result := 'Server For SB Solutions';
        PRODUCT_STANDARD_SERVER_SOLUTIONS : Result := 'Standard Server Solutions';
        PRODUCT_STANDARD_SERVER_SOLUTIONS_CORE : Result := 'Standard Server Solutions (core installation)"';
        PRODUCT_SB_SOLUTION_SERVER_EM : Result := 'Server For SB Solutions EM';
        PRODUCT_SERVER_FOR_SB_SOLUTIONS_EM : Result := 'Server For SB Solutions EM';
        PRODUCT_SOLUTION_EMBEDDEDSERVER   : Result := 'Solution Embedded Server';
        PRODUCT_SOLUTION_EMBEDDEDSERVER_CORE : Result := 'Solution Embedded Server (core installation)';
        PRODUCT_PROFESSIONAL_EMBEDDED : Result := 'Professional Embedded';
        PRODUCT_ESSENTIALBUSINESS_SERVER_MGMT  : Result := 'Windows Essential Server Solution Management';
        PRODUCT_ESSENTIALBUSINESS_SERVER_ADDL : Result := 'Windows Essential Server Solution Additional';
        PRODUCT_ESSENTIALBUSINESS_SERVER_MGMTSVC : Result := 'Windows Essential Server Solution Management SVC';
        PRODUCT_ESSENTIALBUSINESS_SERVER_ADDLSVC : Result := 'Windows Essential Server Solution Additional SVC';
        PRODUCT_SMALLBUSINESS_SERVER_PREMIUM_CORE : Result := 'Small Business Server Premium (core installation';
        PRODUCT_CLUSTER_SERVER_V : Result := 'Server Hyper Core V';
        PRODUCT_EMBEDDED : Result := 'Embedded';
        PRODUCT_STARTER_E,
        PRODUCT_HOME_BASIC_E,
        PRODUCT_HOME_PREMIUM_E,
        PRODUCT_PROFESSIONAL_E,
        PRODUCT_ENTERPRISE_E,
        PRODUCT_ULTIMATE_E : Result := 'Not Supported';

        PRODUCT_ENTERPRISE_EVALUATION : Result := 'Server Enterprise (evaluation installation)';
        PRODUCT_MULTIPOINT_STANDARD_SERVER : Result := 'Windows MultiPoint Server Standard (full installation)';
        PRODUCT_MULTIPOINT_PREMIUM_SERVER  : Result := 'Windows MultiPoint Server Premium (full installation)';
        PRODUCT_STANDARD_EVALUATION_SERVER : Result := 'Server Standard (evaluation installation)';
        PRODUCT_DATACENTER_EVALUATION_SERVER : Result := 'Server Datacenter (evaluation installation)';
        PRODUCT_ENTERPRISE_N_EVALUATION : Result := 'Enterprise N (evaluation installation)';
        PRODUCT_EMBEDDED_AUTOMOTIVE : Result := 'Unknown PRODUCT_EMBEDDED_AUTOMOTIVE';
        PRODUCT_EMBEDDED_INDUSTRY_A : Result := 'Unknown PRODUCT_EMBEDDED_INDUSTRY_A';
        PRODUCT_THINPC  : Result := 'Unknown PRODUCT_THINPC';
        PRODUCT_EMBEDDED_A : Result := 'Unknown PRODUCT_EMBEDDED_A';
        PRODUCT_EMBEDDED_INDUSTRY  : Result := 'Unknown PRODUCT_EMBEDDED_INDUSTRY';
        PRODUCT_EMBEDDED_E : Result := 'Unknown PRODUCT_EMBEDDED_E';
        PRODUCT_EMBEDDED_INDUSTRY_E : Result := 'Unknown PRODUCT_EMBEDDED_INDUSTRY_E';
        PRODUCT_EMBEDDED_INDUSTRY_A_E : Result := 'Unknown PRODUCT_EMBEDDED_INDUSTRY_A_E';
        PRODUCT_STORAGE_WORKGROUP_EVALUATION_SERVER : Result := 'Storage Server Workgroup (evaluation installation)';
        PRODUCT_STORAGE_STANDARD_EVALUATION_SERVER : Result := 'Storage Server Standard (evaluation installation)';
        PRODUCT_CORE_ARM : Result := 'Definition not found';
        PRODUCT_CORE_N : Result := 'Windows 8 N';
        PRODUCT_CORE_COUNTRYSPECIFIC : Result := 'Windows 8 China';
        PRODUCT_CORE_SINGLELANGUAGE : Result := 'Windows 8 Single Language';
        PRODUCT_CORE : Result := 'Windows 8';
        PRODUCT_PROFESSIONAL_WMC : Result := 'Professional with Media Center';
{
        PRODUCT_MOBILE_CORE                        = $00000068;
        PRODUCT_EMBEDDED_INDUSTRY_EVAL             = $00000069;
        PRODUCT_EMBEDDED_INDUSTRY_E_EVAL           = $0000006A;
        PRODUCT_EMBEDDED_EVAL                      = $0000006B;
        PRODUCT_EMBEDDED_E_EVAL                    = $0000006C;
        PRODUCT_CORE_SERVER                        = $0000006D;
        PRODUCT_CLOUD_STORAGE_SERVER               = $0000006E;

        PRODUCT_UNLICENSED                         = $ABCDABCD;
         }
      end;
    end;
  end;
end;

function TWin32OSVersion.GetIsWOW64 : Boolean;
var LRes : BOOL;
begin
   VersionHelpers.IsWow64Process(GetCurrentProcess,LRes);
   Result := LRes;
end;

function TWin32OSVersion.Check(const AMajorVersion, AMinorVersion : Cardinal) : Boolean;
begin
  Result := FMajorVersion = AMajorVersion;
  if Result then
     Result := (FMajorVersion >= AMinorVersion)
  else
    Result := FMajorVersion > AMajorVersion;
end;

end.
