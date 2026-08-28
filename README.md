DISCLAIMER: I forked this from original, I used ChatGPT & Claude to swap the code over from Linux to Windows. I have tested this on my Rog Xbox Ally X and the stuttering issues have gone away.

Previous disclaimer: I have used chatgpt to help me diagnose this issue and write this text. This was tested on a Rog Ally X running bazzite.

# ROG Ally X – SD Card Stutter Fix  
### Realtek RTS525A Voltage-Switch Bug: Technical Summary & Workaround

This repository documents the diagnosis and workaround for SD card stuttering on the **ASUS ROG XBOX Ally X** when using the internal **Realtek RTS525A** SD card reader. The issue causes periodic in-game stutter when running titles from the SD card and produces voltage-switch errors in kernel logs.

The fix below fully eliminates the problem.

---

### 1. Symptoms

- Games/emulators stutter for 1–2 seconds when run from the SD card.
- No stutter occurs when running the same game from NVMe.
Kernel logs show errors such as:
- mmc1: cannot verify signal voltage switch
- mmc1: error -110
- mmc1: voltage switch failed


- Stutter disappears the moment continuous SD I/O occurs.

---

### 2. Root Cause (Verified Through Testing)**

### Realtek RTS525A enters a broken low-power state**

After ~4 seconds of no SD activity, the controller:

1. Enters a deep runtime idle state  
2. Attempts a **1.8 V UHS-I voltage switch** when waking  
3. Frequently fails the voltage switch
4. Resets/retries, causing **1–2 second I/O stalls**

These stalls surface as **regular gameplay stutters**.

### Why OS settings don't help

Tests showed:

- `mmc0/power/control=on` does not prevent the bug  
- Card-level power control causes a forced rebind (crashes applications)  
- Read-only keepalive fails due to caching  
- No `uhs_*` sysfs controls are exposed  
- The behaviour originates inside the **Realtek firmware**, not Linux  

---

### 3. The Fix: A Lightweight Write-Based Keep-Alive

A tiny physical write every 3 seconds prevents the controller from entering its unstable idle state.

This was validated experimentally:

- 5 seconds → stutter still occurs  
- 4 seconds → borderline  
- **3 seconds → fully stable**  

### Why it works

- Only **real block writes** reset the controller’s internal idle timer  
- Cached reads do not  
- Keeping the card “alive” bypasses the faulty voltage-switch path entirely

---

### 4. Wear and Power Usage
NAND wear

At 1 byte every 3 seconds

24 hours/day:
~28 KB/day
~10 MB/year
~50 MB over 5 years

3 hours/day:
~3.6 KB/day
~1.25 MB/year
~6 MB over 5 years

---

### 5. Final Diagnosis

Problem:
Realtek RTS525A voltage-switch failures when recovering from deep idle.

Cause:
Internal firmware behaviour, not controllable by kernel runtime power settings.

Effect:
Stalls SD I/O for 1–2 seconds → gameplay stutter.

Solution:
Prevent the controller from entering the problematic idle state via a lightweight periodic 1-byte write.

---

### 6. Notes on PCIe ASPM (Active State Power Management)

ASPM was investigated because the Realtek RTS525A SD reader is a PCIe device.  
On some systems, aggressive ASPM can cause latency spikes during link power-state transitions.

### Findings from testing on the ROG Ally X (Linux)

- The usual Linux interfaces for adjusting ASPM (`/sys/module/pcie_aspm/parameters/policy`, `/sys/bus/pci/.../link/*`) were either **read-only** or **not writable**.
- This indicates that ASPM policy is **locked by firmware/BIOS** on the Ally X, and cannot be modified from the operating system.
- The device consistently stayed in the same link state regardless of attempted configuration.
- Stuttering and voltage-switch failures continued unchanged.

### Why ASPM is not involved

The problematic behavior occurs at the **MMC/SD voltage-switch layer**, not at the PCIe link layer.  
The Realtek controller transitions into an internal low-power state independent of ASPM and fails during recovery, triggering MMC errors such as:

### Reddit posts:
A couple of reddit posts describing the same issue
https://www.reddit.com/r/PCSX2/comments/1jwig10/pcsx2_occasional_frame_drop_every_15_seconds_on/
https://www.reddit.com/r/ROGAllyX/comments/1i8zgjp/sd_card_stuttersfreeze_ally_x/
https://www.reddit.com/r/LegionGo/comments/17w7unz/games_running_on_sd_card_have_micro_pauses/
https://www.reddit.com/r/ROGAlly/comments/1eni0uf/ally_x_sd_card_stutter/
https://www.reddit.com/r/LegionGo/comments/182j5um/psa_if_you_are_getting_stutterhitchesbad/
https://www.reddit.com/r/ROGAlly/comments/1hely0k/i_have_rog_ally_x_sandisk_extreme_sd_card/
https://www.reddit.com/r/ROGAlly/comments/18e726n/sd_card_stuttering/ (older post, old ally)
https://www.reddit.com/r/EmuDeck/comments/1f37fvs/games_have_minor_stutters_due_to_sd_card/

