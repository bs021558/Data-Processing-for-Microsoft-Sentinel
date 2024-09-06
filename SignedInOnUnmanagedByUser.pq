let
  Sourch = SignInLogs,
  #"Expanded DeviceDetail" = Table.ExpandRecordColumn(
    Source,
    "DeviceDetail",
    {"isManaged"},
    {"DeviceDetail.isManaged"}
  ),
  #"Filtered rows" = Table.SelectRows(
    #"Expanded DeviceDetail",
    each [DeviceDetail.isManaged] <> true and [ResultType] = "0"
  ),
  #"Choose columns" = Table.SelectColumns(
    #"Filtered rows",
    {
      "TimeGenerated",
      "AppDisplayName",
      "UserDisplayName",
      "UserPrincipalName"
    }
  ),
  #"Grouped rows" = Table.Group(
    #"Choose columns",
    {"UserDisplayName", "UserPrincipalName"},
    {
      {"UsedApps", each List.Distinct([AppDisplayName]), type list},
      {"Count", each Table.RowCount(_), Int64.Type},
      {"LastSignedIn", each List.Max([TimeGenerated]), type datetime}
    }
  ),
  #"ChangedColumnType" = Table.TransformColumns(
    #"Grouped rows",
    {"UsedApps", each Text.Combine(_, ", "), type text}
  ),
  #"Sorted rows" = Table.Sort(#"ChangedColumnType", {{"Count", Order.Descending}}),
  SignedInOnUnmanagedByUser = #"Sorted rows"
in
  SignedInOnUnmanagedByUser