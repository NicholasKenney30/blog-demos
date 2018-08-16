Param (
    [String]$List = "LookUp.csv",
    [String]$Files = ".\Files\*.*"
)
$ReplacementList = Import-Csv $List -Delimiter '|';
Get-ChildItem $Files -Recurse |
ForEach-Object {
    $Content = Get-Content -Path $_.FullName;
    foreach ($ReplacementItem in $ReplacementList)
    {
        $Content = $Content.Replace($ReplacementItem.OldValue, $ReplacementItem.NewValue)
    }
    Set-Content -Path $_.FullName -Value $Content
}
