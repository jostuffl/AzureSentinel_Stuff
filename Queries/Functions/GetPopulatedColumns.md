# Setting Up the `GetPopulatedColumns` Function in Microsoft Sentinel

This function returns the list of columns in a table that actually contain at least one value within your query (i.e. it hides empty/unused columns). Follow these steps once; afterward it is available like any built-in function.

## 1. Open the Logs editor

In the Azure portal, go to **Microsoft Sentinel** (or **Log Analytics workspace**) → **Logs**.

## 2. Paste the function body

Paste the following into the query editor. You will see a red underline on `T` saying it is unknown — **ignore it**, this is expected.

```kql
T
| extend bag = pack_all()
| mv-expand kind=array bag
| where isnotempty(bag[1])
| distinct tostring(bag[0])
```

## 3. Save as a function

1. Click **Save** → **Save as function**.
2. **Function name:** `GetPopulatedColumns`
3. **Legacy category:** anything (e.g. `Mine`).

## 4. Define the tabular wildcard parameter

In the **Function parameters** section:

1. Add a parameter: **Type** = `tabular`, **Name** = `T`.
2. A **Tabular parameters** sub-section appears for `T`.
3. **Leave the column list empty** — do **not** add any columns or select any type.

> An empty column list is what makes the parameter a wildcard (`T:(*)`), allowing it to accept any table with any schema.

## 5. Save

Click **Save**. The function is now available in this workspace.

---

## How to call it

Pipe any table — with whatever filters you want — into the function using `invoke`:

```kql
NTANetAnalytics
| where TimeGenerated > ago(1d)
| where SubType == 'FlowLog' and FaSchemaVersion == '3'
| invoke GetPopulatedColumns()
```

The result is a single-column list of the column names that have at least one value within the filtered time range.
