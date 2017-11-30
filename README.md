# OSDBackground-JIT
Re-configures OSDBackground just before Execution wihin the task sequences so that it's messages are built on the Group Headers.
Will be looking into creating another script to evaluate the message that should be displayed on the fly while the task sewuence is running.

Requires tsenv2.exe as I hate Powershell on WinPEx64

# ConfigMgr-Client-Health-Hacks
This Code does not belong to me, I just really needed to add some features and keep track of them all. Hope to convert the real Author to Github https://gallery.technet.microsoft.com/ConfigMgr-Client-Health-ccd00bd7

# Todo or To Cleanup:
* Get Better at Github!

* Look into writing a better log function that can also be configured by config xml to be cmtrace compatible or a "legacy" log.

* Create support for simple rest api so that we can avoid the SQL statements.

* Maybe add Conditional release of configuration settings from XML based on host parameters/registry/wmi/wql.

* Really stop hacking on stuff and actually produce code I like.
