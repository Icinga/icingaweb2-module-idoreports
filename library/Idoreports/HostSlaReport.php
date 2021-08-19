<?php

// Icinga IDO Reports | (c) 2018 Icinga GmbH | GPLv2

namespace Icinga\Module\Idoreports;

use Icinga\Module\Reporting\ReportData;
use Icinga\Module\Reporting\ReportRow;
use Icinga\Module\Reporting\Timerange;
use ipl\Html\Form;

class HostSlaReport extends IdoReport
{
    public function getName()
    {
        return 'Host SLA';
    }

    public function initConfigForm(Form $form)
    {
        $form->addElement('text', 'filter', [
            'label' => 'Filter'
        ]);

        $form->addElement('select', 'breakdown', [
            'label'   => 'Breakdown',
            'options' => [
                'none'  => 'None',
                'day'   => 'Day',
                'week'  => 'Week',
                'month' => 'Month'
            ]
        ]);

        $form->addElement('number', 'threshold', [
            'label'       => 'Threshold',
            'placeholder' => '99.5',
            'step'        => '0.01',
            'min'         => '1',
            'max'         => '100'
        ]);
    }

    protected function fetchSla(Timerange $timerange, array $config = null)
    {
        $rd = new ReportData();

        if (isset($config['breakdown']) && $config['breakdown'] !== 'none') {
            switch ($config['breakdown']) {
                case 'day':
                    $interval = new \DateInterval('P1D');
                    $format = 'Y-m-d';
                    break;
                case 'week':
                    $interval = new \DateInterval('P1W');
                    $format = 'Y-\WW';
                    break;
                case 'month':
                    $interval = new \DateInterval('P1M');
                    $format = 'Y-m';
                    break;
            }

            $rd
                ->setDimensions(['Hostname', ucfirst($config['breakdown'])])
                ->setValues(['SLA in %']);

            $rows = [];

            foreach ($this->yieldTimerange($timerange, $interval) as list($start, $end)) {
                foreach ($this->fetchHostSla(new Timerange($start, $end), $config) as $row) {
                    if ($row->sla === null) {
                        continue;
                    }

                    $rows[] = (new ReportRow())
                        ->setDimensions([$row->host_display_name, $start->format($format)])
                        ->setValues([(float) $row->sla]);
                }
            }

            $rd->setRows($rows);
        } else {
            $rd
                ->setDimensions(['Hostname'])
                ->setValues(['SLA in %']);

            $rows = [];

            foreach ($this->fetchHostSla($timerange, $config) as $row) {
                $rows[] = (new ReportRow())
                    ->setDimensions([$row->host_display_name])
                    ->setValues([(float) $row->sla]);
            }

            $rd->setRows($rows);
        }

        return $rd;
    }
}
