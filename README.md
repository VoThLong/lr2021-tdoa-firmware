# TECHNICAL DOCUMENTATION: LR2021 TDoA FIRMWARE

**Architecture:** Zephyr Out-of-Tree (OOT) Application
**Hardware Platform:** Seeed Studio XIAO nRF54L15 with Semtech LR2021 (LoRa Plus) transceiver
**Application Objective:** Wireless network nodes for Time Difference of Arrival (TDoA) localization algorithms.

---

## 1. PREREQUISITES

### 1.1. System Dependencies
Install the required build tools for your distribution:

**Ubuntu / Debian:**
```bash
sudo apt update
sudo apt install --no-install-recommends git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel \
  xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1
```

**Fedora:**
```bash
sudo dnf install -y git cmake ninja-build gperf \
  ccache dfu-util dtc wget \
  python3-devel python3-pip python3-setuptools python3-wheel \
  xz perl-interpreter make gcc gcc-c++ libgcc.i686 SDL2-devel libmagic
```

### 1.2. Cross-Compilation Toolchain
This project requires **Zephyr SDK v0.16.8** (or later). 
1. Download and install it from the [Zephyr SDK Releases](https://github.com/zephyrproject-rtos/sdk-ng/releases).
2. Ensure it is registered in your environment or installed in the default location (`~/.local/zephyr-sdk-0.16.8`).

### 1.3. Upstream Workspace Initialization
The project relies on the Semtech USP (Universal Software Platform) which contains the OS and drivers.
```bash
# Create a dedicated workspace folder
mkdir -p ~/lora_usp_workspace
cd ~/lora_usp_workspace

# Initialize west and pull dependencies
west init -m https://github.com/Lora-net/usp_zephyr.git --mr main
west update
```

---

## 2. PROJECT SETUP AND COMPILATION

**Step 1: Isolated Virtual Environment**
Create a Python virtual environment to manage tools like `west` and `pyocd`:
```bash
cd ~/path/to/this/repository
python3 -m venv .venv
source .venv/bin/activate
pip install west pyocd
```

**Step 2: Environment Configuration**
Map the project to the upstream Zephyr base. Replace `~/lora_usp_workspace` if you chose a different path in step 1.3:
```bash
export ZEPHYR_BASE="$HOME/lora_usp_workspace/zephyr"
source $ZEPHYR_BASE/zephyr-env.sh
```
*Note: You must run the `source` command in every new terminal session, or add it to your `.bashrc` / `.zshrc` for persistence.*

**Step 3: Permission Setup**
Ensure all automation scripts are executable:
```bash
chmod +x scripts/*.sh
```

**Step 4: Hardware Verification**
Connect your board and verify it is detected:
```bash
pyocd list
```
*Note: You should see a target named `nrf54l15` or similar.*

---

## 3. HARDWARE CONFIGURATION

### 3.1. Pinout Mapping (XIAO nRF54L15 ↔ LR2021)
This project uses a custom pinout optimized to prevent conflicts with the onboard I2C (OLED) and UART (Log) peripherals. 

**Note:** Pin labels (D0, D1, etc.) refer to the **Physical Silkscreen** labels printed on the XIAO board.

| LR2021 Signal | XIAO Pin (Silkscreen) | **nRF54L15 GPIO** | Function | Status |
| :--- | :--- | :--- | :--- | :--- |
| **NSS (CS)** | **D3** | **P1.07** | SPI Chip Select | Active Low |
| **NRESET** | **D2** | **P1.06** | Hardware Reset | Active Low |
| **BUSY** | **D1** | **P1.05** | Busy Handshake | Active High |
| **DIO8** | **D0** | **P1.04** | Primary IRQ | Trigger on Tx/Rx Done |
| **SCK** | **D8** | **P2.01** | SPI Clock | 16 MHz Max |
| **MISO** | **D9** | **P2.04** | SPI MISO | - |
| **MOSI** | **D10** | **P2.02** | SPI MOSI | - |
| **SDA/SCL** | **D4/D5** | **P1.10/P1.11** | I2C (OLED) | Reserved |
| **TX/RX** | **D6/D7** | **P2.08/P2.07** | UART Log | Reserved |

### 3.2. Hardware Verification
Check the BUSY and NSS signals if you encounter SPI timeout errors. The LR2021 requires the BUSY line to go low before accepting any new commands.

---

## 4. APPLICATION LOGIC & MODES

### 4.1. PingPong Application
Designed for basic RF connectivity testing and range validation.
*   **Master:** Sends a "Ping" packet and waits for a "Pong".
*   **Subordinate:** Listens for "Ping" and immediately replies with "Pong".
*   **Use case:** Initial hardware validation and link budget testing.

### 4.2. Ranging Application (ToF)
Uses Time-of-Flight and Frequency Hopping to measure the distance between two nodes.
*   **Manager (Master):** Initiates the ranging exchange, coordinates frequency hopping across multiple channels, and calculates the final median distance.
*   **Subordinate (Slave):** Synchronizes with the Manager and responds to ranging pulses on the correct frequencies.
*   **Use case:** High-precision indoor/outdoor localization research.

---

## 5. BUILDING AND FLASHING

### 5.1. Manual Build
To build the default application (PingPong):
```bash
west build -b xiao_nrf54l15/nrf54l15/cpuapp --shield semtech_wio_lr2021 -p always
```

### 5.2. Automated Flash Scripts
We provide pre-configured scripts for common roles. Use the `[TARGET_UID]` (from `pyocd list`) if multiple boards are connected.

| Application | Role | Command | Description |
| :--- | :--- | :--- | :--- |
| **PingPong** | Master | `./scripts/flash_pingpong_master.sh` | Initiates the ping sequence. |
| **PingPong** | Subordinate | `./scripts/flash_pingpong_sub.sh` | Listens and responds to pings. |
| **Ranging** | Manager | `./scripts/flash_ranging_manager.sh` | Coordinates ToF distance measurement. |
| **Ranging** | Subordinate | `./scripts/flash_ranging_sub.sh` | Participates in the ranging exchange. |
| **Recovery** | Factory | `./scripts/flash_factory.sh` | Restores original LoRa Studio firmware. |

---

## 6. TROUBLESHOOTING

- **Build Errors:** Ensure `ZEPHYR_BASE` is correctly exported and you have run `west update` in the upstream workspace.
- **Flash Failures:** Check USB connection. Ensure your user has permissions to access USB devices (e.g., add to `plugdev` group or use `sudo`).
- **OLED Not Working:** Verify you are using the `semtech_wio_lr2021` shield configuration.
