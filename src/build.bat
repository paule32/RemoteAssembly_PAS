rm -rf tmp
mkdir  tmp
fpc -FiC:\FPC\3.2.2\units\x86_64-win64\fv ^
    -FU.\tmp ^
    -Mdelphi ^
    -O2 -Os -Sc -Se4 -Si -Sm ^
    -Twin64 -WC -WN ^
    -Xs -XX ^
    asmJIT.pas
