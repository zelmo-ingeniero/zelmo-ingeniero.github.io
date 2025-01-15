
# My Windows 11 Home Configuration

## First steps

- Install Nvidia studio driver WHQL (GeForce is installed, because is required by OBS)
- Driver "BT dongle dual-band mini adapter BT AC600 to Windows 10" (after install, when plug will appear the autoinstall prompt)
- Activate windows with this commands:

```powershell
slmgr.vbs /dli
slmgr.vbs /upk
slmgr.vbs /cpky
slmgr.vbs /ipk TX9XD-98N7V-6WMQ6-BX7FG-H8Q99
slmgr.vbs /skms kms8.msguides.com
slmgr.vbs /ato
```

### Windows 11 settings

(After installing software more configurations will be done)

- Set hostname
- Check for updates and then update the system
- System -> Storage -> Storage sense -> 
  - Run every week
  - delete files in downloads every 14 days
- System -> Notifications -> Turn on all
- System -> Notifications -> Aditional settings -> Turn off all
- Power -> Screen and sleep -> 
  - Turn off screeen every 3 minutes
  - Sleep never
- Nearby sharing -> Set turn off
- Personalization -> Backgrounds -> Set your favourite backgrounds
- Personalization -> Colors -> 
  - Theme dark
  - Transparencies should be turn off
  - Set your favourite accent color
- Personalization -> Lock screen -> 
  - Set picture without tips
  - Turn off background to sign-in
- Personalization -> Start -> 
  - More pins
  - Turn on only "show recently added apps"
  - Add folders: Settings and File explorer
- Personalization -> Task Bar -> 
  - Search box hide
  - Turn off all
  - Taskbar behaviors -> Turn on just ->
    - Show badges on taskbar apps
    - Show flashing
    - Show the far corner of the taskbar to show the desktop
- Personalization -> Device usage -> Turn off
- Gaming -> Game bar -> Turn off
- Gaming -> Game  -> Turn off
- Gaming -> Game mode -> Turn off
- Accessibility -> 
  - Always show scrollbars
  - Turn off aminations
- Privacy & security -> Find my device -> Turn off (because is a desktop computer)
- Privacy & security -> General -> Turn off all
- System -> About -> Advanced system settings -> Advanced -> Performance -> Visual effects -> 
  - Adjust for best performance ->
  - Smooth edges of screen fonts
- System -> Display -> Night mode -> Stablish at 70% (change this for your needs)
- Network & Internet -> DNS manual -> Edit -> DNS Servers
  - 8.8.8.8
  - 8.8.4.4 (This is becasue I sometimes have DNS problems)
- Privacy & Security -> Device security -> Memory integrity On
- Privacy & Security -> App & browser control On
- Privacy & Security -> Firewall and network protection -> Advanced settings ->
  - On the principal "Windows Defender Firewall with Advanced Security on Local Computer" title right click -> Properties -> In Domain profile, public profile, and private profile -> 
    - Customize logging settings -> 
      - Enable Log dropped packets
      - Set max size to log file
- Windows update -> Advanced options -> Delivery optimization -> 
  - Not allow downloads
  - Advanced options: Set minimum limits of percentage

## install software:

Web applications for Windows commonly are low performance and hard to configure later (Whatsapp for windows, Youtube for windows and so on), then is better to use just the web pages in the browser

All installations will be in the disk system or `C://`

- Powershell 7 installed from the Microsoft Store (Windows 11 by defaults has 4)
- Git to have gitbash (configure it for your needs, in my case I use Git without the credential manager)
- MobaXterm
- AWS CLI (optional, I prefer use this tools inside the server or in some Linnux VM)
- AZ CLI (optional, I prefer use this tools inside the server or in some Linnux VM)
- VMWare
- Office pro 2024 public preview 
  - Download the "office deployment tool"
  - Run the "office deployment tool" to create a `configuration.xml` and `setup.exe` files
  - Edit the `configuration.xml` file
  - Run the comand `setup.exe /configure configuration.xml` in the path where is the `setup.exe` file
- OBS Studio, just recording my system audio and video
- Lightshot to take screenshots
- Azure VPN Client

Web Browsers:
- Windows has Edge by default and is a good browser but by privacy reasons it not should be used to work or personal use, can be used to test web certificates, URLs, endpoints or frontends. It also has an excellent PDF editor
- Libre Wolf (or whatever else you prefer) is my default browser to work and personal use. The privacy is good, all the videos have a floating tab option and the screenshot tool is excelent. But is not enough to me by the next reasons:
  - Some addonds are not available
  - By default you can not view other people's screens in Microsoft Teams
- Brave is a secondary browser I use to work, more specifically is always open with management websites as Slack, Teams, Google Calendar and so on. Disadvantages:
  - It has too extra funcionalities (for cryptos and a reward system)
  - The tabs are difficult to separate through different windows
- I have installed Google Chrome and eventually use it to test web certificates, URLs, endpoints or frontends by privacy reasons it not should be used to work or personal use

## Regularly do this in Windows settings

I do this when I have nothing else to do or everytime a new important software is installed

- System -> Notifications -> The new application -> Play a sownd when a notification arrives -> Turn Off
- In the Task Manager -> Startup apps -> disable all
- System -> Storage -> Storage used on other devices -> Temporary files -> Sellect all 

### in white TPLink

LAN type: Static IP
IP Address: 192.168.0.2
Subnet mask: 255.255.255.0
Network gateway: 192.168.0.1
Mode: Access point
SSID: (what you prefer)
Mode: 11bgn  mixto
WPS: disabled
Security version: WPA2-PSK
Encryption: AES
Password: changeit
MAC filtering: disabled
Guest network: disabled
DHCP: disabled
Timezone: GMT-06:00
Summer schedule: disabled

## Some temp fixes

Powershell commands to avoid internet (ethernet / wifi) connection

```powershell
ipconfig /flushdns
ipconfig /renew
ipconfig /registerdns
netsh int ip reset
netsh winsock reset
```

