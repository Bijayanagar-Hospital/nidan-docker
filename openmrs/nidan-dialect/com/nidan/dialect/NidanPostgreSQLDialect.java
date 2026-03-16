package com.nidan.dialect;

import org.hibernate.dialect.PostgreSQL82Dialect;
import java.sql.Types;

public class NidanPostgreSQLDialect extends PostgreSQL82Dialect {
    public NidanPostgreSQLDialect() {
        super();
        registerColumnType(Types.CLOB, "text");
        registerColumnType(Types.BLOB, "bytea");
        registerHibernateType(Types.CLOB, "com.nidan.dialect.StringClobType");
    }
}
