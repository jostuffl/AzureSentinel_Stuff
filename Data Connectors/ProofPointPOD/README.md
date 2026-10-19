# Proofpoint POD Data Connector for Microsoft Sentinel

This deployment creates the Azure Monitor resources needed to ingest Proofpoint on Demand (POD) message and mail-log data into an existing Microsoft Sentinel workspace.

The deployment wizard can:

- Select an existing Log Analytics workspace.
- Create or update a Data Collection Endpoint (DCE).
- Create or update a Data Collection Rule (DCR).
- Optionally create `ProofpointPODMessage_CL`.
- Optionally create `ProofpointPODMailLog_CL`.
- Configure the optional `eventTime` and `pps` fields independently for each stream.
- Configure public network access and resource tags.

Deploy it to Azure by clicking the blue button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Frefs%2Fheads%2Fmain%2FData%2520Connectors%2FProofPointPOD%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fjostuffl%2FAzureSentinel_Stuff%2Frefs%2Fheads%2Fmain%2FData%2520Connectors%2FProofPointPOD%2FcreateUiDefinition.json)

## Prerequisites

- An existing Log Analytics workspace with Microsoft Sentinel enabled.
- Permission to deploy resources in the workspace's resource group.
- The `Microsoft.Insights` and `Microsoft.OperationalInsights` resource providers registered in the subscription.
- A Cribl output configured to use the Azure Monitor Logs Ingestion API.
- An identity used by Cribl with the `Monitoring Metrics Publisher` role assigned to the DCR or a parent scope.

Installing the Microsoft Sentinel **Proofpoint On Demand (POD) Email Security** solution from Content Hub is recommended for the native parser, workbook, analytics rules, and hunting queries.

## Deployment

1. Click the **Deploy to Azure** button.
2. Select the subscription and resource group containing the Sentinel workspace.
3. Select the existing workspace.
4. Enter names for the DCE and DCR.
5. Configure public network access.
6. Select whether the Proofpoint tables need to be created.
7. Select the optional fields that match the Cribl output schema.
8. Review and create the deployment.

The DCE and DCR are deployed in the selected workspace's Azure region. The resource group's metadata location is not used.

## Existing resources

The deployment supports an existing DCE or DCR when:

- The resource is in the selected resource group.
- Its name matches the name entered in the wizard.
- Its region matches the selected workspace's region.

The template declares the DCE and DCR, so an existing same-region resource is updated rather than used read-only. Review the selected public network access and tags before redeploying.

An existing DCE or DCR with the same name in another region cannot be moved. Use another resource name or select a workspace in the existing resource's region.

Leave table creation unchecked when a destination table already exists. The optional-field selections configure the DCR stream declarations, but do not add or remove columns from an existing table.

## Table and stream schemas

### Message stream

- Stream: `Custom-ProofpointPodMessage`
- Table: `ProofpointPODMessage_CL`
- Base fields:
  - `TimeGenerated`
  - `guid`
  - `connection`
  - `envelope`
  - `msg`
  - `metadata`
  - `filter`
  - `msgParts`

### Mail-log stream

- Stream: `Custom-ProofpointPodMailLog`
- Table: `ProofpointPODMailLog_CL`
- Base fields:
  - `TimeGenerated`
  - `id`
  - `data`
  - `metadata`
  - `sm`
  - `tls`

Both data flows use the following pass-through transformation:

```json
"transformKql": "source"
```

The deployment does not rename fields, generate timestamps, or convert incoming values.

## Optional fields

The wizard provides separate options for each stream:

| Field | Type | Expected Cribl property |
|---|---|---|
| `eventTime` | `datetime` | Top-level ISO 8601 timestamp |
| `pps` | `dynamic` | Top-level JSON object |

Example:

```json
{
  "eventTime": "2026-10-14T18:17:32.705648Z",
  "pps": {
    "cid": "proofpoint-cluster-id",
    "agent": "proofpoint-agent",
    "version": "proofpoint-version"
  }
}
```

The field name is exactly `eventTime`. A column named `event_time` does not satisfy the native parser.

For an existing deployment, the incoming Cribl JSON, DCR stream declaration, and destination table must use matching property names and types.

Adding `eventTime` and `pps` to an existing DCR and table does not require every record to contain those properties. Records that omit them can continue ingesting with empty values while updated Cribl records populate the new columns.

## Cribl configuration

Configure the Cribl destination with the values returned by the deployment:

- DCE logs ingestion endpoint.
- DCR immutable ID.
- The appropriate stream name.

The ingestion URLs use the following format:

```text
<DCE logs ingestion endpoint>/dataCollectionRules/<DCR immutable ID>/streams/<stream name>?api-version=2023-01-01
```

Send the request body as a JSON array, including when sending a single record.

## Network access

`Enabled` permits ingestion through the DCE public HTTPS endpoint.

`Disabled` requires Azure Monitor Private Link Scope, private endpoints, DNS, and network routing to be configured separately.

## Native ProofpointPOD parser

When `eventTime` and `pps` are included in the table and DCR schemas and Cribl sends those properties, the native Content Hub parser can parse them.

## Files

- [`azuredeploy.json`](./ProofPointPOD/azuredeploy.json) - ARM deployment template.
- [`createUiDefinition.json`](./ProofPointPOD/createUiDefinition.json) - Azure portal deployment wizard.

## References

- [Azure Monitor Logs Ingestion API](https://learn.microsoft.com/azure/azure-monitor/logs/logs-ingestion-api-overview)
- [Data collection rule structure](https://learn.microsoft.com/azure/azure-monitor/data-collection/data-collection-rule-structure)
- [Microsoft Sentinel Proofpoint POD solution](https://github.com/Azure/Azure-Sentinel/tree/master/Solutions/Proofpoint%20On%20demand(POD)%20Email%20Security)
- [Published ProofpointPOD parser](https://github.com/Azure/Azure-Sentinel/blob/master/Solutions/Proofpoint%20On%20demand(POD)%20Email%20Security/Parsers/ProofpointPOD.yaml)
