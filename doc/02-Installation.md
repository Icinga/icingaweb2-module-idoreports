# <a id="Installation"></a>Installation

## Requirements

* Icinga Web 2 (&gt;= 2.6)
* PHP (&gt;= 5.6, preferably 7.x)
* MySQL or MariaDB
* Icinga Web 2 modules:
  * [reporting](https://github.com/Icinga/icingaweb2-module-reporting) (>= 0.9)

## Database Setup

The module ships with database functions for calculating the host and service availability in `etc/schema/`.

Please import those files into your Icinga database.

The following example assumes that your Icinga database and user is named **icinga2**:

```
mysql -p -u icinga2 icinga2 < schema/slaperiods.sql
mysql -p -u icinga2 icinga2 < schema/get_sla_ok_percent.sql
```

## Installation

1. Just drop this module to a `idoreports` subfolder in your Icinga Web 2 module path.

2. Log in with a privileged user in Icinga Web 2 and enable the module in `Configuration -> Modules -> idoreports`.
Or use the `icingacli` and run `icingacli module enable idoreports`.

This concludes the installation. You should now be able to create host and service availability reports.
