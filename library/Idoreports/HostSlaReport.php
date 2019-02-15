<?php
// Icinga IDO Reports | (c) 2018 Icinga GmbH | GPLv2

namespace Icinga\Module\Idoreports;

use Icinga\Module\Reporting\Timerange;
use ipl\Html\Form;
use ipl\Html\Html;

class HostSlaReport extends IdoReport
{
    public function getName()
    {
        return 'Host SLA';
    }

    public function getHtml(Timerange $timerange, array $config = null)
    {
        $data = $this->fetchSla($timerange, $config);

        if (empty($data)) {
            return Html::tag('p', 'No data found.');
        }

        \reset($data);

        $tableHeaderCells = [];

        foreach (\array_keys(\current($data)) as $header) {
            $tableHeaderCells[] = Html::tag('th', null, $header);
        }

        $tableRows = [];

        foreach ($data as $row) {
            $hostname = $row['Hostname'];

            unset($row['Hostname']);

            $cells = [Html::tag('td', null, $hostname)];

            foreach ($row as $sla) {
                if ($sla < 99.5) {
                    $slaClass = 'nok';
                } else {
                    $slaClass = 'ok';
                }

                $cells[] = Html::tag('td', ['class' => "sla-column $slaClass"], $sla);
            }

            $tableRows[] = Html::tag('tr', null, $cells);
        }

        $table = Html::tag(
            'table',
            ['class' => 'common-table sla-table'],
            [
                Html::tag(
                    'thead',
                    null,
                    Html::tag(
                        'tr',
                        null,
                        $tableHeaderCells
                    )
                ),
                Html::tag('tbody', null, $tableRows)
            ]
        );

        return $table;
    }

    public function getCsvData(Timerange $timerange, array $config = null)
    {
        $data = $this->fetchSla($timerange, $config);

        if (! empty($data)) {
            \reset($data);

            $header = \array_keys(\current($data));

            \array_unshift($data, $header);
        }

        return $data;
    }

    public function getJsonData(Timerange $timerange, array $config = null)
    {
        return \array_values($this->fetchSla($timerange, $config));
    }

    public function initConfigForm(Form $form)
    {
        $form->addElement('text', 'filter', [
            'label' => 'Filter'
        ]);

        $form->addElement('select', 'breakdown', [
            'label' => 'Breakdown',
            'options' => [
                'none' => 'None',
                'day' => 'Day',
                'week' => 'Week',
                'month' => 'Month'
            ]
        ]);
    }

    protected function fetchSla(Timerange $timerange, array $config = null)
    {
        $data = [];

        if (isset($config['breakdown']) && $config['breakdown'] !== 'none') {
            $start = clone $timerange->getStart();
            $end = clone $timerange->getEnd();

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

            $end->add($interval);

            $period = new \DatePeriod($start, $interval ,$end, \DatePeriod::EXCLUDE_START_DATE);

            $objectAvg = [];
            $periodAvg = [];

            foreach ($period as $date) {
                foreach ($this->fetchHostSla(new Timerange($start, $date), $config) as $row) {
                    $data[$row->host_display_name][$date->format($format)] = \round((float) $row->sla, 2);
                    $objectAvg[$row->host_display_name][]= (float) $row->sla;
                    $periodAvg[$date->format($format)][] = (float) $row->sla;
                }

                $start = $date;
            }

            foreach ($data as $hostname => &$row) {
                $row = ['Hostname' => $hostname] + $row;
                $row['Average'] = \round(\array_sum($objectAvg[$hostname]) / \count($objectAvg[$hostname]), 2);
                $periodAvg['Average'][] = \round(\array_sum($objectAvg[$hostname]) / \count($objectAvg[$hostname]), 2);
            }

            if (! empty($periodAvg)) {
                foreach ($periodAvg as $period => &$avg) {
                    $avg = \round(\array_sum($avg) / \count($avg), 2);
                }
                $data[] = ['Hostname' => null] + $periodAvg;
            }
        } else {
            $avg = [];
            foreach ($this->fetchHostSla($timerange, $config) as $row) {
                $data[] = [
                    'Hostname' => $row->host_display_name,
                    'SLA in %' => \round((float) $row->sla, 2)
                ];
                $avg[] = (float)$row->sla;
            }
            if (! empty($avg)) {
                $data[] = [
                    'Hostname' => null,
                    'SLA in %' => \round(\array_sum($avg) / \count($avg), 2)
                ];
            }
        }

        return $data;
    }
}
