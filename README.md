# Garmin Uploader and Polar Converter

Garmin's software sucks, so I wrote a script. Also use other software to convert FIT data to HRM and pops open a Polar uploader


## Installation
[Download GcpUploader]

unzip GcpUploader to /opt/pygupload

create a symbolic link, sudo ln -s /opt/pygupload/gupload.py /usr/local/bin/gupload.py

cd into /opt/pygupload and run `setup.py install`





## Usage
* Run `upload.bash` located in the projects root directory

Alternatively, you can setup a [launchd command to help]






## Thanks
* Dave Lotton - [Garmin Uploader]
* erlendleganger - [FIT to HRM conversion]
* 1ka - [Polar Uploader]





[launchd command to help]:http://alvinalexander.com/mac-os-x/launchd-examples-launchd-plist-file-examples-mac
[Garmin Uploader]:http://sourceforge.net/p/gcpuploader/wiki/Home/
[FIT to HRM conversion]:https://github.com/erlendleganger/g2p
[Polar Uploader]:https://github.com/1ka/HRMUploader
[Download GcpUploader]:https://pypi.python.org/pypi?:action=display&name=GcpUploader