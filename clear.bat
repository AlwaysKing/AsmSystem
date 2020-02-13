for  %%I in (%*) do (
    cd .\%%I\make\
    call clear.bat
    cd ..\..\ 
)