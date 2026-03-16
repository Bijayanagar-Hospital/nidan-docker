package com.nidan.dialect;

import org.hibernate.boot.model.TypeContributions;
import org.hibernate.boot.model.TypeContributor;
import org.hibernate.service.ServiceRegistry;

/**
 * Registers StringClobType to override Hibernate's default
 * CLOB handling — intercepted before .hbm.xml type resolution.
 */
public class ClobToTextTypeContributor implements TypeContributor {

    @Override
    public void contribute(TypeContributions typeContributions,
                           ServiceRegistry serviceRegistry) {
        typeContributions.contributeType(
            new StringClobType(),
            new String[]{
                "clob",
                "text",                // catches hbm.xml type="text"
                "java.sql.Clob",
                "org.hibernate.type.TextType"
            }
        );
    }
}