# Core3566 <img src="https://www.luckfox.com/image/catalog/luckfox-100px.png" style="height:7mm"/>

## Install Gentoo <img src="https://www.gentoo.org/assets/img/logo/gentoo-signet.svg" alt="Gentoo Linux" style="height:7mm;position:relative;bottom:-1mm;"/>
- Connect Core3566 to computer in maskrom mode with USB.
- Connect serial cable to GPIO header pins 8 and 10 and listen using serial terminal emulator like `picocom -b 1500000 -e p /dev/ttyUSB0`
- `Docker` with privileges is needed. And run below commands in terminal.
```bash
mkdir -p ~/workspace
cd ~/workspace
curl -LO https://raw.githubusercontent.com/Necktwi/Core3566/refs/heads/master/core3566Gentoo.sh
chmod +x core3566Gentoo.sh
./core3566Gentoo.sh
```
- This should build and flash Gentoo to Core3566 to give a login prompt in `picocom`.
- Running `core3566Gentoo.sh` again, may b to install Gentoo on another Core3566 or previous run failed, won't do redundant work like downloading and building sources, it uses already built binaries.
- To start fresh, run `./core3566Gentoo.sh clean`.
- To install Gentoo with stock kernel-4, read https://wiki.gentoo.org/wiki/Luckfox_Core3566 README.md
- Use https://github.com/Necktwi/Core3566 to create an issue ticket.

### Closure
- My Core3566 booting no more, donno what took it down, possibly mounting it on
  RPi CM4 IO Base which takes 12V input, it should not be the reason, after
  which i realised there should red led on Core3566 which is no more. Usually
  I mount it on Waveshare IO-base-b.
- Since very beginning, nvme gave IO error randomly.
- After few months while i'm trying to get IMX219 working with Kernel-7, i've
  connected its UART2 to ESP-WROOM-32D UART0(5v) by mistake and it stopped
  working. Now I've set kernel to use UART7 for serial console.
- After couple of days I think I connected UART7 to ESP32-C6 GPIO2,3 instead of
  GPIO16,17 for serial console, i'm not sure 'coz I still got serial console,
  few minutes after it stopped responding. I remounted it on IO base, it didn't
  work, I mounted it on RPi CM4 IO base; not even single led lit up.
  Waveshare-io-base-b is working fine, now I mounted BPiCM4 on it.
- I'm not working with Luckfox, I just bought Core3566 from an online store.
  The info I gathered here is from Luckfox online resources and my observations.
- Anyone who wants to augment this document can pull request
  https://github.com/Necktwi/Core3566.git the augmented
  [Linux6+.md](https://github.com/Necktwi/Core3566/blob/master/Linux6%2B.md).
### Overlays
- To disable `HDMI` and `USB`, may b to conserve power, remove `/core3566-waveshare-cm4-io-base-b-usb.dtbo /core3566-waveshare-cm4-io-base-b-hdmi.dtbo` from `FDTOVERLAYS` in `/boot/extlinux/extlinux.conf`
- To enable `CMOS RTC` add `/core3566-waveshare-cm4-io-base-b-rtc.dtbo` to overlays and add `blacklist rtc_rk808` to `/etc/modprobe.d/blacklist-rtc-rk808.conf`
  - With CMOS battery installed, time will be persisted after 2 reboots.
- To control fan with header 4, use `/core3566-waveshare-cm4-io-base-b-fan.dtbo`
- To check all the overlays have all the dependent nodes:
  `fdtoverlay -i /boot/rk3566-core3566.dtb -o /tmp/test.dtb /boot/*.dtbo`
  should not give any error.

## Making SD card out of stock images when eMMC is flashed with Gentoo
1. If eMMC is flashed with Gentoo then sdcards made with Luckfox's instructions
   won't boot because we're using custom u-boot.
1. If SDK already installed go to 2 else download LUCKFOX_LINUX419_SDK from [here](https://drive.google.com/drive/folders/1HCNYaVqQMv0vGc4630fmHkq2Eldi9Y2z)
   as ~/Dowloads/luckfox-sdk.tar.gz
```
mkdir -p ~/workspace/luckfox && cd ~/workspace/luckfox
tar xvf ~/Downloads/luckfox-sdk.tar.gz
mkdir -p .pyvenv/bin
ln -s /usr/bin/python2 .pyvenv/bin/python
export PATH=".pyvenv/bin:$PATH"
.repo/repo/repo sync -l
```
2. Build the kernel
```
export CROSS_COMPILE="$HOME/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
cd kernel
make ARCH=arm64 CC="${CROSS_COMPILE}gcc" -j`nproc` luckfox_core3566_linux_defconfig
make ARCH=arm64 CC="${CROSS_COMPILE}gcc" -j`nproc` rockchip/core3566-hdmi-lp4x-v1-linux.dtb Image
```
3. Download one of the OS images from [here](https://drive.google.com/drive/folders/1ac_wZOGWZGYym02FX6t44EKQeRXdm3OW) as ~/Downloads/core3566.img
```
cd ~/workspace/luckfox/tools/linux/Linux_Pack_Firmware/rockdev/
ln -s ~/Downloads/core3566.img ./update.img
./unpack.sh #gives ./output/Image/ with rootfs image
```
4. Make sdcard with a 64MB fat32 partiton and a ext4 partition with remaining space. format them and assign labels bootfs and rootfs.
5. Mount `rootfs` on `/mnt/sd/` and `bootfs` on `/mnt/sd/boot`
6. Prepare SD card
```
sudo mkdir /mnt/img
sudo mount ~/workspace/luckfox/tools/linux/Linux_Pack_Firmware/rockdev/output/Image/rootfs.img /mnt/img
sudo mkdir /mnt/img/oem
sudo mount ~/workspace/luckfox/tools/linux/Linux_Pack_Firmware/rockdev/output/Image/oem.img /mnt/img/oem
# comment out oem and userdata in fstab
sudo rsync -avpPh /mnt/img/ /mnt/sd
sudo cp ~/workspace/luckfox/kernel/arch/arm64/boot/Image /mnt/sd/boot/
sudo cp ~/workspace/luckfox/kernel/arch/arm64/boot/dts/rockchip/core3566-hdmi-lp4x-v1-linux.dtb /mnt/sd/boot/
sudo mkdir /mnt/sd/boot/extlinux/
sudo tee /mnt/sd/boot/extlinux/extlinux.conf <<EOF
LABEL Linux
KERNEL /Image
FDT /core3566-hdmi-lp4x-v1-linux.dtb
FDTOVERLAYS /overlays/i2c5.dtbo
APPEND root=PARTLABEL=rootfs rw rootwait earlycon=uart8250,mmio32,0xfe660000 console=ttyS2,1500000 console=tty1
EOF
sudo umount -R /mnt/bpi
```
7. Insert SD card into core3566 io base and boot
8. [dmesg](files/linaro.dmesg)
9. [dts](files/linaroCore3566.dts)

### To chroot Luckfox qcow2
```
sudo su
modprobe nbd max_part=8
qemu-nbd --connect=/dev/nbd0 ~/workspace/luckfox/luckfox.qcow2
mkdir -p /mnt/luckfox
mount /dev/nbd0p1 /mnt/luckfox
mount --types proc /proc /mnt/luckfox/proc
mount --rbind /sys /mnt/luckfox/sys
mount --make-rslave /mnt/luckfox/sys
mount --rbind /dev /mnt/luckfox/dev
mount --make-rslave /mnt/luckfox/dev
mount --bind /run /mnt/luckfox/run
mount --make-slave /mnt/luckfox/run
chroot /mnt/luckfox /bin/bash
source /etc/profile
export PATH="/usr/local/sbin:/usr/local/bin:/snap/bin:/usr/bin:/usr/sbin:/bin:/sbin"
export PS1="(chroot) ${PS1}"
login luckfox
```

### To exit chroot
```
exit
exit
umount -R /mnt/luckfox/dev
umount -R /mnt/luckfox/sys
umount -R /mnt/luckfox/proc
umount -R /mnt/luckfox/run
umount -R /mnt/luckfox/dev
umount -R /mnt/luckfox/boot
umount -R /mnt/luckfox/
```

## Troubleshooting
- to boot independent of `extlinux.conf` from `u-boot` console
```
mmc dev 0
fatload mmc 0:1 0x02080000 /Image
fatload mmc 0:1 0x0a100000 /rk3566-core3566.dtb
setenv bootargs "root=PARTLABEL=rootfs rw rootwait earlycon=uart8250,mmio32,0xfe660000 console=ttyS2,1500000 console=tty1"
booti 0x02080000 - 0x0a100000
```

## CM4 Pinout
|Pin|Signal|Description|
|:--|:-----|:----------|
|1  |GND   |Ground (0V)|
|2|GND|Ground (0V)|
|3|Ethernet_Pair3_P|Ethernet pair 3 positive (connect to transformer or MagJack)|
|4|Ethernet_Pair1_P|Ethernet pair 1 positive (connect to transformer or MagJack)|
|5|Ethernet_Pair3_N|Ethernet pair 3 negative (connect to transformer or MagJack)|
|6|Ethernet_Pair1_N|Ethernet pair 1 negative (connect to transformer or MagJack)|
|7|GND|Ground (0V)|
|8|GND|Ground (0V)|
|9|Ethernet_Pair2_N|Ethernet pair 2 negative (connect to transformer or MagJack)|
|10|Ethernet_Pair0_N|Ethernet pair 0 negative (connect to transformer or MagJack)|
|11|Ethernet_Pair2_P|Ethernet pair 2 positive (connect to transformer or MagJack)|
|12|Ethernet_Pair0_P|Ethernet pair 0 positive (connect to transformer or MagJack)|
|13|GND|Ground (0V)|
|14|GND|Ground (0V)|
|15|Ethernet_nLED3|High = Link Up at 1000mbps Blinking = Transmitting or Receiving|
|16|Reserved|NC|
|17|Ethernet_nLED2|High = Link Up at 100mbps Blinking = Transmitting or Receiving|
|18|Reserved|NC|
|19|Reserved|NC|
|20|Reserved|NC|
|21|Pi_nLED_Activity|1U19 -- PWM6/SPI0_MISO_M0/GPIO0_C5_d|
|22|GND|Ground (0V)|
|23|GND|Ground (0V)|
|24|GPIO3_A7|"GPIO: typically a 3.3V signal| but can be a 1.8V signal by connecting GPIO_VREF to 1.8V"|
|25|GPIO4_C2|"GPIO: typically a 3.3V signal| but can be a 1.8V signal by connecting GPIO_VREF to 1.8V"|
|26|GPIO4_C5|"GPIO: typically a 3.3V signal| but can be a 1.8V signal by connecting GPIO_VREF to 1.8V"|
|27|GPIO4_C3|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|28|GPIO3_B1|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|29|GPIO3_A6|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|30|GPIO4_C4|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|31|GPIO3_B2|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|32|GND|Ground (0V)|
|33|GND|Ground (0V)|
|34|GPIO3_C0|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|35|ID_SC|(1T4 -- I2C3_SCL_M1/PWM10_M0/GPIO3_B5_d) GPIO: typically a 3.3V signal but can be a 1.8V signal by connecti ng GPIO_VREF to 1.8V|
|36|ID_SD|(1V2 -- I2C3_SDA_M1/PWM11_IR_M0/GPIO3_B6_d) GPIO: typically a 3.3V signal but can be a 1.8Vsignal by connectin g GPIO_VREF to 1.8V|
|37|GPIO3_A5|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|38|GPIO3_C3|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|39|GPIO3_A4|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|40|GPIO3_C2|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|41|GPIO3_A3|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|42|GND|Ground (0V)|
|43|GND|Ground (0V)|
|44|GPIO3_C1|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|45|GPIO3_A2|GPIO: typically a 3.3V signal but can be a 1.8V signal by c onnecting GPIO_VREF to 1.8V|
|46|GPIO3_C5|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|47|GPIO3_A1|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|48|GPIO3_C4|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|49|GPIO4_C6|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|50|GPIO3_B0|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|51|GPIO0_D0|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|52|GND|Ground (0V)|
|53|GND|Ground (0V)|
|54|GPIO3_B7|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|55|GPIO0_D1|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V|
|56|GPIO3_B3|GPIO: typically a 3.3V signal but can be a 1.8V signal by conn ecting GPIO_VREF to 1.8V. Internal 20kΩ pull up to GPIO_ VREF|
|57|SD_CLK|SD card clock signal|
|58|GPIO3_B4|GPIO: typically a 3.3V signal but can be a 1.8V signal by connecting GPIO_VREF to 1.8V. Internal 20kΩ pull up to GPIO_VREF|
|59|GND|Ground (0V)|
|60|GND|Ground (0V)|
|61|SD_DAT3|SD card/eMMC Data3 signal|
|62|SD_CMD|SD card/eMMC Command signal|
|63|SD_DAT0|SD card/eMMC Data0 signal|
|64|Reserved|NC|
|65|GND|Ground (0V)|
|66|GND|Ground (0V)|
|67|SD_DAT1|SD card/eMMC Data1 signal|
|68|Reserved|NC|
|69|SD_DAT2|SD card/eMMC Data2 signal|
|70|Reserved|NC|
|71|GND|Ground (0V)|
|72|Reserved|NC|
|73|Reserved|NC|
|74|GND|Ground (0V)|
|75|SD_PWR_ON|Default pull-upInternal 10kΩ pull up to CORE_3 .3V|
|76|Reserved|NC|
|77|+5V (Input)|4.75V-5.25V. Main power input|
|78|GPIO_VREF|Must be connected to CORE3 .3V (pins 84 and 86) for 3.3V GPIO or CORE1 .8V (pins 88 and 90) for 1.8V GPIO. This pin cannot be floating or connected to ground.|
|79|+5V (Input)|4.75V-5.25V. Main power input|
|80|SCL0|I2C clock pin (AK37 -- I2C1_SCL/MCU_JTAG_TDO/GPIO0_B3_u): typically used for Camera and Display. Please pull-up resistor to VCC for normal use.|
|81|+5V (Input)|4.75V-5.25V. Main power input|
|82|SDA0|I2C Data pin (AM38 -- I2C1_SDA/PCIE20_BUTTONRSTn/MCU_JTA G_TCK/GPIO0_B4_u): typically used for Camera and Display. Please pull-up resistor toVCC for normal use.|
|83|+5V (Input)|4.75V-5.25V. Main power input|
|84|CORE3.3V (Output)|3.3V ± 2.5%. Power Output max 300mA per pin for a total of 600 mA. This will be powered down during power-off or GLOBAL_EN being set low|
|85|+5V (Input)|4.75V-5.25V. Main power input|
|86|CORE3.3V (Output)|3.3V ± 2.5%. Power Output max 300mA. This will be powered dow n during power-off or GLOBAL_EN being set low|
|87|+5V (Input)|4.75V-5.25V. Main power input|
|88|CORE1.8V (Output)|1.8V ± 2.5%. Power Output max 300mA per pin for a total of 600 mA. This will be powered down during power-off or GLOBAL_EN being set low|
|89|WL_nDisable|A35 -- SDMMC1_PWREN/I2C4_SDA_M1/UART8_RTSn_M0/GPIO2_ B1_d|
|90|CORE1.8V (Output)|1.8V ± 2.5%. Power Output max 300mA per pin for a total of 600 mA. This will be powered down during power-off or GLOBAL_EN being set low|
|91|BT_nDisable|D38 -- I2S2_SCLK_RX_M0/UART6_RTSn_M0/SPI1_MOSI_M0/GPIO2_B7_d|
|92|RUN_PG|Reset pin after power on active low|
|93|nRPIBOOT|Low = LOADER ModeIf there is no burning system = MASKROM Mode Internally pulled up via 10kΩ to +3.3V|
|94|Reserved|NC|
|95|PI_LED_nPWR|Low = CPU Power supply is normal High or Blinking = CPU Pow er supply is abnormal|
|96|Reserved|NC|
|97|CamGPIO|Typically used to shut down the camera to reduce power Reassigning this pin to another function isn’t recommended CORE_3.3V sign alling|
|98|GND|Ground (0V)|
|99|GLOBAL_EN|Enable Signal for external high voltage BUCK|
|100|nEXTRST|Reset pin after power on active low|
|101|USB_OTG_ID|High = Device Mode Low = Host Mode|
|102|PCIe_CLK_nREQ|Input (3.3V signal) PCIe clock request pin (low to request PCI clock) Internally pulled up|
|103|USB_N|USB D-|
|104|Reserved|NC|
|105|USB_P|USB D+|
|106|Reserved|NC|
|107|GND|Ground (0V)|
|108|GND|Ground (0V)|
|109|PCIEnRST|Output (+3.3V signal) PCIe reset active-low|
|110|PCIe_CLK_P|PCIe clock Out positive (100MHz) NB AC coupling capacitor inclu ded on Core|
|111|Reserved|NC|
|112|PCIe_CLK_N|PCIe clock Out negative (100MHz) NB AC coupling capacitor inclu ded on Core|
|113|GND|Ground (0V)|
|114|GND|Ground (0V)|
|115|CAM1_D0_N|Input Camera1 D0 negative|
|116|PCIe_RX_P|Input PCIe GEN 2 RX positive NB external AC coupling capacitor r equired|
|117|CAM1_D0_P|Input Camera1 D0 positive|
|118|PCIe_RX_N|Input PCIe GEN2 RX negative NB external AC coupling capacitor re quired|
|119|GND|Ground (0V)|
|120|GND|Ground (0V)|
|121|CAM1_D1_N|Input Camera1 D1 negative|
|122|PCIe_TX_P|Output PCIe GEN2 TX positive NB AC coupling capacitor included on Core|
|123|CAM1_D1_P|Input Camera1 D1 positive|
|124|PCIe_TX_N|Output PCIe GEN 2 TX positive NB AC coupling capacitor included on Core|
|125|GND|Ground (0V)|
|126|GND|Ground (0V)|
|127|CAM1_C_N|Input Camera1 clock negative|
|128|CAM0_D0_N|Input Camera0 D0 negative|
|129|CAM1_C_P|Input Camera1 clock positive|
|130|CAM0_D0_P|Input Camera0 D0 positive|
|131|GND|Ground (0V)|
|132|GND|Ground (0V)|
|133|CAM1_D2_N|NC / Input Camera0 D0 negative|
|134|CAM0_D1_N|Input Camera0 D1 negative|
|135|CAM1_D2_P|NC / Input Camera0 D0 positive|
|136|CAM0_D1_P|Input Camera0 D1 positive|
|137|GND|Ground (0V)|
|138|GND|Ground (0V)|
|139|CAM1_D3_N|NC / Input Camera0 D1 negative|
|140|CAM0_C_N|Input Camera0 clock negative|
|141|CAM1_D3_P|NC / Input Camera0 D1 positive|
|142|CAM0_C_P|Input Camera0 clock positive|
|143|Reserved|NC|
|144|GND|Ground (0V)|
|145|Reserved|NC|
|146|Reserved|NC|
|147|Reserved|NC|
|148|Reserved|NC|
|149|Reserved|NC|
|150|GND|Ground (0V)|
|151|HDMI0_CEC|Input HDMI0 CEC. Internally pulled up with a 27kΩ. 3.3V tolerant.|
|152|Reserved|NC|
|153|HDMI0_HOTPLUG|Input HDMI0 hotplug. Internally pulled up 10kΩ. 3.3V tolerant.|
|154|Reserved|NC|
|155|GND|Ground (0V)|
|156|GND|Ground (0V)|
|157|DSI0_D0_N|Output Display0 D0 negative|
|158|Reserved|NC|
|159|DSI0_D0_P|Output Display0 D0 positive|
|160|Reserved|NC|
|161|GND|Ground (0V)|
|162|GND|Ground (0V)|
|163|DSI0_D1_N|Output Display0 D1 negative|
|164|Reserved|NC|
|165|DSI0_D1_P|Output Display0 D1 positive|
|166|Reserved|NC|
|167|GND|Ground (0V)|
|168|GND|Ground (0V)|
|169|DSI0_C_N|Output Display0 clock negative|
|170|HDMI0_TX2_P|Output HDMI0 TX2 positive|
|171|DSI0_C_P|Output Display0 clock positive|
|172|HDMI0_TX2_N|Output HDMI0 TX2 negative|
|173|GND|Ground (0V)|
|174|GND|Ground (0V)|
|175|DSI1_D0_N|Output Display1 D0 negative|
|176|HDMI0_TX1_P|Output HDMI0 TX1 positive|
|177|DSI1_D0_P|Output Display1 D0 positive|
|178|HDMI0_TX1_N|Output HDMI0 TX1 negative|
|179|GND|Ground (0V)|
|180|GND|Ground (0V)|
|181|DSI1_D1_N|Output Display1 D1 negative|
|182|HDMI0_TX0_P|Output HDMI0 TX0 positive|
|183|DSI1_D1_P|Output Display1 D1 positive|
|184|HDMI0_TX0_N|Output HDMI0 TX0 negative|
|185|GND|Ground (0V)|
|186|GND|Ground (0V)|
|187|DSI1_C_N|Output Display1 clock negative|
|188|HDMI0_CLK_P|Output HDMI0 clock positive|
|189|DSI1_C_P|Output Display1 clock positive|
|190|HDMI0_CLK_N|Output HDMI0 clock negative|
|191|GND|Ground (0V)|
|192|GND|Ground (0V)|
|193|DSI1_D2_N|Output Display1 D2 negative|
|194|DSI1_D3_N|Output Display1 D3 negative|
|195|DSI1_D2_P|Output Display1 D2 positive|
|196|DSI1_D3_P|Output Display1 D3 positive|
|197|GND|Ground (0V)|
|198|GND|Ground (0V)|
|199|HDMI0_SDA|Bidirectional HDMI0 SDA. Internally pulled up with a 1.8kΩ. 5V tolerant.|
|200|HDMI0_SCL|Bidirectional HDMI0 SCL. Internally pulled up with a 1.8kΩ. 5V tolerant.|

## RK3566
```
System         |           RK3566            |Connectivity
---------------+-----------------------------+------------------
Clock&Reset    |     CortexA55 QuadCore      |PCIe2.1/SATA3.0
WDT            |--Core0--     |--Core1--     |USB3.0HOST/SATA3.0
PLL x9         |32KB L1 ICache|32KB L1 ICache|USB2.0HOSTx2
Timer x6       |32KB L1 DCache|32KB L1 DCache|USB2.0 OTG
SecureTimer x2 |Neon/FPU/Crpto|Neon/FPU/Crpto|I2S/TDM(8ch)x2,one
PMU            |--Core2--     |--Core3--     |for HDMI
Crypto         |32KB L1 ICache|32KB L1 ICache|I2S/PCM(2ch) x2
InterruptCtrlr |32KB L1 DCache|32KB L1 DCache|PDM(8CH)
DMAC x2        |Neon/FPU/Crpto|Neon/FPU/Crpto|SPDIF(8ch)
SARADC x4      |-----------------------------|AudioPWM
TSADC          |        512KB L3Cache        |DigitalAcodec
MCU            |-----------------------------|VAD
Mailbox        |             NPU             |ISO7816
---------------|-----------------------------|UART x10
MultiMediaIface|    MultiMedia Processor     |SPI x4
===============|=============================|SDIO3.0
VOP(SameSource |4kVideoDecoder|GPUMaliG52-2EE|EthernetGMACx1
DualDisp)      |1080pVideoEnc |2dGfxEngine   |(10/100/1000M)
HDMI2.0a       |JPEG Codec    |IEP           |I2C x6
eDP1.3         |8M ISP        |              |PWM x16
SingleLVDS/    |--------------|--------------|GPIO x142
DualMIPI-DSI_TX|  External Memory Interface  |-----------------
EInkIface      |==============|==============|EmbedMem
16bitsCamIface |eMMC 5.1      |NorFlash/     |=================
MIPI-CSI_RX4Lan|              |AsyncSram     |SRAM(64KB)
               |SD3.0/MMC4.51 |SDR/DDR/LBA   |ROM(32KB)
               |              |Nand Flash    |OTP(8Kb)
               |    32bit DDR Controller     |
               |   DDR3/DDR3L/DDR4/LPDDR4/X  |
```

### ISP
Based on the driver code and known Rockchip ISP v5.0 architecture, here's the pipeline (from sensor to output):
```
# Linux-4
IMX219 (Bayer RAW)
    ↓ (MIPI CSI2)
CSI2 D-PHY (rockchip-csi2-dphy)
    ↓
RKISP-CSI-SUBDV (rkisp-csi-subdev) - CSI receiver
    ↓
RKISP-ISP-SUBDV (rkisp-isp-subdev) - ISP processing
    ├─→ Main Path (MP) - /dev/video0 - full resolution output (4416x3312 max)
    ├─→ Self Path (SP) - /dev/video1 - preview resolution (1920x1080 max)
    ├─→ DMA Path (DMATX) - raw dump before processing
    ├─→ Stats Path - AE/AWB/AF histograms to CPU
    └─→ Params Path - ISP configuration from CPU

# Linux-7
IMX219 (Bayer RAW 8MP)
    ↓ (MIPI CSI2 2-lane)
CSI2 D-PHY (fe870000)
    ↓
VICAP (fdfe0000) - video capture unit
    ├─ MIPI CSI2 receiver (4 DMA channels for VCs)
    └─ DVP parallel input
    ↓
ISP (fdff0000) - image signal processor
    ├─ CSI host (MIPI decoder)
    ├─ ISP subdev (format negotiation, crop)
    ├─ Main Path (MP) - full res output /dev/video0
    ├─ Self Path (SP) - preview res /dev/video1
    ├─ DMA write path (raw dump)
    ├─ Stats path (AE/AWB/AF histograms)
    └─ Params path (CPU→ISP config)
    ↓
Memory (DDR)
```

The ISP itself processes: demosaic → WDR → gamma → 3A statistics → color correction → sharpening → output formatting → DMA to memory

## Waveshare CM4-IO-BASE-B V2.0
- Fan header
```
                                           EMC2301 similar to EMC2305
4 control--------------------------5-|PWM5---GND4|-|:*
3|sense----------------------------6-|TACH6  VDD3|-|PWR_3V3
2|5v(RPiIObaseJ17is12v)---|CM4-5V    |CLK7    SCL|-|SCL0
1|GND-------------------|:*          |ALERT8--SDA|-|SDA0
Header4                                        U10
```
- Boot switch: When on, boots from USB-C else from eMMC or SD card.
- Core3566 GPIO Pinout (40-pin)
```
  #|   Opt2|   Opt1|Default|   Func1| Pin |Func1  |Default|Opt1    |Opt2   |#
---|-------|-------|-------|--------|--|--|-------|-------|--------|-------|---
   |      -|      -|      -|     3V3|01|02|5V     |-      |-       |-      |
108|      -|      -|GPIO3B4| I2C5SDA|03|04|5V     |-      |-       |-      |
107|      -|      -|GPIO3B3| I2C5SCL|05|06|GND    |-      |-       |-      |
111|PWM12M0|UART3TX|GPIO3B7|    GPIO|07|08|UART2TX|GPIO0D1|-       |-      |25
   |      -|      -|      -|     GND|09|10|UART2RX|GPIO0D0|-       |-      |24
104|      -|      -|GPIO3B0|    GPIO|11|12|GPIO   |GPIO4C6|SPI3CS0 |PWM13M1|150
116|PWM14M0|UART7TX|GPIO3C4|    GPIO|13|14|GND    |-      |-       |-      |
117|PWM15M0|UART7RX|GPIO3C5|    GPIO|15|16|GPIO   |GPIO3A1|-       |-      |47
   |      -|      -|      -|    3V3 |17|18|GPIO   |GPIO3A2|-       |-      |45
113|      -|      -|GPIO3C1|SPI1MOSI|19|20|GND    |-      |-       |-      |
114|      -|UART5TX|GPIO3C2|SPI1MISO|21|22|GPIO   |GPIO3A3|-       |-      |99
115|      -|UART5RX|GPIO3C3| SPI1CLK|23|24|SPI1CS0|GPIO3A4|-       |-      |100
   |      -|      -|      -|     GND|25|26|SPI1CS1|GPIO3A5|-       |-      |101
110|      -|      -|GPIO3B6| I2C3SDA|27|28|I2C3SCL|GPIO3B5|-       |-      |109
112|PWM13M0|UART3RX|GPIO3C0|    GPIO|29|30|GND    |-      |-       |-      |
148|      -|      -|GPIO4C4|    GPIO|31|32|GPIO   |GPIO3B2|UART4TX |PWM9   |106
105|   PWM8|UART4RX|GPIO3B1|    GPIO|33|34|GND    |-      |-       |-      |
149|PWM12M1|SPI3MIS|GPIO4C5|    GPIO|35|36|GPIO   |GPIO3A6|-       |-      |102
103|      -|      -|GPIO3A7|    GPIO|37|38|GPIO   |GPIO4C3|SPI3MOSI|PWM15M1|147
   |      -|      -|      -|     GND|39|40|GPIO   |GPIO4C2|SPI3CLK |PWM14M1|146
```
- GPIO has 5 banks, GPIO0 to GPIO4, and each bank has 32 pins, named as follows:
```
GPIO0_A0 ~ A7
GPIO0_B0 ~ B7
GPIO0_C0 ~ C7
GPIO0_D0 ~ D7

GPIO1_A0 ~ A7
....
GPIO1_D0 ~ D7
....
GPIO4_D0 ~ D7
```
- CM4H4A
```
SD-VDD-Override-R44/\/\/\--0R|:* -CM4-5V-c9-||-10uF-|:*

---------------1|GND                       GND|-2GND
----TRD3 P ----3|EthernetPair3P EthernetPair1P|-4TRD1P
----TRD3 N ----5|EthernetPair3N EthernetPair1N|-6TRD1N
---------------7|GND                       GND|-8GND
----TRD2 N ----9|EthernetPair2N EthernetPair0N|-10TRD0N
----TRD2 P ---11|EthernetPair2P EthernetPair0P|-12TRD0P
--------------13|GND                       GND|-14GND
----ETH LED G-15|EthernetnLED3  EthernetSYNCIN|-16ETHIN
----ETH LED Y-17|EthernetnLED2 EthernetSYNCOUT|-18ETHOUT
--------------19|EthernetnLED1       EEPROMnWP|-20EEPROMWP
----LED G ----21|PiNLedActivity            GND|-22GND
--------------23|GND                    GPIO26|-24GPIO26
----GPIO21 ---25|GPIO21                 GPIO19|-26GPIO19
----GPIO20 ---27|GPIO20                 GPIO13|-28GPIO13
----GPIO16 ---29|GPIO16                  GPIO6|-30GPIO6
----GPIO12 ---31|GPIO12                    GND|-32
--------------33|Gnd                     GPIO5|-34GPIO5
----ID_SCL ---35|IDSC                     IDSD|-36ID_SDA
----GPIO7 ----37|GPIO7                  GPIO11|-38GPIO11
----GPIO8 ----39|GPIO8                   GPIO9|-40GPIO9
----GPIO25 ---41|GPIO25                    GND|-42
--------------43|GND                    GPIO10|-44GPIO10
---GPIO24-----45|GPIO24                 GPIO22|-46GPIO22
---GPIO23 ----47|GPIO23                 GPIO27|-48GPIO27
----GPIO18 ---49|GPIO18                 GPIO17|-50GPIO17
----GPIO15----51|GPIO15                    GND|-52
--------------53|GND                     GPIO2|-54GPIO4
----GPIO14 ---55|GPIO14                  GPIO3|-56GPIO3
----SD_CLK----57|SDClk                   GPIO2|-58GPIO2
--------------59|Gnd                       GND|-60
----SD_DAT3---61|SD_DAT3                 SDCMD|-62SD_CMD
----SD_DAT0---63|SD_DAT0                SDDAT5|-64SD_DAT5
--------------65|Gnd                       GND|-66SD_DAT4
------SD_DAT1-67|SD_DAT1                SDDAT4|-68SD_DAT7
------SD_DAT2-69|SdDat2                 SDDAT7|-70SD_DAT6
--------------71|Gnd                    SDDAT6|-72
SDVDDOverride-73|SdVddOverride             GND|-74GND
SD PWREN -----75|SdPwrOn              Reserved|-76-
CM4_5V --+----77|+5vInput             GPIOVREF|-78GPIOVREF
---------+----79|+5vInput                 SCL0|-80SCL0
---------+----81|+5vInput                 SDA0|-82SDA0
---------+----83|+5vInput                3.3VO|-84CM43V3
---------+----85|+5vInput                3.3VO|-86CM41V8
---------+----87|+5vInput                1.8VO|-88CM41V8
WIFI_EN ------89|WiFi_nDisable           1.8VO|-90PIRUN
BT_EN --------91|BT_nDisable             RUNPG|-92IP0
PI BOOT ------93|nRPIBOOT            AnalogIP0|-94IP1
PI PWR LED ---95|PI_LED_nPWR         AnalogIP1|-96
CamGPIO ------97|CamGPIO(0_16)             GND|-98GND
PI GLOBAL EN--99|GlobalEN              nEXTRST|-10EXTRST
```
- CM4H4B
```
    USB0ID-101|USBOTGID    PCIECLKNREQ|102
     USB0N-103|USBN           Reserved|104
     USB0P-105|USBP           Reserved|106
           107|Gnd                 Gnd|108
  PCIEnRST-109|PCIEnRST       PCIeClkP|110
           111|VDAC_COMP      PCIeClkN|112
           113|Gnd                 Gnd|114
           115|Cam1D0N         PCIERxP|116
           117|Cam1D0P         PCIERxN|118
           119|Gnd                 Gnd|120
           121|Cam1D1N         PCIETxP|122
           123|Cam1D1P         PCIETxN|124
           125|Gnd                 Gnd|126
           127|Cam1CN          Cam0D0N|128
           129|Cam1CP          Cam0D0P|130
           131|Gnd                 Gnd|132
           133|Cam1D2N         Cam0D1N|134
           135|Cam1D2P         Cam0D1P|136
           137|Gnd                 Gnd|138
           139|Cam1D3N          Cam0CN|140
           141|Cam1D3P          Cam0CP|142
           143|HDMI1HotPlug        Gnd|144
           145|HDMI1SDA      HDMI1Tx2P|146
           147|HDMI1SCL      HDMI1Tx2N|148
           149|HDMI1CEC            Gnd|150
           151|HDMI0CEC      HDMI1Tx1P|152
           153|HDMI0HotPlug  HDMI1Tx1N|154
           155|Gnd                 Gnd|156
           157|DSI0D0N       HDMI1Tx1P|158
           159|DSI0D0P       HDMI1Tx1N|160
           161|Gnd                 Gnd|162
           163|DSI0D1N       HDMI1Tx1P|164
           165|DSI0DIP       HDMI1Tx1N|166
           167|Gnd                 Gnd|168
           169|DSI0CN        HDMI1Tx1P|170
           171|DSI0CP        HDMI1Tx1N|172
           173|Gnd                 Gnd|174
           175|DSI0CN        HDMI1Tx1P|176
           177|DSI0CP        HDMI1Tx1N|178
           179|Gnd                 Gnd|180
           181|DSI1D1N       HDMI1Tx1P|182
           183|DSI1D1P       HDMI1Tx1N|184
           185|Gnd                 Gnd|186
           187|DSI1CN        HDMI1Tx1P|188
           189|DSI1CP        HDMI1Tx1N|190
           191|Gnd                 Gnd|192
           193|DSI1D2N         DSI1D3N|194
           195|DSI1D2P         DSI1D3N|196
           197|Gnd                 Gnd|198
           199|HDMI0SDA       HDMI0SCL|200
```

- Y1
```
*:|-||-C1910pF--XI-1|-|[12Mhz]|+ |-4-|:*
*:|----------------2|          +-|-3-XO-||-C20-10pF--|:*
```

- TypeC Pinout
```
GND-------A12/B1------+
VBUS------A9/B4-------|---CM4_5V
CC2-------B5----------|--+/\/\/\R5-5.1K-IP1-+
SBU1------A8----------|                     |
DP2-------B6-USBBP--+ |                     |
DN1-------A7--------|-|-+                   +-|:*
DP1-------A6--------+ | |                   |
DN2-------B7-USBBN----|-+                   |
CC1-------A5----------|--/\/\/\R9-5.1K-IP0--+
SBU2------B8          |
VBUS------A4/B9-------|---------+---CM4_5V
GND-------A1/B12------+         |
GND-------MTB---------+--|:*    +--||-10uFC14-|:*
```

- U1 FE1_1S USB2 hub(4portCapable) providing the 2 usb ports
```
                                           +-|Hub1.8V
                                           |
                  *:|---1|VSS----VD18|28---+-C10-||-10uF-+
                 ----XO-2|XOUT  TESTJ|27-  +-C11-||-104--+-|:*
                 ----XI-3|XIN    OVCJ|26--|Hub3.3V
              U4N------ 4|DM4    PWRJ|25
              U4P------ 5|DP4    LED2|24
              U3N------ 6|DM3    LED1|23
              U3P------ 7|DP3     DRV|22-DRV
              U2N------ 8|DM2  VD33_0|21-|HUB_3.3V
              U2P------ 9|DP2    VDD5|20-|CM4_5V
              U1N------10|DM1    BUSJ|19-www-100K-R08-+
              U1P------11|DP1   VBUSM|18-www-100K-R10-+-|Hub3.3V
             Hub1.8V|--12|VD180 XRSTJ|17-www-100K-R11-+
       Hub3.3V|----+---13|VD33    DPU|16-USBD0P--
 *:|-R12-2.7K-www--|---14|REXT----DMU|15-USBD0n--
                   |
                   +---+
                   |   |
                  C18 C17
                   |   |
               10uF=   =104
                   |   |
                   +---+--|:*
```

- USB Host2
```
           GndUSB-|Gnd------Gnd|-GndUSB   +--|CM4_5V
CM4_5V|--+---Pwr2-|VBus   VBus2|-Pwr1-----+--||-C16-10uF/10V-|:*
         |    U2N-|Data- Data2-|-U1N
         =    U2P-|Data+ Data2+|-U1P
         +--|:*:|-|Gnd      Gnd|-|:*
           GndUSB-|Gnd------Gnd|-GndUSB

```
- FSUSB42UMX U3
```
                 CMC4
          *:|-104-||-+-|3V3
           ----------+-9|VCC-HSD2-|6-USBD0N
              ---USB0N-2|D-  HSD2+|7-USBD0P
              ---USB0P-1|D+       |
3V3|-R15-47K-www-+----10|Sel      |
        PI_BOOT--+   +-8|OE  HSD1-|4-USBBN
                 *:|-+-3|Gnd-HSD1+|5-USBBP

USB0ID-R17-www-0R/NC--|:*
PI_BOOT-R18-www-0R/NC-|:*
```
- CSI Dual cameras
  - SCL0 is i2c1 and confirmed CAM0. should confirm CAM1_CLK_P belongs to CAM0
```
PWR_3V3-------CSI_3.3V
									 right
                          +-|GND                                 +-|GND
               CAM1_D0_N--|-|D0_N                     CAM0_D0_N--|-|D0_N
               CAM1_DO_P--|-|D0_P                     CAM0_DO_P--|-|D0_P
                          +-|GND                                 +-|GND
               CAM1_D1_N--|-|D1_N                     CAM0_D1_N--|-|D1_N
               CAM1_D1_P--|-|D1_P                     CAM0_D1_P--|-|D1_P
                          +-|GND                                 +-|GND
               CAM1_CLK_N |-|CLK_N                    CAM0_CLK_N |-|CLK_N
GPIO_VREF      CAM1_CLK_P |-|CLK_P     GPIO_VREF      CAM0_CLK_P |-|CLK_P
 +                        +-|GND        +                        +-|GND
 |              CamGPIO---|-|PWDN       |              CamGPIO---|-|PWDN
 |  CM-R1               --|-|MCLK       |  CM-R1               --|-|MCLK
 +--/\/\/-4.7K-SCL0-+-----|-|SCL        +--/\/\/-4.7K-ID_SCL-+---|-|SCL
 +--/\/\/-4.7K-SDA0-+-----|-|SDA        +--/\/\/-4.7K-ID_SDA-+---|-|SDA
    CM-R4      CSI_3.3V +-|-|VDD     CM-R4            CSI_3.3V-+-|-|VDD
                        | | left                                 | |
              C87 0.1UF = |                             C1 0.1UF = |
                        | |                                      | |
                        +-+-|:*                                  +-+-|:*
CAM0                                   CAM1
```

- RTC battery: CR1220
```
 +-||-C35-22pF--+--+   -U4 PCF85063ATL-    +---||-C134--|:*
 |       32.768K=  +-1-|OSCI------ VDD|-10-+--+-D5-K|--PWR_3
 +-||-C36-22pF--+----2-|OSCO    CLKOUT|-9-    +-D6-K|---+---|:-|:-BAT1--+
 |               O---3-|CLKOE       NC|-8-      B5819WS +-||-C133-4.7uF-+-|:*
 |           RTC_INT-4-|INT        SCL|-7-SCL0-
 +--------------+----5-|VSS----+---SDA|-6-SDA0-
							   |
							   +-11-|:*

               -RTC_INT-+
PWR_3V3-+ +-510K-/\/\/\-+
 *:|-||-+-+    C38-100Nf= 1-|NC-VCC|-5-PWR_3V3
C37-100Nf +-510K-/\/\/\-+-2-|A     |
                        *:|-|GND--Y|-4-+-R36-/\/\/-0R/NCP1_GLOBAL_EN
						               +-R37-/\/\/-0R-P1_RUN-
									   +-R39-/\/\/-0R/NC-P7-RTC_INT
```

- M.2 KEY E
```
M.2_3.3V|------|PWR_3V3
3.3V|--/\/\/-R6-1K--LED1->^|--|:*

           +-77|77            |KEY_M_1
           +--1|GND       3.3V|2-3.3V--
           +--3|GND       3.3V|2-3.3V--
           |--5|PETn3     3.3V|4-3.3V--
           |--7|PETp3       NC|6-
           +--9|GND         NC|8-
           | 11|PERn3    LED1#|10-LED1--
           | 13|PERp3     3.3V|12-3.3V--
           +-15|GND       3.3V|14-3.3V--
           |-17|PETn2     3.3V|16-3.3V--
           |-19|PETp2     3.3V|18-3.3V--
           +-21|GND         NC|20--
           |-23|PERn2       NC|22--
           |-25|PERp2       NC|24--
           +-27|GND         NC|26--
           |-29|PETn1       NC|28--
           |-31|PETp1       NC|30
           +-33|GND         NC|32
           |-35|PERn1       NC|34
           |-37|PERp1       NC|36
           +-39|GND         NC|38
 PCIE_RX_N-|-41|PETn0    SMCLK|40
 PCIE_RX_P-|-43|PETp0    SNDAT|42
           | 45|GND      ALERT|44
 PCIE_TX_N-|-47|PERn0       NC|46
 PCIE_TX_N-|-49|PERp0       NC|48
           +-51|GND     PREST#|50-PCIEnRST--
PCIE_CLK_N-|-53|REFCLK CLKREQ#|52
PCIE_CLK_N-|-55|REFCLK PEWAKE#|54
           | 57|GND         NC|56
           |   |            NC|58
           |   |              |
           |   |              |
           |   |              |
           | 67|NC            |
           +-69|PEDET   SUSCLK|68-3.3V--
           +-71|GND       3.3V|70-3.3V--
           +-73|GND       3.3V|72-3.3V--
           +-75|GND       3.3V|74
      *:|--+-76|66            |


```

## 52Pi New Ice Tower Cooler EP-0107
- 3pin; black: gnd, red: 12/5v, blue: pwm control
- no tach

## OV5647

### Working Configuration (from RPi3B)

The OV5647 camera module works in **MIPI CSI-2 mode** (not DVP). Key findings from RPi3B analysis:

**Sensor Properties:**
```
compatible = "ovti,ov5647"
reg = <0x36>
```

**Clock:**
```
clock-frequency = <25000000>  (25MHz, fixed-clock)
```

**CSI Endpoint (MIPI CSI-2 mode):**
```
data-lanes = <1 2>           (2 lanes)
clock-lanes = <0>            (clock on lane 0)
clock-noncontinuous
link-frequencies = /bits/ 64 <297000000>  (297MHz)
```

**Power Supplies (3 required):**
| Supply | Description | Typical Voltage |
|--------|-------------|-----------------|
| avdd-supply | Analog | 2.8V |
| dovdd-supply | Digital I/O | 1.8V |
| dvdd-supply | Digital Core | 1.2V |

**Regulator Settings:**
```
startup-delay-us = <20000>  (20ms delay after enable)
enable-active-high
```

**I2C Bus:** i2c0mux/i2c@1 (camera I2C bus via mux)
**CSI:** csi@7e801000 (unicam)

- `rpicam-jpeg -o test.jpg --nopreview` - **WORKS**
- `vcgencmd get_camera` shows detected
- I2C address 0x36 responds when driver loaded
- Raspbian ov5647 overlay: `arch/arm/boot/dts/overlays/ov5647-overlay.dts`
- Raspbian ov5647 dtsi: `arch/arm/boot/dts/overlays/ov5647.dtsi`

### References


--
HalfBloodPrince
