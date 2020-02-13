for  %%I in (%*) do (
    cd .\%%I\make\
    call make.bat
    cd ..\..\ 
)