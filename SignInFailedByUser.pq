let
  Source = SignInLogs, 
  #"Expanded LocationDetails" = Table.ExpandRecordColumn(
    Source, 
    "LocationDetails", 
    {"countryOrRegion"}, 
    {"LocationDetails.countryOrRegion"}
  ), 
  #"Filtered Failed" = Table.SelectRows(#"Expanded LocationDetails", each [ResultType] <> "0"), 
  
  // Create dimension table that contains only ResultType, ResultDescription.
  #"Columns 1" = Table.SelectColumns(#"Filtered Failed", {"ResultType", "ResultDescription"}), 
  #"Removed duplicates" = Table.Distinct(#"Columns 1", {"ResultType"}), 
  #"DIMSignInResult" = #"Removed duplicates", 
  #"Columns 2" = Table.SelectColumns(
    #"Filtered Failed", 
    {
      "TimeGenerated", 
      "ResultType", 
      "LocationDetails.countryOrRegion", 
      "UserDisplayName", 
      "UserPrincipalName"
    }
  ), 
  #"Grouped rows" = Table.Group(
    #"Columns 2", 
    {"UserDisplayName", "UserPrincipalName", "ResultType"}, 
    {{"Count", each Table.RowCount(_), Int64.Type}}
  ), 
  #"Filtered Internal Users" = Table.SelectRows(
    #"Grouped rows", 
    each not Text.Contains([UserDisplayName], "-")
  ), 
  #"Filtered Anonymous Users" = Table.SelectRows(
    #"Grouped rows", 
    each Text.Contains([UserDisplayName], "-")
  ), 
  #"Columns 3" = Table.SelectColumns(#"Filtered Anonymous Users", {"ResultType", "Count"}), 
  
  // Sum all rows with various anonymous ids.
  #"Grouped by ResultType" = Table.Group(
    #"Columns 3", 
    {"ResultType"}, 
    {
      {"UserDisplayName", each "Unknown", type text}, 
      {"UserPrincipalName", each "Unknown", type text}, 
      {"Count", each List.Sum([Count]), type nullable number}
    }
  ), 
  #"Combined table" = Table.Combine({#"Filtered Internal Users", #"Grouped by ResultType"}), 
  #"Joined Table" = Table.NestedJoin(
    #"Combined table", 
    {"ResultType"}, 
    #"DIMSignInResult", 
    {"ResultType"}, 
    "DIMSignInResult", 
    JoinKind.LeftOuter
  ), 
  #"Expanded DIMSignInResult" = Table.ExpandTableColumn(
    #"Joined Table", 
    "DIMSignInResult", 
    {"ResultDescription"}, 
    {"ResultDescription"}
  ), 
  
  // Sum Count and serialize result descriptions.
  #"Grouped by User" = Table.Group(
    #"Expanded DIMSignInResult", 
    {"UserDisplayName", "UserPrincipalName"}, 
    {
      {"Count", each List.Sum([Count]), type nullable number}, 
      {"Reasons", each Text.Combine([ResultDescription], ", "), type text}
    }
  ), 
  #"Changed column type" = Table.TransformColumnTypes(#"Grouped by User", {{"Count", Int64.Type}}), 
  SignInFailedByUser = #"Changed column type"
in
  SignInFailedByUser