<?php
// Icinga IDO Reports | (c) 2018 Icinga GmbH | GPLv2

namespace Icinga\Module\Idoreports;

use Icinga\Data\Filter\Filter;
use Icinga\Data\Filterable;
use Icinga\Exception\ConfigurationError;
use Icinga\Module\Monitoring\Backend\MonitoringBackend;
use Icinga\Module\Reporting\Hook\ReportHook;
use Icinga\Module\Reporting\ReportData;
use Icinga\Module\Reporting\Timerange;
use ipl\Html\Html;

/**
 * @TODO(el): Respect restrictions from monitoring module
 */
abstract class IdoReport extends ReportHook
{
    public function getData(Timerange $timerange, array $config = null)
    {
        return $this->fetchSla($timerange, $config);
    }

    public function getHtml(Timerange $timerange, array $config = null)
    {
        $data = $this->fetchSla($timerange, $config);

        if (! count($data)) {
            return Html::tag('p', 'No data found.');
        }

        $tableHeaderCells = [];

        foreach ($data->getDimensions() as $dimension) {
            $tableHeaderCells[] = Html::tag('th', null, $dimension);
        }

        foreach ($data->getValues() as $value) {
            $tableHeaderCells[] = Html::tag('th', null, $value);
        }

        $tableRows = [];

        foreach ($data->getRows() as $row) {
            $cells = [];

            foreach ($row->getDimensions() as $dimension) {
                $cells[] = Html::tag('td', null, $dimension);
            }

            // We only have one metric
            $sla = $row->getValues()[0];

            if ($sla < 99.5) {
                $slaClass = 'nok';
            } else {
                $slaClass = 'ok';
            }

            $cells[] = Html::tag('td', ['class' => "sla-column $slaClass"], \round($sla, 2));

            $tableRows[] = Html::tag('tr', null, $cells);
        }

        // We only have one average
        $average = $data->getAverages()[0];

        if ($average < 99.5) {
            $slaClass = 'nok';
        } else {
            $slaClass = 'ok';
        }

        $tableRows[] = Html::tag('tr', null, [
            Html::tag('td', ['colspan' => count($data->getDimensions())], 'Total'),
            Html::tag('td', ['class' => "sla-column $slaClass"], \round($average, 2))
        ]);

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

    /**
     * @param   Timerange   $timerange
     * @param   array       $config
     *
     * @return  ReportData
     */
    abstract protected function fetchSla(Timerange $timerange, array $config = null);

    protected function getBackend()
    {
        MonitoringBackend::clearInstances();

        return MonitoringBackend::instance();
    }

    protected function applyFilterString($string, Filterable $filterable)
    {
        if ($string === '*') {
            return $filterable;
        }

        $filter = Filter::matchAll();

        $filter->setAllowedFilterColumns(array(
            'host_name',
            'hostgroup_name',
            'instance_name',
            'service_description',
            'servicegroup_name',
            function ($c) {
                return \preg_match('/^_(?:host|service)_/i', $c);
            }
        ));

        try {
            $filter->addFilter(Filter::fromQueryString($string));
        } catch (\Exception $e) {
            throw new ConfigurationError(
                'Cannot apply the filter %s. You can only use the following columns: %s',
                $string,
                \implode(', ', array(
                    'instance_name',
                    'host_name',
                    'hostgroup_name',
                    'service_description',
                    'servicegroup_name',
                    '_(host|service)_<customvar-name>'
                )),
                $e
            );
        }

        $filterable->applyFilter($filter);

        return $filterable;
    }

    protected function fetchHostSla(Timerange $timerange, array $config)
    {
        $sla = $this->getBackend()->select()->from('hoststatus', ['host_display_name'])->order('host_display_name');

        if (isset($config['filter'])) {
            $this->applyFilterString($config['filter'], $sla);
        }

        /** @var \Zend_Db_Select $select */
        $select = $sla->getQuery()->getSelectQuery();

        $columns = $sla->getQuery()->getColumns();
        $columns['sla'] = new \Zend_Db_Expr(\sprintf(
            "idoreports_get_sla_ok_percent(%s, '%s', '%s', NULL)",
            'ho.object_id',
            $timerange->getStart()->format('Y-m-d H:i:s'),
            $timerange->getEnd()->format('Y-m-d H:i:s')
        ));

        $select->columns($columns);

        return $this->getBackend()->getResource()->getDbAdapter()->query($select);
    }

    protected function fetchServiceSla(Timerange $timerange, array $config)
    {
        $sla = $this
            ->getBackend()
            ->select()
            ->from('servicestatus', ['host_display_name', 'service_display_name'])
            ->order('host_display_name');

        if (isset($config['filter'])) {
            $this->applyFilterString($config['filter'], $sla);
        }

        /** @var \Zend_Db_Select $select */
        $select = $sla->getQuery()->getSelectQuery();

        $columns = $sla->getQuery()->getColumns();
        $columns['sla'] = new \Zend_Db_Expr(\sprintf(
            "idoreports_get_sla_ok_percent(%s, '%s', '%s', NULL)",
            'so.object_id',
            $timerange->getStart()->format('Y-m-d H:i:s'),
            $timerange->getEnd()->format('Y-m-d H:i:s')
        ));

        $select->columns($columns);

        return $this->getBackend()->getResource()->getDbAdapter()->query($select);
    }
}
