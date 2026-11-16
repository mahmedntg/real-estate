package com.aqar.api.service;

import com.aqar.api.domain.Property;
import com.aqar.api.payload.model.ImageView;
import com.aqar.api.payload.model.OwnerView;
import com.aqar.api.payload.response.PropertyDetailResponse;
import com.aqar.api.payload.response.PropertySummaryResponse;
import org.springframework.stereotype.Component;

/**
 * Maps stored listings to the summary and detail payloads returned by the API.
 *
 * <p>The mapping is read-only and exposes the country and area codes alongside the land details
 * so the client can render cards and detail pages without extra calls.
 *
 * @author Mohamed Sayed
 */
@Component
public class PropertyMapper {

    /**
     * Builds the compact listing card payload, using the first image as the cover.
     *
     * @param property listing to map
     * @param favorite whether the viewer saved this listing
     * @return summary payload of the listing
     */
    public PropertySummaryResponse summary(final Property property, final boolean favorite) {
        PropertySummaryResponse response = new PropertySummaryResponse();
        response.setId(property.getId());
        response.setTitleEn(property.getTitleEn());
        response.setTitleAr(property.getTitleAr());
        response.setPropertyType(property.getPropertyType());
        response.setListingType(property.getListingType());
        response.setCountryCode(property.getGovernorate().getCountry().getCode());
        response.setGovernorateCode(property.getGovernorate().getCode());
        response.setAreaCode(areaCode(property));
        response.setPrice(property.getPrice());
        response.setAreaSqm(property.getAreaSqm());
        response.setBedrooms(property.getBedrooms());
        response.setBathrooms(property.getBathrooms());
        response.setFurnished(property.isFurnished());
        response.setCoverImage(property.getImages().isEmpty() ? null : property.getImages().get(0).getUrl());
        response.setFavorite(favorite);
        response.setCreatedAt(property.getCreatedAt());
        response.setLandKind(property.getLandKind());
        response.setAreaQirats(property.getAreaQirats());
        response.setNegotiable(property.isNegotiable());
        return response;
    }

    /**
     * Builds the full listing payload with images, owner, land details and viewer flags.
     *
     * @param property listing to map
     * @param favorite whether the viewer saved this listing
     * @param mine whether the viewer owns this listing
     * @return detail payload of the listing
     */
    public PropertyDetailResponse detail(final Property property, final boolean favorite, final boolean mine) {
        PropertyDetailResponse response = new PropertyDetailResponse();
        response.setId(property.getId());
        response.setTitleEn(property.getTitleEn());
        response.setTitleAr(property.getTitleAr());
        response.setDescriptionEn(property.getDescriptionEn());
        response.setDescriptionAr(property.getDescriptionAr());
        response.setPropertyType(property.getPropertyType());
        response.setListingType(property.getListingType());
        response.setCountryCode(property.getGovernorate().getCountry().getCode());
        response.setGovernorateCode(property.getGovernorate().getCode());
        response.setAreaCode(areaCode(property));
        response.setPrice(property.getPrice());
        response.setAreaSqm(property.getAreaSqm());
        response.setBedrooms(property.getBedrooms());
        response.setBathrooms(property.getBathrooms());
        response.setFurnished(property.isFurnished());
        response.setLatitude(property.getLatitude());
        response.setLongitude(property.getLongitude());
        response.setImages(property.getImages().stream().map(this::image).toList());
        response.setVideoUrl(property.getVideoUrl());
        response.setOwner(owner(property));
        response.setFavorite(favorite);
        response.setMine(mine);
        response.setCreatedAt(property.getCreatedAt());
        response.setUpdatedAt(property.getUpdatedAt());
        response.setLandKind(property.getLandKind());
        response.setAreaQirats(property.getAreaQirats());
        response.setFrontageM(property.getFrontageM());
        response.setDepthM(property.getDepthM());
        response.setStreetWidthM(property.getStreetWidthM());
        response.setBuildingPermit(property.getBuildingPermit());
        response.setBoundaryNorth(property.getBoundaryNorth());
        response.setBoundarySouth(property.getBoundarySouth());
        response.setBoundaryEast(property.getBoundaryEast());
        response.setBoundaryWest(property.getBoundaryWest());
        response.setNegotiable(property.isNegotiable());
        return response;
    }

    /**
     * Maps a stored image to its identifier and serving URL.
     *
     * @param image stored image
     * @return image reference
     */
    private ImageView image(final com.aqar.api.domain.PropertyImage image) {
        ImageView view = new ImageView();
        view.setId(image.getId());
        view.setUrl(image.getUrl());
        return view;
    }

    /**
     * Maps the owner of a listing to its identifier and display name.
     *
     * @param property listing whose owner is mapped
     * @return owner reference
     */
    private OwnerView owner(final Property property) {
        OwnerView view = new OwnerView();
        view.setId(property.getOwner().getId());
        view.setFullName(property.getOwner().getFullName());
        return view;
    }

    /**
     * Returns the area code of a listing, or null when no area is assigned.
     *
     * @param property listing to read
     * @return area code of the listing, or null
     */
    private String areaCode(final Property property) {
        return property.getArea() == null ? null : property.getArea().getCode();
    }
}
