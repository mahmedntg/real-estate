package com.aqar.api.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import com.aqar.api.domain.Area;
import com.aqar.api.domain.Country;
import com.aqar.api.domain.Governorate;
import com.aqar.api.payload.response.AreaResponse;
import com.aqar.api.payload.response.CountryResponse;
import com.aqar.api.payload.response.GovernorateResponse;
import com.aqar.api.exception.ApiException;
import com.aqar.api.repository.AreaRepository;
import com.aqar.api.repository.CountryRepository;
import com.aqar.api.repository.GovernorateRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resolves countries, governorates and areas and builds the location catalog.
 *
 * <p>Unknown codes are reported as bad requests, and inactive countries are rejected when a
 * governorate is required for a new listing.
 *
 * @author Mohamed Sayed
 */
@Service
public class LocationService {

    private final CountryRepository countries;
    private final GovernorateRepository governorates;
    private final AreaRepository areas;

    /**
     * Creates the service with its repositories.
     *
     * @param countries repository of countries
     * @param governorates repository of governorates
     * @param areas repository of areas
     */
    public LocationService(final CountryRepository countries, final GovernorateRepository governorates,
                           final AreaRepository areas) {
        this.countries = countries;
        this.governorates = governorates;
        this.areas = areas;
    }

    /**
     * Builds the active location tree with areas nested under governorates and governorates
     * nested under countries, all ordered by their configured sort order.
     *
     * @return ordered list of countries with their governorates and areas
     */
    @Transactional(readOnly = true)
    public List<CountryResponse> catalog() {
        Map<Long, List<AreaResponse>> areasByGovernorate = new LinkedHashMap<>();
        for (Area area : areas.findAllActiveOrdered()) {
            areasByGovernorate.computeIfAbsent(area.getGovernorate().getId(), id -> new ArrayList<>())
                    .add(areaView(area));
        }

        Map<String, List<GovernorateResponse>> governoratesByCountry = new LinkedHashMap<>();
        for (Governorate governorate : governorates.findAllActiveOrdered()) {
            governoratesByCountry.computeIfAbsent(governorate.getCountry().getCode(), code -> new ArrayList<>())
                    .add(governorateView(governorate,
                            areasByGovernorate.getOrDefault(governorate.getId(), List.of())));
        }

        List<CountryResponse> catalog = new ArrayList<>();
        for (Country country : countries.findByActiveTrueOrderBySortOrderAscCodeAsc()) {
            catalog.add(countryView(country, governoratesByCountry.getOrDefault(country.getCode(), List.of())));
        }
        return catalog;
    }

    /**
     * Maps a stored area to its code and bilingual names.
     *
     * @param area area to map
     * @return area response
     */
    private AreaResponse areaView(final Area area) {
        AreaResponse response = new AreaResponse();
        response.setCode(area.getCode());
        response.setNameEn(area.getNameEn());
        response.setNameAr(area.getNameAr());
        return response;
    }

    /**
     * Maps a stored governorate to its code, bilingual names and mapped areas.
     *
     * @param governorate governorate to map
     * @param areas mapped areas of the governorate
     * @return governorate response
     */
    private GovernorateResponse governorateView(final Governorate governorate, final List<AreaResponse> areas) {
        GovernorateResponse response = new GovernorateResponse();
        response.setCode(governorate.getCode());
        response.setNameEn(governorate.getNameEn());
        response.setNameAr(governorate.getNameAr());
        response.setAreas(areas);
        return response;
    }

    /**
     * Maps a stored country to its names, currency details, taglines and mapped governorates.
     *
     * @param country country to map
     * @param governorates mapped governorates of the country
     * @return country response
     */
    private CountryResponse countryView(final Country country, final List<GovernorateResponse> governorates) {
        CountryResponse response = new CountryResponse();
        response.setCode(country.getCode());
        response.setNameEn(country.getNameEn());
        response.setNameAr(country.getNameAr());
        response.setCurrencyCode(country.getCurrencyCode());
        response.setCurrencySymbolEn(country.getCurrencySymbolEn());
        response.setCurrencySymbolAr(country.getCurrencySymbolAr());
        response.setTaglineEn(country.getTaglineEn());
        response.setTaglineAr(country.getTaglineAr());
        response.setGovernorates(governorates);
        return response;
    }

    /**
     * Resolves a governorate by its country and governorate codes.
     *
     * @param countryCode country code the governorate belongs to
     * @param governorateCode governorate code to resolve
     * @return the matching governorate
     */
    @Transactional(readOnly = true)
    public Governorate requireGovernorate(final String countryCode, final String governorateCode) {
        return governorates.findByCountry_CodeAndCode(countryCode, governorateCode)
                .orElseThrow(() -> ApiException.badRequest("Invalid location",
                        "Unknown governorate '" + governorateCode + "' for country '" + countryCode + "'"));
    }

    /**
     * Resolves a governorate and rejects it when its country is not accepting listings.
     *
     * @param countryCode country code the governorate belongs to
     * @param governorateCode governorate code to resolve
     * @return the matching governorate of an active country
     */
    @Transactional(readOnly = true)
    public Governorate requireActiveGovernorate(final String countryCode, final String governorateCode) {
        Governorate governorate = requireGovernorate(countryCode, governorateCode);
        if (!governorate.getCountry().isActive()) {
            throw ApiException.badRequest("Invalid location",
                    "Listings are not accepted for country '" + countryCode + "'");
        }
        return governorate;
    }

    /**
     * Resolves an area inside the given governorate.
     *
     * @param governorate governorate the area belongs to
     * @param areaCode area code to resolve
     * @return the matching area
     */
    @Transactional(readOnly = true)
    public Area requireArea(final Governorate governorate, final String areaCode) {
        return areas.findByGovernorateAndCode(governorate, areaCode)
                .orElseThrow(() -> ApiException.badRequest("Invalid location",
                        "Unknown area '" + areaCode + "' for governorate '" + governorate.getCode() + "'"));
    }
}
