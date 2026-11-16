package com.aqar.api.web;

import java.math.BigDecimal;
import java.util.Locale;
import java.util.UUID;
import com.aqar.api.domain.ListingType;
import com.aqar.api.domain.PropertyType;
import com.aqar.api.payload.request.PropertyWriteRequest;
import com.aqar.api.payload.response.PageResponse;
import com.aqar.api.payload.response.PropertyDetailResponse;
import com.aqar.api.payload.response.PropertySummaryResponse;
import com.aqar.api.security.CurrentUser;
import com.aqar.api.service.PropertyService;
import com.aqar.api.service.PropertyService.SearchQuery;
import com.aqar.api.validation.ValidationGroups;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Exposes the listing search, detail, creation, update and deletion endpoints.
 *
 * @author Mohamed Sayed
 */
@RestController
@RequestMapping("/api/v1/properties")
public class PropertyController {

    private final PropertyService propertyService;
    private final CurrentUser currentUser;

    /**
     * Creates the controller with its listing collaborators.
     *
     * @param propertyService service reading and writing listings
     * @param currentUser resolver for the authenticated caller
     */
    public PropertyController(final PropertyService propertyService, final CurrentUser currentUser) {
        this.propertyService = propertyService;
        this.currentUser = currentUser;
    }

    /**
     * Searches listings of active countries and returns a paginated summary page.
     *
     * @param q free-text term matched against titles, descriptions, governorates and areas
     * @param type property type filter
     * @param listingType sale or rent filter
     * @param country country code filter, matched case-insensitively
     * @param governorate governorate code filter, matched case-insensitively
     * @param area area code filter, matched case-insensitively
     * @param minPrice minimum price filter
     * @param maxPrice maximum price filter
     * @param bedrooms minimum bedrooms filter
     * @param furnished furnished flag filter
     * @param sort sort option: newest, price_asc or price_desc
     * @param page zero-based page index
     * @param size page size, defaults to twelve
     * @return paginated listing summaries marked with the caller's favorites
     */
    @GetMapping
    public PageResponse<PropertySummaryResponse> search(
            @RequestParam(required = false) final String q,
            @RequestParam(required = false) final PropertyType type,
            @RequestParam(required = false) final ListingType listingType,
            @RequestParam(required = false) final String country,
            @RequestParam(required = false) final String governorate,
            @RequestParam(required = false) final String area,
            @RequestParam(required = false) final BigDecimal minPrice,
            @RequestParam(required = false) final BigDecimal maxPrice,
            @RequestParam(required = false) final Integer bedrooms,
            @RequestParam(required = false) final Boolean furnished,
            @RequestParam(defaultValue = "newest") final String sort,
            @RequestParam(defaultValue = "0") final int page,
            @RequestParam(defaultValue = "12") final int size) {

        SearchQuery query = new SearchQuery(q, type, listingType, code(country), code(governorate),
                code(area), minPrice, maxPrice, bedrooms, furnished);
        return propertyService.search(query, currentUser.id().orElse(null), sort, page, size);
    }

    /**
     * Normalises a location code by trimming it and upper-casing it.
     *
     * @param value raw query value
     * @return trimmed upper-case code, or null when the value is missing or blank
     */
    private String code(final String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim().toUpperCase(Locale.ROOT);
    }

    /**
     * Returns one listing with its media and the caller's favorite and ownership flags.
     *
     * @param id listing identifier
     * @return full listing detail
     */
    @GetMapping("/{id}")
    public PropertyDetailResponse get(@PathVariable final UUID id) {
        return propertyService.get(id, currentUser.id().orElse(null));
    }

    /**
     * Creates a listing owned by the authenticated caller.
     *
     * @param request listing payload to persist
     * @return the created listing detail
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PropertyDetailResponse create(
            @Validated(ValidationGroups.OnCreate.class) @RequestBody final PropertyWriteRequest request) {
        return propertyService.create(currentUser.requireId(), request);
    }

    /**
     * Updates a listing owned by the caller, or any listing when the caller is an admin.
     *
     * @param id listing identifier
     * @param request listing payload to apply
     * @return the updated listing detail
     */
    @PutMapping("/{id}")
    public PropertyDetailResponse update(@PathVariable final UUID id,
                                         @Validated(ValidationGroups.OnUpdate.class)
                                         @RequestBody final PropertyWriteRequest request) {
        return propertyService.update(id, currentUser.requireId(), currentUser.isAdmin(), request);
    }

    /**
     * Deletes a listing owned by the caller, or any listing when the caller is an admin.
     *
     * @param id listing identifier
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable final UUID id) {
        propertyService.delete(id, currentUser.requireId(), currentUser.isAdmin());
    }
}
