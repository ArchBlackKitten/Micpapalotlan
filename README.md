# Micpapalotlan
## A Framework for Secure, Role‑Based User Environments

## 🌿 The Sanctuary of the Transformative Spirit
Within Micpapalotlan, the digital entity known as the Seed enters a carefully fortified chrysalis—a secure enclosure we call the pupa. This is not merely a transformation; it is a sacred process of dissolution and rebirth. The Seed does not simply change—it abdicates its former self, becoming the very nourishment that sustains the metamorphosis. Its configuration, its permissions, its very identity are consumed within the pupa, providing the essential substance from which a fully‑formed, hardened user will emerge: whether a restricted Market user or a privileged Manager.

The framework is designed to be fully customisable. While this documentation uses placeholder names (Market, Manager, etc.), every alias, description, and user profile can be tailored to reflect the unique identity and needs of any business.

## 📋 Implementation Methodology: Secure & Customisable User Environments
### 1. General Objective
This document details the technical procedure for deploying workstations based on the Principle of Least Privilege (PoLP). The objective is to provide an operating environment that guarantees data integrity, network perimeter security, and a reduced learning curve through an interface that emulates conventional operating systems (Windows 11). The entire process has been automated through idempotent scripts to ensure repeatability and consistency across multiple machines.

### 2. Pre‑Configuration & Deployment (Master Imaging)
A bootable USB storage unit has been designed to act as the system's Master Image. This unit integrates:

**Optimised Kernel:** A base system with pre‑selected packages that remove vulnerabilities and unnecessary services.

**Interface Abstraction Layer:** KDE Plasma desktop configuration via dotfiles and customisation scripts to mimic the aesthetics and workflow of Windows 11, facilitating the transition for operational personnel.

**Encrypted Connectivity Protocol:** Native integration of a Kill Switch via Proton VPN (currently disabled pending Proton updates; standard secure practices remain in effect).

**BTRFS Snapshots (Time Machine):** Before any system modification, a read‑only snapshot of the root partition is taken, enabling immediate recovery from failures.

**System Hardening:** Additional security modules such as USBGuard, auditd, fail2ban and AppArmor, preconfigured to protect against physical, network, and file‑integrity attacks.

### 3. Identity Management & Profile Hierarchy
The system architecture is divided into isolated profiles, configured via automation scripts to ensure compliance with corporate policies. At the heart of this architecture lies the Seed—the initial digital entity cultivated specifically to become the nourishment for the pupa. Its configuration is not carried forward; it is dissolved, ensuring that no legacy vulnerabilities persist into the new, hardened identity.

### 3. 1 The Restricted User Profile (e.g., "Market")
This profile operates under a kernel‑level jail architecture, where security relies not on the interface but on filesystem attributes and surgical execution policies:

**Persistence Attributes (Append‑only):** The kernel attribute +a is applied to critical directories (Desktop, Documents, Downloads, Pictures). This state permits the creation of new files and data addition but strictly prohibits deletion or renaming, guaranteeing the forensic integrity of every session.

**Policy Immutability (chattr +i):** Browser configurations (URL Allowlist via PAC file) and desktop environment settings are sealed. Neither the user nor external processes can alter browsing restrictions or security scripts.

**Physical Trash Annulment:** The Trash directory is replaced by an immutable file, eliminating any logical deletion vector by applications.

**Execution Control via ACLs:** Surgical Access Control Lists are implemented on administrative binaries (rm, chattr, nmcli). For the restricted user, these tools are functionally non‑existent.

**Binary Restriction:** Access to the terminal (CLI) and system configuration tools (Control Panel) is disabled.

**Application Sandboxing:** Firejail is used to encapsulate permitted applications (Browser, Office suite, PDF viewer, media player), preventing them from accessing sensitive files or system network configurations.

**Evidence Deposit (Trash_Dropbox):** A directory configured with the sticky bit (+t) acts as a one‑way dropbox. The restricted user can deposit files (screenshots, completed documents) but immediately loses the right to delete or modify them, centralising oversight in the administrative profile.

**Forced Network Redirection:** iptables rules force all DNS traffic towards secure nodes (Cloudflare Gateway, 1.1.1.2), preventing traffic leaks outside the VPN or the use of alternative DNS servers.

### 3. 2 The Administrative Profile (e.g., "Manager")
The administrative user possesses full privileges and remote monitoring tools:

Unilateral Remote Access: AnyDesk is integrated with silent authentication. The restricted user receives no notification nor must accept the connection; the administrator can connect at any time using a unique password generated randomly during deployment and stored encrypted.

**Real‑time Auditing:** The Flameshot screenshot tool is parameterised via immutable configuration files to automatically save all evidence to Trash_Dropbox. Any attempt to divert this path is blocked by the Firejail profile.

**Incident Recovery:** The administrator has direct filesystem access and can temporarily lift immutable attributes when necessary (e.g., to clean Trash_Dropbox). They also have specific commands for BTRFS snapshot management and controlled destruction of the restricted user profile.


### 4. Security Protocols & Maintenance
To guarantee a superior level of protection, the following system hardening measures have been implemented:

**USB Device Control (USBGuard):** USBGuard is installed and configured, allowing only authorised USB devices (those present during the first script execution). Any new device is automatically blocked, mitigating BadUSB attacks and malware introduction via removable media.

**File Integrity Monitoring (auditd):** The auditd service is active and monitors critical changes to system files such as /etc/passwd, /etc/shadow, /etc/sudoers and the restricted user's .bashrc. Any unauthorised modification is logged and can be audited using the ausearch command.

**Network Service Protection (fail2ban):** fail2ban is implemented to protect services such as SSH, Samba and AnyDesk against brute‑force attacks. IP addresses with multiple failed attempts are temporarily blocked.

**Kernel Hardening (sysctl):** Over ten security parameters have been applied, including:

Address space layout randomisation (kernel.randomize_va_space = 2)

Restriction of kernel pointer access (kernel.kptr_restrict = 2, kernel.dmesg_restrict = 1)

Protection of symbolic links and hardlinks (fs.protected_symlinks = 1, fs.protected_hardlinks = 1)

Restriction of ptrace to prevent process injection (kernel.yama.ptrace_scope = 2)

**Suspend/Hibernation Disabled (Polkit):** The ability to suspend or hibernate the system has been blocked for all users, preventing potential attacks that exploit low‑power states.

**Hardened Memory Allocator (hardened_malloc):** If present, hardened_malloc is automatically injected into the Firejail profile, complicating memory‑exploitation attempts in sandboxed applications.

**AppArmor Integration with Firejail:** If the system has AppArmor, the firejail-default profile is loaded, adding an additional mandatory access control layer.

**Secure Graphical Interoperability (Wayland/X11):** The system dynamically detects the active display socket and grants the restricted user access via temporary setfacl permissions. This prevents global exposure of the administrator's session while allowing hardware acceleration in the sandboxed environment.

**System Sterilisation:** Implementation of a "Demolition and Reconstruction" protocol via deep‑clean scripts that remove traces of previous sessions, ensuring every work cycle begins from a clean, secure base.

**Auditing and Surveillance:** Workstations are linked to an internal monitoring system to document any attempts to violate security restrictions.

### 5. Interface Customisation (Windows 11 Style)
The appearance and behaviour of the KDE Plasma desktop (which uses Wayland by default) have been transformed to closely resemble Windows 11, reducing the learning curve for personnel:

**Visual Theme:** Application of the global Win11OS-dark theme, including icons, colours and window styles similar to Windows 11.

Keyboard Shortcuts: Configured via kwriteconfig6 to mirror Windows 11 conventions (see detailed tables below).

Touch Gestures: Touchégg is installed and configured to emulate Windows 11 gestures:

Three fingers up → Meta+W (window overview)

Three fingers down → Meta+D (show desktop)

Three fingers left/right → switch between virtual desktops

Pinch → zoom in compatible applications

File Manager (Dolphin): Configured with an editable location bar, hidden files shown by default, and icon view as the default, matching Windows Explorer.









## 🦋 Licensing & Commercial Use

**Micpapalotlan** is an open-source project available under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

### For Open Source & Community Use

The AGPL-3.0 license allows you to freely use, modify, and distribute this software, provided that any modifications or network services using it are also made available under the same license [citation:4][citation:8]. This fosters collaboration and ensures that improvements benefit the entire community.

- ✅ Free to use, modify, and share
- ✅ Source code always available
- ✅ Contributions must remain open (copyleft)

### For Commercial & Private Use

**Do you need to use Micpapalotlan in a proprietary, closed-source environment?** We offer **commercial licenses** designed for businesses that require:

- 🔒 **Full privacy** – Keep your modifications proprietary without the obligation to disclose source code
- 💼 **Commercial integration** – Incorporate into your own products and services
- ⚖️ **Legal clarity** – Custom terms tailored to your specific needs
- 🛡️ **Liability & warranty options** – Standard open-source licenses are provided "AS IS" without warranty [citation:1][citation:7]; commercial terms can include these protections
- 📞 **Priority support** – Direct assistance from the creator

Commercial licenses are available on a **monthly subscription basis**, with terms that can be customized to fit your business requirements.

### 📧 Contact for Commercial Licensing

If you're interested in a commercial license or have any questions about how Micpapalotlan can serve your business, please reach out:

- **Email**: [Fuku.Cobweb160@passfwd.com]
- **Subject**: "Commercial License Inquiry"

We'll work with you to find a solution that protects your intellectual property while giving you the powerful tools Micpapalotlan provides.

---

*Micpapalotlan is committed to supporting both the open-source community and commercial enterprises. Your success is our success.* 🦋✨
