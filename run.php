<?php

namespace Icinga\Module\Idoreports {

    use Icinga\Application\Icinga;

    /** @var \Icinga\Application\Modules\Module $this */

    $this->provideHook('reporting/Report', '\\Icinga\\Module\\Idoreports\\HostSlaReport');
    $this->provideHook('reporting/Report', '\\Icinga\\Module\\Idoreports\\ServiceSlaReport');
}
