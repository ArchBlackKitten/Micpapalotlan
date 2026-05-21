#!/bin/bash
# With help of Z.AI & Deepseek & Claude & Cursor

# based on commit 6f1141b


# -------------------------------------------------
# ==============================================================================
# Metamorphosis.sh – Unified Restrictive Profile Creator
# ==============================================================================
# Version: 2.1.0 (Major Overhaul - Update-Friendly)
# Compatibility: Arch EndeavourOS Plasma Wayland (Up to March 2026)
# Behavior: Mostly silent except for Errors, Echoes, and Important User Results.
# Purpose: Forging fully restrictive enterprise profiles via the chrysalis.
# ==============================================================================
#
# 🔄 UPDATE MODE:
# - Automatically detects if user exists (UPDATE mode vs INSTALL mode)
# - Preserves user data, configs, and admin's custom bashrc settings
# - Unlocks immutable files before updating
# - Cleans orphaned scripts from previous versions
# - No password prompt on updates
# - Update mode: Harvester/Dissolve runs first (clean teardown), then config refresh
# - After Dissolve transmutation to Seed, continues via Seed → profile rename
#
# To update an existing installation:
# 1. Run this script again with the SAME username
# 2. Script will detect existing user and enter UPDATE mode
# 3. All configurations will be refreshed while preserving user data
# ==============================================================================


# Some utilities undocumented

# --- 🏗️ CORE & ARCHITECTURE ---
# Dynamic Profiles: Market, Secretary, Marketing, Manager, Inventory, Accountant.
# Isolated Plasma Wayland sessions with dynamic socket detection.
# BTRFS pre-installation snapshots (fails silently if filesystem is unsupported).

# --- 🛡️ SECURITY & HARDENING ---
# Firejail Playpen: Custom DNS, Seccomp profiles, AppArmor, Hardened Malloc.
# Kernel Hardening: sysctl application completely silenced (ignores runtime-only flags).
# AIDE File Integrity: Weekly automated checks via proper cron integration.
# System Guards: USBGuard (device whitelisting) and Fail2ban active.

# --- 🌐 NETWORK & IDENTITY (THE DUCK) ---
# Full Windows Mimicry: TTL 128, Samba, WSD, Avahi disabled.
# Randomized Windows Hostname (DESKTOP-XXXXXX).
# UFW Firewall: Pre-configured for AnyDesk, CUPS (631), Zebra raw socket (9100), mDNS.
# Label printing: gLabels → CUPS/Ghostscript → ZPL → Zebra ZT231 (queue installed at deploy; sanctuary user needs no admin).

# --- 🪟 UI & RESTRICTIONS ---
# Brave Browser: Dual-layer restriction (Global JSON Policy + Local PAC Proxy).
# KDE Desktop Lock: Dual enforcement (DBUS lockCorona + chattr immutable plasma config).
# Application Menu: Strict whitelisting via local .desktop overrides.
# Admin Dropbox: Fixed visibility and proper append-only drop permissions.
# System Tweaks: Disabled KDE Wallet popups & Traditional Trash system.

# --- 🚨 EMERGENCY TOOLKIT (BASH FUNCTIONS - No sudo needed) ---
# Seal-Pupa: Reapplies all restrictions, hides apps, sets immutability (auto-elevates).
# Free-Pupa: Temporary lift; fully reversible by Seal-Pupa (auto-elevates).
# Shatter-Chrysalis: Total destruction; deletes Firejail/Brave policies, restores GUI (auto-elevates).
# Gardener: USB tethering, USBGuard, and Zebra label printer find/setup (no Metamorphosis re-run).
# Supernova/Cerberus: Kill switch (guardian only — NOT armed by default).
# dissolve: Quick user destruction (function, not alias - better for prompts).
# start-${USUARIO}-session: Manual Wayland session launcher.

# ==============================================================================
# Recommendations for Setup:
# - Keep Seed Open in TTY3
# - Connect ALL the Devices you want the PC to remember before running.
# ==============================================================================

# ----------------------------------------------------------------------
# 🦋 PRE-FLIGHT REMINDER – A GENTLE NUDGE
# ----------------------------------------------------------------------
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║   🌸  BEFORE WE BEGIN – A LITTLE CHECK-IN  🌸                    ║"
echo "║        Just to make sure your garden is ready to bloom.          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Recommendations"
echo "Keep Seed Open in TTY3"
echo "Connect ALL the Devices you want the PC to remember"
echo ""
echo ""

echo "🌱 REMINDER 1: The Hatchling Rite"
echo "   Hatchling gives your machine its unique identity."
echo "   It must be run ONCE, right after restoring the ISO."
echo ""
read -rp "   Have you run the Hatchling script? (yes/no): " hatchling_answer
echo ""

echo "📦 REMINDER 2: The APPS Installation"
echo "   APPS.sh installs all the essential software packages."
echo "   Without it, the magic won't have its tools."
echo ""
read -rp "   Have you run the APPS script? (yes/no): " apps_answer
echo ""

# ----------------------------------------------------------------------
# The Gentle Gate
# ----------------------------------------------------------------------
if [[ "$hatchling_answer" =~ ^[Yy](es)?$ ]] && [[ "$apps_answer" =~ ^[Yy](es)?$ ]]; then
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║     🎉  WONDERFUL! You're all set.  🎉                           ║"
    echo "║          Let the transformation begin.                           ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
else
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║   🌸  A QUICK REMINDER, LOVELY  🌸                               ║"
    echo "║                                                                  ║"
    if [[ ! "$hatchling_answer" =~ ^[Yy](es)?$ ]]; then
        echo "║   🌱 Hatchling should be run first!                          ║"
        echo "║      It gives your machine its unique identity.              ║"
        echo "║      Run: sudo ./Hatchling.sh                                ║"
        echo "║                                                              ║"
    fi
    if [[ ! "$apps_answer" =~ ^[Yy](es)?$ ]]; then
        echo "║   📦 APPS should be run next!                                ║"
        echo "║      It installs all the essential packages.                 ║"
        echo "║      Run: sudo ./APPS.sh                                     ║"
        echo "║                                                              ║"
    fi
    echo "║    Once you've done both, come back and run this script again.   ║"
    echo "║             Your garden will bloom beautifully. 🌸               ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

# ----------------------------------------------------------------------
# Require root privileges
# ----------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root (e.g. sudo ./Metamorphosis.sh)."
    exit 1
fi

# -----------------------------------------------------------------------------
# 0. PRE‑FLIGHT: Check prerequisites and choose profile
# -----------------------------------------------------------------------------
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║   🌸  WELCOME TO THE CHRYSALIS FORMATION CREW  🌸                 ║"
echo "║     Forming a safe & isolated pupa for your chosen spirit!       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# ----------------------------------------------------------------------
# 🦋 PROFILE SELECTION
# ----------------------------------------------------------------------
echo ""
echo " Please choose the profile type you wish to create: "
echo ""
echo "   1) Market"
echo "   2) Secretary"
echo "   3) Marketing"
echo "   4) Manager"
echo "   5) Inventory"
echo "   6) Accountant"
echo ""
echo "   👁️  Guardian (guardian) can silently supervise ALL profiles"
echo ""
read -rp "👉 Enter the number of your choice (1-6): " PROFILE_CHOICE

case $PROFILE_CHOICE in
    1)
        USUARIO="Market"
        CAN_CONNECT=false          # Cannot initiate AnyDesk to others
        CAN_BE_SURVEILLED_BY_MANAGER=true
        ;;
    2)
        USUARIO="Secretary"
        CAN_CONNECT=false
        CAN_BE_SURVEILLED_BY_MANAGER=true
        ;;
    3)
        USUARIO="Marketing"
        CAN_CONNECT=false
        CAN_BE_SURVEILLED_BY_MANAGER=true
        ;;
    4)
        USUARIO="Manager"
        CAN_CONNECT=true           # Can initiate AnyDesk to others
        CAN_BE_SURVEILLED_BY_MANAGER=false   # Cannot be surveilled by other Managers
        ;;
    5)
        USUARIO="Inventory"
        CAN_CONNECT=false          # Only handles stock internally, no remote access needed
        CAN_BE_SURVEILLED_BY_MANAGER=true  
        ;;
    6)
        USUARIO="Accountant"
        CAN_CONNECT=false
        CAN_BE_SURVEILLED_BY_MANAGER=true
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again and select 1-6."
        exit 1
        ;;
esac


echo ""
echo "✨ Creating profile: $USUARIO"
if [[ "$CAN_CONNECT" == true ]]; then
    echo "   🔓 This profile CAN initiate AnyDesk connections to supervise others."
else
    echo "   🔒 This profile CANNOT initiate AnyDesk connections."
fi
echo "   👁️  Guardian can silently supervise this profile at any time."
if [[ "$CAN_BE_SURVEILLED_BY_MANAGER" == true ]] && [[ "$USUARIO" != "Manager" ]]; then
    echo "   👁️  Manager can also supervise this profile (with visible connection)."
fi
echo ""

# ----------------------------------------------------------------------
# Early mode detection (before Harvester / destructive operations)
# ----------------------------------------------------------------------
IS_UPDATE=false
if id "$USUARIO" &>/dev/null; then
    IS_UPDATE=true
fi

unlock_plasma_for_user() {
    local target_user="$1"
    local dbus_cmd=""
    if command -v qdbus6 &>/dev/null; then dbus_cmd="qdbus6"
    elif command -v qdbus &>/dev/null; then dbus_cmd="qdbus"
    fi
    if [[ -z "$dbus_cmd" ]]; then
        echo "         ⚠️  qdbus not available"
        return 1
    fi
    local user_pid
    user_pid=$(pgrep -u "$target_user" -f plasmashell | head -1)
    if [[ -z "$user_pid" ]]; then
        echo "         ⚠️  No plasmashell"
        return 1
    fi
    local dbus_addr
    dbus_addr=$(sudo grep -z DBUS_SESSION_BUS_ADDRESS "/proc/${user_pid}/environ" 2>/dev/null | tr -d '\0' | cut -d= -f2-)
    if [[ -z "$dbus_addr" ]]; then
        echo "         ⚠️  No DBus session address"
        return 1
    fi
    if sudo -u "$target_user" DBUS_SESSION_BUS_ADDRESS="$dbus_addr" "$dbus_cmd" \
        org.kde.plasmashell /PlasmaShell evaluateScript 'lockCorona(false)' 2>/dev/null; then
        echo "         ✅ Unlocked"
        return 0
    fi
    echo "         ⚠️  Failed (session may have ended)"
    return 1
}

# Dissolve-style prep for an existing profile (no user deletion)
prepare_profile_for_update() {
    local target_user="$1"
    echo "🔧 Preparing '$target_user' for update (sessions, Plasma, immutability)..."
    sudo loginctl terminate-user "$target_user" 2>/dev/null || true
    sleep 1
    sudo pkill -u "$target_user" -9 2>/dev/null || true
    echo "   🔓 Unlocking KDE Desktop..."
    unlock_plasma_for_user "$target_user" || true
    echo "   💎 Removing +i / +a protections under /home/$target_user ..."
    if [[ -d "/home/$target_user" ]]; then
        sudo chattr -R -i -a "/home/$target_user" 2>/dev/null || true
        sudo setfacl -R -b "/home/$target_user" 2>/dev/null || true
    fi
    for f in \
        "/home/$target_user/.local/share/Trash" \
        "/home/$target_user/.brave-restricted/whitelist.pac" \
        "/home/$target_user/Trash_Dropbox/incoming" \
        "/home/$target_user/Trash_Dropbox/logs" \
        "/home/$target_user/.config/plasma-org.kde.plasma.desktop-appletsrc"
    do
        sudo chattr -i -a "$f" 2>/dev/null || true
    done
    sudo chattr -i /home/guardian/.bashrc 2>/dev/null || true
    echo "✅ Profile prepared for update"
    echo ""
}

# ----------------------------------------------------------------------
# Ensure admin user exists
# ----------------------------------------------------------------------
if ! id "guardian" &>/dev/null; then
    echo "❌ Admin user 'guardian' does not exist. Please create it first."
    exit 1
fi

# ----------------------------------------------------------------------
# 0.5 📸 BTRFS SNAPSHOT - TIME TRAVEL CAPABILITY
# ----------------------------------------------------------------------
echo "--- 📸 PREPARING THE TIME MACHINE (BTRFS Snapshot) ---"
if findmnt / -t btrfs &>/dev/null; then
     sudo mkdir -p /.snapshots
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    SNAPSHOT_NAME="pre_${USUARIO}_${TIMESTAMP}"
    echo "⏳ Creating pre-installation snapshot: $SNAPSHOT_NAME"
    if sudo btrfs subvolume snapshot -r / "/.snapshots/$SNAPSHOT_NAME" 2>/dev/null; then
        echo "✅ Snapshot created: /.snapshots/$SNAPSHOT_NAME"
        echo "   Use 'sudo btrfs subvolume list /.snapshots' to see all snapshots"
    else
        echo "ℹ️  Could not create snapshot (permission or subvolume structure issue)."
    fi
else
    echo "⚠️  Root filesystem is not BTRFS. Snapshots not available."
fi
echo ""

# ----------------------------------------------------------------------
# 1. 🌾 THE HARVESTER HAS AWAKENED (Total Demolition - SAFE UPGRADE PATH)
# ----------------------------------------------------------------------
echo "--- THE HARVESTER HAS AWAKENED (Total Demolition) ---"
if [[ "$IS_UPDATE" == true ]]; then
    echo "🔄 Update mode for '$USUARIO': Harvester/Dissolve runs before configuration refresh."
    echo "   Choose '$USUARIO' as the survivor when prompted, then confirm DISSOLVE."
    echo ""
fi
echo "🔍 The Harvester gazes upon the land, seeking ALL previous constructions..."

# All possible chrysalis profile names (Seed is NEVER in this list)
ALL_PROFILES=("Market" "Secretary" "Marketing" "Manager" "Inventory" "Accountant")

# ─── Scan for existing chrysalis ───
FOUND_PROFILES=()
for profile in "${ALL_PROFILES[@]}"; do
    if id "$profile" &>/dev/null; then
        FOUND_PROFILES+=("$profile")
    fi
done

if [[ ${#FOUND_PROFILES[@]} -eq 0 ]]; then
    echo "😌 No previous chrysalis profiles found. The Harvester rests."
    echo "   Clean slate detected. Proceeding with construction..."
    echo ""
    if [[ "$IS_UPDATE" == true ]] && id "$USUARIO" &>/dev/null; then
        prepare_profile_for_update "$USUARIO"
    fi
else
    echo ""
    echo "⚠️  The Harvester senses ${#FOUND_PROFILES[@]} existing profile(s):"
    for p in "${FOUND_PROFILES[@]}"; do
        echo "      • $p"
    done
    echo ""
    echo "   💡 Selecting YES will perform a COMPLETE CHRYSALIS DISSOLUTION:"
    echo "      • Unlock ALL system binaries and interpreters"
    echo "      • Remove ALL immutable/append-only flags"
    echo "      • Clear ALL ACLs"
    echo "      • Remove ALL SDDM, Brave, Firejail, Seccomp artifacts"
    echo "      • Delete ALL found profiles EXCEPT ONE (which becomes new Seed)"
    echo "      • Purge ALL profile aliases from admin's bashrc"
    echo "      • The spared chrysalis will be wiped CLEAN and renamed to 'Seed'"
    echo "      • All interface config preserved in the new Seed!"
    echo ""
    
    # ─── LET USER CHOOSE WHICH CHRYSALIS TO SPARE (becomes new Seed) ───
    echo "🌱 Which chrysalis shall survive to become the NEW SEED?"
    echo "   (This one will be cleaned but NOT deleted - keeping all configs!)"
    if [[ "$IS_UPDATE" == true ]]; then
        echo "   👉 Updating '$USUARIO': select '$USUARIO' as survivor."
    fi
    echo ""
    
    select SURVIVOR in "${FOUND_PROFILES[@]}" "CANCEL - Dissolve All / Create Fresh Seed"; do
        if [[ "$REPLY" == "$((${#FOUND_PROFILES[@]}+1))" ]] || [[ "$SURVIVOR" == "CANCEL"* ]]; then
            echo ""
            echo "❌ User cancelled selection. No partial dissolution."
            echo "   Exiting without changes."
            exit 0
        elif [[ -n "$SURVIVOR" ]] && id "$SURVIVOR" &>/dev/null; then
            echo ""
            echo "✅ '$SURVIVOR' chosen as the survivor!"
            echo "   🔄 This chrysalis will be cleaned and renamed to: Seed"
            echo "   💾 All KDE/interface configs will be PRESERVED!"
            break
        else
            echo "⚠️  Invalid selection. Try again."
        fi
    done
    
    echo ""
    read -rp "🌀 Proceed with DISSOLVE? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🌾 DISSOLVE BEGINS - TOTAL ANNIHILATION!"
        echo "   🌱 Survivor: $SURVIVOR → will become 'Seed'"
        echo ""
        
        # Separate victims from survivor
        VICTIMS=()
        for profile in "${FOUND_PROFILES[@]}"; do
            if [[ "$profile" != "$SURVIVOR" ]]; then
                VICTIMS+=("$profile")
            fi
        done
        
        TOTAL_USERS=${#VICTIMS[@]}
        
        # ═══════════════════════════════════════════════════════
        # PHASE 1: DISSOLVE ALL OTHER CHRYSALIS (except survivor)
        # ═══════════════════════════════════════════════════════
        if [[ ${#VICTIMS[@]} -gt 0 ]]; then
            CURRENT_NUM=0
            
            for VICTIM in "${VICTIMS[@]}"; do
                ((CURRENT_NUM++))
                echo "╔══════════════════════════════════════════════════════════════╗"
                echo "║  [$CURRENT_NUM/$TOTAL_USERS] Dissolving chrysalis: $VICTIM"
                echo "╚══════════════════════════════════════════════════════════════╝"
                
                VICTIM_ID=$(id -u "$VICTIM" 2>/dev/null || echo "")
                
                # ─── 1. Kill processes ───
                echo "   [1/7] ⚰️  Terminating processes..."
                sudo loginctl terminate-user "$VICTIM" 2>/dev/null || true
                sleep 1
                sudo pkill -u "$VICTIM" -9 2>/dev/null || true
                echo "         ✅ Done"
                
                # ─── 2. Unlock KDE Desktop ───
                echo "   [2/7] 🔓 Unlocking KDE Desktop..."
                unlock_plasma_for_user "$VICTIM"
                
                # ─── 3. Remove immutable/append-only ───
                echo "   [3/7] 💎 Removing file protections..."
                if [[ -d "/home/$VICTIM" ]]; then
                    sudo chattr -R -i -a "/home/$VICTIM" 2>/dev/null || true
                    echo "         ✅ Flags removed"
                else
                    echo "         ⚠️  No home directory"
                fi
                
                # ─── 4. Clear ACLs on user home ───
                echo "   [4/7] 🧹 Clearing ACLs..."
                if [[ -d "/home/$VICTIM" ]]; then
                    sudo setfacl -R -b "/home/$VICTIM" 2>/dev/null || true
                    echo "         ✅ Cleared"
                else
                    echo "         ⚠️  Skipped"
                fi
                
                # ─── 5. Remove artifacts ───
                echo "   [5/7] 🗑️  Removing artifacts..."
                REMOVED=0
                for artifact in \
                    "/etc/sddm.conf.d/${VICTIM}.conf" \
                    "/etc/brave/policies/managed/${VICTIM}_policy.json" \
                    "/etc/brave/policies/managed/${VICTIM}_policy.json.bak" \
                    "/etc/firejail/${VICTIM}.profile" \
                    "/etc/seccomp/${VICTIM}-profile.json" \
                    "/etc/sudoers.d/${VICTIM}"
                do
                    if [[ -f "$artifact" ]]; then
                        sudo rm -f "$artifact"
                        ((REMOVED++))
                    fi
                done
                
                # Clean Wayland runtime
                if [[ -n "$VICTIM_ID" ]] && [[ -d "/run/user/$VICTIM_ID" ]]; then
                    sudo rm -rf "/run/user/$VICTIM_ID" 2>/dev/null || true
                fi
                
                echo "         ✅ Removed $REMOVED artifacts"
                
                # ─── 6. Delete user ───
                echo "   [6/7] 💀 Deleting user..."
                sudo userdel -rf "$VICTIM" 2>/dev/null || true
                sudo rm -rf "/home/$VICTIM" 2>/dev/null || true
                echo "         ✅ User '$VICTIM' deleted"
                
                # ─── 7. Clean specific aliases from admin bashrc ───
                echo "   [7/7] 🧹 Cleaning admin aliases for $VICTIM..."
                if [[ -f "/home/guardian/.bashrc" ]]; then
                    sudo sed -i "/run-in-${VICTIM}()/,/^}/d" /home/guardian/.bashrc 2>/dev/null || true
                    echo "         ✅ Done"
                else
                    echo "         ⚠️  Skipped"
                fi
                
                echo ""
            done
        else
            echo "ℹ️  No other chrysalis to dissolve. Only survivor exists."
        fi
        
        # ═══════════════════════════════════════════════════════
        # PHASE 2: WIPE THE SURVIVOR CLEAN (but don't delete!)
        # ═══════════════════════════════════════════════════════
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║  🌱 PREPARING THE CHOSEN ONE: $SURVIVOR"
        echo "║     → Will become: Seed"
        echo "╚══════════════════════════════════════════════════════════════╝"
        
        SURVIVOR_ID=$(id -u "$SURVIVOR" 2>/dev/null || echo "")
        
        # ─── 1. Kill survivor's processes ───
        echo "   [1/6] ⚰️  Terminating survivor's processes..."
        sudo loginctl terminate-user "$SURVIVOR" 2>/dev/null || true
        sleep 1
        sudo pkill -u "$SURVIVOR" -9 2>/dev/null || true
        echo "         ✅ Done"
        
        # ─── 2. Unlock KDE Desktop ───
        echo "   [2/6] 🔓 Unlocking KDE Desktop..."
        unlock_plasma_for_user "$SURVIVOR"
        
        # ─── 3. Remove immutable/append-only from survivor ───
        echo "   [3/6] 💎 Removing file protections from survivor..."
        if [[ -d "/home/$SURVIVOR" ]]; then
            sudo chattr -R -i -a "/home/$SURVIVOR" 2>/dev/null || true
            echo "         ✅ Flags removed (configs preserved!)"
        else
            echo "         ⚠️  No home directory"
        fi
        
        # ─── 4. Clear ACLs on survivor ───
        echo "   [4/6] 🧹 Clearing ACLs from survivor..."
        if [[ -d "/home/$SURVIVOR" ]]; then
            sudo setfacl -R -b "/home/$SURVIVOR" 2>/dev/null || true
            echo "         ✅ Cleared (configs preserved!)"
        else
            echo "         ⚠️  Skipped"
        fi
        
        # ─── 5. Remove survivor's artifacts (but keep home dir!) ───
        echo "   [5/6] 🗑️  Removing survivor's system artifacts..."
        REMOVED=0
        for artifact in \
            "/etc/sddm.conf.d/${SURVIVOR}.conf" \
            "/etc/brave/policies/managed/${SURVIVOR}_policy.json" \
            "/etc/brave/policies/managed/${SURVIVOR}_policy.json.bak" \
            "/etc/firejail/${SURVIVOR}.profile" \
            "/etc/seccomp/${SURVIVOR}-profile.json" \
            "/etc/sudoers.d/${SURVIVOR}"
        do
            if [[ -f "$artifact" ]]; then
                sudo rm -f "$artifact"
                ((REMOVED++))
            fi
        done
        
        # Clean Wayland runtime
        if [[ -n "$SURVIVOR_ID" ]] && [[ -d "/run/user/$SURVIVOR_ID" ]]; then
            sudo rm -rf "/run/user/$SURVIVOR_ID" 2>/dev/null || true
        fi
        
        echo "         ✅ Removed $REMOVED artifacts"
        echo "         💾 Home directory /home/$SURVIVOR INTACT with all configs!"
        
        # ─── 6. Clean survivor's aliases from admin bashrc ───
        echo "   [6/6] 🧹 Cleaning admin aliases for $SURVIVOR..."
        if [[ -f "/home/guardian/.bashrc" ]]; then
            sudo sed -i "/run-in-${SURVIVOR}()/,/^}/d" /home/guardian/.bashrc 2>/dev/null || true
            echo "         ✅ Done"
        else
            echo "         ⚠️  Skipped"
        fi
        
        echo ""
        # ═══════════════════════════════════════════════════════
        # PHASE 3: RENAME SURVIVOR TO SEED (CRITICAL - MUST SUCCEED)
        # ═══════════════════════════════════════════════════════
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║  🔄 TRANSMUTATION: $SURVIVOR → Seed"
        echo "╚══════════════════════════════════════════════════════════════╝"
        
        # Check if Seed already exists
        if id "Seed" &>/dev/null; then
            echo "   ⚠️  'Seed' user already exists!"
            echo "   💀 Must destroy old Seed first to make room..."
            sudo loginctl terminate-user "Seed" 2>/dev/null || true
            sleep 1
            sudo pkill -u "Seed" -9 2>/dev/null || true
            sudo userdel -rf "Seed" 2>/dev/null || true
            sudo rm -rf "/home/Seed" 2>/dev/null || true
            
            # Verify old Seed is gone
            if id "Seed" &>/dev/null; then
                echo ""
                echo "╔══════════════════════════════════════════════════════════════╗"
                echo "║  ❌ FATAL ERROR: Could not remove existing 'Seed' user!      ║"
                echo "║     Transmutation IMPOSSIBLE.                               ║"
                echo "║                                                              ║"
                echo "║     Manual intervention required:                           ║"
                echo "║     • Check if Seed is logged in: who | grep Seed           ║"
                echo "║     • Force logout: sudo loginctl terminate-user Seed       ║"
                echo "║     • Delete manually: sudo userdel -rf Seed               ║"
                echo "║     • Then re-run this script                              ║"
                echo "╚══════════════════════════════════════════════════════════════╝"
                echo ""
                echo "🛑 SCRIPT CANCELLED - Transmutation failed"
                exit 1
            fi
            echo "   ✅ Old Seed removed"
            echo ""
        fi
        
        # ─── ATTEMPT TRANSMUTATION ───
        echo "   🔮 Casting transmutation spell..."
        TRANSMUTATION_SUCCESS=false
        
        # Method 1: Try usermod (cleanest way)
        if sudo usermod -l "Seed" "$SURVIVOR" 2>/dev/null; then
            echo "   ✅ Username changed via usermod: $SURVIVOR → Seed"
            TRANSMUTATION_SUCCESS=true
        else
            echo "   ⚠️  usermod failed, trying alternative method..."
            
            # Method 2: Manual approach (create new, copy data, delete old)
            # Get survivor's groups and info BEFORE we lose access
            SURVIVOR_GROUPS=$(id -Gn "$SURVIVOR" 2>/dev/null | tr ' ' ',')
            SURVIVOR_SHELL=$(grep "^$SURVIVOR:" /etc/passwd | cut -d: -f7)
            SURVIVOR_PASSHASH=$(sudo grep "^$SURVIVOR:" /etc/shadow | cut -d: -f2)
            
            # Create new Seed user
            if sudo useradd -m -s "${SURVIVOR_SHELL:-/bin/bash}" -G "${SURVIVOR_GROUPS:-wheel}" "Seed" 2>/dev/null; then
                echo "   ✅ New 'Seed' user created"
                
                # Copy password hash
                if [[ -n "$SURVIVOR_PASSHASH" ]]; then
                    echo "Seed:$SURVIVOR_PASSHASH" | sudo chpasswd -e 2>/dev/null && echo "   ✅ Password preserved" || echo "   ⚠️  Password not preserved (will need reset)"
                fi
                
                # Copy home directory contents (preserving configs!)
                if [[ -d "/home/$SURVIVOR" ]]; then
                    if sudo cp -a "/home/$SURVIVOR/." "/home/Seed/" 2>/dev/null; then
                        echo "   ✅ Home directory copied with all configs"
                    else
                        echo "   ❌ Failed to copy home directory!"
                        # Cleanup failed attempt
                        sudo userdel -rf "Seed" 2>/dev/null
                    fi
                fi
                
                # Fix ownership
                sudo chown -R Seed:Seed /home/Seed 2>/dev/null
                
                # Delete old survivor user
                if sudo userdel "$SURVIVOR" 2>/dev/null; then
                    echo "   ✅ Old user '$SURVIVOR' removed"
                    sudo rm -rf "/home/$SURVIVOR" 2>/dev/null
                    TRANSMUTATION_SUCCESS=true
                else
                    echo "   ❌ Failed to delete old user '$SURVIVOR'"
                    # Cleanup
                    sudo userdel -rf "Seed" 2>/dev/null
                fi
            else
                echo "   ❌ Failed to create new 'Seed' user"
            fi
        fi
        
        # Rename home directory if it still has old name (for usermod success case)
        if [[ "$TRANSMUTATION_SUCCESS" == "true" ]] && [[ -d "/home/$SURVIVOR" ]]; then
            echo "   📁 Renaming home directory..."
            if sudo mv "/home/$SURVIVOR" "/home/Seed" 2>/dev/null; then
                sudo usermod -d "/home/Seed" "Seed" 2>/dev/null
                echo "   ✅ Home moved to /home/Seed"
            else
                echo "   ⚠️  Could not rename home dir (permissions?)"
                # Not fatal - home might already be correct or user can fix manually
            fi
        fi
        
        # Final ownership fix
        if [[ "$TRANSMUTATION_SUCCESS" == "true" ]]; then
            sudo chown -R Seed:Seed /home/Seed 2>/dev/null
            # CRITICAL FIX: Force group name to match exact username case
            SURVIVOR_GROUP=$(sudo grep "^$SURVIVOR:" /etc/group | cut -d: -f1)
            if [[ "$SURVIVOR_GROUP" != "Seed" ]]; then
                sudo groupmod -n "Seed" "$SURVIVOR_GROUP" 2>/dev/null || true
            fi
        fi
        
        # ═══════════════════════════════════════════════════════
        # CRITICAL CHECK: Did transmutation succeed?
        # ═══════════════════════════════════════════════════════
        if [[ "$TRANSMUTATION_SUCCESS" != "true" ]]; then
            echo ""
            echo "╔══════════════════════════════════════════════════════════════╗"
            echo "║  💥 CATASTROPHIC FAILURE: TRANSMUTATION FAILED! 💥              ║"
            echo "║                                                                  ║"
            echo "║  The survivor '$SURVIVOR' could NOT be renamed to 'Seed'         ║"
            echo "║                                                                  ║"
            echo "║  Possible causes:                                                ║"
            echo "║    • User '$SURVIVOR' is currently logged in (active session)   ║"
            echo "║    • Process still running under that username                  ║"
            echo "║    • Filesystem permissions issue                               ║"
            echo "║    • Authentication database locked (pwck/grpck needed)         ║"
            echo "║                                                                  ║"
            echo "║  ⛔ SCRIPT ABORTED - No changes committed beyond this point     ║"
            echo "║                                                                  ║"
            echo "║  To retry:                                                       ║"
            echo "║    1. Ensure '$SURVIVOR' is fully logged out                     ║"
            echo "║       sudo loginctl terminate-user $SURVIVOR                   ║"
            echo "║    2. Kill any lingering processes:                             ║"
            echo "║       sudo pkill -9 -u $SURVIVOR                               ║"
            echo "║    3. Verify no sessions: who | grep $SURVIVOR                  ║"
            echo "║    4. Re-run this script                                        ║"
            echo "║                                                                  ║"
            echo "║  🛑 Your original chrysalis '$SURVIVOR' is still intact          ║"
            echo "║     (no damage done - safe to retry)                            ║"
            echo "╚══════════════════════════════════════════════════════════════╝"
            echo ""
            exit 2  # Exit code 2 = transmutation failure
        fi
        
        # Verify the new Seed actually exists
        if ! id "Seed" &>/dev/null; then
            echo ""
            echo "❌ ERROR: Transmutation reported success but 'Seed' user not found!"
            echo "   Inconsistent state detected. Aborting."
            exit 3
        fi
        
        echo ""
        echo "   🌱✨ TRANSMUTATION COMPLETE ✨🌱"
        echo "   The survivor '$SURVIVOR' is now 'Seed'"
        echo "   All KDE configs, desktop settings, and customizations preserved!"
        echo ""
    fi
fi

# Harvester/Dissolve leaves the profile as Seed — continue update via Seed → $USUARIO rename
if [[ "$IS_UPDATE" == true ]] && id "Seed" &>/dev/null && ! id "$USUARIO" &>/dev/null; then
    echo "🔄 Dissolve complete: continuing update (Seed → '$USUARIO')."
    IS_UPDATE=false
    echo ""
fi

# ----------------------------------------------------------------------
# 1.1 🔍 DETECCIÓN DE MODO: UPDATE vs INSTALL
# ----------------------------------------------------------------------
if [[ "$IS_UPDATE" == true ]]; then
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║   🔄 MODO ACTUALIZACIÓN DETECTADO                                ║"
    echo "║   Usuario '$USUARIO' ya existe - actualizando configuración      ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    if id "$USUARIO" &>/dev/null; then
        prepare_profile_for_update "$USUARIO"
    fi
    
    # Limpiar archivos huérfanos de versiones anteriores
    echo "🧹 Limpiando archivos huérfanos de versiones anteriores..."
    for orphan in "/usr/local/bin/Print" "/usr/local/bin/${USUARIO}-lock" "/usr/local/bin/${USUARIO}-unlock-full" "/usr/local/bin/${USUARIO}-nuke" "/usr/local/bin/start-${USUARIO}-session" "/usr/local/bin/Gardener"; do
        if [ -f "$orphan" ]; then
            sudo rm -f "$orphan"
            echo "   🗑️  Eliminado: $orphan"
        fi
    done
    echo "✅ Limpieza completada"
    echo ""
else
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║   🆕 MODO INSTALACIÓN NUEVA                                      ║"
    echo "║   Usuario '$USUARIO' no existe - instalación desde cero          ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
fi

# ----------------------------------------------------------------------
# 1.2 🌱 RENOMBRAR SEED A $USUARIO SI ES NECESARIO (install o post-Dissolve update)
# ----------------------------------------------------------------------
if id "Seed" &>/dev/null && ! id "$USUARIO" &>/dev/null; then
    echo "🌱 Found user 'Seed'. Renaming to '$USUARIO'..."

     sudo pkill -u Seed 2>/dev/null || true
    sleep 1

     sudo usermod -l "$USUARIO" Seed
     sudo usermod -d "/home/$USUARIO" -m "$USUARIO"
     # CRITICAL FIX: Force group name to match exact username case
     SEED_GROUP=$(sudo grep "^Seed:" /etc/group | cut -d: -f1)
     if [[ "$SEED_GROUP" != "$USUARIO" ]]; then
         sudo groupmod -n "$USUARIO" "$SEED_GROUP" 2>/dev/null || true
     fi

    echo "✅ User renamed to '$USUARIO'."
     sudo usermod -aG video,render,audio "$USUARIO" 2>/dev/null || true
   
    echo "🔑 Seed's password was inherited. Set a new one for $USUARIO:"
    sudo passwd "$USUARIO"
    echo ""

    if [[ -d "/home/$USUARIO" ]]; then
        echo "🔧 Adjusting paths in configuration files for $USUARIO (ex-Seed)..."
        find "/home/$USUARIO/.config" "/home/$USUARIO/.local/share" -type f -exec grep -Iq . {} \; \
            -exec sudo sed -i "s|/home/Seed|/home/$USUARIO|g" {} + 2>/dev/null || true
        find "/home/$USUARIO/.config" "/home/$USUARIO/.local/share" -type f -exec grep -Iq . {} \; \
            -exec sudo sed -i "s|/home/guardian|/home/$USUARIO|g" {} + 2>/dev/null || true
    fi
fi

# ----------------------------------------------------------------------
# 2. CREAR USUARIO SI NO EXISTE (solo en modo install)
# ----------------------------------------------------------------------
if [[ "$IS_UPDATE" == "false" ]] && ! id "$USUARIO" &>/dev/null; then
    echo "--- 🎨 PHASE 2: LAYING THE FOUNDATIONS (User Creation) ---"
    echo "👷‍♀️ Creating the main occupant for our cozy space: '$USUARIO'..."
     sudo useradd -m -s /bin/bash "$USUARIO"
     sudo chown -R "${USUARIO}:${USUARIO}" "/home/$USUARIO"
    echo "🔑 Please set a secret password for $USUARIO (make it a good one!):"
    sudo passwd "$USUARIO"
     sudo passwd -n 9999 "$USUARIO" 2>/dev/null || true
    echo "✨ Granted basic groups: video, render, audio, lp, scanner."
     sudo usermod -aG video,render,audio,lp,scanner "$USUARIO" 2>/dev/null > /dev/null || true
    echo "✅ User '$USUARIO' has been created."
elif [[ "$IS_UPDATE" == "true" ]]; then
    echo "--- 🔄 User '$USUARIO' already exists. Updating configuration..."
fi

USER_ID=$(id -u "$USUARIO")

# ----------------------------------------------------------------------
# SOPORTE GRÁFICO (Wayland) - SESIÓN AISLADA
# ----------------------------------------------------------------------
echo "--- 🔧 SETTING UP WAYLAND GRAPHICS SUPPORT (ISOLATED SESSION) ---"

 sudo mkdir -p "/run/user/$USER_ID"
 sudo chown "${USUARIO}:${USUARIO}" "/run/user/$USER_ID"
 sudo chmod 700 "/run/user/$USER_ID"

# Dynamically find the Wayland socket instead of hardcoding it
WAYLAND_DISPLAY_NAME=$(sudo -u "$USUARIO" bash -c 'echo $WAYLAND_DISPLAY')
if [ -z "$WAYLAND_DISPLAY_NAME" ]; then
    echo "⚠️  Could not detect Wayland display dynamically. Falling back to wayland-0"
    WAYLAND_DISPLAY_NAME="wayland-0"
else
    echo "✅ Detected Wayland display for $USUARIO: $WAYLAND_DISPLAY_NAME"
fi



echo "🖥️ Configuring display manager for auto-login..."
 sudo mkdir -p /etc/sddm.conf.d
 sudo tee "/etc/sddm.conf.d/${USUARIO}.conf" > /dev/null <<EOF
[Autologin]
User=$USUARIO
Session=plasma

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
EOF
echo "✅ SDDM configured to auto-login '$USUARIO' to a dedicated Wayland session."

# Clean up any previous ACL grants to admin's session
ID_GUARDIAN=$(id -u guardian 2>/dev/null || echo "")
if [[ -n "$ID_GUARDIAN" ]]; then
    echo "🧹 Revoking any existing Wayland socket permissions for admin..."
    while IFS= read -r socket; do
        if sudo setfacl -x u:"$USUARIO" "$socket" 2>/dev/null; then
            echo "   Removed ACL from $socket"
        fi
    done < <(sudo find "/run/user/$ID_GUARDIAN" -maxdepth 1 -name "wayland-*" ! -name "*.lock" 2>/dev/null)
     sudo rm -f "/run/user/$USER_ID"/wayland-* 2>/dev/null || true
fi

echo "✅ Wayland setup complete. '$USUARIO' will have its own isolated graphical session."
echo ""

# ----------------------------------------------------------------------
# 3. 🪟 QUACKING WINDOWS (network mimic)
# ----------------------------------------------------------------------
echo "If it quacks and looks like a duck, is a duck 🦆."

 sudo tee /etc/sysctl.d/99-windows-like.conf > /dev/null <<'EOF'
net.ipv4.ip_default_ttl=128
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_window_scaling=0
EOF
 sudo sysctl --system > /dev/null
echo "✅ Network stack now mimics Windows (TTL=128, no timestamps)."

if ! command -v smbd &>/dev/null; then
    echo "⚠️ Samba not found. Please add 'samba' to APPS.sh."
else
     sudo tee /etc/samba/smb.conf > /dev/null <<'EOF'
[global]
   workgroup = WORKGROUP
   server string = %h server
   netbios name = %h
   server role = standalone server
   unix extensions = no
   server min protocol = SMB2_02
   server max protocol = SMB3_11
[homes]
   comment = Home Directories
   browseable = yes
   read only = no
   create mask = 0700
   directory mask = 0700
   valid users = %S
EOF
     sudo systemctl enable --now smb nmb > /dev/null
    echo "✅ Samba services (smb, nmb) started."
fi

if systemctl cat wsdd &>/dev/null; then
     sudo systemctl enable --now wsdd > /dev/null
    echo "✅ wsdd service started."
else
    echo "⚠️ wsdd not found. Please add 'wsdd' from AUR to APPS.sh."
fi

if systemctl cat avahi-daemon &>/dev/null; then
     sudo systemctl disable --now avahi-daemon avahi-daemon.socket 2>/dev/null || true
    echo "✅ Avahi (mDNS) disabled to avoid Linux-like behavior."
fi
echo "✅ Windows network mimicry complete. This duck now quacks! 🦆"
echo ""

# ----------------------------------------------------------------------
# 3.5 🏷️ GIVING THE DUCK A WINDOWS-STYLE NAME (hostname)
# ----------------------------------------------------------------------
echo "--- 🏷️ Giving the duck a proper Windows-style name ---"
NEW_HOSTNAME="DESKTOP-$(tr -dc 'A-Z0-9' < /dev/urandom | head -c6)"
echo "🦆 New hostname will be: $NEW_HOSTNAME"
 sudo hostnamectl set-hostname "$NEW_HOSTNAME"
 sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
echo "✅ Hostname changed to $NEW_HOSTNAME (a true Windows duck now!)"
echo ""

# ----------------------------------------------------------------------
# 4. 🔥 FIREWALL
# ----------------------------------------------------------------------
echo "--- 🔥 LIGHTING THE PROTECTIVE FIREWALL ---"
 sudo ufw --force enable
 sudo ufw default deny incoming
 sudo ufw default allow outgoing
 sudo ufw allow 7070/tcp comment 'AnyDesk'
 sudo ufw allow 631/tcp comment 'CUPS Printing'
 sudo ufw allow out 9100/tcp comment 'Zebra ZT231 raw ZPL socket'
 sudo ufw allow 5353/udp comment 'mDNS local' 
# Necesario para SANE descubrir el escáner en la red local
 sudo systemctl enable ufw
echo "✅ Firewall is up! It's a gentle but firm shield. 🛡️"
echo ""

# ----------------------------------------------------------------------
# 4.1 ALIASES PARA EL ADMIN (written inside Guardian bashrc block in section 7.3)
# ----------------------------------------------------------------------
echo "--- 🌐 GIVING THE ARCHITECT SOME NETWORK SUPERPOWERS ---"
echo "ℹ️  Network/AnyDesk aliases are installed with the Guardian admin toolkit (section 7.3)."
echo ""

# ----------------------------------------------------------------------
# 4.2 PROTON VPN (solo si el CLI está instalado)
# ----------------------------------------------------------------------
echo "--- 🔒 ADDING A SECRET TUNNEL (Proton VPN) ---"
if ! command -v protonvpn &>/dev/null; then
    echo "⚠️  protonvpn CLI is missing. Continuing without Proton VPN."
else
    cat <<EOF
   🛡️  Let's set up your secret tunnel! It needs a moment of your attention.
   Please follow these steps MANUALLY as the '$USUARIO' user to complete the setup:

       1. sudo -u $USUARIO protonvpn signin [your_user]
       2. sudo -u $USUARIO protonvpn connect
EOF
    echo "⏸️  Press Enter once you've completed the Proton VPN login."
    read -r
    echo "✅ Great! Moving on. 🚀"
fi

if command -v proton-vpn-gtk-app &>/dev/null; then
    echo "✅ Proton VPN GUI detected."
else
    echo "ℹ️  Proton VPN GUI not installed."
fi
echo ""

# ----------------------------------------------------------------------
# 5. 📬 ADMIN DROPBOX (structured)
# ----------------------------------------------------------------------
echo "--- 📬 CREATING STRUCTURED ADMIN DROPBOX ---"
DROPBOX="/home/$USUARIO/Trash_Dropbox"

 sudo mkdir -p "$DROPBOX"/{incoming,outgoing,logs}
 sudo chown -R "${USUARIO}:${USUARIO}" "$DROPBOX"
 sudo chmod 750 "$DROPBOX"
 sudo chmod 730 "$DROPBOX/incoming"
 sudo chattr +a "$DROPBOX/incoming" 2>/dev/null && echo "   ✅ incoming is append-only"
 sudo chmod 750 "$DROPBOX/outgoing"
 sudo chmod 770 "$DROPBOX/logs"
 sudo chattr +a "$DROPBOX/logs" 2>/dev/null && echo "   ✅ logs is append-only"

echo "✅ Dropbox structure ready:"
echo "   - incoming/ : $USUARIO can deposit files (append-only)"
echo "   - outgoing/ : Admin can leave files for $USUARIO (read-only for $USUARIO)"
echo "   - logs/     : Both can write (append-only audit trail)"

# ----------------------------------------------------------------------
# 6. ⛓️ FIREJAIL PROFILE
# ----------------------------------------------------------------------
echo "--- ⛓️  BUILDING A COZY (BUT SECURE) PLAYPEN (Firejail) ---"
if ! command -v firejail &>/dev/null; then
    echo "❌ firejail is not installed. Please run APPS.sh first. Exiting."
    exit 1
fi

 sudo tee "/etc/firejail/${USUARIO}.profile" > /dev/null <<EOF
include /etc/firejail/default.profile

# DNS seguros
netfilter
dns 1.1.1.2
dns 9.9.9.9
dns6 2606:4700:4700::1112
dns6 2620:fe::9

# Wayland
noblacklist /run/user/$USER_ID
whitelist /run/user/$USER_ID/wayland-*
env WAYLAND_DISPLAY=$WAYLAND_DISPLAY_NAME
env XDG_RUNTIME_DIR=/run/user/$USER_ID
env QT_QPA_PLATFORM=wayland

# D-Bus (necesario para KDE)
dbus-user
dbus-user.talk org.kde.*

# Dispositivos
whitelist /dev/dri
whitelist /dev/shm
whitelist /tmp/.X11-unix
whitelist /dev/bus/usb

# Impresoras (CUPS + gLabels → ZPL pipeline)
noblacklist /run/cups
whitelist /run/cups/cups.sock
noblacklist /etc/cups
whitelist /etc/cups/cupsd.conf
whitelist /etc/cups/client.conf
noblacklist /usr/lib/cups
whitelist /usr/lib/cups/filter
noblacklist /var/spool/cups
noblacklist \${HOME}/.config/glabels
whitelist \${HOME}/.config/glabels

# Archivos de usuario (solo las carpetas necesarias)
noblacklist \${HOME}/Documents
noblacklist \${HOME}/Downloads
noblacklist \${HOME}/Desktop
noblacklist \${HOME}/Pictures
whitelist \${HOME}/Documents
whitelist \${HOME}/Downloads
whitelist \${HOME}/Desktop
whitelist \${HOME}/Pictures

# Brave
noblacklist \${HOME}/.brave-restricted
whitelist \${HOME}/.brave-restricted

# Admin Dropbox (Visible so user can drop files into 'incoming')
noblacklist \${HOME}/Trash_Dropbox
whitelist \${HOME}/Trash_Dropbox

# Bloquear papelera
blacklist \${HOME}/.local/share/Trash

# Opciones de seguridad
caps.drop all
ipc-namespace
noexec /tmp
noexec /var/tmp
nonewprivs
noroot
seccomp
apparmor
EOF
echo "✅ The playpen is ready! $USUARIO's apps will run safely inside. 🎠"
echo ""

# ----------------------------------------------------------------------
# 7.5 ☢️ SUPERNOVA / CERBERUS — Digital defense (admin only, not armed)
# ----------------------------------------------------------------------
echo "--- ☢️ SUPERNOVA / CERBERUS (kill switch — NOT armed by default) ---"

_METAMORPHOSIS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo mkdir -p /etc/micpapalotlan /usr/local/lib/micpapalotlan /var/.local
sudo chmod 700 /var/.local 2>/dev/null || true

if [[ ! -f /etc/micpapalotlan/supernova.env ]]; then
    _SN_CODE=$(tr -dc '0-9' < /dev/urandom | head -c 4)
    printf "# Supernova manual trigger code (guardian only)\n# Change this before deployment.\nSUPERNOVA_CODE='%s'\n" "$_SN_CODE" | sudo tee /etc/micpapalotlan/supernova.env > /dev/null
    sudo chmod 600 /etc/micpapalotlan/supernova.env
    echo "🔑 Supernova code created: /etc/micpapalotlan/supernova.env (root read only)"
    echo "   View once: sudo cat /etc/micpapalotlan/supernova.env"
else
    echo "📄 Supernova env exists: /etc/micpapalotlan/supernova.env"
fi

if [[ -f "$_METAMORPHOSIS_ROOT/lib/micpapalotlan-supernova-cerberus.sh" ]]; then
    sudo install -m 644 "$_METAMORPHOSIS_ROOT/lib/micpapalotlan-supernova-cerberus.sh" /usr/local/lib/micpapalotlan/supernova-admin.sh
    echo "✅ Installed /usr/local/lib/micpapalotlan/supernova-admin.sh"
else
    echo "⚠️  Missing lib/micpapalotlan-supernova-cerberus.sh beside Metamorphosis.sh"
fi

sudo tee /usr/local/bin/supernova-silent > /dev/null <<'SNSILENT'
#!/bin/bash
(
    ip link set lo down 2>/dev/null
    for iface in $(ip link show | grep -E "^[0-9]" | awk -F: '{print $2}' | tr -d ' '); do
        ip link set "$iface" down 2>/dev/null
    done
    for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
        pkill -9 -u "$user" 2>/dev/null
        userdel -rf "$user" 2>/dev/null
        rm -rf "/home/$user" 2>/dev/null
    done
    [[ -f /etc/shadow ]] && dd if=/dev/urandom of=/etc/shadow bs=$(stat -c%s /etc/shadow) count=1 2>/dev/null
    find /root -type f \( -name "*.gpg" -o -name "*password*" -o -name "*key*" \) 2>/dev/null | while read -r f; do
        dd if=/dev/urandom of="$f" bs=4096 count=1 conv=notrunc 2>/dev/null
    done
    rm -rf /root/.ssh 2>/dev/null
    for dir in /home /root /etc /var/log /var/spool; do
        find "$dir" -type f 2>/dev/null | head -3000 | while read -r f; do
            dd if=/dev/urandom of="$f" bs=4096 count=1 conv=notrunc 2>/dev/null &
        done
        wait
    done
    for bootf in /boot/initramfs-linux.img /boot/vmlinuz-linux; do
        [[ -f "$bootf" ]] && dd if=/dev/urandom of="$bootf" bs=1M count=1 2>/dev/null
    done
    find /etc/grub.d -type f -exec dd if=/dev/urandom of={} bs=4096 count=1 conv=notrunc \; 2>/dev/null
    echo "DESKTOP-$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 8)" > /etc/hostname
    sync
    poweroff -f
) &>/dev/null
SNSILENT
sudo chmod 755 /usr/local/bin/supernova-silent

sudo tee /usr/local/bin/supernova-check > /dev/null <<'SNCHECK'
#!/bin/bash
HEARTBEAT_FILE="/var/.local/.heartbeat"
if [[ ! -f /var/.local/.supernova_armed ]]; then
    exit 0
fi
if [[ -f "$HEARTBEAT_FILE" ]]; then
    EXPIRA=$(cat "$HEARTBEAT_FILE")
    NOW=$(date +%s)
    if [[ "$NOW" -gt "$EXPIRA" ]]; then
        /usr/local/bin/supernova-silent
    fi
fi
SNCHECK
sudo chmod 755 /usr/local/bin/supernova-check

sudo tee /usr/local/bin/cerberus-watchdog > /dev/null <<'CWD'
#!/bin/bash
BAIT_FILE="/var/.local/.cerberus_bait_ip"
[[ -f /var/.local/.cerberus_armed ]] || exit 0
[[ -f "$BAIT_FILE" ]] || exit 0
BAIT_IP=$(cat "$BAIT_FILE")
CURRENT_EXIT=$(tailscale status 2>/dev/null | grep -i 'exit node' | awk '{print $1}' | head -1)
if [[ "$CURRENT_EXIT" == "$BAIT_IP" ]]; then
    /usr/local/bin/supernova-silent
fi
CWD
sudo chmod 755 /usr/local/bin/cerberus-watchdog

sudo systemctl stop supernova-timer.timer cerberus.timer 2>/dev/null || true
sudo systemctl disable supernova-timer.timer cerberus.timer 2>/dev/null || true
rm -f /var/.local/.supernova_armed /var/.local/.cerberus_armed 2>/dev/null || true

echo "✅ Supernova/Cerberus binaries installed (disarmed)"
echo "   Admin: Supernova | Supernova-Arm | Cerberus-Deploy | Supernova-Overview"
echo "   ⚠️  IRREVERSIBLE — never arm on sanctuary PCs unless intended"
echo ""

# ----------------------------------------------------------------------
# 7. 🚨 EMERGENCY ALIASES (para el admin) - Generate scripts separately
# ----------------------------------------------------------------------
echo "--- 🚨 INSTALLING THE EMERGENCY TOOLKIT (for Admin) ---"

# Function to add lock function to bashrc
add_lock_function_to_bashrc() {
    local user="$1"
    local cap_connect="$2"
    
    # Create the function content and add to bashrc
    cat >> /home/guardian/.bashrc <<LOCKEOF

# --- 🔒 LOCK FUNCTION (Seal-Pupa) ---
Seal-Pupa() {
    local user="${user}"
    
    # Auto-elevate to root if not already
    if [ "\$EUID" -ne 0 ]; then
        echo "🔐 Elevating to root privileges..."
        sudo bash -c "\$(declare -f Seal-Pupa); Seal-Pupa"
        return \$?
    fi
    
    echo "🔒 REINSTATING ORDER: sealing the pupa for \${user}..."
    echo ""

    if ! id "${user}" &>/dev/null; then
        echo "❌ Oopsie! User '${user}' doesn't exist. Aborting."
        return 1
    fi

echo "🔍 Checking current state... all good so far!"
echo ""

BACKUP_DIR="/root/${user}-lock-backup-\$(date +%Y%m%d-%H%M%S)"
mkdir -p "\$BACKUP_DIR"
echo "📦 Saving a magical backup to \$BACKUP_DIR"

find /home/${user} -exec lsattr {} \; 2>/dev/null > "\$BACKUP_DIR/attrs.txt"
find /home/${user} -exec getfacl {} \; 2>/dev/null > "\$BACKUP_DIR/acl.txt"
find /home/${user} -printf '%p %u %g\n' 2>/dev/null > "\$BACKUP_DIR/owner.txt"
echo "✅ Backup complete – you can restore manually if needed."
echo ""

# Personal folders
echo "--- 📁 ADDING A 'NO-ERASE' SPELL TO PERSONAL FOLDERS ---"
for dir in "Desktop" "Documents" "Downloads" "Pictures"; do
    mkdir -p "/home/${user}/\$dir"
    chown ${user}:${user} "/home/${user}/\$dir"
    chmod 770 "/home/${user}/\$dir"
    echo "  ✅ \$dir is ready"
done
echo ""

# Config ownership
echo "--- 🔑 ENSURING CONFIG FOLDERS BELONG TO ${user} ---"
chown ${user}:${user} /home/${user}/.config 2>/dev/null && echo "  ✅ .config" || echo "  ⚠️ .config not found"
chown ${user}:${user} /home/${user}/.local 2>/dev/null && echo "  ✅ .local" || echo "  ⚠️ .local not found"
chown ${user}:${user} /home/${user}/.cache 2>/dev/null && echo "  ✅ .cache" || echo "  ⚠️ .cache not found"
echo ""

# Root protection for crown jewels
echo "--- 👑 PLACING CROWN JEWELS UNDER ROOT'S PROTECTION ---"
for file in "/home/${user}/.bashrc" "/home/${user}/.brave-restricted/whitelist.pac" "/home/${user}/.config/flameshot/flameshot.ini" "/home/${user}/.local/share/Trash"; do
    if [ -e "\$file" ]; then
        chattr -i "\$file" 2>/dev/null
        if chown root:root "\$file" 2>/dev/null; then
            echo "  ✅ \$(basename \$file)"
        else
            echo "  ❌ \$(basename \$file) — chown FAILED"
        fi
    else
        echo "  ⚠️ \$file not found (skipping)"
    fi
done

if [ -d "/home/${user}/.local/share/applications" ]; then
    find /home/${user}/.local/share/applications -name "*.desktop" -exec chattr -i {} \; 2>/dev/null
    find /home/${user}/.local/share/applications -name "*.desktop" -exec chown root:root {} \;
    echo "  ✅ All .desktop files now owned by root"
else
    echo "  ⚠️ /home/${user}/.local/share/applications not found"
fi
echo ""

# AnyDesk Wayland helper: DEBE pertenecer al usuario y NO ser inmutable.
# Plasma source los scripts de plasma-workspace/env con privilegios del usuario;
# si son root-owned o inmutables, Plasma los ignora y AnyDesk no captura pantalla.
if [ -f "/home/${user}/.config/plasma-workspace/env/anydesk-wayland.sh" ]; then
    chattr -i "/home/${user}/.config/plasma-workspace/env/anydesk-wayland.sh" 2>/dev/null
    if chown ${user}:${user} "/home/${user}/.config/plasma-workspace/env/anydesk-wayland.sh" 2>/dev/null \
       && chmod 755 "/home/${user}/.config/plasma-workspace/env/anydesk-wayland.sh" 2>/dev/null; then
        echo "  ✅ anydesk-wayland.sh (user-owned, executable, mutable)"
    else
        echo "  ❌ anydesk-wayland.sh — chown/chmod FAILED"
    fi
fi

# Hide menu entries for applications that should be inaccessible after lockdown
echo "--- 🚫 HIDING DANGEROUS APPLICATIONS FROM MENU ---"
HIDE_APPS=("kmenuedit")

mkdir -p "/home/${user}/.local/share/applications"

for app in "\${HIDE_APPS[@]}"; do
    while IFS= read -r filepath; do
        filename=\$(basename "\$filepath")
        cat > "/home/${user}/.local/share/applications/\$filename" << 'INNERDESK'
[Desktop Entry]
Type=Application
NoDisplay=true
Exec=/usr/bin/false
INNERDESK
        echo "   🔒 Hidden: \$filename"
    done < <(find /usr/share/applications -type f -iname "*\${app}*.desktop" 2>/dev/null)
done
echo ""

# Immutability
echo "--- 💎 CASTING THE FINAL IMMUTABILITY SPELL ---"
apply_immutable() {
    local file="\$1"
    if [ -e "\$file" ]; then
        if lsattr "\$file" 2>/dev/null | grep -q "^....i"; then
            echo "  ✅ \$file is already immutable"
        else
            if chattr +i "\$file" 2>/dev/null; then
                echo "  ✅ \$file is now immutable"
            else
                echo "  ⚠️ Could not set +i on \$file"
            fi
        fi
    else
        echo "  ⚠️ \$file not found, skipping"
    fi
}

apply_immutable "/home/${user}/.bashrc"
apply_immutable "/home/${user}/.brave-restricted/whitelist.pac"
apply_immutable "/home/${user}/.config/flameshot/flameshot.ini"
apply_immutable "/home/${user}/.local/share/Trash"

if [ -f "/home/${user}/.config/wezterm/wezterm.lua" ]; then
    chattr -i "/home/${user}/.config/wezterm/wezterm.lua" 2>/dev/null
    chown root:root "/home/${user}/.config/wezterm/wezterm.lua" 2>/dev/null
    chmod 644 "/home/${user}/.config/wezterm/wezterm.lua" 2>/dev/null
    apply_immutable "/home/${user}/.config/wezterm/wezterm.lua"
fi

if [ -d "/home/${user}/.local/share/applications" ]; then
    find /home/${user}/.local/share/applications -name "*.desktop" -exec chmod 644 {} \;
    echo "  ✅ .desktop files permissions set to 644"
fi
echo ""

# anydesk-wayland.sh: user-owned + executable, NO inmutable (Plasma debe poder leerlo
# como su dueño al sourcearlo en login).
if [ -f "/home/${user}/.config/plasma-workspace/env/anydesk-wayland.sh" ]; then
    chattr -i "/home/${user}/.config/plasma-workspace/env/anydesk-wayland.sh" 2>/dev/null
    chown ${user}:${user} "/home/${user}/.config/plasma-workspace/env/anydesk-wayland.sh" 2>/dev/null
    chmod 755 "/home/${user}/.config/plasma-workspace/env/anydesk-wayland.sh" 2>/dev/null
fi

# Plasma desktop locking
echo "--- 🔒 LOCKING PLASMA DESKTOP (immutable panels) ---"
PLASMA_CONF="/home/${user}/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "\$PLASMA_CONF" ]; then
    chattr -i "\$PLASMA_CONF" 2>/dev/null
    if [ ! -f "\$PLASMA_CONF.bak" ]; then
        cp "\$PLASMA_CONF" "\$PLASMA_CONF.bak"
        echo "  ✅ Backup of plasma config created"
    fi
    chown ${user}:${user} "\$PLASMA_CONF"
    chattr +i "\$PLASMA_CONF" 2>/dev/null
    echo "  ✅ Plasma desktop locked (panels and widgets are now immutable)."
else
    echo "  ⚠️ Plasma config file not found – will be locked after first login."
fi
echo ""

# Append-only folders
echo "--- 📁 APPLYING APPEND-ONLY TO PERSONAL FOLDERS ---"
_FS_TYPE=\$(df -T "/home/${user}" 2>/dev/null | awk 'NR==2{print \$2}')
_IS_BTRFS=false
[[ "\$_FS_TYPE" == "btrfs" ]] && _IS_BTRFS=true
[ "\$_IS_BTRFS" = true ] && echo "  📌 BTRFS detected — +a not supported on this filesystem."

for dir in "Desktop" "Documents" "Downloads" "Pictures"; do
    FULL_PATH="/home/${user}/\$dir"
    if [ ! -d "\$FULL_PATH" ]; then
        echo "  ⚠️ \$FULL_PATH not found, skipping"
        continue
    fi
    if [ "\$_IS_BTRFS" = true ]; then
        echo "  ⏭️  \$dir — BTRFS (append-only N/A, skipped)"
        continue
    fi
    if lsattr -d "\$FULL_PATH" 2>/dev/null | grep -q "^....a"; then
        echo "  ✅ \$dir is already append-only"
    else
        if chattr +a "\$FULL_PATH" 2>/dev/null; then
            if lsattr -d "\$FULL_PATH" 2>/dev/null | grep -q "^....a"; then
                echo "  ✅ \$dir is now append-only"
            else
                echo "  ⚠️ \$dir — +a reported success but not applied (FS limitation)"
            fi
        else
            echo "  ⚠️ Could not set +a on \$dir"
        fi
    fi
done

# Same for Trash_Dropbox
if [ -d "/home/${user}/Trash_Dropbox" ]; then
    if [ "\$_IS_BTRFS" = true ]; then
        echo "  ⏭️  Trash_Dropbox — BTRFS (append-only N/A, skipped)"
    else
        if lsattr -d "/home/${user}/Trash_Dropbox" 2>/dev/null | grep -q "^....a"; then
            echo "  ✅ Trash_Dropbox is already append-only"
        else
            if chattr +a "/home/${user}/Trash_Dropbox" 2>/dev/null; then
                if lsattr -d "/home/${user}/Trash_Dropbox" 2>/dev/null | grep -q "^....a"; then
                    echo "  ✅ Trash_Dropbox is now append-only"
                else
                    echo "  ⚠️ Trash_Dropbox — +a reported success but not applied (FS limitation)"
                fi
            else
                echo "  ⚠️ Could not set +a on Trash_Dropbox"
            fi
        fi
    fi
else
    echo "  ⚠️ /home/${user}/Trash_Dropbox not found, skipping"
fi

# Block dangerous binaries
echo "--- 🚫 SEALING DANGEROUS BINARIES FROM ${user} ---"
binarios=(
    "/usr/bin/ark"
    "/usr/bin/chattr"
    "/usr/bin/kitty"
    "/usr/bin/kmenuedit"
    "/usr/bin/konsole"
    "/usr/bin/kwriteconfig5"
    "/usr/bin/kwriteconfig6"
    "/usr/bin/lsattr"
    "/usr/bin/gufw"
    "/usr/bin/nm-connection-editor"
    "/usr/bin/nmcli"
    "/usr/bin/plasma-open-settings"
    "/usr/bin/reflector-simple"
    "/usr/bin/rm"
    "/usr/bin/systemsettings"
    "/usr/bin/uxterm"
    "/usr/bin/xterm"
    "/usr/bin/yad"
)
# Add globs
for pattern in "/usr/bin/assistant*" "/usr/bin/cpan*" "/usr/bin/designer*" "/usr/bin/linguist*" "/usr/bin/pip3*" "/usr/bin/proton-pass*" "/usr/bin/protonvpn*"; do
    for b in \$pattern; do
        [ -f "\$b" ] && binarios+=("\$b")
    done
done

for b in "\${binarios[@]}"; do
    if [ -f "\$b" ]; then
        chmod 750 "\$b" 2>/dev/null
        chown root:guardian "\$b" 2>/dev/null
        setfacl -b "\$b" 2>/dev/null
        setfacl -m u:${user}:0 "\$b" 2>/dev/null
        echo "   🔒 Blocked: \$b"
    fi
done

# Also block interpreters
for pattern in "/usr/bin/python*" "/usr/bin/perl*" "/usr/bin/ruby*" "/usr/bin/node*" "/usr/bin/php*" "/usr/bin/lua*" "/usr/bin/tclsh*"; do
    for b in \$pattern; do
        if [ -f "\$b" ]; then
            setfacl -m u:${user}:0 "\$b" 2>/dev/null
            echo "   🔒 Blocked interpreter: \$b"
        fi
    done
done

# Block AnyDesk if this user cannot initiate connections
if [ "${cap_connect}" != "true" ]; then
    if [ -f "/usr/bin/anydesk" ]; then
        setfacl -m u:${user}:0 /usr/bin/anydesk 2>/dev/null
        echo "   🔒 Blocked: AnyDesk (no connect permission)"
    fi
fi

# Verify lockdown
echo "--- 🔍 VERIFYING LOCKDOWN ---"
for file in "/home/${user}/.bashrc" "/home/${user}/.brave-restricted/whitelist.pac" "/home/${user}/.config/flameshot/flameshot.ini"; do
    if [ ! -e "\$file" ]; then
        echo "  ⚠️ \$(basename \$file) does not exist (skipped earlier?)"
    elif lsattr "\$file" 2>/dev/null | grep -q "^....i"; then
        echo "  ✅ \$(basename \$file) is immutable"
    else
        echo "  ❌ \$(basename \$file) is NOT immutable!"
    fi
done

for dir in "Desktop" "Documents" "Downloads" "Pictures" "Trash_Dropbox"; do
    if [ ! -d "/home/${user}/\$dir" ]; then
        echo "  ⚠️ \$dir directory does not exist"
    elif [ "\$_IS_BTRFS" = true ]; then
        echo "  ⏭️  \$dir — BTRFS (append-only N/A)"
    elif lsattr -d "/home/${user}/\$dir" 2>/dev/null | grep -q "^....a"; then
        echo "  ✅ \$dir is append-only"
    else
        echo "  ❌ \$dir is NOT append-only!"
    fi
done

for file in "/home/${user}/.bashrc" "/home/${user}/.config/flameshot/flameshot.ini" "/home/${user}/.local/share/Trash"; do
    if [ ! -e "\$file" ]; then
        echo "  ⚠️ \$(basename \$file) does not exist"
    elif [ "\$(stat -c %U "\$file" 2>/dev/null)" = "root" ]; then
        echo "  ✅ \$(basename \$file) owned by root"
    else
        echo "  ❌ \$(basename \$file) not owned by root (current owner: \$(stat -c %U "\$file" 2>/dev/null))"
    fi
done

# Remove sudo
echo "--- 🔒 REMOVING SUDO ACCESS FROM ${user} ---"
if groups ${user} | grep -q wheel; then
    gpasswd -d ${user} wheel
    echo "✅ ${user} removed from wheel group."
else
    echo "ℹ️ ${user} not in wheel group (already safe)."
fi
rm -f /etc/sudoers.d/${user}

_SUDO_CHECK=\$(sudo -l -U ${user} 2>&1)
if echo "\$_SUDO_CHECK" | grep -qi "not allowed to run sudo\|no sudoers file\|User ${user} is not allowed"; then
    echo "✅ ${user} has no sudo privileges – perfect!"
elif echo "\$_SUDO_CHECK" | grep -qi "(root) NOPASSWD:"; then
    echo "⚠️ ${user} still has sudo – better check manually!"
    echo "   Detail: \$(echo "\$_SUDO_CHECK" | grep NOPASSWD | head -3)"
else
    echo "✅ ${user} has no sudo privileges."
fi

# Clear command history for root (current session)
history -c

# Clear command history for the target user
if [ -f "/home/${user}/.bash_history" ]; then
     sudo truncate -s 0 "/home/${user}/.bash_history" 2>/dev/null && echo "✅ Cleared ${user}'s command history."
fi


echo ""
echo "The caterpillar rests within its sealed chrysalis, awaiting rebirth 🐛..."
}
LOCKEOF
}




# Function to add unlock function to bashrc
add_unlock_function_to_bashrc() {
    local user="$1"
    
    cat >> /home/guardian/.bashrc <<UNLOCKEOF

# --- 🔓 UNLOCK FUNCTION (Free-Pupa) ---
Free-Pupa() {
    local user="${user}"
    
    # Auto-elevate to root if not already
    if [ "\$EUID" -ne 0 ]; then
        echo "🔐 Elevating to root privileges..."
        sudo bash -c "\$(declare -f Free-Pupa); Free-Pupa"
        return \$?
    fi
    
    echo "🔓 EMERGENCY MODE ACTIVATED: Temporarily freeing \${user}..."
    pkill -u ${user} 2>/dev/null || true
    sleep 2

# 1. Unlock the GUI panels via DBUS
DBUS_CMD=""
if command -v qdbus6 &>/dev/null; then DBUS_CMD="qdbus6"; elif command -v qdbus &>/dev/null; then DBUS_CMD="qdbus"; fi
if [ -n "\$DBUS_CMD" ]; then
    USER_PID=\$(pgrep -u ${user} -f plasmashell | head -1)
    if [ -n "\$USER_PID" ]; then
        DBUS_ADDR=\$(sudo grep -z DBUS_SESSION_BUS_ADDRESS /proc/\$USER_PID/environ 2>/dev/null | tr -d '\0' | cut -d= -f2-)
        if [ -n "\$DBUS_ADDR" ]; then
            sudo -u ${user} DBUS_SESSION_BUS_ADDRESS="\$DBUS_ADDR" \$DBUS_CMD org.kde.plasmashell /PlasmaShell evaluateScript 'lockCorona(false)' 2>/dev/null && echo "  ✅ KDE Desktop unlocked."
        fi
    fi
fi

# 2. Remove file immutability/append-only
 sudo chattr -R -i -a /home/${user} 2>/dev/null || true
 sudo chown -R ${user}:${user} /home/${user} 2>/dev/null || true
 sudo setfacl -R -b /home/${user} 2>/dev/null || true
echo "  ✅ File attributes and ACLs removed."

# 3. Unblock all system binaries and interpreters
binarios=(
    "/usr/bin/ark" "/usr/bin/chattr" "/usr/bin/kitty" "/usr/bin/kmenuedit"
    "/usr/bin/konsole" "/usr/bin/kwriteconfig5" "/usr/bin/kwriteconfig6"
    "/usr/bin/lsattr" "/usr/bin/gufw" "/usr/bin/nm-connection-editor"
    "/usr/bin/nmcli" "/usr/bin/plasma-open-settings" "/usr/bin/reflector-simple"
    "/usr/bin/rm" "/usr/bin/systemsettings" "/usr/bin/uxterm" "/usr/bin/xterm"
    "/usr/bin/yad"
)
for pattern in "/usr/bin/assistant*" "/usr/bin/cpan*" "/usr/bin/designer*" "/usr/bin/linguist*" "/usr/bin/pip3*" "/usr/bin/proton-pass*" "/usr/bin/protonvpn*" "/usr/bin/python*" "/usr/bin/perl*" "/usr/bin/ruby*" "/usr/bin/node*" "/usr/bin/php*" "/usr/bin/lua*" "/usr/bin/tclsh*"; do
    for b in \$pattern; do [ -f "\$b" ] && binarios+=("\$b"); done
done
for b in "\${binarios[@]}"; do
    if [ -f "\$b" ]; then
         sudo chmod 755 "\$b" 2>/dev/null
         sudo chown root:root "\$b" 2>/dev/null
         sudo setfacl -b "\$b" 2>/dev/null
    fi
done
echo "  ✅ System binaries unblocked."

# 4. Restore App Menu (so they can actually open apps to troubleshoot)
 sudo rm -rf /home/${user}/.local/share/applications/*.desktop 2>/dev/null || true
 sudo -u ${user} XDG_DATA_DIRS="/home/${user}/.local/share:/usr/share" update-desktop-database /home/${user}/.local/share/applications/ 2>/dev/null || true
echo "  ✅ Application menu restored."

# 5. Suspend Brave restrictions (rename to .bak so brave-policies-on can restore it later)
if [ -f "/etc/brave/policies/managed/${user}_policy.json" ]; then
     sudo mv "/etc/brave/policies/managed/${user}_policy.json" "/etc/brave/policies/managed/${user}_policy.json.bak" 2>/dev/null
    echo "  ✅ Brave policies suspended."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  🕊️  ${user} IS TEMPORARILY FREE TO BE FIXED.  🕊️"
echo "═══════════════════════════════════════════════════════════════"
echo "  🔔 Once fixed, lock it back up by running: Seal-Pupa"
}
UNLOCKEOF
}



# Function to add nuke function to bashrc
add_nuke_function_to_bashrc() {
    local user="$1"
    
    cat >> /home/guardian/.bashrc <<NUKEEOF

# --- 💥 NUKE FUNCTION (Shatter-Chrysalis) ---
Shatter-Chrysalis() {
    local user="${user}"
    
    # Auto-elevate to root if not already
    if [ "\$EUID" -ne 0 ]; then
        echo "🔐 Elevating to root privileges..."
        sudo bash -c "\$(declare -f Shatter-Chrysalis); Shatter-Chrysalis"
        return \$?
    fi
    
    echo "🔥🔥🔥 SHATTERING THE CHRYSALIS – TOTAL EMERGENCY RESET 🔥🔥🔥"
    echo "⚠️  This will remove ALL restrictions, unblock binaries, restore policies, and free \${user}."
    read -rp "💥 Are you ABSOLUTELY sure? Type 'YES' (all caps): " confirm
    if [ "\$confirm" != "YES" ]; then
        echo "😌 Phew! Emergency reset cancelled. Nothing changed."
        return 0
    fi

echo "💫 Freeing ${user} from all chains..."

# 1. Kill user processes to prevent state conflicts
 sudo pkill -u ${user} 2>/dev/null || true
sleep 1

# 2. Unlock the KDE Desktop via DBUS (if currently logged in)
DBUS_CMD=""
if command -v qdbus6 &>/dev/null; then DBUS_CMD="qdbus6"; elif command -v qdbus &>/dev/null; then DBUS_CMD="qdbus"; fi
if [ -n "\$DBUS_CMD" ]; then
    USER_PID=\$(pgrep -u ${user} -f plasmashell | head -1)
    if [ -n "\$USER_PID" ]; then
        DBUS_ADDR=\$(sudo grep -z DBUS_SESSION_BUS_ADDRESS /proc/\$USER_PID/environ 2>/dev/null | tr -d '\0' | cut -d= -f2-)
        if [ -n "\$DBUS_ADDR" ]; then
            sudo -u ${user} DBUS_SESSION_BUS_ADDRESS="\$DBUS_ADDR" \$DBUS_CMD org.kde.plasmashell /PlasmaShell evaluateScript 'lockCorona(false)' 2>/dev/null && echo "  ✅ KDE Desktop unlocked."
        fi
    fi
fi

# 3. Remove all file immutability and append-only flags
 sudo chattr -R -i -a /home/${user} 2>/dev/null || true
echo "  ✅ File attributes (immutable/append-only) removed."

# 4. Restore full ownership to the user
 sudo chown -R ${user}:${user} /home/${user} 2>/dev/null || true
echo "  ✅ File ownership restored to ${user}."

# 5. Clear all ACLs on the user's home directory
 sudo setfacl -R -b /home/${user} 2>/dev/null || true
echo "  ✅ Custom ACLs cleared."

# 6. Unblock all restricted system binaries and interpreters
binaries=(
    "/usr/bin/ark" "/usr/bin/chattr" "/usr/bin/kitty" "/usr/bin/kmenuedit"
    "/usr/bin/konsole" "/usr/bin/kwriteconfig5" "/usr/bin/kwriteconfig6"
    "/usr/bin/lsattr" "/usr/bin/gufw" "/usr/bin/nm-connection-editor"
    "/usr/bin/nmcli" "/usr/bin/plasma-open-settings" "/usr/bin/reflector-simple"
    "/usr/bin/rm" "/usr/bin/systemsettings" "/usr/bin/uxterm" "/usr/bin/xterm"
    "/usr/bin/yad"
)
for pattern in "/usr/bin/assistant*" "/usr/bin/cpan*" "/usr/bin/designer*" "/usr/bin/linguist*" "/usr/bin/pip3*" "/usr/bin/proton-pass*" "/usr/bin/protonvpn*" "/usr/bin/python*" "/usr/bin/perl*" "/usr/bin/ruby*" "/usr/bin/node*" "/usr/bin/php*" "/usr/bin/lua*" "/usr/bin/tclsh*"; do
    for b in \$pattern; do [ -f "\$b" ] && binaries+=("\$b"); done
done

for b in "\${binaries[@]}"; do
    if [ -f "\$b" ]; then
         sudo chmod 755 "\$b" 2>/dev/null
         sudo chown root:root "\$b" 2>/dev/null
         sudo setfacl -b "\$b" 2>/dev/null
    fi
done
echo "  ✅ System binaries and interpreters unblocked."

# 7. Remove Firejail profile
 sudo rm -f /etc/firejail/${user}.profile 2>/dev/null || true
echo "  ✅ Firejail profile deleted."

# 8. Remove SDDM auto-login config for this user
 sudo rm -f /etc/sddm.conf.d/${user}.conf 2>/dev/null || true
echo "  ✅ SDDM auto-login removed."

# 9. Remove Brave browser restrictions
 sudo rm -f /etc/brave/policies/managed/${user}_policy.json 2>/dev/null || true
 sudo rm -f /etc/brave/policies/managed/${user}_policy.json.bak 2>/dev/null || true
 sudo rm -rf /home/${user}/.brave-restricted 2>/dev/null || true
echo "  ✅ Brave policies nuked."

# 10. Restore .desktop files (unhide apps)
 sudo rm -rf /home/${user}/.local/share/applications/*.desktop 2>/dev/null || true
 sudo -u ${user} XDG_DATA_DIRS="/home/${user}/.local/share:/usr/share" update-desktop-database /home/${user}/.local/share/applications/ 2>/dev/null || true
echo "  ✅ Application menu restored."

# 10.5 Restore Plasma desktop configuration from backup (Coworker's safety net)
PLASMA_CONF="/home/${user}/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "\$PLASMA_CONF.bak" ]; then
    echo "🔄 Restoring Plasma desktop configuration from backup..."
     sudo mv "\$PLASMA_CONF.bak" "\$PLASMA_CONF" 2>/dev/null || true
     sudo chown ${user}:${user} "\$PLASMA_CONF" 2>/dev/null || true
    echo "  ✅ Plasma panels restored to pre-lock state."
fi

# 11. Give back sudo temporarily if requested
read -rp "🔑 Grant ${user} temporary sudo/wheel access? (y/N): " grant_sudo
if [[ "\$grant_sudo" =~ ^[Yy]\$ ]]; then
     sudo usermod -aG wheel ${user} 2>/dev/null
    echo "  ✅ ${user} added to wheel group."
else
     sudo gpasswd -d ${user} wheel 2>/dev/null || true
    echo "  ℹ️  ${user} kept out of wheel group."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  🕊️  THE CHRYSALIS IS SHATTERED. ${user} IS COMPLETELY FREE.  🕊️"
echo "═══════════════════════════════════════════════════════════════"
echo "  ⚠️  Note: Global hardening (Firewall, USBGuard, Auditd, Fail2ban)"
echo "  remains active to protect the system."
echo ""
echo "  🔔 To put the spells back later, run: Seal-Pupa"
}
NUKEEOF
}

# Clean and reset admin's .bashrc - preserving custom content
echo "🧹 Limpiando configuración Micpapalotlan del bashrc de guardian..."

# Limpiar archivos temporales residuales de ejecuciones anteriores (pueden tener permisos incorrectos)
rm -f /tmp/bashrc-custom.tmp /tmp/admin-extras.tmp /tmp/sanctuary-guide.tmp /tmp/Harvest-Dropbox.tmp /tmp/Tend-Garden.tmp /tmp/Sanctuary-Watch.tmp /tmp/run-in-user.tmp /tmp/Unweave-Cocoon.tmp /tmp/Weave-Cocoon-header.tmp /tmp/brave-policy-fresh.json 2>/dev/null || true

# Usar archivo temporal único y propiedad del root para evitar conflictos
BASHRC_TMP=$(mktemp /tmp/micpapalotlan-bashrc.XXXXXX)
chmod 600 "$BASHRC_TMP"

# Check if bashrc exists and has custom content before markers
if [ -f /home/guardian/.bashrc ]; then
    # Eliminar inmutabilidad si existe (versión antigua pudo haberlo bloqueado)
    chattr -i /home/guardian/.bashrc 2>/dev/null || true
    
    # Extract content before Micpapalotlan markers (user's custom config)
    if grep -q "# === MICPAPALOTLAN CONFIG BEGIN ===" /home/guardian/.bashrc 2>/dev/null; then
        # Has markers - extract only custom content before markers
        sed -n '1,/# === MICPAPALOTLAN CONFIG BEGIN ===/p' /home/guardian/.bashrc | head -n -1 > "$BASHRC_TMP"
        echo "✅ Configuración personalizada preservada (con marcadores)"
    else
        # No markers found - this is from old version, reset to default
        echo "⚠️  Bashrc sin marcadores detectado (versión antigua)"
        echo "   Reseteando a configuración por defecto..."
        cat > "$BASHRC_TMP" << 'DEFAULTBASHRC'
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
DEFAULTBASHRC
        echo "✅ Bashrc reseteado a configuración por defecto"
    fi
    
    # Replace entire bashrc with clean custom content (verify write succeeded)
    if ! cp "$BASHRC_TMP" /home/guardian/.bashrc; then
        echo "❌ ERROR: No se pudo reemplazar /home/guardian/.bashrc"
        exit 1
    fi
    chown guardian:guardian /home/guardian/.bashrc
    
else
    # Create default bashrc if it doesn't exist
    cat > "$BASHRC_TMP" << 'DEFAULTBASHRC'
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
DEFAULTBASHRC
    cp "$BASHRC_TMP" /home/guardian/.bashrc
    chown guardian:guardian /home/guardian/.bashrc
    echo "✅ .bashrc creado con configuración por defecto"
fi

# Limpiar archivo temporal
rm -f "$BASHRC_TMP"

# Start Micpapalotlan configuration section
echo "" >> /home/guardian/.bashrc
echo "# === MICPAPALOTLAN CONFIG BEGIN ===" >> /home/guardian/.bashrc
echo "# Auto-generated by Metamorphosis.sh - Do not edit manually between markers" >> /home/guardian/.bashrc
echo "# Generated: $(date)" >> /home/guardian/.bashrc

# Add functions to admin's .bashrc
add_lock_function_to_bashrc "$USUARIO" "$CAN_CONNECT"
add_unlock_function_to_bashrc "$USUARIO"
add_nuke_function_to_bashrc "$USUARIO"

echo "   🌟 Seal-Pupa       – reapplies restrictions"
echo "   🔓 Free-Pupa       – removes restrictions"
echo "   💥 Shatter-Chrysalis – total reset (use with caution)"
echo ""

# ----------------------------------------------------------------------
# 7.2 🌾 GOD OF HARVEST COMMANDS (for guardian)
# ----------------------------------------------------------------------
echo "--- 🌾 INSTALLING HARVESTER AND DISSOLVE COMMANDS ---"
cat >> /home/guardian/.bashrc <<'GODEOF

# --- 🌾 GOD OF HARVEST COMMANDS ---
alias harvester='if id "$USUARIO" &>/dev/null; then echo "⚠️  The Harvester senses a user named $USUARIO exists. Use \"dissolve\" to destroy."; else echo "😌 The Harvester: No $USUARIO user found."; fi'

# Dissolve function (better than alias for interactive prompts)
dissolve() {
    local target_user="$USUARIO"
    
    if ! id "$target_user" &>/dev/null; then
        echo "😌 No $target_user user to dissolve."
        return 0
    fi
    
    echo "⚠️  The Harvester has found user: $target_user"
    read -p "🌀 Proceed with DISSOLVE? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🌾 DISSOLVE INITIATED..."
        sudo loginctl terminate-user "$target_user" 2>/dev/null
        sleep 2
        sudo pkill -u "$target_user" -9 2>/dev/null
        sudo chattr -R -i -a "/home/$target_user" 2>/dev/null
        sudo userdel -rf "$target_user" 2>/dev/null
        sudo rm -rf "/home/$target_user" 2>/dev/null
        echo "🌾 DISSOLVED! $target_user returned to the earth."
    else
        echo "😌 Dissolve cancelled. The user lives another day."
    fi
}
GODEOF

# Replace $USUARIO placeholder with actual username (escape sed metacharacters in name)
_USUARIO_SED=$(printf '%s' "$USUARIO" | sed 's/[&/\]/\\&/g')
sed -i "s/\\\$USUARIO/${_USUARIO_SED}/g" /home/guardian/.bashrc

echo "✅ Harvester and Dissolve commands installed! Use them wisely, Keeper of the Garden. 🌾"
echo ""

# ----------------------------------------------------------------------
# 7.3 📸 BTRFS SNAPSHOT, RESCUE GUIDE, AND AUDIT COMMANDS
# ----------------------------------------------------------------------
if id "guardian" &>/dev/null; then
    # Create the additional bashrc content in a temp file first
    cat > /tmp/start-session.tmp <<STARTSESSIONEOF

# --- 🚀 START SESSION FUNCTION ---
start-${USUARIO}-session() {
    echo "Starting ${USUARIO}'s Wayland session..."
    sudo -u ${USUARIO} dbus-launch --exit-with-session startplasma-wayland &
    echo "Session started. Check with 'ps aux | grep plasma-wayland'."
}
STARTSESSIONEOF
     sudo tee -a /home/guardian/.bashrc < /tmp/start-session.tmp > /dev/null
    rm -f /tmp/start-session.tmp

    cat > /tmp/net-aliases.tmp <<NETALIASEOF

# --- GLOBAL IDENTITY SWITCH ---
alias android16='sudo sysctl -w net.ipv4.ip_default_ttl=65 && sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 && echo "MOBILE MODE: TTL 65 | IPv6 Blocked | Hidden Tethering"'
alias quack='sudo sysctl -w net.ipv4.ip_default_ttl=128 && sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 && sudo sysctl -w net.ipv4.tcp_timestamps=0 && sudo sysctl -w net.ipv4.tcp_window_scaling=0 && sudo systemctl enable --now smb nmb wsdd 2>/dev/null && sudo systemctl disable --now avahi-daemon 2>/dev/null && echo "🦆 QUACK! Now I am a Windows duck!"'
alias unquack='sudo sysctl -w net.ipv4.ip_default_ttl=64 && sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 && sudo sysctl -w net.ipv4.tcp_timestamps=1 && sudo sysctl -w net.ipv4.tcp_window_scaling=1 && sudo systemctl disable --now smb nmb wsdd 2>/dev/null && sudo systemctl enable --now avahi-daemon 2>/dev/null && echo "🐧 Unquack! Back to being a Linux penguin."'
alias net-check='echo "Current TTL: $(sudo sysctl -n net.ipv4.ip_default_ttl)" && echo "IPv6 Disabled: $(sudo sysctl -n net.ipv6.conf.all.disable_ipv6)"'

# --- 📡 ANYDESK DIAGNOSTICS ---
alias anydesk-status='echo "📡 AnyDesk Service:" && sudo systemctl status anydesk --no-pager -l 2>/dev/null | head -15'
alias anydesk-id='echo "📡 AnyDesk ID: $(anydesk --get-id 2>/dev/null)" && echo "📡 Password: $(sudo gpg --decrypt /root/anydesk-password.gpg 2>/dev/null)"'
alias anydesk-restart='echo "📡 Restarting AnyDesk..." && sudo systemctl restart anydesk && sleep 3 && echo "✅ ID: $(anydesk --get-id)"'
alias anydesk-wayland-check='echo "📡 Checking Wayland permissions for AnyDesk..." && TARGET_USER="${USUARIO}" && TARGET_UID=$(id -u "$TARGET_USER" 2>/dev/null) && if [[ -n "$TARGET_UID" && -d "/run/user/$TARGET_UID" ]]; then echo "Runtime dir: /run/user/$TARGET_UID" && ls -la /run/user/$TARGET_UID/wayland-* 2>/dev/null && echo "ACLs:" && getfacl /run/user/$TARGET_UID/wayland-* 2>/dev/null; else echo "❌ User not logged in or no Wayland socket found"; fi'
NETALIASEOF
    sudo tee -a /home/guardian/.bashrc < /tmp/net-aliases.tmp > /dev/null
    rm -f /tmp/net-aliases.tmp

    cat > /tmp/admin-extras.tmp <<'ADMINEOF'

# --- 📸 BTRFS SNAPSHOT COMMANDS ---
alias snapshots='sudo btrfs subvolume list /.snapshots 2>/dev/null || echo "❌ No snapshots found or not BTRFS"'

alias snapshot-create='sudo mkdir -p /.snapshots && SNAP_NAME="pre_$(date +"%Y%m%d_%H%M%S")" && sudo btrfs subvolume snapshot -r / "/.snapshots/$SNAP_NAME" && echo "✅ Snapshot created: $SNAP_NAME" && echo "   Use: snapshot-restore $SNAP_NAME to restore it"'

snapshot-restore() {
    if [ -z "$1" ]; then
        echo "❌ Usage: snapshot-restore SNAPSHOT_NAME"
        echo "   Example: snapshot-restore pre_20250226_143025"
        echo "   Use 'snapshots' to see available names"
    else
        echo "🌀 Restoring snapshot: $1"
        echo "   This will replace your current system!"
        read -rp "💥 Are you ABSOLUTELY sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ROOT_SUBVOL=$(sudo btrfs subvolume show / 2>/dev/null | grep -oP '/(@?[^/]+)$' | head -1)
            [ -z "$ROOT_SUBVOL" ] && ROOT_SUBVOL="@"
             sudo btrfs subvolume delete "$ROOT_SUBVOL" 2>/dev/null || true
            if sudo btrfs subvolume snapshot "/.snapshots/$1" "$ROOT_SUBVOL"; then
                echo "✅ Restored to $1! Reboot now."
            else
                echo "❌ Failed to restore snapshot"
            fi
        else
            echo "😌 Restore cancelled."
        fi
    fi
}

ADMINEOF

     sudo tee -a /home/guardian/.bashrc < /tmp/admin-extras.tmp > /dev/null
    rm -f /tmp/admin-extras.tmp
    echo "ℹ️  Manual launcher: start-${USUARIO}-session (run from guardian)"

    cat > /tmp/zebra-admin.tmp <<'ZEBRAADMINEOF

# --- 🏷️ Zebra ZT231 / gLabels CUPS helpers ---
# Prerequisite: ZT231 on network; CUPS uses raw ZPL socket :9100.
# gLabels prints PostScript — Ghostscript/CUPS filters produce ZPL (not gLabels).

zebra-zt231-setup() {
    local ip="${1:-}"
    if [[ -z "$ip" ]]; then
        read -rp "Zebra ZT231 IP address: " ip
    fi
    if [[ -z "$ip" ]]; then
        echo "❌ No IP provided."
        return 1
    fi
    sudo mkdir -p /etc/micpapalotlan
    printf "ZEBRA_IP='%s'\nZEBRA_QUEUE='Zebra_ZT231'\n" "$ip" | sudo tee /etc/micpapalotlan/zebra-zt231.env > /dev/null
    echo "🔧 Applying CUPS queue via pupa-zebra-apply ..."
    if sudo /usr/local/bin/pupa-zebra-apply; then
        echo "✅ Queue ready. Or use: sudo Gardener → option 3"
        lpstat -p Zebra_ZT231 -l 2>/dev/null | head -5 || true
    else
        echo "❌ Setup failed. Try: sudo Gardener (option 3) to scan the network."
        return 1
    fi
}

zebra-print-test() {
    local zpl='^XA^FO50,50^ADN,36,20^FDMicpapalotlan ZPL test^FS^XZ'
    echo "🖨️  Sending test ZPL to Zebra_ZT231..."
    echo "$zpl" | lp -d Zebra_ZT231 -o raw 2>/dev/null && echo "✅ Job submitted." || {
        echo "❌ Print failed. Run zebra-zt231-setup <ip> first."
        return 1
    }
}

zebra-print-status() {
    echo "--- CUPS queues ---"
    lpstat -p 2>/dev/null || echo "CUPS not responding"
    echo ""
    echo "--- Zebra pipeline doc ---"
    [[ -f /etc/cups/zebra-zt231-pipeline.txt ]] && sed -n '1,20p' /etc/cups/zebra-zt231-pipeline.txt
}
ZEBRAADMINEOF
    sudo tee -a /home/guardian/.bashrc < /tmp/zebra-admin.tmp > /dev/null
    rm -f /tmp/zebra-admin.tmp
    echo "✅ Admin helpers: zebra-zt231-setup, zebra-print-test, zebra-print-status"

    # Supernova / Cerberus (admin only — installed in section 7.5)
    cat >> /home/guardian/.bashrc <<'SNLOAD'
# --- ☢️ SUPERNOVA / CERBERUS (guardian only — IRREVERSIBLE) ---
[[ -f /usr/local/lib/micpapalotlan/supernova-admin.sh ]] && source /usr/local/lib/micpapalotlan/supernova-admin.sh
SNLOAD
    echo "✅ Supernova/Cerberus wired (disarmed until Supernova-Arm / Cerberus-Deploy)"

    # Add rescue-me alias separately
    cat > /tmp/sanctuary-guide.tmp <<RESCUEEOF

# --- 🆘 SANCTUARY GUIDE ---
sanctuary-guide() {
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "                      🆘 EMERGENCY SANCTUARY GUIDE 🆘                "
    echo "═══════════════════════════════════════════════════════════════════════"
    echo ""
    echo "✅ Emergency toolkit installed! Admin now has these powerful spells:"
    echo "   🔓 Free-Pupa        – Unlocks everything (basic)"
    echo "   💥 Shatter-Chrysalis – Total reset (removes all restrictions, use with caution!)"
    echo "   ✨ Seal-Pupa        – Locks it back"
    echo "   🧹 Tend-Garden      – Tidies up USERTOKEN's mess"
    echo "   👁️ Sanctuary-Watch  – Audits the chrysalis and judges"
    echo "   🐯 Unweave-Cocoon   – Unrestricted Browser"
    echo "   🐯 Weave-Cocoon     – Restricted Browser"
    echo "   🔓 cocoon-unlock    – Fix 'Brave is already running' error"
    echo "   🦆 quack            – Mimic Windows network (TTL 128, enable SMB/wsdd, disable Avahi)"
    echo "   📱 android16        – Mimic mobile tethering (TTL 65, disable IPv6)"
    echo "   🐧 unquack          – Revert to Linux network (TTL 64, enable Avahi, disable SMB/wsdd)"
    echo "   🔍 net-check        – Show current TTL and IPv6 status"
    echo "   🛡️ Gardener         – USB tethering, USBGuard, Zebra printer setup"
    echo "   🏷️ zebra-zt231-setup   – CUPS queue for Zebra ZT231 (gLabels → ZPL)"
    echo "   🏷️ zebra-print-test    – Send raw ZPL test label"
    echo "   🏷️ zebra-print-status  – CUPS / pipeline status"
    echo "   ☢️ Supernova-Overview  – Kill-switch status (admin only, irreversible)"
    echo "💡 Aliases will be available after logging out/in or running 'source ~/.bashrc'"
    echo ""
    echo "🔹 IF YOU CAN LOGIN AS ADMIN (guardian):"
    echo "   • Emergency unlock: Depending on the severity either run Free-Pupa for an easy fix or Shatter-Chrysalis for something malicious happening"
    echo "   • Relock after fixing: Seal-Pupa"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "   WARNING: NEVER DO CHANGES AS SEED, ALWAYS AS THE ADMIN GUARDIAN"
    echo ""
    echo "🔹 IF SYSTEM WON'T BOOT AND USB Lilith IS AVAILABLE:"
    echo "   1. Insert USB Lilith and boot from it (Rescuezilla)."
    echo "   2. Restore the Micpapalotlan ISO and reboot."
    echo "   3. Run Hatchling.sh and reboot."
    echo "   4. Run Seed.sh and reboot."
    echo "   5. Run APPS.sh and reboot."
    echo "   6. Run Prepare-Machine.sh (If it fixes AppArmor, reboot and run it again)."
    echo "   7. Run Metamorphosis.sh."
    echo "   8. Log in as guardian and run: source ~/.bashrc"
    echo "   9. Take a look inside the Chrysalis and make any changes you would like to keep."
    echo "  10. Run: Seal-Pupa"
    echo "  11. Reboot."
    echo "   All settings will be reapplied."
    echo ""
    echo "🔹 IF USB Lilith IS LOST BUT THE MICPAPALOTLAN ISO IS AVAILABLE:"
    echo "   1. Download Rescuezilla, create bootable USB with the Micpapalotlan ISO."
    echo "   2. Restore the ISO and reboot."
    echo "   3. Run Hatchling.sh and reboot."
    echo "   4. Run Seed.sh and reboot."
    echo "   5. Run APPS.sh and reboot."
    echo "   6. Run Prepare-Machine.sh (If it fixes AppArmor, reboot and run it again)."
    echo "   7. Run Metamorphosis.sh."
    echo "   8. Log in as guardian and run: source ~/.bashrc"
    echo "   9. Take a look inside the Chrysalis and make any changes you would like to keep."
    echo "  10. Run: Seal-Pupa"
    echo "  11. Reboot."
    echo ""
    echo "🔹 IF EVERYTHING IS TERRIBLE (NO USB, NO ISO):"
    echo "   1. Reinstall Arch from scratch (Select BTRFS, GRUB, Swap NO hibernation)."
    echo "   2. Create Guardian Admin during install."
    echo "   3. Run Hatchling.sh and reboot."
    echo "   4. Run Seed.sh and reboot."
    echo "   5. Run APPS.sh and reboot."
    echo "   6. Run Prepare-Machine.sh (If it fixes AppArmor, reboot and run it again)."
    echo "   7. Run Metamorphosis.sh."
    echo "   8. Log in as guardian and run: source ~/.bashrc"
    echo "   9. Take a look inside the Chrysalis and make any changes you would like to keep."
    echo "  10. Run: Seal-Pupa"
    echo "  11. Reboot."
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "     🌸 Don't panic! The butterfly always finds its way home. 🦋✨"
    echo "═══════════════════════════════════════════════════════════════════════"
}
RESCUEEOF
    sed -i "s/USERTOKEN/${USUARIO}/g" /tmp/sanctuary-guide.tmp
     sudo tee -a /home/guardian/.bashrc < /tmp/sanctuary-guide.tmp > /dev/null
    rm -f /tmp/sanctuary-guide.tmp

    # Add empty-trash alias
    cat > /tmp/Harvest-Dropbox.tmp <<EMPTYTRAVERSEOF

# --- 🧹 HARVEST DROPBOX ---
alias Harvest-Dropbox='if [ -d "/home/${USUARIO}/Trash_Dropbox" ]; then echo "🧹 Harvesting Admin Dropbox..."; sudo chattr -a /home/${USUARIO}/Trash_Dropbox 2>/dev/null; sudo rm -rf /home/${USUARIO}/Trash_Dropbox/* 2>/dev/null; sudo chattr +a /home/${USUARIO}/Trash_Dropbox 2>/dev/null; echo "✅ Admin Dropbox harvested and relocked!"; else echo "❌ Trash_Dropbox not found."; fi'
EMPTYTRAVERSEOF
     sudo tee -a /home/guardian/.bashrc < /tmp/Harvest-Dropbox.tmp > /dev/null
    rm -f /tmp/Harvest-Dropbox.tmp

    # Add clean-around function
    cat > /tmp/Tend-Garden.tmp <<CLEANEOF

# --- 🧹 TEND GARDEN SPELL ---
Tend-Garden() {
    echo "🧹 Sweeping away ${USUARIO}'s cobwebs..."
    local err=0
    local msg=""
    if [ -d "/home/${USUARIO}/.cache" ]; then
         sudo rm -rf /home/${USUARIO}/.cache/* 2>/dev/null || { err=1; msg+="Cache directory could not be emptied. "; }
    fi
    if [ -d "/home/${USUARIO}/.local/share/Trash" ]; then
         sudo rm -rf /home/${USUARIO}/.local/share/Trash/* 2>/dev/null || { err=1; msg+="Trash directory could not be emptied. "; }
    fi
     sudo journalctl --vacuum-size=50M > /dev/null 2>&1 || { err=1; msg+="Journal could not be vacuumed. "; }
    if [ \$err -eq 0 ]; then
        echo "✨ The garden is clean and blooming!"
    else
        echo "🧼 Something failed: \$msg"
    fi
}
CLEANEOF
     sudo tee -a /home/guardian/.bashrc < /tmp/Tend-Garden.tmp > /dev/null
    rm -f /tmp/Tend-Garden.tmp

    # Add sauron-gaze function
    cat > /tmp/Sanctuary-Watch.tmp <<SAURONEOF

# --- 👁️ SANCTUARY WATCH – The Eye Turns Towards the Chrysalis ---
Sanctuary-Watch() {
    local LOGFILE="/home/${USUARIO}/Trash_Dropbox/${USUARIO}-audit-\$(date +%Y%m%d-%H%M%S).log"
    local ISSUES=0
    local SUSPICIOUS=""
    local NETWORK=""
    local FILES=""
    local SUDO=""
    local UPDATES=""

    echo "👁️‍🔥 THE EYE TURNS ITS GAZE UPON THE CHRYSALIS... 👁️‍🔥"
    echo "   (A report of all that is seen will be left in the sanctuary dropbox)"
    echo ""

    SUSPICIOUS=\$(ps aux | grep -E "nc|netcat|nmap|nikto|sqlmap" | grep -v grep)
    if command -v ss &>/dev/null; then
        NETWORK=\$(ss -tupan | grep ESTAB | grep -v ":22\|:443\|:80")
    else
        NETWORK=\$(sudo netstat -tupan 2>/dev/null | grep ESTABLISHED | grep -v ":22\|:443\|:80")
    fi
    FILES=\$(sudo find /etc /usr/bin -type f -mtime -1 2>/dev/null | grep -v "cache\|log")
    SUDO=\$(sudo journalctl -u sudo -n 20 --no-pager 2>/dev/null | grep "FAILED")
    UPDATES=\$(pacman -Qu 2>/dev/null)

    {
        echo "╔══════════════════════════════════════════════════════════════════════╗"
        echo "║                🜁  THE KEEPER'S SCRUTINY  🜁                           ║"
        echo "║                   (A report for the Sanctuary)                      ║"
        echo "╚══════════════════════════════════════════════════════════════════════╝"
        echo "Date: \$(date)"
        echo ""
        echo "=== 🕷️ AGITATION IN THE PUPA (Suspicious processes) ==="
        if [ -n "\$SUSPICIOUS" ]; then
            echo "\$SUSPICIOUS"
            ISSUES=\$((ISSUES+1))
        else
            echo "   None... for now."
        fi
        echo ""
        echo "=== 🌐 WHISPERS BEYOND THE SANCTUARY (Network) ==="
        if [ -n "\$NETWORK" ]; then
            echo "\$NETWORK"
            ISSUES=\$((ISSUES+1))
        else
            echo "   All whispers are silent."
        fi
        echo ""
        echo "=== 📜 SIGNS OF PREMATURE EMERGENCE (Altered system files) ==="
        if [ -n "\$FILES" ]; then
            echo "\$FILES"
            ISSUES=\$((ISSUES+1))
        else
            echo "   No signs of emergence."
        fi
        echo ""
        echo "=== ⛓️ ATTEMPTS TO BREAK THE SHELL (sudo logs) ==="
        if [ -n "\$SUDO" ]; then
            echo "\$SUDO"
            ISSUES=\$((ISSUES+1))
        else
            echo "   None. They know better."
        fi
        echo ""
        echo "=== 📹 PACKAGES AWAITING THE KEEPER'S TOUCH (Updates) ==="
        if [ -n "\$UPDATES" ]; then
            echo "\$UPDATES"
            ISSUES=\$((ISSUES+1))
        else
            echo "   Everything is in order."
        fi
        echo ""
        echo "=== 🗡️ THE CHRYSALIS'S RESOURCES (${USUARIO}'s home) ==="
        df -h /home/${USUARIO} 2>/dev/null || echo "   The vessel does not exist."
        echo ""
        echo "=== 👣 LAST FOOTSTEPS IN THE SANCTUARY (${USUARIO}'s logins) ==="
        last -n 10 | grep ${USUARIO} || echo "   No recent footprints."
        echo ""
        echo "═══════════════════════════════════════════════════════════════════════"
    } | tee "\$LOGFILE"

    echo ""
    if [ \$ISSUES -eq 0 ]; then
        echo "👁️‍🔥 THE EYE IS PLEASED. 👁️‍🔥"
        echo "   All is well in the sanctuary. Your vigilance pleases the Keeper."
    else
        echo "👁️‍🔥 THE EYE IS DISPLEASED. 👁️‍🔥"
        echo "   The reports of disorder have reached the throne."
        echo "   You shall take up your arms and restore order."
        if [ -n "\$SUSPICIOUS" ]; then
            echo "   ⚔️  Slay the suspicious processes: pkill -f nc; pkill -f netcat; etc."
        fi
        if [ -n "\$NETWORK" ]; then
            echo "   ⛓️  Bind the unusual connections: sudo ss -tupan | grep ESTAB"
        fi
        if [ -n "\$FILES" ]; then
            echo "   🔍 Inspect the altered files"
        fi
        if [ -n "\$SUDO" ]; then
            echo "   🔐 Fortify the gates: Review /etc/sudoers"
        fi
        if [ -n "\$UPDATES" ]; then
            echo "   📦 Update the realm: sudo pacman -Syu"
        fi
        echo "   Once done, gaze again with 'Sanctuary-Watch'."
    fi
    echo ""
    echo "👁️‍🔥 The gaze has passed. Report left in: \$LOGFILE"
}
SAURONEOF
     sudo tee -a /home/guardian/.bashrc < /tmp/Sanctuary-Watch.tmp > /dev/null
    rm -f /tmp/Sanctuary-Watch.tmp

    # Add run-in-user helper function
    cat > /tmp/run-in-user.tmp <<RUNINEOF


# --- 🎯 Helper to run commands in ${USUARIO}'s session ---
run-in-${USUARIO}() {
    local target_user="${USUARIO}"
    local target_uid=\$(id -u "\$target_user" 2>/dev/null)
    
    if [[ -z "\$target_uid" ]]; then
        echo "❌ User '\$target_user' does not exist."
        return 1
    fi
    
    local session_id=\$(loginctl list-sessions | grep "\$target_user" | grep seat0 | awk '{print \$1}' | head -1)
    if [[ -z "\$session_id" ]]; then
        echo "❌ No active graphical session for \$target_user. Is the user logged in?"
        return 1
    fi
    
    local session_pid=\$(loginctl show-session "\$session_id" -p Leader | cut -d= -f2)
    if [[ -z "\$session_pid" ]]; then
        echo "❌ Could not get session PID."
        return 1
    fi
    
    local dbus_addr=\$(sudo grep -z DBUS_SESSION_BUS_ADDRESS /proc/\$session_pid/environ 2>/dev/null | tr -d '\0' | cut -d= -f2-)
    local wayland_display=\$(sudo grep -z WAYLAND_DISPLAY /proc/\$session_pid/environ 2>/dev/null | tr -d '\0' | cut -d= -f2-)
    local xdg_runtime_dir=\$(sudo grep -z XDG_RUNTIME_DIR /proc/\$session_pid/environ 2>/dev/null | tr -d '\0' | cut -d= -f2-)
    
    if [[ -z "\$dbus_addr" ]]; then
        echo "❌ No DBUS session found for \$target_user. Cannot run command."
        return 1
    fi
    
    if [[ -z "\$wayland_display" ]]; then
        echo "⚠️  No WAYLAND_DISPLAY found. Command may fail if it requires graphical output."
    fi
    
    sudo -u "\$target_user" env \
        DBUS_SESSION_BUS_ADDRESS="\$dbus_addr" \
        WAYLAND_DISPLAY="\$wayland_display" \
        XDG_RUNTIME_DIR="\$xdg_runtime_dir" \
        "\$@"
}
RUNINEOF
     sudo tee -a /home/guardian/.bashrc < /tmp/run-in-user.tmp > /dev/null
    rm -f /tmp/run-in-user.tmp
fi

# ----------------------------------------------------------------------
# 7.4 🛡️ GARDENER (USB TETHERING & DEVICE MANAGER)
# ----------------------------------------------------------------------

# Add Gardener function to bashrc
cat >> /home/guardian/.bashrc << 'EOF'

# --- 🛡️ GARDENER FUNCTION (USB Tethering & Device Manager) ---
Gardener() {
# 🌸 THE ULTIMATE USB HELPER – TENDING THE SANCTUARY'S GATES 🌸
# With love, sparkles, and a little bit of magic! 🦋

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║   🐣  WELCOME, KEEPER! LET'S TEND TO THE SANCTUARY'S GATES!  🐣  ║"
echo "║   USB tethering, devices, and Zebra label printer setup.         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# 0. 🔑 AUTO-ELEVATE TO ROOT (no need to type sudo)
if [ "$EUID" -ne 0 ]; then
    echo "🔐 Elevating to root privileges..."
    sudo bash -c "$(declare -f Gardener); Gardener"
    return $?
fi

# ----------------------------------------------------------------------
# FUNCTIONS (defined first so they're ready!)
# 🌸 TETHERING MODE
tethering_mode() {
    echo ""
    echo "🔍 Peeking at your USB devices to find your phone..."

    # Get list of USB devices that look like phones
    mapfile -t phone_list < <(lsusb | grep -i "android\|samsung\|motorola\|xiaomi\|oneplus\|google\|iphone\|honor\|nokia\|pixel\|caterpillar\|hp\|lg\|oppo\|realme\|tecno\|zte" || true)

    if [ ${#phone_list[@]} -eq 0 ]; then
        echo "😢 Awww, I couldn't find any phones connected. Did you plug it in?"
        echo "   Make sure your phone is connected and maybe unlocked?"
        read -p "🌸 Press Enter to continue..." dummy
        return
    fi

    echo "🎉 Ooh! I found some possible phone friends:"
    echo ""

    for i in "${!phone_list[@]}"; do
        bus=$(echo "${phone_list[$i]}" | awk '{print $2}')
        device=$(echo "${phone_list[$i]}" | awk '{print $4}' | tr -d ':')
        echo "   $((i+1)). ${phone_list[$i]}"
        phone_bus[$i]="$bus"
        phone_dev[$i]="$device"
    done

    echo ""
    echo "🌸 Which one is your phone, darling? (Enter the number, please!)"
    read -p "👉 " choice_num

    if ! [[ "$choice_num" =~ ^[0-9]+$ ]] || [ "$choice_num" -lt 1 ] || [ "$choice_num" -gt ${#phone_list[@]} ]; then
        echo "❌ That's not a valid number, sweetie! Let's try again."
        read -p "🌸 Press Enter to continue..." dummy
        return
    fi

    idx=$((choice_num-1))
    selected_line="${phone_list[$idx]}"
    selected_bus="${phone_bus[$idx]}"
    echo ""
    echo "✨ Great choice! I'll work my magic on: $selected_line"

    # USBGuard check and allow
    if systemctl is-active usbguard &>/dev/null; then
        echo "🔒 USBGuard is active. Let's see if it's blocking your phone..."
        device_id=$(sudo usbguard list-devices | grep -B 2 -i "$(echo "$selected_line" | grep -oE 'ID [0-9a-f]{4}:[0-9a-f]{4}')" | grep -oE '^[0-9]+' | head -1)
        if [ -n "$device_id" ]; then
            echo "   📱 Found your phone as device ID $device_id in USBGuard."
            if sudo usbguard list-devices | grep "^$device_id" | grep -q "block"; then
                echo "   😲 It's blocked! Let me allow it..."
                sudo usbguard allow-device "$device_id"
                echo "   ✅ Done!"
            else
                echo "   ✅ Already allowed."
            fi
        else
            echo "   🤔 Hmm, your phone doesn't appear in USBGuard's list. Maybe it's new?"
            sudo usbguard generate-policy > /tmp/usbguard-rules-new.conf
            if grep -qi "$(echo "$selected_line" | grep -oE 'ID [0-9a-f]{4}:[0-9a-f]{4}')" /tmp/usbguard-rules-new.conf; then
                sudo cp /etc/usbguard/rules.conf /etc/usbguard/rules.conf.bak 2>/dev/null
                sudo cp /tmp/usbguard-rules-new.conf /etc/usbguard/rules.conf
                sudo systemctl restart usbguard
                echo "   ✅ Fresh policy applied. Your phone should be welcome now."
            else
                echo "   😕 Something's odd – your phone still not in the new policy. We'll proceed anyway."
            fi
        fi
    else
        echo "🌸 USBGuard isn't running, so no worries there!"
    fi

    # Rebind USB device
    echo ""
    echo "🔄 Giving the USB connection a little hug to wake it up..."
    usb_path=$(lsusb -t | grep -B 1 "$selected_bus" | grep -oE 'Port [0-9]+' | head -1 | sed 's/Port //')
    if [ -n "$usb_path" ]; then
        port_path="1-$usb_path"  # assume bus 1
        sudo sh -c "echo -n '$port_path' > /sys/bus/usb/drivers/usb/unbind" 2>/dev/null
        sleep 2
        sudo sh -c "echo -n '$port_path' > /sys/bus/usb/drivers/usb/bind" 2>/dev/null
        echo "   💫 Rebind done! Waiting for your phone to introduce itself..."
        sleep 3
    else
        echo "   🤷 Couldn't figure out the exact USB port, but I'll try anyway."
    fi

    # Search for network interface
    echo ""
    echo "🔎 Searching for the new network interface your phone created..."
    found_iface=""
    for i in {1..10}; do
        for iface in $(ls /sys/class/net | grep -v lo); do
            if [ -d "/sys/class/net/$iface/device" ]; then
                if grep -q "USB" "/sys/class/net/$iface/device/uevent" 2>/dev/null; then
                    found_iface="$iface"
                    break 2
                fi
            fi
        done
        sleep 1
        echo -n "."
    done
    echo ""

    if [ -z "$found_iface" ]; then
        echo "😿 Aww, I couldn't find any new USB network interface."
        echo "   Did you enable 'USB Tethering' on your phone? It's super important!"
        read -p "🌸 Press Enter to continue..." dummy
        return
    fi

    echo "🎀 Yay! I found it! The new interface is called: **$found_iface**"

    # DHCP
    echo ""
    echo "🌐 Now I'll ask the network nicely for an IP address using DHCP..."
    if ! command -v dhclient &>/dev/null; then
        echo "   📦 Oops, dhclient isn't installed. Let me fix that..."
        sudo pacman -S --noconfirm dhclient
    fi

    sudo dhclient -v "$found_iface" 2>&1 | sed 's/^/      /'

    ip_addr=$(ip -4 addr show "$found_iface" 2>/dev/null | grep inet | awk '{print $2}')
    if [ -n "$ip_addr" ]; then
        echo ""
        echo "✨✨ SUCCESS! ✨✨"
        echo "   Your phone is connected! IP: $ip_addr"
    else
        echo ""
        echo "😔 Hmm, DHCP didn't give us an IP. Let's try one more time..."
        sudo dhclient -r "$found_iface"
        sudo dhclient -v "$found_iface"
        ip_addr=$(ip -4 addr show "$found_iface" 2>/dev/null | grep inet | awk '{print $2}')
        [ -n "$ip_addr" ] && echo "🎉 Second time's the charm! IP: $ip_addr" || echo "💔 Still no IP."
    fi

    read -p "🌸 Press Enter to continue..." dummy
}

# 🔌 USB DEVICE MANAGEMENT
manage_usb_devices() {
    # Check if USBGuard is installed and active
    if ! command -v usbguard &>/dev/null; then
        echo "😕 USBGuard is not installed. Installing it now..."
        sudo pacman -S --noconfirm usbguard
        sudo systemctl enable --now usbguard
    fi

    if ! systemctl is-active usbguard &>/dev/null; then
        echo "🚨 USBGuard is not running. Starting it..."
        sudo systemctl start usbguard
    fi

    echo ""
    echo "🔌 Here are all the USB devices USBGuard knows about:"
    echo "------------------------------------------------------"
    sudo usbguard list-devices
    echo "------------------------------------------------------"
    echo ""
    echo "What would you like to do, dear?"
    echo "   a) Allow a device (give it permission)"
    echo "   b) Block a device (reject it)"
    echo "   c) Generate a new policy (let USBGuard relearn all connected devices)"
    echo "   d) Go back to main menu"
    echo ""
    read -p "👉 Type a, b, c, or d: " usb_choice

    case $usb_choice in
        a|A)
            echo ""
            read -p "Enter the device ID (number from the list) to allow: " dev_id
            if [[ "$dev_id" =~ ^[0-9]+$ ]]; then
                sudo usbguard allow-device "$dev_id"
                echo "✅ Device $dev_id has been allowed! Good little device."
            else
                echo "❌ That's not a valid number, silly."
            fi
            ;;
        b|B)
            echo ""
            read -p "Enter the device ID (number from the list) to block: " dev_id
            if [[ "$dev_id" =~ ^[0-9]+$ ]]; then
                sudo usbguard block-device "$dev_id"
                echo "🔒 Device $dev_id has been blocked. Naughty device!"
            else
                echo "❌ That's not a valid number, silly."
            fi
            ;;
        c|C)
            echo "📝 Generating a new policy based on currently connected devices..."
            sudo usbguard generate-policy > /tmp/usbguard-rules-new.conf
            sudo cp /etc/usbguard/rules.conf /etc/usbguard/rules.conf.bak
            sudo cp /tmp/usbguard-rules-new.conf /etc/usbguard/rules.conf
            sudo systemctl restart usbguard
            echo "✅ New policy applied. All currently connected devices are now allowed."
            ;;
        d|D)
            return
            ;;
        *)
            echo "❌ Not a valid choice, sweetie. Going back."
            ;;
    esac
    echo ""
    read -p "🌸 Press Enter to continue..." dummy
}

# 🏷️ ZEBRA LABEL PRINTER (find, save, apply — no Metamorphosis re-run)
zebra_printer_mode() {
    local ZEBRA_CONF=/etc/micpapalotlan/zebra-zt231.env
    local ZEBRA_QUEUE=Zebra_ZT231
    local saved_ip="" found_ips=() choice_ip=""

    echo ""
    echo "🏷️  Zebra ZT231 label printer setup"
    if pgrep -x glabels >/dev/null 2>&1; then
        echo "   📎 gLabels is running — we'll make sure Print works when we're done."
    fi
    echo ""

    systemctl enable --now cups 2>/dev/null || true

    if [[ -f "$ZEBRA_CONF" ]]; then
        # shellcheck source=/dev/null
        source "$ZEBRA_CONF"
        saved_ip="${ZEBRA_IP:-}"
        ZEBRA_QUEUE="${ZEBRA_QUEUE:-Zebra_ZT231}"
        echo "   📄 Saved config: IP=${saved_ip:-none}  queue=$ZEBRA_QUEUE"
    else
        echo "   📄 No saved config yet ($ZEBRA_CONF)"
        mkdir -p /etc/micpapalotlan
    fi

    local zebra_healthy=false
    local zebra_action=""
    if /usr/local/bin/pupa-zebra-ensure 2>/dev/null; then
        zebra_healthy=true
        echo "   ✅ Printer queue looks healthy (CUPS + port 9100)."
    else
        echo "   ⚠️  Queue missing, offline, or port 9100 not reachable."
    fi

    echo ""
    if [[ -n "$saved_ip" ]]; then
        echo "   What would you like to do?"
        echo "   1) Refresh IP — scan the LAN again (if the printer moved or DHCP changed)"
        echo "   2) Re-apply saved IP — keep ${saved_ip}, rebuild the CUPS queue only"
        echo "   3) Enter IP manually"
        echo "   4) Cancel"
        echo ""
        read -rp "   👉 Choice [1-4]: " zebra_action
        case "$zebra_action" in
            2)
                choice_ip="$saved_ip"
                echo "   🔄 Re-applying saved IP ${saved_ip} ..."
                ;;
            3)
                read -rp "   IP address: " choice_ip
                ;;
            4|"")
                read -p "🌸 Press Enter to continue..." dummy
                return
                ;;
            1|*)
                zebra_action=1
                echo "   🔄 Refreshing — scanning for Zebra printers ..."
                ;;
        esac
    else
        zebra_action=1
    fi

    # Network scan (refresh path + first-time setup)
    if [[ "$zebra_action" == "1" && -z "$choice_ip" ]]; then
        if [[ -n "$saved_ip" ]]; then
            echo "   🔎 Checking saved IP $saved_ip ..."
            if timeout 1 bash -c "echo >/dev/tcp/${saved_ip}/9100" 2>/dev/null; then
                found_ips+=("$saved_ip")
                echo "      ✅ Saved IP still responds on 9100"
            else
                echo "      ⚠️  Saved IP not answering (may have changed)"
            fi
        fi

        if lsusb 2>/dev/null | grep -qi "zebra"; then
            echo "   🔌 USB Zebra detected (network IP :9100 is used for printing)."
        fi

        echo "   🔎 Scanning sanctuary LAN (port 9100, ~30s)..."
        local subnet="" last_octet
        subnet=$(ip -4 route show default 2>/dev/null | awk '{print $3}' | head -1)
        if [[ -n "$subnet" ]]; then
            subnet="${subnet%.*}"
            for last_octet in $(seq 1 254); do
                local try_ip="${subnet}.${last_octet}"
                [[ " ${found_ips[*]} " == *" $try_ip "* ]] && continue
                timeout 0.15 bash -c "echo >/dev/tcp/${try_ip}/9100" 2>/dev/null && found_ips+=("$try_ip")
            done
        fi

        if [[ ${#found_ips[@]} -gt 0 ]]; then
            echo ""
            echo "   🎉 Found ${#found_ips[@]} host(s) on port 9100:"
            local i=1
            for try_ip in "${found_ips[@]}"; do
                local tag=""
                [[ "$try_ip" == "$saved_ip" ]] && tag=" (saved)"
                echo "      $i) $try_ip$tag"
                ((i++))
            done
            echo "      m) Enter IP manually"
            echo "      r) Scan again"
            echo "      s) Cancel"
            echo ""
            while true; do
                read -rp "   👉 Pick number, m, r, or s: " pick
                if [[ "$pick" == "r" || "$pick" == "R" ]]; then
                    found_ips=()
                    choice_ip=""
                    zebra_action=1
                    echo "   🔎 Rescanning ..."
                    if [[ -n "$saved_ip" ]]; then
                        timeout 1 bash -c "echo >/dev/tcp/${saved_ip}/9100" 2>/dev/null && found_ips+=("$saved_ip")
                    fi
                    if [[ -n "$subnet" ]]; then
                        for last_octet in $(seq 1 254); do
                            try_ip="${subnet}.${last_octet}"
                            [[ " ${found_ips[*]} " == *" $try_ip "* ]] && continue
                            timeout 0.15 bash -c "echo >/dev/tcp/${try_ip}/9100" 2>/dev/null && found_ips+=("$try_ip")
                        done
                    fi
                    echo "   Found ${#found_ips[@]} host(s)."
                    i=1
                    for try_ip in "${found_ips[@]}"; do
                        tag=""
                        [[ "$try_ip" == "$saved_ip" ]] && tag=" (saved)"
                        echo "      $i) $try_ip$tag"
                        ((i++))
                    done
                    continue
                fi
                if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#found_ips[@]} )); then
                    choice_ip="${found_ips[$((pick-1))]}"
                    break
                fi
                if [[ "$pick" == "m" || "$pick" == "M" ]]; then
                    read -rp "   IP address: " choice_ip
                    break
                fi
                if [[ "$pick" == "s" || "$pick" == "S" ]]; then
                    read -p "🌸 Press Enter to continue..." dummy
                    return
                fi
                echo "   ❌ Invalid choice."
            done
        else
            echo "   😕 No printers found on the scan."
            read -rp "   Enter Zebra IP manually (empty = cancel): " choice_ip
        fi
    fi

    [[ -z "$choice_ip" ]] && { read -p "🌸 Press Enter to continue..." dummy; return; }

    if [[ "$choice_ip" != "$saved_ip" ]]; then
        echo "   📝 IP change: ${saved_ip:-none} → $choice_ip"
    fi

    printf "ZEBRA_IP='%s'\nZEBRA_QUEUE='%s'\n" "$choice_ip" "$ZEBRA_QUEUE" > "$ZEBRA_CONF"
    chmod 644 "$ZEBRA_CONF"
    echo "   💾 Saved $ZEBRA_CONF"

    if /usr/local/bin/pupa-zebra-apply; then
        echo "   ✅ CUPS queue '$ZEBRA_QUEUE' is ready @ $choice_ip"
        echo "   Sanctuary staff: Print Labels → Print (no Metamorphosis re-run needed)."
        if pgrep -x glabels >/dev/null 2>&1; then
            echo "   💡 gLabels is open — try Print again now."
        fi
    else
        echo "   ❌ pupa-zebra-apply failed. Check: systemctl status cups"
    fi
    read -p "🌸 Press Enter to continue..." dummy
}

# Quick health check used at Gardener startup
_zebra_needs_attention() {
    [[ -f /etc/micpapalotlan/zebra-zt231.env ]] || return 0
    /usr/local/bin/pupa-zebra-ensure 2>/dev/null && return 1
    return 0
}

# ----------------------------------------------------------------------
# MAIN MENU (now after the functions – they're ready to be called!)
if pgrep -x glabels >/dev/null 2>&1 && /usr/local/bin/pupa-zebra-ensure 2>/dev/null; then
    echo "🏷️  gLabels is running — label printer looks ready. ✨"
    echo ""
elif _zebra_needs_attention || pgrep -x glabels >/dev/null 2>&1; then
    echo "🏷️  Label printer needs setup (not saved, not reachable, or gLabels is open)."
    read -rp "   Fix Zebra printer now? (Y/n): " zfix
    if [[ ! "$zfix" =~ ^[Nn]$ ]]; then
        zebra_printer_mode
    fi
    echo ""
fi

while true; do
    echo ""
    echo "🌸 What would you like to do today, darling?"
    echo "   1️⃣  Set up USB Tethering (connect your phone's internet)"
    echo "   2️⃣  Manage USB Devices (allow/block them with USBGuard)"
    echo "   3️⃣  Label printer — find/setup Zebra ZT231 (gLabels / CUPS)"
    echo "   4️⃣  Exit (go away, meanie! 😜)"
    echo ""
    read -p "👉 Type 1, 2, 3, or 4: " choice

    case $choice in
        1)
            tethering_mode
            ;;
        2)
            manage_usb_devices
            ;;
        3)
            zebra_printer_mode
            ;;
        4)
            echo "💔 Aww, leaving so soon? Bye bye, sweetie!"
            return 0
            ;;
        *)
            echo "❌ That's not a valid choice, silly! Please enter 1, 2, 3, or 4."
            read -p "🌸 Press Enter to continue..." dummy
            ;;
    esac
done
}
EOF

# ----------------------------------------------------------------------
# 8. 🖥️ WEZTERM (emergency terminal) - SECRET TOGGLE DOOR
# ----------------------------------------------------------------------
echo "--- 🖥️  ADDING A SECRET TERMINAL DOOR (WezTerm) ---"
 sudo -u "$USUARIO" mkdir -p "/home/$USUARIO/.config/wezterm"
 sudo chown -R "${USUARIO}:${USUARIO}" "/home/$USUARIO/.config/wezterm"
echo ""

# ----------------------------------------------------------------------
# 9. 🌍 BRAVE WHITELIST (PAC)
# ----------------------------------------------------------------------
echo "--- 🌍 FORGING THE INTERNET PASSPORT (Brave Whitelist) ---"
PAC_FILE="/home/$USUARIO/.brave-restricted/whitelist.pac"
 sudo mkdir -p "/home/$USUARIO/.brave-restricted"
 sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.brave-restricted"
 sudo chmod 700 "/home/$USUARIO/.brave-restricted"
 sudo tee "$PAC_FILE" > /dev/null <<'PACEOF'
function FindProxyForURL(url, host) {
    var allowed_domains = [
    // --- TIENDAS ADULTOS Y LENCERÍA (PANAMÁ) --- 
    "scarletstore.com",
    "dreamsptystore.com",
    "royalfantasypty.com",
    "eroticcitysexshop.com",
    "privatesexshoppanama.com",
    "touchepanama.com",
    "victoriassecretbeauty.com",
    "victoriassecret.com",
    "victoriassecretbeauty.pa",
    "vsecret.com.pa",
    "leonisa.pa",
    "lilipink.com",
    "hotlivingpty.com",
    "conwayclick.com",
    "stevens.com.pa",
    // --- MODA Y ROPA GENERAL --- 
    "zara.com",
    "zara.us",
    "static.zara.net",
    "itxid.com",
    "static.zgo.com",
    "static.itxserve.com",
    "inditex.com",
    "shein.com",
    "shein.us",
    "sheinsa.com",
    "sheincdn.com",
    "asos.com",
    "asosmedia.com",
    "hm.com",
    "hm.com.us",
    "hmcdn.com",
    "hmrn.dk",
    "zalando.com",
    "zalando-img.de",
    "zalando-media.de",
    // --- PROVEEDORES MAYORISTAS (ADULTOS Y GENERAL) ---
    "alibaba.com", 
    "alibabacloud.com",
    "1688.com",
    "aliexpress.com",
    "aliexpress.us",
    "alicdn.com",
    "aliexpresscdn.com",
    "ae01.alicdn.com",
    "adamandeve.com",
    "lovehoney.com",
    "calexotics.com",
    "docjohnson.com",
    "pinkcherry.com",
    // --- TIENDAS DE INVENTARIO ---
    "amazon.com",
    "amazon-adsystem.com",
    "media-amazon.com",
    "ssl-images-amazon.com",
    "images-amazon.com",
    "images-na.ssl-images-amazon.com",
    "ebay.com",
    "ebayimg.com",
    "ebaystatic.com",
    "walmart.com",
    "walmart.com.mx",
    "walmart-chile.cl",
    "walmart.com.co",
    "walmartcentroamerica.com",
    "walmartimages.com",
    "target.com",
    "targetimg.com",
    "bestbuy.com",
    "bbystatic.com",
    "etsy.com",
    "etsystatic.com",
    "mercari.com",
    "mercariapp.com",
    "mercari-img.com",
    "rakuten.com",
    "rakuten-static.com",
    // --- INFRAESTRUCTURA DE E-COMMERCE Y RECURSOS ---
    "shopify.com",
    "myshopify.com",
    "shopifycdn.com",
    "shopifyapps.com",
    "shopifypreview.com",
    "cdn.shopify.com",
    "vtex.com",
    "vteximg.com.br",
    "vtexassets.com",
    "static.wixstatic.com",
    "wix.com",
    "wordpress.com",
    "s.w.org",
    "switch-soft.com",
    "scarletrose.switch-soft.com",
    "cloudfront.net",
    "cuanto.app",
    "checkout.cuanto.app",
    // --- LOGÍSTICA Y ENVIOS ---
    "uber.com",
    "uberinternal.com",
    "maps.googleapis.com",
    "maps.gstatic.com",
    "s3.amazonaws.com",
    "unoexpresspanama.com",
    "1boxpanama.com",
    "hotexpresspanama.com",
    "tracking.unoexpresspanama.com",
    "api.unoexpresspanama.com",
    "chavale.com",
    "clientes.chavale.com",
    "ferguzon.com",
    "asap507.com",
    "asap.com.pa",
    "asap-api.com",
    "zappydelivery.com",
    "crm.zappydelivery.com",
    "maps.googleapis.com",
    "maps.gstatic.com",
    "ggpht.com",
    "dl.google.com",
    "mt0.google.com",
    "mt1.google.com",
    "fcm.googleapis.com",
    "firebaseio.com",
    "googleapis.com",
    "gstatic.com",
    "firebase.google.com",
    "www.google.com/recaptcha",
    "wixstatic.com",        // Usado por Zappy
    "s.w.org",              // Usado por sitios en WordPress como Chavale
    "fonts.googleapis.com",
    "fonts.gstatic.com",
    "dhl.com",
    "dhlparcel.com",
    "fedex.com",
    "ups.com",
    "mundocourier.com.pa",
    "trazable.net",
    "estafeta.com",
    "s3.amazonaws.com",
    // --- REDES SOCIALES, COMUNICACIÓN Y CONTENIDO ---
    "instagram.com",
    "facebook.com",
    "business.facebook.com",
    "connect.facebook.net",
    "tiktok.com",
    "whatsapp.com",
    "web.whatsapp.com",
    "business.whatsapp.com",
    "x.com",
    "twitter.com",
    "twimg.com",
    "abs.twimg.com",
    "pinterest.com",
    "pinimg.com",
    "youtube.com",
    "ytimg.com",
    "youtu.be",
    "photopea.com",
    // --- GOOGLE WORKSPACE Y ECOSISTEMA ---
    "*.google.com",
    "workspace.google.com",
    "tasks.google.com",
    "ads.google.com",
    "gemini.google.com",
    "music.youtube.com",
    "google.com",
    "gmail.com",
    "gstatic.com",
    "www.gstatic.com",
    "googleusercontent.com",
    "googleapis.com",
    "accounts.google.com",
    "accounts.google.co.uk",
    "accounts.youtube.com",
    "oauthaccountmanager.googleapis.com",
    "clients4.google.com",
    "calendar.google.com",
    "docs.google.com",
    "drive.google.com",
    "meet.google.com",
    "chat.google.com",
    "keep.google.com",
    "sites.google.com",
    "forms.google.com",
    "script.google.com",
    "googleadservices.com",
    "doubleclick.net",
    "google-analytics.com",
    "googletagmanager.com",
    "www.googletagmanager.com",
    "fonts.googleapis.com",
    "fonts.gstatic.com",
    "recaptcha.net",
    "www.google.com/recaptcha",
    // --- MICROSOFT ---
    "microsoft.com",
    "m365.cloud.microsoft",
    "*.cloud.microsoft",
    "*.microsoft.com",
    "live.com",
    "office.com",
    "office365.com",
    "microsoftonline.com",
    "login.microsoftonline.com",
    "office.net",
    "copilot.microsoft.com",
    "sharepoint.com",
    "skype.com",
    // --- BANCOS Y PASARELAS DE PAGO (PANAMÁ) ---
    "bgeneral.com",
    "zonasegura.bgeneral.com",
    "yappy.com.pa",
    "yappy.pa",
    "baccredomatic.com",
    "bac.net",
    "baccredomatic.com.pa",
    "bacpanama.com",
    "banistmo.com",
    "wompi.pa",
    "wompi.com.pa",
    "nequi.com.pa",
    "banconal.com.pa",
    "globalbank.com.pa",
    "cajadeahorros.com.pa",
    "paguelofacil.com",
    "api.paguelofacil.com",
    "viva.com.pa",
    "tilopay.com",
    "mercadopago.com",
    // --- PAGOS INTERNACIONALES Y SEGURIDAD ---
    "paypal.com",
    "paypalobjects.com",
    "c.paypal.com",
    "stripe.com",
    "js.stripe.com",
    // --- GOBIERNO Y REGULACIÓN ---
    "dgi.mef.gob.pa",   // -- Legal --
    "mef.gob.pa",
    "etax2.mef.gob.pa",
    "santiago.mef.gob.pa",
    "panamadigital.gob.pa",
    "css.gob.pa",
    "sipe.css.gob.pa",
    "mici.gob.pa",
    "panamaemprende.gob.pa",
    "mitradel.gob.pa",
    "registro-publico.gob.pa",
    "anati.gob.pa",
    "ssnf.gob.pa",
    "superbancos.gob.pa",
    "thefactoryhka.com.pa",
    "facturafacil.com.pa",
    "efacturapty.com",
    "guru-soft.com",
    "digifact.com.pa",
    "infile.com.pa",
    "gosocket.net",
    "edicom.com.pa",
    "factura.pa",
    "dora.com.pa",
    "alegra.com",
    "interfuerza.com",
    "quickbooks.intuit.com",
    "sap.com",
    "xero.com",
    "zoho.com/books",
    "sage.com",
    "alanube.co",
    "colegiocpapanama.org",
    "acontapanama.org",
    "ifrs.org",
    "nic.pa",
    "autenticacion.panamadigital.gob.pa",
    "firmaelectronica.gob.pa",
    "valida.junta-tecnica.mici.gob.pa",
    // --- SALUD Y EDUCACIÓN SEXUAL (PARA ATENCIÓN AL CLIENTE) ---
    "plannedparenthood.org",
    "mayoclinic.org",
    "webmd.com",
    // --- COMODIDADES Y HERRAMIENTAS PARA EL USUARIO ---
    "spotify.com",
    "*.spotify.com",
    "soundcloud.com",
    "app.diagrams.net",
    // --- SISTEMA INTERNO DEL NAVEGADOR Y HERRAMIENTAS DE TECNOLOGIA ---
    "github.dev",
    "coderabbit.ai",
    "*github.dev",
    "github.com",
    "*github.com",
    "claude.ai",
    "chat.deepseek.com",
    "deepseek.com",
    "*.chatgpt.com",
    "chatgpt.com",
    "openai.com",
    "*.openai.com",
    "chat.z.ai",
    "rustpad.io",
    "*.archlinux.org",
    "brave.com",
    "brave-browser",
    "about:newtab",
    "brave://newtab",
    "brave://welcome",
    "chrome://newtab",
    "static1.brave.com",
    "variations.brave.com",
    "laptop-updates.brave.com",
    "p3a.brave.com",
    "ads-serve.brave.com"
    ];
    for (var i = 0; i < allowed_domains.length; i++) {
        if (shExpMatch(host, "*." + allowed_domains[i]) || host == allowed_domains[i]) {
            return "DIRECT";
        }
    }
    return "PROXY 127.0.0.1:65535";
}
PACEOF
 sudo chown root:root "$PAC_FILE"
 sudo chmod 644 "$PAC_FILE"
 sudo chattr +i "$PAC_FILE" 2>/dev/null || true
echo "✅ Brave's internet passport is ready! Only approved sites are visitable. ✈️"
echo ""

# ----------------------------------------------------------------------
# 9.1 🌍 BRAVE POLICY TOGGLE ALIASES (off by default)
# ----------------------------------------------------------------------
echo "--- 🌍 SKIPPING GLOBAL BRAVE POLICY CREATION ---"
echo "ℹ️  No JSON policy created. Use 'Weave-Cocoon' when ready."
echo ""

# Add brave policies on then
if id "guardian" &>/dev/null; then
    # Create brave-policies-off alias
    cat > /tmp/Unweave-Cocoon.tmp <<BRAVEOFFEOF

# --- 🌍 GLOBAL BRAVE POLICY TOGGLE (affects ${USUARIO}) ---
alias Unweave-Cocoon='echo "🔥 Unweaving Brave policies for ${USUARIO}..."; sudo pkill -f brave 2>/dev/null || true; sudo rm -rf /home/${USUARIO}/.config/BraveSoftware /home/${USUARIO}/.cache/BraveSoftware 2>/dev/null || true; sudo rm -f /etc/brave/policies/managed/${USUARIO}_policy.json /etc/brave/policies/managed/${USUARIO}_policy.json.bak 2>/dev/null || true; echo "🎉 Brave completely reset for ${USUARIO}. No policies remain."'

# --- 🔓 COCOON UNLOCK SINGLETON (fixes "Brave is already running" error) ---
alias cocoon-unlock='echo "🔓 Removing Brave singleton locks..."; rm -f ~/.config/BraveSoftware/Brave-Browser/SingletonLock ~/.config/BraveSoftware/Brave-Browser/SingletonSocket ~/.config/BraveSoftware/Brave-Browser/SingletonCookie 2>/dev/null && echo "✅ Brave locks removed. You can now start Brave." || echo "⚠️ No locks found or already removed."'
BRAVEOFFEOF
     sudo tee -a /home/guardian/.bashrc < /tmp/Unweave-Cocoon.tmp > /dev/null
    rm -f /tmp/Unweave-Cocoon.tmp

    # Create brave-policies-on alias with embedded policy
    cat > /tmp/Weave-Cocoon-header.tmp <<BRAVEONHEADER

Weave-Cocoon() {
    echo "🔒 Weaving Brave policies for ${USUARIO}..."
    if [ -f /etc/brave/policies/managed/${USUARIO}_policy.json.bak ]; then
         sudo mv /etc/brave/policies/managed/${USUARIO}_policy.json.bak /etc/brave/policies/managed/${USUARIO}_policy.json
        echo "   ✅ Policies restored from backup"
    else
        echo "   ℹ️ No backup found, creating fresh policy file"
        cat > /tmp/brave-policy-fresh.json << 'BRAVEPOLICY'
{
  "URLBlocklist": ["*"],
  "URLAllowlist": [
    // --- TIENDAS ADULTOS Y LENCERÍA (PANAMÁ) --- 
    "scarletstore.com",
    "dreamsptystore.com",
    "royalfantasypty.com",
    "eroticcitysexshop.com",
    "privatesexshoppanama.com",
    "touchepanama.com",
    "victoriassecretbeauty.com",
    "victoriassecret.com",
    "victoriassecretbeauty.pa",
    "vsecret.com.pa",
    "leonisa.pa",
    "lilipink.com",
    "hotlivingpty.com",
    "conwayclick.com",
    "stevens.com.pa",
    // --- MODA Y ROPA GENERAL --- 
    "zara.com",
    "zara.us",
    "static.zara.net",
    "itxid.com",
    "static.zgo.com",
    "static.itxserve.com",
    "inditex.com",
    "shein.com",
    "shein.us",
    "sheinsa.com",
    "sheincdn.com",
    "asos.com",
    "asosmedia.com",
    "hm.com",
    "hm.com.us",
    "hmcdn.com",
    "hmrn.dk",
    "zalando.com",
    "zalando-img.de",
    "zalando-media.de",
    // --- PROVEEDORES MAYORISTAS (ADULTOS Y GENERAL) ---
    "alibaba.com", 
    "alibabacloud.com",
    "1688.com",
    "aliexpress.com",
    "aliexpress.us",
    "alicdn.com",
    "aliexpresscdn.com",
    "ae01.alicdn.com",
    "adamandeve.com",
    "lovehoney.com",
    "calexotics.com",
    "docjohnson.com",
    "pinkcherry.com",
    // --- TIENDAS DE INVENTARIO ---
    "amazon.com",
    "amazon-adsystem.com",
    "media-amazon.com",
    "ssl-images-amazon.com",
    "images-amazon.com",
    "images-na.ssl-images-amazon.com",
    "ebay.com",
    "ebayimg.com",
    "ebaystatic.com",
    "walmart.com",
    "walmart.com.mx",
    "walmart-chile.cl",
    "walmart.com.co",
    "walmartcentroamerica.com",
    "walmartimages.com",
    "target.com",
    "targetimg.com",
    "bestbuy.com",
    "bbystatic.com",
    "etsy.com",
    "etsystatic.com",
    "mercari.com",
    "mercariapp.com",
    "mercari-img.com",
    "rakuten.com",
    "rakuten-static.com",
    // --- INFRAESTRUCTURA DE E-COMMERCE Y RECURSOS ---
    "shopify.com",
    "myshopify.com",
    "shopifycdn.com",
    "shopifyapps.com",
    "shopifypreview.com",
    "cdn.shopify.com",
    "vtex.com",
    "vteximg.com.br",
    "vtexassets.com",
    "static.wixstatic.com",
    "wix.com",
    "wordpress.com",
    "s.w.org",
    "switch-soft.com",
    "scarletrose.switch-soft.com",
    "cloudfront.net",
    "cuanto.app",
    "checkout.cuanto.app",
    // --- LOGÍSTICA Y ENVIOS ---
    "uber.com",
    "uberinternal.com",
    "maps.googleapis.com",
    "maps.gstatic.com",
    "s3.amazonaws.com",
    "unoexpresspanama.com",
    "1boxpanama.com",
    "hotexpresspanama.com",
    "tracking.unoexpresspanama.com",
    "api.unoexpresspanama.com",
    "chavale.com",
    "clientes.chavale.com",
    "ferguzon.com",
    "asap507.com",
    "asap.com.pa",
    "asap-api.com",
    "zappydelivery.com",
    "crm.zappydelivery.com",
    "maps.googleapis.com",
    "maps.gstatic.com",
    "ggpht.com",
    "dl.google.com",
    "mt0.google.com",
    "mt1.google.com",
    "fcm.googleapis.com",
    "firebaseio.com",
    "googleapis.com",
    "gstatic.com",
    "firebase.google.com",
    "www.google.com/recaptcha",
    "wixstatic.com",        // Usado por Zappy
    "s.w.org",              // Usado por sitios en WordPress como Chavale
    "fonts.googleapis.com",
    "fonts.gstatic.com",
    "dhl.com",
    "dhlparcel.com",
    "fedex.com",
    "ups.com",
    "mundocourier.com.pa",
    "trazable.net",
    "estafeta.com",
    "s3.amazonaws.com",
    // --- REDES SOCIALES, COMUNICACIÓN Y CONTENIDO ---
    "instagram.com",
    "facebook.com",
    "business.facebook.com",
    "connect.facebook.net",
    "tiktok.com",
    "whatsapp.com",
    "web.whatsapp.com",
    "business.whatsapp.com",
    "x.com",
    "twitter.com",
    "twimg.com",
    "abs.twimg.com",
    "pinterest.com",
    "pinimg.com",
    "youtube.com",
    "ytimg.com",
    "youtu.be",
    "photopea.com",
    // --- GOOGLE WORKSPACE Y ECOSISTEMA ---
    "*.google.com",
    "workspace.google.com",
    "tasks.google.com",
    "ads.google.com",
    "gemini.google.com",
    "music.youtube.com",
    "google.com",
    "gmail.com",
    "gstatic.com",
    "www.gstatic.com",
    "googleusercontent.com",
    "googleapis.com",
    "accounts.google.com",
    "accounts.google.co.uk",
    "accounts.youtube.com",
    "oauthaccountmanager.googleapis.com",
    "clients4.google.com",
    "calendar.google.com",
    "docs.google.com",
    "drive.google.com",
    "meet.google.com",
    "chat.google.com",
    "keep.google.com",
    "sites.google.com",
    "forms.google.com",
    "script.google.com",
    "googleadservices.com",
    "doubleclick.net",
    "google-analytics.com",
    "googletagmanager.com",
    "www.googletagmanager.com",
    "fonts.googleapis.com",
    "fonts.gstatic.com",
    "recaptcha.net",
    "www.google.com/recaptcha",
    // --- MICROSOFT ---
    "microsoft.com",
    "m365.cloud.microsoft",
    "*.cloud.microsoft",
    "*.microsoft.com",
    "live.com",
    "office.com",
    "office365.com",
    "microsoftonline.com",
    "login.microsoftonline.com",
    "office.net",
    "copilot.microsoft.com",
    "sharepoint.com",
    "skype.com",
    // --- BANCOS Y PASARELAS DE PAGO (PANAMÁ) ---
    "bgeneral.com",
    "zonasegura.bgeneral.com",
    "yappy.com.pa",
    "yappy.pa",
    "baccredomatic.com",
    "bac.net",
    "baccredomatic.com.pa",
    "bacpanama.com",
    "banistmo.com",
    "wompi.pa",
    "wompi.com.pa",
    "nequi.com.pa",
    "banconal.com.pa",
    "globalbank.com.pa",
    "cajadeahorros.com.pa",
    "paguelofacil.com",
    "api.paguelofacil.com",
    "viva.com.pa",
    "tilopay.com",
    "mercadopago.com",
    // --- PAGOS INTERNACIONALES Y SEGURIDAD ---
    "paypal.com",
    "paypalobjects.com",
    "c.paypal.com",
    "stripe.com",
    "js.stripe.com",
    // --- GOBIERNO Y REGULACIÓN ---
    "dgi.mef.gob.pa",   // -- Legal --
    "mef.gob.pa",
    "etax2.mef.gob.pa",
    "santiago.mef.gob.pa",
    "panamadigital.gob.pa",
    "css.gob.pa",
    "sipe.css.gob.pa",
    "mici.gob.pa",
    "panamaemprende.gob.pa",
    "mitradel.gob.pa",
    "registro-publico.gob.pa",
    "anati.gob.pa",
    "ssnf.gob.pa",
    "superbancos.gob.pa",
    "thefactoryhka.com.pa",
    "facturafacil.com.pa",
    "efacturapty.com",
    "guru-soft.com",
    "digifact.com.pa",
    "infile.com.pa",
    "gosocket.net",
    "edicom.com.pa",
    "factura.pa",
    "dora.com.pa",
    "alegra.com",
    "interfuerza.com",
    "quickbooks.intuit.com",
    "sap.com",
    "xero.com",
    "zoho.com/books",
    "sage.com",
    "alanube.co",
    "colegiocpapanama.org",
    "acontapanama.org",
    "ifrs.org",
    "nic.pa",
    "autenticacion.panamadigital.gob.pa",
    "firmaelectronica.gob.pa",
    "valida.junta-tecnica.mici.gob.pa",
    // --- SALUD Y EDUCACIÓN SEXUAL (PARA ATENCIÓN AL CLIENTE) ---
    "plannedparenthood.org",
    "mayoclinic.org",
    "webmd.com",
    // --- COMODIDADES Y HERRAMIENTAS PARA EL USUARIO ---
    "spotify.com",
    "*.spotify.com",
    "soundcloud.com",
    "app.diagrams.net",
    // --- SISTEMA INTERNO DEL NAVEGADOR Y HERRAMIENTAS DE TECNOLOGIA ---
    "github.dev",
    "coderabbit.ai",
    "*github.dev",
    "github.com",
    "*github.com",
    "claude.ai",
    "chat.deepseek.com",
    "deepseek.com",
    "*.chatgpt.com",
    "chatgpt.com",
    "openai.com",
    "*.openai.com",
    "chat.z.ai",
    "rustpad.io",
    "*.archlinux.org",
    "brave.com",
    "brave-browser",
    "about:newtab",
    "brave://newtab",
    "brave://welcome",
    "chrome://newtab",
    "static1.brave.com",
    "variations.brave.com",
    "laptop-updates.brave.com",
    "p3a.brave.com",
    "ads-serve.brave.com"
  ]
}
BRAVEPOLICY
         sudo mv /tmp/brave-policy-fresh.json /etc/brave/policies/managed/${USUARIO}_policy.json
        echo "   ✅ Policies created"
    fi
     sudo pkill -f brave 2>/dev/null || true
     sudo mkdir -p "/home/${USUARIO}/.config/BraveSoftware/Brave-Browser/Policy" "/home/${USUARIO}/.cache/BraveSoftware"
     sudo chown -R "${USUARIO}:${USUARIO}" "/home/${USUARIO}/.config/BraveSoftware" "/home/${USUARIO}/.cache/BraveSoftware" 2>/dev/null || true
    echo "🎯 Policies woven. Reopen Brave to see restrictions."
}
BRAVEONHEADER
     sudo tee -a /home/guardian/.bashrc < /tmp/Weave-Cocoon-header.tmp > /dev/null
    rm -f /tmp/Weave-Cocoon-header.tmp

    echo "✅ Brave policy toggle aliases installed for guardian (affects $USUARIO)."
fi

# Close Micpapalotlan configuration section in bashrc
echo "" >> /home/guardian/.bashrc
echo "# === MICPAPALOTLAN CONFIG END ===" >> /home/guardian/.bashrc
echo "✅ Configuración de Micpapalotlan completada en bashrc"
echo ""

# ----------------------------------------------------------------------
# 10. 🪄 APPLICATION LAUNCHERS (menu filtering)
# ----------------------------------------------------------------------
echo "--- 🪄 CRAFTING THE APPLICATION MENU ---"
 sudo -u "$USUARIO" mkdir -p "/home/$USUARIO/.local/share/applications/"
prohibidas=(
    "eos" "systemsettings" "ark" "avahi" "eos-update" "endeavour" "kitty"
    "firewall" "firewall-config" "hardware-locality"
    "icon-browser" "info-center" "spectacle" "kdeconnect" "konsole"
    "proton" "assistant" "designer" "linguist" "v4l2" "reflector" "wallpaper"
    "software-token" "system-monitor" "uxterm" "welcome" "wezterm" "icon"
    "xterm" "firefox" "yad" "vnc" "ssh" "zeroconf" "bssh" "bvnc" "proton"
    "qv4l2" "qvidcap" "hloc" "istopo" "token" "kinfocenter" "pip"
    "ksysguard" "qdbusviewer" "lstopo" "gufw" "plasma-systemmonitor" "assistant"
    "nm-connection-editor" "nmcli" "plasma" "plasma-open-settings" "partitionmanager"
)
if [ "$CAN_CONNECT" = false ]; then
    prohibidas+=("anydesk")
fi

for pattern in "${prohibidas[@]}"; do
    while IFS= read -r filepath; do
        filename=$(basename "$filepath")
         sudo -u "$USUARIO" tee "/home/$USUARIO/.local/share/applications/$filename" > /dev/null <<HIDDENEOF
[Desktop Entry]
Type=Application
NoDisplay=true
Exec=/usr/bin/false
HIDDENEOF
    done < <(find /usr/share/applications -type f -iname "*${pattern}*.desktop" 2>/dev/null)
done

white_list=(
    "org.kde.dolphin.desktop"
    "org.kde.kcalc.desktop"
    "org.kde.kate.desktop"
    "org.gnome.gedit.desktop"
    "glabels.desktop"
    "store-labels.desktop"
    "libreoffice-startcenter.desktop"
    "org.kde.okular.desktop"
    "mpv.desktop"
    "org.kde.haruna.desktop"
    "org.flameshot.Flameshot.desktop"
    "Zoom.desktop"
    "teams-for-linux.desktop"
    "outlook-for-linux.desktop"
    "discord.desktop"
    "projectlibre.desktop"
    "org.kde.gwenview.desktop"
    "spotify-launcher.desktop"
)

for app in "${white_list[@]}"; do
    if [[ -f "/usr/share/applications/$app" ]]; then
         sudo cp "/usr/share/applications/$app" "/home/$USUARIO/.local/share/applications/"
        local_desktop="/home/$USUARIO/.local/share/applications/$app"
         sudo chown "${USUARIO}:${USUARIO}" "$local_desktop"
         sudo chmod 755 "$local_desktop"
    else
        echo "⚠️  Warning: /usr/share/applications/$app not found."
    fi
done

 sudo tee "/home/$USUARIO/.local/share/applications/${USUARIO}-brave.desktop" > /dev/null <<BRAVEDESKEOF
[Desktop Entry]
Name=Navegador ${USUARIO}
GenericName=Web Browser
Exec=brave --user-data-dir=/home/${USUARIO}/.brave-restricted --no-first-run --proxy-pac-url="file:///home/${USUARIO}/.brave-restricted/whitelist.pac" --ozone-platform=wayland --enable-wayland-ime --disable-features=UseDnsHttpsSvcb
Icon=brave-browser
Type=Application
Categories=Network;WebBrowser;
NoDisplay=true
Terminal=false
BRAVEDESKEOF

 sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.local/share/applications/${USUARIO}-brave.desktop"
 sudo chmod 755 "/home/$USUARIO/.local/share/applications/${USUARIO}-brave.desktop"
 sudo chown -R "${USUARIO}:${USUARIO}" "/home/$USUARIO/.local/share/applications/"
 sudo find "/home/$USUARIO/.local/share/applications/" -name "*.desktop" -exec chmod 755 {} \;
 sudo -u "$USUARIO" XDG_DATA_DIRS="/home/$USUARIO/.local/share:/usr/share/applications:/usr/share" update-desktop-database "/home/$USUARIO/.local/share/applications/" 2>/dev/null || true
 sudo -u "$USUARIO" kbuildsycoca6 --noincremental 2>/dev/null || sudo -u "$USUARIO" kbuildsycoca5 --noincremental 2>/dev/null || true
echo "✅ The app menu is now tidy! Only the chosen ones appear. ✨"

# 10-D. DISABLE TRASH
echo "--- DISABLING THE TRASH SYSTEM ---"
 sudo rm -rf "/home/$USUARIO/.local/share/Trash" 2>/dev/null || true
 sudo mkdir -p "/home/$USUARIO/.config"
 sudo tee "/home/$USUARIO/.config/kiorc" > /dev/null <<KIORCEOF
[Confirmations]
ConfirmDelete=true
ConfirmEmptyTrash=true
ConfirmTrash=false
[Executable]
Value=true
KIORCEOF
 sudo chown -R "${USUARIO}:${USUARIO}" "/home/$USUARIO/.config" "/home/$USUARIO/.local" 2>/dev/null || true
 sudo touch "/home/$USUARIO/.local/share/Trash"
 sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.local/share/Trash"
 sudo chattr +i "/home/$USUARIO/.local/share/Trash" 2>/dev/null || true
echo "✅ The trash system is now a permanent box. Nothing gets thrown away accidentally! 📦"
echo ""

# 10-E. DISABLE KDE WALLET (global para todos los usuarios)
sudo mkdir -p /etc/xdg
sudo tee /etc/xdg/kwalletrc > /dev/null << 'EOF'
[Wallet]
Enabled=false
EOF

# ----------------------------------------------------------------------
# 10-F. 🏷️ gLabels → Zebra ZT231 (CUPS / ZPL — sanctuary user, no admin)
# ----------------------------------------------------------------------
echo "--- 🏷️ LABEL PRINTING: gLabels → Zebra ZT231 (CUPS / ZPL) ---"

ZEBRA_QUEUE_NAME="Zebra_ZT231"
ZEBRA_CONF="/etc/micpapalotlan/zebra-zt231.env"
ZEBRA_PRINT_PKGS=(glabels ghostscript cups cups-filters)
ZEBRA_PRINT_MISSING=()
for pkg in "${ZEBRA_PRINT_PKGS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        ZEBRA_PRINT_MISSING+=("$pkg")
    fi
done
if [[ ${#ZEBRA_PRINT_MISSING[@]} -gt 0 ]]; then
    echo "⚠️  Missing packages (install via APPS.sh): ${ZEBRA_PRINT_MISSING[*]}"
else
    echo "✅ Label-print dependencies present: ${ZEBRA_PRINT_PKGS[*]}"
fi
sudo systemctl enable --now cups 2>/dev/null || true

# Ensure sanctuary user can print (no wheel/sudo; lp group is enough)
sudo usermod -aG lp "$USUARIO" 2>/dev/null || true

sudo mkdir -p /etc/micpapalotlan /etc/cups
sudo tee /etc/cups/zebra-zt231-pipeline.txt > /dev/null <<'ZEBRADOC'
gLabels → Zebra ZT231 printing pipeline (Arch Linux / Micpapalotlan Sanctuary)
======================================================================

Deploy-time setup (Metamorphosis — NOT the sanctuary user):
  The installer enters the printer IP once. CUPS queue "Zebra_ZT231" is created
  automatically. Config is saved in /etc/micpapalotlan/zebra-zt231.env (re-read on update).

Sanctuary user workflow (no terminal, no admin):
  1. Open "Print Labels" from the application menu (gLabels).
  2. Design the label (text, barcodes, small images).
  3. File → Print (or Ctrl+P). Default printer is already Zebra_ZT231.
  4. gLabels sends PostScript to CUPS; Ghostscript/filter chain → ZPL → port 9100.

Strict rules:
  - NO direct ZPL from gLabels. Translation is CUPS/Ghostscript, never in gLabels.
  - Images: under ~200×200 px recommended (^GF RAM limits on printer).
  - Rotation: ZPL 0/90/180/270° only.
  - Sizing: minor mm drift possible (PS → ZPL).

Printer missing or new IP: sudo Gardener → option 3 (find/setup Zebra).
  Saved IP refresh: Gardener option 3 → 1) Refresh IP (LAN scan again).
  Also: zebra-zt231-setup <ip>  |  pre-edit /etc/micpapalotlan/zebra-zt231.env
ZEBRADOC

# ─── System helpers (Gardener + Print Labels launcher use these) ───
sudo tee /usr/local/bin/pupa-zebra-apply > /dev/null <<'ZEBRAAPPLY'
#!/bin/bash
# Apply CUPS queue from /etc/micpapalotlan/zebra-zt231.env (root only)
set -euo pipefail
ZEBRA_CONF=/etc/micpapalotlan/zebra-zt231.env
ZEBRA_QUEUE=Zebra_ZT231
[[ $EUID -eq 0 ]] || { echo "root required"; exit 1; }
[[ -f "$ZEBRA_CONF" ]] || { echo "missing $ZEBRA_CONF"; exit 1; }
# shellcheck source=/dev/null
source "$ZEBRA_CONF"
[[ -n "${ZEBRA_IP:-}" ]] || { echo "ZEBRA_IP not set"; exit 1; }
ZEBRA_QUEUE="${ZEBRA_QUEUE:-Zebra_ZT231}"
systemctl enable --now cups 2>/dev/null || true
lpadmin -p "$ZEBRA_QUEUE" -E -v "socket://${ZEBRA_IP}:9100" -m raw \
  -L "Store Label Printer" -o printer-is-shared=false 2>/dev/null
cupsenable "$ZEBRA_QUEUE" 2>/dev/null || true
cupsaccept "$ZEBRA_QUEUE" 2>/dev/null || true
lpadmin -d "$ZEBRA_QUEUE" 2>/dev/null || true
for u in $(awk -F: '$3>=1000 && $1!="guardian" && $1!="nobody" {print $1}' /etc/passwd); do
  sudo -u "$u" lpoptions -d "$ZEBRA_QUEUE" 2>/dev/null || true
done
echo "OK: ${ZEBRA_QUEUE} -> socket://${ZEBRA_IP}:9100"
ZEBRAAPPLY
sudo chmod 755 /usr/local/bin/pupa-zebra-apply

sudo tee /usr/local/bin/pupa-zebra-ensure > /dev/null <<'ZEBRAENSURE'
#!/bin/bash
# Quick check: is the sanctuary label queue usable? (any user)
QUEUE=Zebra_ZT231
CONF=/etc/micpapalotlan/zebra-zt231.env
systemctl is-active cups &>/dev/null || exit 1
lpstat -p "$QUEUE" &>/dev/null || exit 1
lpstat -p "$QUEUE" 2>/dev/null | grep -qi "disabled" && exit 1
if [[ -f "$CONF" ]]; then
  # shellcheck source=/dev/null
  source "$CONF"
  if [[ -n "${ZEBRA_IP:-}" ]]; then
    timeout 1 bash -c "echo >/dev/tcp/${ZEBRA_IP}/9100" 2>/dev/null || exit 1
  fi
fi
exit 0
ZEBRAENSURE
sudo chmod 755 /usr/local/bin/pupa-zebra-ensure

sudo tee /usr/local/bin/pupa-glabels-launch > /dev/null <<'GLAUNCH'
#!/bin/bash
# Open gLabels; if printer queue is down, tell the user (no terminal skills needed)
if ! /usr/local/bin/pupa-zebra-ensure 2>/dev/null; then
  if command -v zenity &>/dev/null; then
    zenity --warning --width=420 --title="Label printer" \
      --text="The label printer is not ready.\n\nA keeper can fix it with:\n  sudo Gardener  →  option 3 (Zebra printer)\n\nNo need to re-run Metamorphosis.sh." 2>/dev/null || true
  fi
fi
exec glabels "$@"
GLAUNCH
sudo chmod 755 /usr/local/bin/pupa-glabels-launch

# ─── Printer IP: ask installer NOW (not the sanctuary employee) ───
ZEBRA_IP=""
if [[ -f "$ZEBRA_CONF" ]]; then
    # shellcheck disable=SC1090
    source "$ZEBRA_CONF"
    echo "📄 Using saved printer config: $ZEBRA_CONF (IP=${ZEBRA_IP:-unset})"
fi

if [[ -z "${ZEBRA_IP:-}" ]]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  🏷️  ZEBRA ZT231 — SET UP NOW FOR THE SANCTUARY (one time)       ║"
    echo "║  Sanctuary staff will NOT configure this. No admin/terminal later.║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    read -rp "   Zebra ZT231 IP on the sanctuary LAN (empty = skip label printing): " ZEBRA_IP
    if [[ -n "$ZEBRA_IP" ]]; then
        printf "ZEBRA_IP='%s'\nZEBRA_QUEUE='%s'\n" "$ZEBRA_IP" "$ZEBRA_QUEUE_NAME" | sudo tee "$ZEBRA_CONF" > /dev/null
        sudo chmod 644 "$ZEBRA_CONF"
        echo "✅ Saved to $ZEBRA_CONF"
    else
        echo "⚠️  Skipped Zebra setup. Re-run Metamorphosis or create $ZEBRA_CONF later."
    fi
    echo ""
fi

if [[ -n "${ZEBRA_IP:-}" ]]; then
    printf "ZEBRA_IP='%s'\nZEBRA_QUEUE='%s'\n" "$ZEBRA_IP" "$ZEBRA_QUEUE_NAME" | sudo tee "$ZEBRA_CONF" > /dev/null
    if /usr/local/bin/pupa-zebra-apply 2>/dev/null; then
        sudo mkdir -p "/home/$USUARIO/.cups"
        sudo chown -R "${USUARIO}:lp" "/home/$USUARIO/.cups" 2>/dev/null || sudo chown -R "${USUARIO}:${USUARIO}" "/home/$USUARIO/.cups" 2>/dev/null || true
        echo "✅ Default printer for '$USUARIO': $ZEBRA_QUEUE_NAME"
        lpstat -p "$ZEBRA_QUEUE_NAME" 2>/dev/null | head -3 || true
    else
        echo "❌ Could not create CUPS queue. Check: systemctl status cups, ping $ZEBRA_IP"
    fi
fi

# Friendly launcher (no terminal) — "Print Labels" in the app menu
GLABELS_ICON="glabels"
[[ -f /usr/share/pixmaps/glabels.png ]] && GLABELS_ICON="/usr/share/pixmaps/glabels.png"
sudo tee "/home/$USUARIO/.local/share/applications/store-labels.desktop" > /dev/null <<STORELABELSEOF
[Desktop Entry]
Type=Application
Name=Print Labels
GenericName=Label designer
Comment=Design and print labels on the sanctuary Zebra printer
Exec=/usr/local/bin/pupa-glabels-launch
Icon=${GLABELS_ICON}
Categories=Office;Printing;
Terminal=false
StartupNotify=true
STORELABELSEOF
sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.local/share/applications/store-labels.desktop"
sudo chmod 755 "/home/$USUARIO/.local/share/applications/store-labels.desktop"
echo "✅ Menu entry: Print Labels (gLabels)"

sudo -u "$USUARIO" mkdir -p "/home/$USUARIO/Documents"
sudo tee "/home/$USUARIO/Documents/ZEBRA-LABEL-PRINTING.txt" > /dev/null <<USERZEBRADOC
How to print labels (no technical steps)
========================================

1. Open "Print Labels" from the application menu.
2. Create your label (text, barcode, small logo if needed).
3. Press Print (or Ctrl+P).
4. The sanctuary label printer should already be selected. Click Print again.

Tips:
  • Keep pictures small (about 200×200 pixels or less).
  • Straight text and barcodes work best (not diagonal).
  • If the label is blank, use a smaller image and try again.

You do not need a password, admin account, or terminal for printing.

If Print says no printer: a keeper can fix it with  sudo Gardener  (option 3).
No need to re-run Metamorphosis.sh.
USERZEBRADOC
sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/Documents/ZEBRA-LABEL-PRINTING.txt"
sudo chmod 644 "/home/$USUARIO/Documents/ZEBRA-LABEL-PRINTING.txt"

for glabels_desktop in glabels.desktop org.gnome.glabels.desktop; do
    if [[ -f "/usr/share/applications/$glabels_desktop" ]] && \
       [[ ! -f "/home/$USUARIO/.local/share/applications/$glabels_desktop" ]]; then
        sudo cp "/usr/share/applications/$glabels_desktop" "/home/$USUARIO/.local/share/applications/"
        sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.local/share/applications/$glabels_desktop"
        sudo chmod 755 "/home/$USUARIO/.local/share/applications/$glabels_desktop"
    fi
done

if [[ -n "${ZEBRA_IP:-}" ]]; then
    echo "✅ Sanctuary printing ready: menu → Print Labels → Print (default: $ZEBRA_QUEUE_NAME)"
else
    echo "⚠️  Label printing not configured (no Zebra IP). Add $ZEBRA_CONF and re-run Metamorphosis."
fi
echo ""

# ----------------------------------------------------------------------
# 11. 📸 FLAMESHOT CONFIGURATION
# ----------------------------------------------------------------------
echo "--- 📸 SETTING UP THE SHOOTING ROOM (Flameshot) ---"
 sudo -u "$USUARIO" mkdir -p "/home/$USUARIO/.config/flameshot"
 sudo -u "$USUARIO" kwriteconfig6 --file "/home/$USUARIO/.config/flameshot/flameshot.ini" --group General --key savePath "/home/$USUARIO/Trash_Dropbox" 2>/dev/null || \
 sudo -u "$USUARIO" kwriteconfig5 --file "/home/$USUARIO/.config/flameshot/flameshot.ini" --group General --key savePath "/home/$USUARIO/Trash_Dropbox" 2>/dev/null || true
 sudo -u "$USUARIO" kwriteconfig6 --file "/home/$USUARIO/.config/flameshot/flameshot.ini" --group General --key savePathFixed true 2>/dev/null || \
 sudo -u "$USUARIO" kwriteconfig5 --file "/home/$USUARIO/.config/flameshot/flameshot.ini" --group General --key savePathFixed true 2>/dev/null || true
echo "✅ Flameshot will now save all captures directly to the Admin Dropbox. Say cheese! 📸✨"
echo ""

# ----------------------------------------------------------------------
# 13. 📡 REMOTE ACCESS (AnyDesk)
# ----------------------------------------------------------------------
echo "--- 📡 ACTIVATING THE REMOTE VIEWPORT (AnyDesk) ---"

# AnyDesk corre como servicio del sistema (root) pero necesita
# acceder a la sesión Wayland del usuario pupa para capturar pantalla.
# NO bloqueamos el binario - solo lo ocultamos del menú.

 sudo systemctl enable --now anydesk
sleep 5

# Configurar contraseña
ANYDESK_PASSWORD=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 16)
echo "$ANYDESK_PASSWORD" | sudo anydesk --set-password
echo "$ANYDESK_PASSWORD" | sudo gpg --batch --yes --symmetric --output /root/anydesk-password.gpg 2>/dev/null || true
echo "✅ AnyDesk password saved encrypted in /root/anydesk-password.gpg"
echo "   To view it: sudo gpg --decrypt /root/anydesk-password.gpg"

# ─── CRÍTICO: Permitir acceso no atendido ───
echo "🔧 Configuring unattended access..."
 sudo anydesk --settings "security.interactive_access=1" 2>/dev/null || true
 sudo anydesk --settings "security.enable_unattended_access=1" 2>/dev/null || true

# ─── CRÍTICO: Permiso para capturar pantalla en Wayland ───
echo "🔧 Granting Wayland screen capture permissions..."

# El servicio anydesk (root) necesita acceder al socket del usuario pupa
# Sin esto, la conexión entra pero no puede ver la pantalla → rechaza
if [[ -d "/run/user/$USER_ID" ]]; then
    # Dar acceso al directorio runtime del usuario
     sudo setfacl -m u:root:rx "/run/user/$USER_ID" 2>/dev/null || true
    
    # Dar acceso al socket de Wayland
    while IFS= read -r socket; do
        if [[ -f "$socket" ]]; then
             sudo setfacl -m u:root:rw "$socket" 2>/dev/null || true
            echo "   ✅ Granted access to: $socket"
        fi
    done < <(find "/run/user/$USER_ID" -maxdepth 1 -name "wayland-*" ! -name "*.lock" 2>/dev/null)
else
    echo "   ⚠️  Runtime directory not found yet (user not logged in)."
    echo "   ℹ️  Wayland permissions will be applied on first login."
fi

# NOTA: NO se crea regla udev para sockets Wayland porque NO son devices
# del kernel — son sockets Unix gestionados por el compositor en /run/user/UID/.
# Una regla "KERNEL==wayland-*" nunca se aplicaría. Los permisos sobre el socket
# se aplican vía setfacl arriba y vía el script ~/.config/plasma-workspace/env/
# que se ejecuta al iniciar sesión.
# Limpieza por si una versión vieja del script dejó la regla rota:
 sudo rm -f /etc/udev/rules.d/99-anydesk-wayland.rules 2>/dev/null || true
 sudo udevadm control --reload-rules 2>/dev/null || true

# Crear script que se ejecuta al inicio de sesión del usuario pupa
# para garantizar los permisos de Wayland
 sudo mkdir -p "/home/$USUARIO/.config/plasma-workspace/env"
 sudo tee "/home/$USUARIO/.config/plasma-workspace/env/anydesk-wayland.sh" > /dev/null <<WAYLANDEOF
#!/bin/bash
# Grant anydesk service access to this user's Wayland socket
# Required for remote screen capture to work
if [[ -n "\$WAYLAND_DISPLAY" && -n "\$XDG_RUNTIME_DIR" ]]; then
    SOCKET="\$XDG_RUNTIME_DIR/\$WAYLAND_DISPLAY"
    if [[ -S "\$SOCKET" ]]; then
        setfacl -m u:root:rw "\$SOCKET" 2>/dev/null || true
    fi
    # Also grant on the directory
    setfacl -m u:root:rx "\$XDG_RUNTIME_DIR" 2>/dev/null || true
fi
WAYLANDEOF
 sudo chmod +x "/home/$USUARIO/.config/plasma-workspace/env/anydesk-wayland.sh"
 sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.config/plasma-workspace/env/anydesk-wayland.sh"

# Escribir config persistente del daemon (anydesk --settings falla silente en v6+)
# Esto garantiza que las conexiones entrantes con password sean aceptadas sin UI.
echo "🔧 Writing persistent daemon config to /etc/anydesk/service.conf..."
 sudo mkdir -p /etc/anydesk
 sudo touch /etc/anydesk/service.conf
 sudo chmod 600 /etc/anydesk/service.conf
# Eliminar líneas previas de las claves que vamos a setear (idempotente)
 sudo sed -i -E '/^(ad\.security\.unattended_access|ad\.security\.allow_unattended_access_pwd|ad\.security\.interactive_access|ad\.security\.permission_profiles)=/d' /etc/anydesk/service.conf 2>/dev/null || true
 sudo tee -a /etc/anydesk/service.conf > /dev/null <<'ADCONF'
ad.security.unattended_access=true
ad.security.allow_unattended_access_pwd=true
ad.security.interactive_access=2
ad.security.permission_profiles=unattended_full_access
ADCONF

# Reiniciar anydesk para aplicar toda la configuración
 sudo systemctl restart anydesk
sleep 3

ANYDESK_ID=$(anydesk --get-id 2>/dev/null || echo "UNKNOWN")

cat <<EOF

╔════════════════════════════════════════════════════════════════════╗
║                    🔐 REMOTE ACCESS CONFIGURED                     ║
╠════════════════════════════════════════════════════════════════════╣
║                                                                    ║
║   ▶ AnyDesk ID: $ANYDESK_ID                                       ║
║   ▶ Password: encrypted in /root/anydesk-password.gpg             ║
║                                                                    ║
║   ▶ Unattended access: ENABLED                                     ║
║   ▶ Wayland capture: CONFIGURED                                    ║
║                                                                    ║
╠════════════════════════════════════════════════════════════════════╣
║  🔒 SECURITY NOTES:                                                ║
║                                                                    ║
║  ✅ $USUARIO CANNOT initiate AnyDesk (no menu, no terminal)        ║
║  ✅ $USUARIO CANNOT see/change AnyDesk password                    ║
║  ✅ $USUARIO CANNOT disable AnyDesk service                        ║
║  ✅ Guardian CAN connect to supervise $USUARIO                     ║
║  ✅ Manager CAN connect to supervise $USUARIO                     ║
║                                                                    ║
║  ⚠️  First connection may show a black screen for 5-10 seconds    ║
║     while AnyDesk initializes the Wayland capture.                 ║
║     This is NORMAL - wait and it will appear.                      ║
║                                                                    ║
║  ⚠️  If black screen persists after reboot:                        ║
║     1. Log in as $USUARIO first                                    ║
║     2. Wait 30 seconds for session to fully load                   ║
║     3. Then try connecting from external PC                        ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo ""
# ----------------------------------------------------------------------
# 13.1 🧙 ADVANCED HARDENING SPELLS
# ----------------------------------------------------------------------
echo "--- 🧙 CASTING ADVANCED PROTECTION SPELLS ---"

# Password policy
echo "🔐 Setting strong password policies..."
if ! grep -q "^minlen" /etc/security/pwquality.conf 2>/dev/null; then
     sudo tee -a /etc/security/pwquality.conf > /dev/null <<'PWEOF'
minlen = 14
minclass = 4
maxrepeat = 3
dictcheck = 1
usercheck = 1
enforcing = 1
PWEOF
fi
 sudo chage -M 30 guardian 2>/dev/null && echo "✅ Guardian password expires every 30 days."
echo ""

# BTRFS hooks
echo "📸 Enabling pre-update snapshots..."
 sudo mkdir -p /etc/pacman.d/hooks
if [[ ! -f /etc/pacman.d/hooks/btrfs-snapshot.hook ]]; then
     sudo tee /etc/pacman.d/hooks/btrfs-snapshot.hook > /dev/null <<'BTREEOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *
[Action]
Description = 📸 Creating BTRFS snapshot before changes...
When = PreTransaction
Exec = /usr/bin/bash -c 'btrfs subvolume snapshot -r / "/.snapshots/pre-update-$(date +%Y%m%d_%H%M%S)"'
BTREEOF
fi
echo "✅ Hook installed. Snapshots will be created before each pacman operation."
echo ""

# USBGuard
echo "🔌 Hardening USB ports..."
if ! command -v usbguard &>/dev/null; then
     sudo pacman -S --noconfirm usbguard 2>/dev/null || echo "⚠️ Could not install usbguard"
fi
if [[ ! -f /etc/usbguard/rules.conf ]] && command -v usbguard &>/dev/null; then
     sudo usbguard generate-policy > /tmp/usbguard-rules.conf 2>/dev/null
     sudo cp /tmp/usbguard-rules.conf /etc/usbguard/rules.conf 2>/dev/null || true
    sudo rm -f /tmp/usbguard-rules.conf
fi
if command -v usbguard &>/dev/null; then
     sudo systemctl enable --now usbguard 2>&1 || echo "⚠️ Could not enable usbguard"
    echo "✅ USBGuard active. Only currently connected devices are allowed."
    echo "   Ravens stay together... 🐦"
else
    echo "⚠️ USBGuard not available."
fi
echo ""

# Auditd
echo "👁️ Activating the Eye of Sauron (auditd)..."
if ! systemctl is-enabled auditd &>/dev/null; then
     sudo pacman -S --noconfirm audit 2>/dev/null || echo "⚠️ Could not install audit"
fi
if command -v auditctl &>/dev/null; then
     sudo systemctl enable --now auditd 2>/dev/null || true
    sleep 5
     sudo auditctl -w /etc/passwd -p wa -k passwd_changes 2>/dev/null || true
     sudo auditctl -w /etc/shadow -p wa -k shadow_changes 2>/dev/null || true
     sudo auditctl -w /etc/sudoers -p wa -k sudoers_changes 2>/dev/null || true
     sudo auditctl -w "/home/$USUARIO/.bashrc" -p wa -k user_bashrc 2>/dev/null || true
    echo "✅ Audit rules added. Use 'sudo ausearch -k <key>' to view logs."
else
    echo "⚠️ auditctl not available."
fi
echo "   I see you, mortal... 🧙"
echo ""

# Fail2ban
echo "🕊️ Migrating birds know where to go (Fail2ban)..."
if ! command -v fail2ban-server &>/dev/null; then
     sudo pacman -S --noconfirm fail2ban 2>/dev/null || echo "⚠️ Could not install fail2ban"
fi
if [[ ! -f /etc/fail2ban/jail.local ]] && [[ -f /etc/fail2ban/jail.conf ]]; then
     sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local 2>/dev/null || true
fi
if command -v fail2ban-server &>/dev/null; then
     sudo systemctl enable --now fail2ban 2>&1 || echo "⚠️ Could not enable fail2ban"
    echo "✅ Fail2ban is watching. Petting feathers... 🐦"
else
    echo "⚠️ Fail2ban not available."
fi
echo ""

# Kernel hardening
echo "⚙️ Hardening kernel parameters..."
# Nota: kernel.modules_disabled se omite porque es "one-way" (una vez en 1, no baja a 0 sin reboot)
# y 0 es el valor por defecto, por lo que ponerlo es redundante y causa errores en re-ejecuciones.
if [[ ! -f /etc/sysctl.d/99-hardening.conf ]]; then
     sudo tee /etc/sysctl.d/99-hardening.conf > /dev/null <<'KERNEOF'
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
kernel.yama.ptrace_scope = 2
KERNEOF
else
    # En modo actualización, eliminar kernel.modules_disabled si existe de versión antigua
    sudo sed -i '/^kernel\.modules_disabled/d' /etc/sysctl.d/99-hardening.conf 2>/dev/null || true
fi
# Recargar sysctl ignorando claves no escribibles (--ignore silencia "Argumento inválido")
 sudo sysctl --system > /dev/null 2>&1 || true
echo "✅ Kernel hardening applied. Bears hibernate, ducks don't! 🐻"
echo ""

# Disable suspend
echo "⛔ Hibernation? We're too busy being fabulous! 💅🌸"
if [[ ! -f /etc/polkit-1/rules.d/99-disable-suspend.rules ]]; then
     sudo tee /etc/polkit-1/rules.d/99-disable-suspend.rules > /dev/null <<'SUSPENDEOF'
polkit.addRule(function(action, subject) {
   if (action.id == "org.freedesktop.login1.suspend" ||
       action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
       action.id == "org.freedesktop.login1.hibernate" ||
       action.id == "org.freedesktop.login1.hibernate-multiple-sessions") {
      return polkit.Result.NO;
   }
});
SUSPENDEOF
fi
echo "✅ Suspend/hibernate disabled for all users."
echo ""

# AppArmor integration
echo "🛡️ Integrating AppArmor with Firejail..."
if command -v apparmor_parser &>/dev/null && [[ -f "/etc/apparmor.d/firejail-default" ]]; then
     sudo apparmor_parser -r /etc/apparmor.d/firejail-default 2>/dev/null && \
    echo "✅ AppArmor profile loaded for Firejail."
else
    echo "⚠️ AppArmor or firejail-default profile not found. Skipping."
fi
echo ""

# Hardened malloc
echo "🔧 Checking for hardened_malloc..."
if [[ -f "/usr/lib/libhardened_malloc.so" ]]; then
    echo "✅ hardened_malloc detected."
    if ! grep -q "libhardened_malloc.so" "/etc/firejail/${USUARIO}.profile"; then
        echo "env LD_PRELOAD=/usr/lib/libhardened_malloc.so" | sudo tee -a "/etc/firejail/${USUARIO}.profile" > /dev/null
        echo "   Added to ${USUARIO}.profile automatically."
    fi
else
    echo "⚠️ hardened_malloc not installed. (Optional: install from AUR)"
fi
echo ""
echo "--- 🧙 ADVANCED PROTECTION SPELLS COMPLETE ---"
echo ""

# ----------------------------------------------------------------------
# Install and configure AIDE
# ----------------------------------------------------------------------
echo "--- 🔍 SETTING UP FILE INTEGRITY MONITORING (AIDE) ---"

if ! command -v aide &>/dev/null; then
    echo "⚠️ AIDE not found. Please install it with: sudo pacman -S aide"
else
    if [[ ! -f /var/lib/aide/aide.db.gz ]]; then
         sudo aideinit > /dev/null 2>&1
         sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz 2>/dev/null || true
    fi

    if [[ ! -f /etc/cron.weekly/aide-check ]]; then
        sudo mkdir -p /etc/cron.weekly
        sudo tee /etc/cron.weekly/aide-check > /dev/null <<'AIDEEOF'
#!/bin/bash
/usr/bin/aide --check | mail -s "AIDE integrity check" root
AIDEEOF
         sudo chmod +x /etc/cron.weekly/aide-check
    fi

    echo "✅ AIDE configured. Weekly checks will be emailed to root."
    echo "   To run manually: sudo aide --check"
fi

# ----------------------------------------------------------------------
# Create custom seccomp profile
# ----------------------------------------------------------------------
echo "--- 🛡️ CREATING CUSTOM SECCOMP PROFILE ---"

 sudo mkdir -p /etc/seccomp
if [[ ! -f "/etc/seccomp/${USUARIO}-profile.json" ]]; then
     sudo tee "/etc/seccomp/${USUARIO}-profile.json" > /dev/null <<'SECCEOFE'
{
    "defaultAction": "SCMP_ACT_ALLOW",
    "architectures": [
        "SCMP_ARCH_X86_64",
        "SCMP_ARCH_X86",
        "SCMP_ARCH_AARCH64"
    ],
    "syscalls": [
        {
            "names": [
                "personality",
                "kexec_load",
                "kexec_file_load",
                "bpf",
                "perf_event_open",
                "userfaultfd"
            ],
            "action": "SCMP_ACT_ERRNO"
        }
    ]
}
SECCEOFE
fi

if ! grep -q "seccomp=/etc/seccomp/${USUARIO}-profile.json" "/etc/firejail/${USUARIO}.profile"; then
    echo "seccomp=/etc/seccomp/${USUARIO}-profile.json" | sudo tee -a "/etc/firejail/${USUARIO}.profile" > /dev/null
fi

echo "✅ Seccomp profile created and added to firejail profile."
echo "   Blocks dangerous syscalls: personality, kexec_*, bpf, perf_event_open, userfaultfd."

# ----------------------------------------------------------------------
# 13.2 🧹 FINAL PERMISSIONS AND KDE CACHE REBUILD
# ----------------------------------------------------------------------
echo "--- 🧹 FIXING PERMISSIONS AND REBUILDING KDE CACHE ---"
# Temporarily unlock files that were made immutable/append-only earlier
 sudo chattr -i "/home/$USUARIO/.local/share/Trash" 2>/dev/null || true
 sudo chattr -a "/home/$USUARIO/Trash_Dropbox/incoming" 2>/dev/null || true
 sudo chattr -a "/home/$USUARIO/Trash_Dropbox/logs" 2>/dev/null || true
 sudo chattr -i "/home/$USUARIO/.brave-restricted/whitelist.pac" 2>/dev/null || true

 sudo chown -R "${USUARIO}:${USUARIO}" "/home/$USUARIO"

# Re-apply the protections immediately
 sudo chattr +i "/home/$USUARIO/.local/share/Trash" 2>/dev/null || true
 sudo chattr +a "/home/$USUARIO/Trash_Dropbox/incoming" 2>/dev/null || true
 sudo chattr +a "/home/$USUARIO/Trash_Dropbox/logs" 2>/dev/null || true
 sudo chattr +i "/home/$USUARIO/.brave-restricted/whitelist.pac" 2>/dev/null || true

 sudo -u "$USUARIO" kbuildsycoca6 --noincremental 2>/dev/null || echo "⚠️  kbuildsycoca6 could not run (may not be necessary)."
echo "✅ Cache and permissions fixed."

# ----------------------------------------------------------------------
# 14. PERSONAL FOLDERS (append-only applied later by lock script)
# ----------------------------------------------------------------------
echo "--- 📁 ADDING A 'NO-ERASE' SPELL TO PERSONAL FOLDERS ---"
for dir in "Desktop" "Documents" "Downloads" "Pictures"; do
     sudo mkdir -p "/home/$USUARIO/$dir"
     sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/$dir"
     sudo chmod 770 "/home/$USUARIO/$dir"
done
echo "✅ Personal folders are prepared for the final protective spell."
echo ""

# ----------------------------------------------------------------------
# 15. CONFIGURATION FOLDER OWNERSHIP
# ----------------------------------------------------------------------
echo "--- 🔑 MAKING SURE EVERYTHING IS IN THE RIGHT HANDS ---"
 sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.config" 2>/dev/null || true
 sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.local" 2>/dev/null || true
 sudo chown "${USUARIO}:${USUARIO}" "/home/$USUARIO/.cache" 2>/dev/null || true
echo "✅ Configuration folders now belong to $USUARIO."
echo ""

# ----------------------------------------------------------------------
# 16. ROOT OWNERS FOR CRITICAL FILES
# ----------------------------------------------------------------------
echo "--- 👑 PLACING CROWN JEWELS UNDER ROOT'S PROTECTION ---"
 sudo chown root:root "/home/$USUARIO/.bashrc" 2>/dev/null || true
 sudo chown root:root "/home/$USUARIO/.brave-restricted/whitelist.pac" 2>/dev/null || true
 sudo chown root:root "/home/$USUARIO/.config/flameshot/flameshot.ini" 2>/dev/null || true
 sudo chown root:root "/home/$USUARIO/.local/share/Trash" 2>/dev/null || true
echo "✅ Critical files now have a royal guard (root)."
echo ""


# ----------------------------------------------------------------------
# 17. FINAL MESSAGE
# ----------------------------------------------------------------------
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          🌟  $USUARIO CHRYSALIS FORMATION COMPLETE!  🌟          ║"
echo "║       A safe and isolated pupa has been formed for $USUARIO.      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo " 🔔  Remember..."
echo "   - After rebooting, all changes will be permanent."
echo ""
echo "    But before that..."
echo "   - Run 'source ~/.bashrc' as guardian to load new aliases."
echo "   - Switch to any TTY above 3 or switch user, log in as $USUARIO, and look around the GUI."
echo "   - While logged in as $USUARIO, come back to your main TTY as guardian, open a terminal and run:"
echo "       sudo -u $USUARIO DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus qdbus6 org.kde.plasmashell /PlasmaShell evaluateScript 'lockCorona(true)'"
echo "   - Then run 'history -c' to clear the terminal history."
echo ""
echo "   ...If everything went great, Welcome $USUARIO to the Sanctuary by running:"
echo "       Seal-Pupa   (to apply final restrictions)"
echo ""
echo "      then run 'rm -rf SR-Setup'"
echo ""
echo ""
echo "   Remember, you have the following commands if something goes wrong:"
echo "       Free-Pupa        (to lift them temporarily)"
echo "       Shatter-Chrysalis (to completely remove restrictions)"
echo ""
echo ""

# ----------------------------------------------------------------------
# 🔮 FUN EASTER EGG: Numerology & Chinese Zodiac
# ----------------------------------------------------------------------
LINE_COUNT=$(wc -l < "$0")
reduce_to_single() {
    local num=$1
    while [[ $num -gt 9 ]]; do
        local sum=0
        while [[ $num -gt 0 ]]; do
            sum=$((sum + num % 10))
            num=$((num / 10))
        done
        num=$sum
    done
    echo "$num"
}
DIGIT_SUM=$(reduce_to_single "$LINE_COUNT")
case $DIGIT_SUM in
    1) MEANING="new beginnings and leadership 🌱" ;;
    2) MEANING="balance and partnership 🕊️" ;;
    3) MEANING="creativity and communication 🎨" ;;
    4) MEANING="stability and hard work 🏛️" ;;
    5) MEANING="freedom and adventure 🦋" ;;
    6) MEANING="harmony and responsibility 💞" ;;
    7) MEANING="introspection and wisdom 🔮" ;;
    8) MEANING="abundance and power 💰" ;;
    9) MEANING="completion and humanitarianism 🌍" ;;
esac

YEAR=$(date +%Y)
ANIMALS=("Rat" "Ox" "Tiger" "Rabbit" "Dragon" "Snake" "Horse" "Goat" "Monkey" "Rooster" "Dog" "Pig")
ELEMENTS=("Metal" "Metal" "Water" "Water" "Wood" "Wood" "Fire" "Fire" "Earth" "Earth")
ELEMENT_QUALITY=("resilience and determination" "resilience and determination"
                 "adaptability and intuition" "adaptability and intuition"
                 "growth and creativity" "growth and creativity"
                 "passion and transformation" "passion and transformation"
                 "stability and nurturing" "stability and nurturing")
BRANCH_INDEX=$(((YEAR - 4) % 12))
ANIMAL=${ANIMALS[$BRANCH_INDEX]}
STEM_INDEX=$((YEAR % 10))
ELEMENT=${ELEMENTS[$STEM_INDEX]}
ELEMENT_QUALITY_STR=${ELEMENT_QUALITY[$STEM_INDEX]}
if [[ $((STEM_INDEX % 2)) -eq 0 ]]; then
    POLARITY="Yang"
else
    POLARITY="Yin"
fi
case $ANIMAL in
    Rat)    EMOJI="🐭"; TRAIT="resourcefulness and survival" ;;
    Ox)     EMOJI="🐮"; TRAIT="diligence and strength" ;;
    Tiger)  EMOJI="🐯"; TRAIT="courage and unpredictability" ;;
    Rabbit) EMOJI="🐰"; TRAIT="peace and elegance" ;;
    Dragon) EMOJI="🐉"; TRAIT="luck and ambition" ;;
    Snake)  EMOJI="🐍"; TRAIT="wisdom and mystery" ;;
    Horse)  EMOJI="🐎"; TRAIT="energy and freedom" ;;
    Goat)   EMOJI="🐐"; TRAIT="creativity and gentleness" ;;
    Monkey) EMOJI="🐒"; TRAIT="intelligence and playfulness" ;;
    Rooster) EMOJI="🐓"; TRAIT="confidence and hard work" ;;
    Dog)    EMOJI="🐶"; TRAIT="loyalty and honesty" ;;
    Pig)    EMOJI="🐷"; TRAIT="generosity and indulgence" ;;
esac

echo "--- 🔮 A MESSAGE FROM THE STARS 🔮 ---"
echo ""
echo "✨ This sacred script has $LINE_COUNT lines, reduces to $DIGIT_SUM, which in numerology signifies:"
echo "   $MEANING"
echo ""
echo "🐉 The year $YEAR is the $ELEMENT $ANIMAL ($POLARITY)."
echo "   According to Chinese astrology, this $ELEMENT $ANIMAL year brings:"
echo "   ✦ The $ANIMAL's $TRAIT"
echo "   ✦ Infused with the $ELEMENT element's $ELEMENT_QUALITY_STR"
echo "   Together, it's a time of $(echo "$TRAIT" | cut -d' ' -f1) with a touch of $(echo "$ELEMENT_QUALITY_STR" | cut -d' ' -f1). $EMOJI"
echo ""
