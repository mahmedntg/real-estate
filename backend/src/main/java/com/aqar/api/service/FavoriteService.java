package com.aqar.api.service;

import java.util.List;
import java.util.UUID;
import com.aqar.api.domain.Favorite;
import com.aqar.api.domain.Property;
import com.aqar.api.domain.User;
import com.aqar.api.payload.response.PageResponse;
import com.aqar.api.payload.response.PropertySummaryResponse;
import com.aqar.api.exception.ApiException;
import com.aqar.api.repository.FavoriteRepository;
import com.aqar.api.repository.PropertyRepository;
import com.aqar.api.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Manages the saved listings of a user.
 *
 * <p>Adding a listing twice is a no-op, and the saved listings are listed newest first with a
 * clamped page size.
 *
 * @author Mohamed Sayed
 */
@Service
public class FavoriteService {

    private static final int MAX_PAGE_SIZE = 50;

    private final FavoriteRepository favorites;
    private final PropertyRepository properties;
    private final UserRepository users;
    private final PropertyMapper mapper;

    /**
     * Creates the service with its repositories and the listing mapper.
     *
     * @param favorites repository of saved listings
     * @param properties repository used to resolve the saved listing
     * @param users repository used to reference the saving user
     * @param mapper mapper that builds the listing summaries
     */
    public FavoriteService(final FavoriteRepository favorites, final PropertyRepository properties,
                           final UserRepository users, final PropertyMapper mapper) {
        this.favorites = favorites;
        this.properties = properties;
        this.users = users;
        this.mapper = mapper;
    }

    /**
     * Saves a listing for the user, silently succeeding when it is already saved.
     *
     * @param propertyId identifier of the listing to save
     * @param userId identifier of the user saving it
     */
    @Transactional
    public void add(final UUID propertyId, final UUID userId) {
        if (favorites.existsByUserIdAndPropertyId(userId, propertyId)) {
            return;
        }
        Property property = properties.findById(propertyId)
                .orElseThrow(() -> ApiException.notFound("Property not found"));
        User user = users.getReferenceById(userId);

        Favorite favorite = new Favorite();
        favorite.setUser(user);
        favorite.setProperty(property);
        favorites.save(favorite);
    }

    /**
     * Removes a listing from the user's saved listings.
     *
     * @param propertyId identifier of the listing to remove
     * @param userId identifier of the user removing it
     */
    @Transactional
    public void remove(final UUID propertyId, final UUID userId) {
        favorites.deleteByUserIdAndPropertyId(userId, propertyId);
    }

    /**
     * Lists the listings the user saved, newest first, each flagged as a favourite.
     *
     * @param userId identifier of the user whose favourites are listed
     * @param page zero-based page index
     * @param size requested page size, clamped to the allowed maximum
     * @return page of listing summaries
     */
    @Transactional(readOnly = true)
    public PageResponse<PropertySummaryResponse> list(final UUID userId, final int page, final int size) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), clamp(size),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Favorite> result = favorites.findActiveByUserId(userId, pageable);
        List<PropertySummaryResponse> items = result.getContent().stream()
                .map(favorite -> mapper.summary(favorite.getProperty(), true))
                .toList();
        return PageResponse.of(result, items);
    }

    /**
     * Clamps a requested page size, falling back to twelve when it is not positive.
     *
     * @param size requested page size
     * @return page size within the allowed range
     */
    private int clamp(final int size) {
        if (size < 1) {
            return 12;
        }
        return Math.min(size, MAX_PAGE_SIZE);
    }
}
