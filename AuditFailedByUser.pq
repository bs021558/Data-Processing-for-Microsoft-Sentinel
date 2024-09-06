let
  Source = AuditLogs, 
  #"Filtered rows" = Table.SelectRows(
    Source, 
    each [Result] <> "success" and not Text.Contains([ResultDescription], "Exception")
  ), 
  #"Parsed JSON" = Table.TransformColumns(
    #"Filtered rows", 
    {
      {"InitiatedBy", each Json.Document(_), type record}, 
      {"TargetResources", each Json.Document(_){0}, type record}
    }
  ), 
  #"Expanded InitiatedBy" = Table.ExpandRecordColumn(
    #"Parsed JSON", 
    "InitiatedBy", 
    {"user", "app"}, 
    {"InitiatedBy.user", "InitiatedBy.app"}
  ), 
  #"Expanded InitiatedBy.user" = Table.ExpandRecordColumn(
    #"Expanded InitiatedBy", 
    "InitiatedBy.user", 
    {"displayName", "id", "userPrincipalName", "ipAddress"}, 
    {"user.displayName", "user.id", "user.userPrincipalName", "user.ipAddress"}
  ), 
  #"Expanded InitiatedBy.app" = Table.ExpandRecordColumn(
    #"Expanded InitiatedBy.user", 
    "InitiatedBy.app", 
    {"appId", "displayName", "servicePrincipalId", "servicePrincipalName"}, 
    {"app.appId", "app.displayName", "app.servicePrincipalId", "app.servicePrincipalName"}
  ), 
  #"Expanded TargetResources" = Table.ExpandRecordColumn(
    #"Expanded InitiatedBy.app", 
    "TargetResources", 
    {"id", "displayName", "type", "userPrincipalName"}, 
    {
      "TargetResource.id", 
      "TargetResource.displayName", 
      "TargetResource.type", 
      "TargetResource.userPrincipalName"
    }
  ), 
  // Group and sort by time in each groups and keep them
  #"Choose columns" = Table.SelectColumns(
    #"Expanded TargetResources", 
    {
      "TimeGenerated", 
      "OperationName", 
      "user.userPrincipalName", 
      "app.displayName", 
      "TargetResource.displayName", 
      "TargetResource.userPrincipalName"
    }
  ), 
  GroupedTable = Table.Group(
    #"Choose columns", 
    {"user.userPrincipalName"}, 
    {
      {"rowsbyuser", each Table.Sort(_, {{"TimeGenerated", Order.Descending}}), type table}, 
      {"Count", each Table.RowCount(_), Int64.Type}
    }
  ), 
  // Select first row each group
  #"First Rows" = Table.TransformColumns(GroupedTable, {"rowsbyuser", each Table.FirstN(_, 1)}), 
  #"Expanded First Rows" = Table.ExpandTableColumn(
    #"First Rows", 
    "rowsbyuser", 
    {
      "TimeGenerated", 
      "OperationName", 
      "app.displayName", 
      "TargetResource.displayName", 
      "TargetResource.userPrincipalName"
    }, 
    {
      "TimeGenerated", 
      "OperationName", 
      "app.displayName", 
      "TargetResource.displayName", 
      "TargetResource.userPrincipalName"
    }
  ), 
  #"Changed Type" = Table.TransformColumnTypes(
    #"Expanded First Rows", 
    {
      {"TimeGenerated", type datetime}, 
      {"OperationName", type text}, 
      {"app.displayName", type text}, 
      {"TargetResource.displayName", type text}, 
      {"TargetResource.userPrincipalName", type text}, 
      {"Count", Int64.Type}
    }
  ), 
  AuditFailedByUser = #"Changed Type"
in
  AuditFailedByUser