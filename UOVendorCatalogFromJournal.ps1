$journal = gci "C:\Program Files (x86)\Ultima Online Outlands\ClassicUO\Data\Client\JournalLogs\" | select -last 1 | gc
#$journal = gc "C:\Program Files (x86)\Ultima Online Outlands\ClassicUO\Data\Client\JournalLogs\2023_02_08_18_45_23_journal.txt"

$catalogStarted = $false
$vendorCatalog = [System.Collections.ArrayList]::new()
$vendor = [pscustomobject]@{
    Name = ""
    Items = [System.Collections.ArrayList]::new()
}

for($index=0;$index -lt $journal.Length;$index++){
    if($journal[$index] -like "*START CATALOGUE*"){
        write-host $journal[$index]
        $catalogStarted = $true
    } elseif($journal[$index] -like "*DONE CATALOGUE*"){
        write-host $journal[$index]
        $catalogStarted = $false
    } 

    if($catalogStarted){
        if($journal[$index] -like "*Razor: Target:*" -and $journal[$index+1] -like "*NEW VENDOR*"){
            if($vendor.Items.Count -gt 0){
                $vendor.Items = $vendor.Items | sort Price -Descending
                $vendorCatalog.Add($vendor) >> $null
            }
            $lineSplit = $journal[$index].Split()
            $vendor = [pscustomobject]@{
                Name = $lineSplit[5..$lineSplit.Length] -join " "
                Items = [System.Collections.ArrayList]::new()
            }
        } elseif($vendor.Name){
            if($journal[$index] -like "*Price:*"){
                $lineSplit = $journal[$index].Split()
                $price = $lineSplit[5]
                $nameAmount = $lineSplit[6..$lineSplit.Length] -join " "
                $nameAmount = $nameAmount.Split('(')[0]

                $lineSplit = $nameAmount.Split(':')
                $amount = 0
                $itemName = ""
                if(-not [int]::TryParse($lineSplit[$lineSplit.Length-1],[ref]$amount)){
                    $amount = 1
                    $itemName = $lineSplit -join " "
                } else {
                    $itemName = $lineSplit[0..($lineSplit.Length-2)] -join " "
                }
                
                $vendorItemEntry = [pscustomobject]@{
                    Item = $itemName
                    Price = $price
                    Amount = $amount
                    PricePer = [Math]::Round($price/$amount)
                }
                $vendor.Items.Add($vendorItemEntry) >> $null
            }
        }
    }
}

if($vendor.Items.Count -gt 0){
    $vendor.Items = $vendor.Items | sort Price -descending
    $vendorCatalog.Add($vendor) >> $null
}

foreach($vendor in $vendorCatalog){
    write-host "VENDOR NAME:" $vendor.Name
    $uniqueItems = $vendor.Items | % Item | get-unique
    $uniqueItems | % {
        $uniqueItem = $_
        $lowestPrice = $vendor.Items | ? Item -like $uniqueItem | sort PricePer | select -first 1 | % PricePer
        $uniqueItemAmount = $vendor.Items | ? Item -like $uniqueItem | Measure-Object Amount -Sum | % Sum
        [pscustomobject]@{
            Item = $uniqueItem
            LowestPrice = $lowestPrice
            Amount = $uniqueItemAmount
        } 
    } | format-table @{e='Item'; width=50}, @{e='LowestPrice'; width=11}, @{e='Amount'; width=6}
}

$uniqueItems = [System.Collections.ArrayList]::new()
foreach($vendor in $vendorCatalog){
    $vendor.Items | % Item | get-unique | % {
        $uniqueItems.Add($_) >> $null
    }
}

$uniqueItems | sort | get-unique