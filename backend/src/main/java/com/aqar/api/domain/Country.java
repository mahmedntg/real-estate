package com.aqar.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * JPA entity mapped to the countries table, holding bilingual names and taglines, currency code
 * and symbols, a sort order and an active flag that limits the visible catalogue.
 *
 * @author Mohamed Sayed
 */
@Entity
@Table(name = "countries")
public class Country {

    @Id
    @Column(length = 2)
    private String code;

    @Column(name = "name_en", nullable = false, length = 80)
    private String nameEn;

    @Column(name = "name_ar", nullable = false, length = 80)
    private String nameAr;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "currency_symbol_en", nullable = false, length = 10)
    private String currencySymbolEn;

    @Column(name = "currency_symbol_ar", nullable = false, length = 10)
    private String currencySymbolAr;

    @Column(name = "tagline_en", nullable = false, length = 160)
    private String taglineEn;

    @Column(name = "tagline_ar", nullable = false, length = 160)
    private String taglineAr;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(nullable = false)
    private boolean active;

    public String getCode() {
        return code;
    }

    public String getNameEn() {
        return nameEn;
    }

    public String getNameAr() {
        return nameAr;
    }

    public String getCurrencyCode() {
        return currencyCode;
    }

    public String getCurrencySymbolEn() {
        return currencySymbolEn;
    }

    public String getCurrencySymbolAr() {
        return currencySymbolAr;
    }

    public String getTaglineEn() {
        return taglineEn;
    }

    public String getTaglineAr() {
        return taglineAr;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public boolean isActive() {
        return active;
    }
}
