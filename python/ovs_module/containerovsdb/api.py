import abc

from oslo_utils import importutils
import six


def get_instance(context):
    """Return the configured OVSDB API implementation"""
    iface = importutils.import_module('ovs_module.containerovsdb.impl_idl')
    return iface.api_factory(context)


@six.add_metaclass(abc.ABCMeta)
class ImplAPI(object):
    @abc.abstractmethod
    def has_table_column(self, table, column):
        """Check if a column exists in a database table
        :param table: (string) table name
        :param column: (string) column name
        :return: True if the column exists, False if not.
        """
