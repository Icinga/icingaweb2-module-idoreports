<?php

namespace Icinga\Module\Idoreports;

use Icinga\Data\Filter\Filter;
use Icinga\Data\Filterable;
use Icinga\Exception\ConfigurationError;
use Icinga\Module\Monitoring\Backend\MonitoringBackend;
use Icinga\Module\Reporting\Hook\ReportHook;
use Icinga\Module\Reporting\Timerange;

/**
 * @TODO(el): Respect restrictions from monitoring module
 */
abstract class IdoReport extends ReportHook
{
    protected function getBackend()
    {
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
        $sla = $this->getBackend()->select()->from('hoststatus', ['host_display_name']);

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
        $sla = $this->getBackend()->select()->from('servicestatus', ['host_display_name', 'service_display_name']);

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
