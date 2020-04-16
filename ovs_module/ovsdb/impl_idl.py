from ovs.db import idl
from ovsdbapp.backend.ovs_idl import connection
from ovsdbapp.backend.ovs_idl import idlutils
from ovsdbapp.backend.ovs_idl import vlog
from ovsdbapp.schema.open_vswitch import impl_idl

from ovs_module.ovsdb import api


def idl_factory(config):
    conn = config.connection
    schema_name = 'Open_vSwitch'
    helper = idlutils.get_schema_helper(conn, schema_name)
    helper.register_all()
    return idl.Idl(conn, helper)


def api_factory(config):
    conn = connection.Connection(
        idl=idl_factory(config),
        timeout=config.timeout)
    return OvsdbIdl(conn)


class OvsdbIdl(impl_idl.OvsdbIdl, api.ImplAPI):
    """IDL interface for OVS database back-end
    This class provides an OVSDB IDL (Open vSwitch Database Interface
    Definition Language) interface to the OVS back-end.
    """
    def __init__(self, conn):
        vlog.use_python_logger()
        super(OvsdbIdl, self).__init__(conn)

    def _get_table_columns(self, table):
        return list(self.tables[table].columns)

    def has_table_column(self, table, column):
        return column in self._get_table_columns(table)
