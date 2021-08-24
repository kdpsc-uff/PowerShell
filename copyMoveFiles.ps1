<# 
                                
This is my first PowerShell script, created on 2020-10-23.
So, it shouldn't be anything extraordinary.

This  script was  made to copy  files  released in a folder  as output from  an application to a
storage disk and then move them to a network maping where these files are consumed by a service.

It should run as an hourly scheduled task and should not find many files in its executions, this
is not an optimal algorithm, it will consume CPU and disk IO, so it should not be used for large
amounts of files.

Respectively the  files are outputing in D:\<path-to-files> and are copied to E:\<path-to-files>
and after  copied  they are moved  from D:\<path-to-files>  to F:\<path-to-files> where they are 
consumed by an service of application.

The  mapped network share  (F:\) uses a user  that must exist  at the base of the AD or existing 
such as a local user on the machine and must be the owner of the share. 

#>

param($credUser, $credPass)

function controller
{
    function model($src, $dest, $comm)
    {
        function testHash($orig, $dest)
        {
            $hashOrig = (Get-Filehash "$orig" -Algorithm MD5).Hash
            $hashDest = (Get-Filehash "$dest" -Algorithm MD5).Hash
            
            if ($hashOrig -ne $hashDest)
            {
                echo "The MD5 sum of file $orig is $hashOrig." 1>> "$logfile"
                echo "The MD5 sum of file $dest is $hashDest." 1>> "$logfile"
                echo "The MD5 sum of file $orig and $dest aren't equals!"`n`n 1>> "$logFile"
                exit
            }
            else
            {
                echo "The MD5 sum of file $orig is $hashOrig." 1>> "$logfile"
                echo "The MD5 sum of file $dest is $hashDest." 1>> "$logfile"
                echo "The MD5 sum of file $orig and $dest are equals."`n`n 1>> "$logFile"
            }
        }
        
        $logFile = "C:\<path-to-scripts>\copyMoveFiles.log"

        $hoursNow = Get-Date -Format "yyyy/MM/dd HH:mm"
        
        $pathFiles = Get-ChildItem -Path "$src" | Select-Object -ExpandProperty FullName
		
        ForEach($pathFile in $pathFiles)
        {
            $lastFile = "$pathFile" | %{ $_.Split('\')[3]; }

            if(!(Test-Path -Path $dest\$lastFile))
            {
                if ("$comm".equals('copy'))
                {
                    Try
                    {
                        Copy-Item -Path "$pathFile" -Destination "$dest"
                        echo "Copy file $lastFile success at $hoursNow"`n`n 1>> "$logFile"
                        testHash $pathFile $dest\$lastFile
                    } 
                    Catch
                    {
                        echo "Copy file error at $hoursNow"`n`n 1>> "$logFile"
                        exit
                    }
                } 
                elseif ("$comm".equals('move'))
                {
                    Try
                    {
                        Move-Item -Path "$pathFile" -Destination "$dest"
                        echo "Move file $lastFile success at $hoursNow"`n`n 1>> "$logFile"
                        testHash E:\<path-to-files>\$lastfile $dest\$lastFile
                    } 
                    Catch
                    {
                        echo "Move file error at $hoursNow"`n`n 1>> "$logFile"
                        exit
                    }
                }					   
            }
        }
    }
    
    $pathOrig = "D:\<path-to-files>"
    $pathCopy = "E:\<path-to-files>"
    $pathDest = "F:\<path-to-files>"
    
    if(Test-Path -Path "$pathDest")
    {
        model "$pathOrig" "$pathCopy" "copy"
        model "$pathOrig" "$pathDest" "move"
    }
    else
    {
        Try
        {
            $net = new-object -ComObject WScript.Network
            $net.MapNetworkDrive("F:", "\\<host>\<shared-dir>", "$false", "$credUser", "$credPass")
            
            echo "mount shared success at $hoursNow" 1>> "$logFile"
            
            model "$pathOrig" "$pathCopy" "copy"
            model "$pathOrig" "$pathDest" "move"
        }
        Catch
        {
            echo "Mount shared error at $hoursNow" 1>> "$logFile"
            exit
        }
    }
}

function main
{
   controller 
}

main
