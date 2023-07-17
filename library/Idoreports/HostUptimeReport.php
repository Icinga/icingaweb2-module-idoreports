<?php
// Icinga IDO Reports | (c) 2018 Icinga GmbH | GPLv2

namespace Icinga\Module\Idoreports;

use Icinga\Module\Reporting\ReportData;
use Icinga\Module\Reporting\ReportRow;
use Icinga\Module\Reporting\Timerange;
use ipl\Html\Form;

class HostUptimeReport extends IdoReport
{
    public function getName()
    {
        return 'Host Outage';
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

    private function secondsToString($seconds) {
	$y = floor($seconds / 31536000);
	$d = floor(($seconds % 31536000) / 86400); 
	$h = floor((($seconds % 31536000) % 86400) / 3600);
	$i = floor(((($seconds % 31536000) % 86400) % 3600) / 60);
	$s = ((($seconds % 31536000) % 86400) % 3600) % 60;
	if ( $y > 0 ) return $y . " y " .  $d . " d " . $h . " h " . $i . " m " . $s . " s";
	if ( $d > 0 ) return $d . " d " . $h . " h " . $i . " m " . $s . " s";
	if ( $h > 0 ) return $h . " h " . $i . " m " . $s . " s";
	if ( $i > 0 ) return $i . " m " . $s . " s";
	if ( $s > 0 ) return $s . " s";
    }

    protected function fetchHostUptime(Timerange $timerange, array $config)
    {
        $sla = $this->getBackend()->select()->from('hoststatus', ['host_display_name'])->order('host_display_name');

        $this->applyFilterAndRestrictions($config['filter'] ?: '*', $sla);

        /** @var \Zend_Db_Select $select */
        $select = $sla->getQuery()->getSelectQuery();

        $columns = $sla->getQuery()->getColumns();
        $columns['outage'] = new \Zend_Db_Expr(\sprintf(
            "idoreports_get_outage(%s, '%s', '%s', NULL)",
            'ho.object_id',
            $timerange->getStart()->format('Y-m-d H:i:s'),
            $timerange->getEnd()->format('Y-m-d H:i:s')
	));

        $select->columns($columns);

        return $this->getBackend()->getResource()->getDbAdapter()->query($select);
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

    protected function fetchUptime(Timerange $timerange, array $config = null)
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
                ->setValues(['Outage']);

            $rows = [];

            foreach ($this->yieldTimerange($timerange, $interval) as list($start, $end)) {
		    foreach ($this->fetchHostUptime(new Timerange($start, $end), $config) as $row) {
			    //var_dump($row);
                    $rows[] = (new ReportRow())
                        ->setDimensions([$row->host_display_name, $start->format($format)])
                        ->setValues([$this->secondsToString((int) $row->outage)]);
                }
            }

            $rd->setRows($rows);
        } else {
            $rd
                ->setDimensions(['Hostname'])
                ->setValues(['Outage']);

            $rows = [];

            foreach ($this->fetchHostUptime($timerange, $config) as $row) {
                $rows[] = (new ReportRow())
                    ->setDimensions([$row->host_display_name])
                    ->setValues([(int) $row->outage]);
            }

            $rd->setRows($rows);
        }

        return $rd;
    }
}
