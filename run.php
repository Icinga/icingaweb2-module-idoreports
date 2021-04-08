<?php

// Icinga IDO Reports | (c) 2018 Icinga GmbH | GPLv2

namespace Icinga\Module\Idoreports {

    use Icinga\Application\Icinga;

    /** @var \Icinga\Application\Modules\Module $this */

    $this->provideHook('reporting/Report', '\\Icinga\\Module\\Idoreports\\HostSlaReport');
    $this->provideHook('reporting/Report', '\\Icinga\\Module\\Idoreports\\ServiceSlaReport');
}
