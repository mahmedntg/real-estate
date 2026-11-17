package com.aqar.api.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import com.aqar.api.domain.Area;
import com.aqar.api.domain.Governorate;
import com.aqar.api.domain.LandKind;
import com.aqar.api.domain.ListingType;
import com.aqar.api.domain.Property;
import com.aqar.api.domain.PropertyType;
import com.aqar.api.domain.User;
import com.aqar.api.payload.response.PageResponse;
import com.aqar.api.exception.ApiException;
import com.aqar.api.payload.request.PropertyWriteRequest;
import com.aqar.api.payload.response.PropertyDetailResponse;
import com.aqar.api.payload.response.PropertySummaryResponse;
import com.aqar.api.repository.FavoriteRepository;
import com.aqar.api.repository.PropertyRepository;
import com.aqar.api.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Creates, updates, deletes and searches property listings.
 *
 * <p>Searches are translated into a JPA specification that always requires an active country and
 * then narrows the result by text, classification, location, price, bedrooms and furnishing, while
 * updates and deletes are limited to the owner or an administrator.
 *
 * @author Mohamed Sayed
 */
@Service
public class PropertyService {

    private static final int MAX_PAGE_SIZE = 50;

    private final PropertyRepository properties;
    private final UserRepository users;
    private final FavoriteRepository favorites;
    private final PropertyMapper mapper;
    private final MediaService mediaService;
    private final LocationService locations;

    /**
     * Creates the service with its repositories and collaborators.
     *
     * @param properties repository of listings
     * @param users repository of accounts
     * @param favorites repository of saved listings
     * @param mapper mapper that builds the listing payloads
     * @param mediaService service that deletes the stored media files of a listing
     * @param locations service used to resolve governorates and areas
     */
    public PropertyService(final PropertyRepository properties, final UserRepository users,
                           final FavoriteRepository favorites, final PropertyMapper mapper,
                           final MediaService mediaService, final LocationService locations) {
        this.properties = properties;
        this.users = users;
        this.favorites = favorites;
        this.mapper = mapper;
        this.mediaService = mediaService;
        this.locations = locations;
    }

    /**
     * Searches active listings with the supplied filters and flags the ones the viewer saved.
     *
     * @param query filters to apply, all optional
     * @param viewerId identifier of the viewing user, may be null for anonymous callers
     * @param sort requested ordering, either price ascending, price descending or newest first
     * @param page zero-based page index
     * @param size requested page size, clamped to the allowed maximum
     * @return page of listing summaries
     */
    @Transactional(readOnly = true)
    public PageResponse<PropertySummaryResponse> search(final SearchQuery query, final UUID viewerId,
                                                        final String sort, final int page, final int size) {
        Pageable pageable = PageRequest.of(normalizePage(page), normalizeSize(size), sortFor(sort));
        Page<Property> result = properties.findAll(toSpecification(query), pageable);

        Set<UUID> favoriteIds = favoriteIds(viewerId, result.getContent());
        List<PropertySummaryResponse> items = result.getContent().stream()
                .map(property -> mapper.summary(property, favoriteIds.contains(property.getId())))
                .toList();
        return PageResponse.of(result, items);
    }

    /**
     * Lists the listings owned by a user, newest first, restricted to active countries.
     *
     * @param ownerId identifier of the owner
     * @param page zero-based page index
     * @param size requested page size, clamped to the allowed maximum
     * @return page of listing summaries
     */
    @Transactional(readOnly = true)
    public PageResponse<PropertySummaryResponse> myListings(final UUID ownerId, final int page, final int size) {
        Pageable pageable = PageRequest.of(normalizePage(page), normalizeSize(size),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Property> result = properties.findByOwnerIdAndGovernorateCountryActiveTrue(ownerId, pageable);
        Set<UUID> favoriteIds = favoriteIds(ownerId, result.getContent());
        List<PropertySummaryResponse> items = result.getContent().stream()
                .map(property -> mapper.summary(property, favoriteIds.contains(property.getId())))
                .toList();
        return PageResponse.of(result, items);
    }

    /**
     * Loads a single listing with the saved and ownership flags of the viewer.
     *
     * @param id identifier of the listing
     * @param viewerId identifier of the viewing user, may be null for anonymous callers
     * @return detail payload of the listing
     */
    @Transactional(readOnly = true)
    public PropertyDetailResponse get(final UUID id, final UUID viewerId) {
        Property property = properties.findById(id)
                .orElseThrow(() -> ApiException.notFound("Property not found"));
        boolean favorite = viewerId != null && favorites.existsByUserIdAndPropertyId(viewerId, id);
        boolean mine = viewerId != null && viewerId.equals(property.getOwner().getId());
        return mapper.detail(property, favorite, mine);
    }

    /**
     * Creates a listing owned by the caller and applies the submitted values to it.
     *
     * @param ownerId identifier of the owner of the new listing
     * @param request submitted listing values
     * @return detail payload of the created listing
     */
    @Transactional
    public PropertyDetailResponse create(final UUID ownerId, final PropertyWriteRequest request) {
        User owner = users.findById(ownerId)
                .orElseThrow(() -> ApiException.notFound("User not found"));
        Property property = new Property();
        property.setOwner(owner);
        apply(property, request);
        properties.saveAndFlush(property);
        return mapper.detail(property, false, true);
    }

    /**
     * Updates a listing after checking that the caller owns it or is an administrator.
     *
     * @param id identifier of the listing to update
     * @param actorId identifier of the user performing the update
     * @param admin whether the caller may manage any listing
     * @param request submitted listing values
     * @return detail payload of the updated listing
     */
    @Transactional
    public PropertyDetailResponse update(final UUID id, final UUID actorId, final boolean admin, final PropertyWriteRequest request) {
        Property property = properties.findById(id)
                .orElseThrow(() -> ApiException.notFound("Property not found"));
        requireManageAccess(property, actorId, admin);
        apply(property, request);
        properties.saveAndFlush(property);
        boolean favorite = favorites.existsByUserIdAndPropertyId(actorId, id);
        return mapper.detail(property, favorite, property.getOwner().getId().equals(actorId));
    }

    /**
     * Deletes a listing and its managed media files after checking ownership.
     *
     * @param id identifier of the listing to delete
     * @param actorId identifier of the user performing the deletion
     * @param admin whether the caller may manage any listing
     */
    @Transactional
    public void delete(final UUID id, final UUID actorId, final boolean admin) {
        Property property = properties.findById(id)
                .orElseThrow(() -> ApiException.notFound("Property not found"));
        requireManageAccess(property, actorId, admin);
        mediaService.deleteManagedImages(property);
        mediaService.deleteManagedVideo(property);
        properties.delete(property);
    }

    /**
     * Rejects the caller unless it is an administrator or the owner of the listing.
     *
     * @param property listing being managed
     * @param actorId identifier of the user performing the change
     * @param admin whether the caller may manage any listing
     */
    private void requireManageAccess(final Property property, final UUID actorId, final boolean admin) {
        if (!admin && !property.getOwner().getId().equals(actorId)) {
            throw ApiException.forbidden("You can only manage your own listings");
        }
    }

    /**
     * Copies the submitted values onto the listing, normalising text and validating that at least
     * one title and one description are present and that the location is active.
     *
     * @param property listing that receives the values
     * @param request submitted listing values
     */
    private void apply(final Property property, final PropertyWriteRequest request) {
        String titleEn = normalize(request.getTitleEn());
        String titleAr = normalize(request.getTitleAr());
        if (titleEn == null && titleAr == null) {
            throw ApiException.badRequest("Missing title", "Provide a title in at least one language");
        }
        String descriptionEn = normalize(request.getDescriptionEn());
        String descriptionAr = normalize(request.getDescriptionAr());
        if (descriptionEn == null && descriptionAr == null) {
            throw ApiException.badRequest("Missing description", "Provide a description in at least one language");
        }
        property.setTitleEn(titleEn == null ? "" : titleEn);
        property.setTitleAr(titleAr == null ? "" : titleAr);
        property.setDescriptionEn(descriptionEn == null ? "" : descriptionEn);
        property.setDescriptionAr(descriptionAr == null ? "" : descriptionAr);
        property.setPropertyType(request.getPropertyType());
        property.setListingType(request.getListingType());
        Governorate governorate = locations.requireActiveGovernorate(
                normalizeCode(request.getCountryCode()), normalizeCode(request.getGovernorateCode()));
        property.setGovernorate(governorate);
        String areaCode = normalize(request.getAreaCode());
        property.setArea(areaCode == null ? null : locations.requireArea(governorate, normalizeCode(areaCode)));
        property.setPrice(request.getPrice());
        applyLand(property, request);
        BigDecimal netArea = property.netAreaSqm();
        if (netArea != null) {
            property.setAreaSqm(netArea);
        } else if (request.getAreaQirats() != null) {
            property.setAreaSqm(Property.qiratsToSqm(request.getAreaQirats()));
        } else {
            property.setAreaSqm(request.getAreaSqm());
        }
        property.setBedrooms(request.getBedrooms());
        property.setBathrooms(request.getBathrooms());
        property.setFurnished(request.isFurnished());
        property.setLatitude(request.getLatitude());
        property.setLongitude(request.getLongitude());
    }

    /**
     * Applies or clears the land detail fields of a listing.
     *
     * <p>Land details are rejected on non-land listings and cleared there, agricultural land must
     * carry an area in qirats, building plots must carry a building permit flag, and the four plot
     * sides are either all present or all absent so the net area can be derived.
     *
     * @param property listing that receives the land details
     * @param request submitted listing values
     */
    private void applyLand(final Property property, final PropertyWriteRequest request) {
        boolean hasLandDetails = request.getLandKind() != null
                || request.getAreaQirats() != null
                || request.getNorthSideM() != null
                || request.getSouthSideM() != null
                || request.getEastSideM() != null
                || request.getWestSideM() != null
                || request.getStreetWidthM() != null
                || request.getBuildingPermit() != null
                || request.getBoundaryNorth() != null
                || request.getBoundarySouth() != null
                || request.getBoundaryEast() != null
                || request.getBoundaryWest() != null;
        if (property.getPropertyType() != PropertyType.LAND) {
            if (hasLandDetails) {
                throw ApiException.badRequest("Invalid land details",
                        "Land details are only allowed on land listings");
            }
            property.setLandKind(null);
            property.setAreaQirats(null);
            property.setNorthSideM(null);
            property.setSouthSideM(null);
            property.setEastSideM(null);
            property.setWestSideM(null);
            property.setStreetWidthM(null);
            property.setBuildingPermit(null);
            property.setBoundaryNorth(null);
            property.setBoundarySouth(null);
            property.setBoundaryEast(null);
            property.setBoundaryWest(null);
            property.setNegotiable(false);
            return;
        }
        boolean anySide = request.getNorthSideM() != null
                || request.getSouthSideM() != null
                || request.getEastSideM() != null
                || request.getWestSideM() != null;
        boolean allSides = request.getNorthSideM() != null
                && request.getSouthSideM() != null
                && request.getEastSideM() != null
                && request.getWestSideM() != null;
        if (anySide && !allSides) {
            throw ApiException.badRequest("Invalid land details",
                    "Provide all four plot sides or none");
        }
        if (request.getLandKind() == LandKind.AGRICULTURAL && request.getAreaQirats() == null) {
            throw ApiException.badRequest("Invalid land details",
                    "Agricultural land requires an area in qirats");
        }
        if (request.getLandKind() == LandKind.BUILDING && request.getBuildingPermit() == null) {
            throw ApiException.badRequest("Invalid land details",
                    "Building plots require a building permit flag");
        }
        property.setLandKind(request.getLandKind());
        property.setAreaQirats(request.getAreaQirats());
        property.setNorthSideM(request.getNorthSideM());
        property.setSouthSideM(request.getSouthSideM());
        property.setEastSideM(request.getEastSideM());
        property.setWestSideM(request.getWestSideM());
        property.setStreetWidthM(request.getStreetWidthM());
        property.setBuildingPermit(request.getBuildingPermit());
        property.setBoundaryNorth(normalize(request.getBoundaryNorth()));
        property.setBoundarySouth(normalize(request.getBoundarySouth()));
        property.setBoundaryEast(normalize(request.getBoundaryEast()));
        property.setBoundaryWest(normalize(request.getBoundaryWest()));
        property.setNegotiable(Boolean.TRUE.equals(request.getNegotiable()));
    }

    /**
     * Translates the search filters into a specification that always requires an active country
     * and then narrows by free text, type, location, price range, bedrooms and furnishing.
     *
     * @param query filters to apply, all optional
     * @return specification combining the active-country rule with every supplied filter
     */
    private Specification<Property> toSpecification(final SearchQuery query) {
        Specification<Property> spec = (root, criteriaQuery, cb) ->
                cb.isTrue(root.get("governorate").get("country").get("active"));

        if (query.q() != null && !query.q().isBlank()) {
            String like = "%" + query.q().trim().toLowerCase() + "%";
            spec = spec.and((root, criteriaQuery, cb) -> {
                Join<Property, Area> area = root.join("area", JoinType.LEFT);
                return cb.or(
                        cb.like(cb.lower(root.get("titleEn")), like),
                        cb.like(cb.lower(root.get("titleAr")), like),
                        cb.like(cb.lower(root.get("descriptionEn")), like),
                        cb.like(cb.lower(root.get("descriptionAr")), like),
                        cb.like(cb.lower(root.get("governorate").get("nameEn")), like),
                        cb.like(cb.lower(root.get("governorate").get("nameAr")), like),
                        cb.like(cb.lower(area.get("nameEn")), like),
                        cb.like(cb.lower(area.get("nameAr")), like));
            });
        }
        if (query.propertyType() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.equal(root.get("propertyType"), query.propertyType()));
        }
        if (query.listingType() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.equal(root.get("listingType"), query.listingType()));
        }
        if (query.countryCode() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.equal(root.get("governorate").get("country").get("code"), query.countryCode()));
        }
        if (query.governorateCode() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.equal(root.get("governorate").get("code"), query.governorateCode()));
        }
        if (query.areaCode() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.equal(root.get("area").get("code"), query.areaCode()));
        }
        if (query.minPrice() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.greaterThanOrEqualTo(root.get("price"), query.minPrice()));
        }
        if (query.maxPrice() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.lessThanOrEqualTo(root.get("price"), query.maxPrice()));
        }
        if (query.bedrooms() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.greaterThanOrEqualTo(root.get("bedrooms"), query.bedrooms()));
        }
        if (query.furnished() != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.equal(root.get("furnished"), query.furnished()));
        }
        return spec;
    }

    /**
     * Resolves which listings of the page are saved by the viewer.
     *
     * @param viewerId identifier of the viewing user, may be null for anonymous callers
     * @param page listings shown on the current page
     * @return identifiers of the listings saved by the viewer, empty when there are none
     */
    private Set<UUID> favoriteIds(final UUID viewerId, final List<Property> page) {
        if (viewerId == null || page.isEmpty()) {
            return Set.of();
        }
        return favorites.findPropertyIds(viewerId, page.stream().map(Property::getId).toList());
    }

    /**
     * Resolves the requested ordering, defaulting to newest first for unknown values.
     *
     * @param sort requested ordering, may be null
     * @return sort applied to the query
     */
    private Sort sortFor(final String sort) {
        if (sort == null) {
            return Sort.by(Sort.Direction.DESC, "createdAt");
        }
        return switch (sort) {
            case "price_asc" -> Sort.by(Sort.Direction.ASC, "price");
            case "price_desc" -> Sort.by(Sort.Direction.DESC, "price");
            default -> Sort.by(Sort.Direction.DESC, "createdAt");
        };
    }

    /**
     * Maps a negative page index to the first page.
     *
     * @param page requested page index
     * @return page index that is at least zero
     */
    private int normalizePage(final int page) {
        return Math.max(page, 0);
    }

    /**
     * Clamps a requested page size, falling back to twelve when it is not positive.
     *
     * @param size requested page size
     * @return page size within the allowed range
     */
    private int normalizeSize(final int size) {
        if (size < 1) {
            return 12;
        }
        return Math.min(size, MAX_PAGE_SIZE);
    }

    /**
     * Trims a value and maps blank strings to null.
     *
     * @param value raw value
     * @return trimmed value, or null when absent or blank
     */
    private String normalize(final String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    /**
     * Normalises a location code to upper case after trimming it.
     *
     * @param value raw location code
     * @return upper case code, or null when absent or blank
     */
    private String normalizeCode(final String value) {
        String normalized = normalize(value);
        return normalized == null ? null : normalized.toUpperCase(Locale.ROOT);
    }

    /**
     * Optional filters accepted by the listing search, combined with an AND when supplied.
     *
     * <p>Numeric and boolean filters compare directly, while the text filter matches the titles,
     * descriptions, governorate names and area names.
     *
     * @author Mohamed Sayed
     */
    public record SearchQuery(
            String q,
            PropertyType propertyType,
            ListingType listingType,
            String countryCode,
            String governorateCode,
            String areaCode,
            BigDecimal minPrice,
            BigDecimal maxPrice,
            Integer bedrooms,
            Boolean furnished) {
    }
}
