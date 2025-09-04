# KuShu-Shimon - Intune Stateful Device Fingerprinting (ISDF)

![KuShu-Shimon Logo](/images/KuShu_Shimon_ISDF_Logo.png)

**KuShu-Shimon** implements **Intune Stateful Device Fingerprinting (ISDF)**:  
a tamper-resistant fingerprint for each enrolled Windows device, enforced through Intune Custom Compliance.  

In **Cloud** mode it additionally **attests** the fingerprint to **Entra ID** (via **APIM → Logic App → Microsoft Graph**) so you can build **trusted device filters**, **dynamic groups**, and **Conditional Access Policies** that are far harder to spoof than OOTB signals.

---

## Repository Structure

```
├─ Kushu-Shimon/
│  ├─ LICENSE
│  ├─ README.md
│  ├─ deployments/
│  │  ├─ api/
│  │  │  ├─ isdf-api-spec.json
│  │  │  └─ isdfwriter-la.openapi.yaml
│  │  ├─ arm/
│  │  │  ├─ template-ISDFWriter-APIM/
│  │  │  │  ├─ parameters.json
│  │  │  │  └─ template.json
│  │  │  └─ template-ISDFWriter-LogicApp/
│  │  │     ├─ parameters.json
│  │  │     └─ template.json
│  │  ├─ bicep/
│  │  │  ├─ isdf_apim.bicep
│  │  │  └─ isdfwriter_la.bicep
│  │  └─ json/
│  │     └─ ISDF_LogicApp_Definition.json
│  ├─ example_metadata/
│  │  ├─ AVD_IMDS_Compute.json
│  │  ├─ DevBox_IMDS_Compute.json
│  │  ├─ DevTestLabs_IMDS_Compute.json
│  │  └─ W365_IMDS_Compute.json
│  ├─ images/
│  ├─ policy/
│  │  ├─ ISDF_Compliance_Cloud.json
│  │  └─ idsf_apim_policy.xml
│  ├─ scripts/
│  │  ├─ ISDFDetect.ps1
│  │  ├─ ISDF_PR_Detection.ps1
│  │  └─ ISDF_PR_Watchdog.ps1
│  └─ secops/
│     ├─ isdf_find_deviceCompliance_failures.kql
│     └─ isdf_find_deviceCompliance_failures_detailed.kql
```

### Top‑level
- **`Kushu-Shimon/scripts/ISDFDetect.ps1`** – Primary PowerShell **5.1‑safe** detection script with 64‑bit bootstrap. No WMI. Self‑heals local baseline under `HKLM:\SOFTWARE\ISDF`.  
  Emits `ISDF_*` booleans and **exits 0 only when all required booleans are true** (mode‑aware).
- **`Kushu-Shimon/policy/ISDF_Compliance_Cloud.json`** – Custom Compliance rules for both *Local* and *Cloud* modes.
- **`Kushu-Shimon/scripts/ISDF_PR_Detection.ps1`** – Proactive Remediation (PR) **detection** to validate the local protected baseline (no Graph).
- **`Kushu-Shimon/scripts/ISDF_PR_Watchdog.ps1`** – Idempotent Scheduled Task creator (`\ISDF\ComplianceSync`) that:
  - Starts **PushLaunch** and `Schedule #3*` IME tasks
  - Triggers `intunemanagementextension://synccompliance`
  - Runs at startup, logon, and every 15 minutes with jitter.
- **`Kushu-Shimon/deployments/`** – ARM/Bicep & OpenAPI assets for **APIM** and **Logic App** (Cloud mode).
- **`Kushu-Shimon/example_metadata/`** – IMDS samples: **W365**, **Dev Box**, **AVD**, **DevTest Labs**, **Azure VM**.
- **`Kushu-Shimon/images/`** – Diagrams & screenshots (Intune configuration, registry baseline, watchdog task).
- **`Kushu-Shimon/secops/`** – KQL queries for auditing/monitoring compliance.

---

## How it Works

### On‑device (always)
- Collects **IMDS compute** (e.g., `azEnvironment`, `subscriptionId`, `resourceGroupName`, `vmId`, `resourceId`, `osProfile.computerName`, `tags` including `ms.inv.v0.backedby.origin.sourceArmId`).
- Reads **SystemInformation** (Registry) for `SystemManufacturer` and `SystemProductName`.
- Parses **AAD** identifiers from `dsregcmd /status` (TenantId, DeviceId).
- Derives a **Channel**: `ISDF:W365 | ISDF:DevBox | ISDF:AVD | ISDF:DevTestLabs | ISDF:AzureVM`.
- Builds a **Signal** JSON and encrypts it with **DPAPI** using a **per‑VM key** derived from a stable tuple *(IMDS + TenantId)*.
- Writes under `HKLM:\SOFTWARE\ISDF`:
  - `SignalProtected_v2`, `ChannelProtected_v2` (encrypted), `SignalB64` (forensics), `BaselineVer`, `Version`.
- Emits `ISDF_*` booleans for Custom Compliance, including:
  - `ISDF_ChannelOk`, `ISDF_TenantIdOK`, `ISDF_AzEnvOk`, `ISDF_HostnameMatchesProvisioned`,
  - `ISDF_SystemManufacturerOk`, `ISDF_SystemProductNamePrefixOk`,
  - `ISDF_EA2_Decrypts`, `ISDF_LiveEqualsDecrypted`,
  - *(Cloud only)* `ISDF_WebhookConfigured`, `ISDF_WebhookLastOk`, `ISDF_EA1_Matches`, `ISDF_EA2_Matches`, `ISDF_LastSyncFresh`.

### CloudSync (optional, **Cloud** mode)
1. Device presents a **per‑device client certificate** (TPM‑backed where available) to **APIM** (**mTLS**).  
   APIM validates chain + revocation and pins issuer(s); injects headers.
2. APIM authenticates to **Logic App** using **Managed Identity** (OAuth).  
   Logic App is locked down: **SAS disabled**, only APIM MI allowed; header checks enforced.
3. Logic App PATCHes Entra device **extension attributes** via Microsoft Graph (least‑privilege):
   - `extensionAttribute1` = **Channel**
   - `extensionAttribute2` = **ISDF fingerprint blob (EA2)**
   - plus hash/telemetry fields as configured
4. Logic App returns a small JSON payload, for example:

```json
{
  "syncResult": "Success",
  "echo": { "...": "..." },
  "processedAtUtc": "2025-08-29T18:22:54Z"
}
```

The detect script records freshness (`LastCloudWriteUtc`) and sets the Cloud booleans.

> These EA values are **server‑stamped** and thus suitable for **device filters**, **dynamic groups**, and **Conditional Access** with higher integrity than client‑controlled signals.

---

## Quick Start - Intended for experienced Intune Admins - Full docs at [docs](docs/README.md)

### 1) Deploy (Local first)
1. Assign **`Kushu-Shimon/scripts/ISDFDetect.ps1`** as an **Intune Custom Compliance** detection script using **`Kushu-Shimon/policy/ISDF_Compliance_Cloud.json`**.
2. Deploy **PR Watchdog** using **`Kushu-Shimon/scripts/ISDF_PR_Watchdog.ps1`** to create the cadence task.
3. (Optional) Deploy **PR Detection** (**`ISDF_PR_Detection.ps1`**) to validate local baseline health.

> In Local mode the registry key `Mode` is not required (defaults to `Local`).

### 2) Enable Cloud mode (optional)
1. Deploy **APIM** and **Logic App** using **`deployments/arm`** or **`deployments/bicep`**.  
   Import the API from **`deployments/api/isdfwriter-la.openapi.yaml`** or **`isdf-api-spec.json`**.
2. Issue **per‑device client certificates** via Intune (client‑auth EKU). Prefer TPM storage (Microsoft Platform Crypto Provider).
3. In the device registry (`HKLM:\SOFTWARE\ISDF`), set:
   - `Mode` = `Cloud`
   - `WebhookUrl` = `https://<your-apim-host>/isdf/write` *(or your route)*
   - `SyncTTLHours` = hours a cloud write is considered fresh (e.g., `48`)
4. Watch `ISDF_WebhookLastOk` + `ISDF_LastSyncFresh` flip **true** once the pipeline writes extension attributes.

---

## Registry Keys (Device)

- **`Mode`**: `Local` *(default)* | `Cloud`  
- **`WebhookUrl`**: APIM public HTTPS endpoint
- **`SyncTTLHours`**: integer hours; **0 → always stale** (non‑compliant for Cloud freshness)
- **Script‑managed**: `LastCloudWriteUtc`, `Version`, `BaselineVer`, `SignalProtected_v2`, `ChannelProtected_v2`, `SignalB64`

> The script is self‑healing: if the ISDF key/hive is missing, it rebuilds the baseline on next run.

---

## Security Notes

- **DPAPI** with a **per‑VM key** (derived from IMDS + TenantId) protects the on‑device baseline.
- **mTLS** with **per‑device certs** (TPM‑backed when available) gates Cloud writes at APIM.  
- **APIM → Logic App** uses **Managed Identity (OAuth)**; Logic App is **SAS‑disabled** and header‑pinned.
- **Least privilege** Graph permissions for the Logic App MI; monitor Entra audit logs for *extensionAttribute* writes.

---

## Monitoring

- **Intune**: compliance state for `ISDF_*` booleans; presence of watchdog task.
- **APIM**: client‑cert thumbprint, issuer, failures; correlation IDs.
- **Logic App**: run history; Graph response codes; end‑to‑end correlation.
- **Entra**: audit logs on extension attribute writes; alert on writes by non‑MI principals.
- **KQL**: see `Kushu-Shimon/secops/*.kql`.

---

## 📜 License

Apache 2.0 License - see [LICENSE](LICENSE).

---

## 🏯 About KuShuSec

KuShu-Shimon is part of the **[KuShuSec](https://github.com/KuShuSec)** family.  
- *Shimon* (指紋) means **fingerprint** in Japanese - symbolising ISDF’s purpose as a verifiable device identity.  
- Sister projects:  
  - [KuShu-Atama](https://github.com/KuShuSec/KuShu-Atama) -- Cloud Guardian Mind Maps.  
  - Other ISDF-aligned tooling and research.  

---