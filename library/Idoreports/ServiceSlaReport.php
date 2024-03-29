<?php

// Icinga IDO Reports | (c) 2018 Icinga GmbH | GPLv2

namespace Icinga\Module\Idoreports;

use Icinga\Module\Reporting\ReportData;
use Icinga\Module\Reporting\ReportRow;
use Icinga\Module\Reporting\Timerange;
use ipl\Html\Form;

class ServiceSlaReport extends IdoReport
{
    public function getName()
    {
        return 'Service SLA';
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
                    $boundary = false;
                    break;
                case 'week':
                    $interval = new \DateInterval('P1W');
                    $format = 'Y-\WW';
                    $boundary = 'monday next week midnight';
                    break;
                case 'month':
                    $interval = new \DateInterval('P1M');
                    $format = 'Y-m';
                    $boundary = 'first day of next month midnight';
                    break;
            }

            $rd
                ->setDimensions(['Hostname', 'Service Name', ucfirst($config['breakdown'])])
                ->setValues(['SLA in %']);

            $rows = [];

            foreach ($this->yieldTimerange($timerange, $interval, $boundary) as list($start, $end)) {
                foreach ($this->fetchServiceSla(new Timerange($start, $end), $config) as $row) {
                    if ($row->sla === null) {
                        continue;
                    }

                    $rows[] = (new ReportRow())
                        ->setDimensions([$row->host_display_name, $row->service_display_name, $start->format($format)])
                        ->setValues([(float) $row->sla]);
                }
            }

            $rd->setRows($rows);
        } else {
            $rd
                ->setDimensions(['Hostname', 'Service Name'])
                ->setValues(['SLA in %']);

            $rows = [];

            foreach ($this->fetchServiceSla($timerange, $config) as $row) {
                $rows[] = (new ReportRow())
                    ->setDimensions([$row->host_display_name, $row->service_display_name])
                    ->setValues([(float) $row->sla]);
            }

            $rd->setRows($rows);
        }

        return $rd;
    }
}
