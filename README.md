# Garmin Uploader and Polar Converter

Garmin's software sucks, so I wrote a script that interfaces with other developers' software. Does everything Garmin software does but more!


## Installation
* [Download GcpUploader]
* unzip GcpUploader to /opt/pygupload
* create a symbolic link, sudo ln -s /opt/pygupload/gupload.py /usr/local/bin/gupload.py
* cd into /opt/pygupload and run `sudo setup.py install`
* Git clone this repo into whatever directory you want


## Usage
* Create a .guploadrc file in your cloned repo directory, with your garmin credentials laid out like this:

```java
[Credentials]
username=<username>
password=<password>
```
** Note: This is stored in plaintext...so anyone with access to your filesystem can see it, maybe set read perms on the file if you want to keep nosy people out

* Run `upload.bash` located in the projects root directory
**Alternatively, you can setup a [launchd command to help]

* Once this runs, you'll see in your terminal that your data is uploaded to Garmin. After this, it will convert your data over to .hrm files. A client will pop up, asking you to log into your Polar account. Log in, and browse the contents of your computer. Your HRM data should be inside GarminPolarUploader/hrm. Once they're uploaded, a checkbox will appear next to it, indicating that its been uploaded.

## Configuration
Default configuration supports Garmin FR 620, and Garmin Edge 800, scanning as far back as 1 full day (24 hours) of activity. If you'd like to add more devices, or change how far back to scan, feel free to alter these properties in the .settings file in the root dir of this project.



## Thanks
* Dave Lotton - [Garmin Uploader]
* erlendleganger - [FIT to HRM conversion]
* 1ka - [Polar Uploader]





[launchd command to help]:http://alvinalexander.com/mac-os-x/launchd-examples-launchd-plist-file-examples-mac
[Garmin Uploader]:http://sourceforge.net/p/gcpuploader/wiki/Home/
[FIT to HRM conversion]:https://github.com/erlendleganger/g2p
[Polar Uploader]:https://github.com/1ka/HRMUploader
[Download GcpUploader]:https://pypi.python.org/pypi?:action=display&name=GcpUploader
