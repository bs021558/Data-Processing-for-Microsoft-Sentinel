let
  Source = SignInLogs, 
  #"Filtered rows" = Table.SelectRows(
    Source, 
    each (
      Time.Hour(DateTime.Time([TimeGenerated])) >= 21
      or Time.Hour(DateTime.Time([TimeGenerated])) < 6
    )
    and [ResultType] = "0"
  ), 
  #"Choose columns" = Table.SelectColumns(
    #"Filtered rows", 
    {"TimeGenerated", "UserDisplayName", "UserPrincipalName"}
  ), 
  #"Changed column type" = Table.AddColumn(
    #"Choose columns", 
    "Date", 
    each Date.From([TimeGenerated])
  ), 
  #"Choose columns 1" = Table.SelectColumns(
    #"Changed column type", 
    {"UserDisplayName", "UserPrincipalName", "Date"}
  ), 
  #"Removed duplicates" = Table.Distinct(#"Choose columns 1", {"Date", "UserDisplayName"}), 
  DailySignedInOffHoursByUser = #"Removed duplicates"
in
  DailySignedInOffHoursByUser