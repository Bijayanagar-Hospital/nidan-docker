package org.openmrs.hibernate.dialect;

import org.hibernate.dialect.PostgreSQL82Dialect;
import org.hibernate.type.descriptor.sql.SqlTypeDescriptor;
import org.hibernate.type.descriptor.sql.VarcharTypeDescriptor;
import org.hibernate.type.descriptor.sql.BinaryTypeDescriptor;
import java.sql.Types;

public class NidanPostgreSQLDialect extends PostgreSQL82Dialect {
    public NidanPostgreSQLDialect() {
        super();
        registerColumnType(Types.BLOB, "bytea");
        registerColumnType(Types.VARBINARY, "bytea");
        registerColumnType(Types.LONGVARBINARY, "bytea");
        registerColumnType(Types.BINARY, "bytea");
        registerColumnType(Types.CLOB, "text");
        registerColumnType(Types.LONGVARCHAR, "text");
        registerColumnType(Types.VARCHAR, "character varying($l)");
    }

    @Override
    public SqlTypeDescriptor getSqlTypeDescriptorOverride(int sqlCode) {
        if (sqlCode == Types.CLOB || sqlCode == Types.LONGVARCHAR) {
            return VarcharTypeDescriptor.INSTANCE;
        }
        if (sqlCode == Types.BLOB || sqlCode == Types.VARBINARY || sqlCode == Types.LONGVARBINARY || sqlCode == Types.BINARY) {
            return BinaryTypeDescriptor.INSTANCE;
        }
        return super.getSqlTypeDescriptorOverride(sqlCode);
    }

    @Override
    public SqlTypeDescriptor remapSqlTypeDescriptor(SqlTypeDescriptor sqlTypeDescriptor) {
        if (sqlTypeDescriptor.getSqlType() == Types.CLOB || sqlTypeDescriptor.getSqlType() == Types.LONGVARCHAR) {
            return VarcharTypeDescriptor.INSTANCE;
        }
        if (sqlTypeDescriptor.getSqlType() == Types.BLOB || sqlTypeDescriptor.getSqlType() == Types.VARBINARY || sqlTypeDescriptor.getSqlType() == Types.LONGVARBINARY || sqlTypeDescriptor.getSqlType() == Types.BINARY) {
            return BinaryTypeDescriptor.INSTANCE;
        }
        return super.remapSqlTypeDescriptor(sqlTypeDescriptor);
    }
}
