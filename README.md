# Verify system requirements 

## Introduction

You can use the Linux bash script to check compliance with the system requirements for the one Versio.io managed instance before installation. 

Please make sure that all red marked hints are removed before installation. For the yellow notifications, you should be sure that you have the expertise to solve the problem yourself.

## Execution

Execute the following commands to download and execute the script as root user:

```
curl https://raw.githubusercontent.com/versio-io/check-versio.io-system-requirements/main/check-versio.io-system-requirements.sh -o check-versio.io-system-requirements.sh

sudo bash check-versio.io-system-requirements.sh 
```

Enclosed you will find two examples of how such a verification was successfully or unsuccessfully executed. It's that simple!

![Script execution example](img/exceution-example.gif)
