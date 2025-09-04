# KuShu‑Shimon Documentation

This folder contains the **deployment guides** for ISDF in both modes:

- **Local Mode** — everything happens on the device. No cloud write-back path; ideal for fast rollout and air‑gapped or cost‑controlled deployments.
- **CloudSync Mode** — devices **securely sync** a signed signal to the cloud using **mTLS** via **API Management (APIM)** into an **Azure Logic App**, which then writes canonical values into Entra ID **device `extensionAttributes`**. This allows a  comparison of cloud vs local signatures as well as a device channel/class that is useful for more reliable device filtering than some of the more commonly used out of the box filters such as `device.model` and `device.displayName`.

![KuShu‑Shimon / ISDF](../images/KuShu_Shimon_ISDF_Logo.png)

## Start here

- 🖥️ **Local Mode:** see [LocalMode.md](./LocalMode.md)
- ☁️ **CloudSync Mode:** see [CloudSync.md](./CloudSync.md)

> Before you begin, read the root‑level files: [README.md](../README.md), [DISCLAIMER](../DISCLAIMER), [LICENSE](../LICENSE), and [NOTICE](../NOTICE).
