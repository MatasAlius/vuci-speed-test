# vuci-speed-test
Vuci internet speed test using Lua and Curl.<br />
#### Speed test process steps:
* System downloads speedtest server list.
* User selects best server or chooses server from downloaded list.
* Best server selected by filtering server list by user country and then doing latency tests. Server with lowest latency becomes best server.<br />System uses ipwhois.app api to find user's location.
* User begins speed test by pressing Start button.

#### Main page:
![Main window](./Main.png)
#### Server list window:
![Server list window](./List.png)