package com.aqar.api.web;

import java.util.UUID;
import com.aqar.api.payload.response.PageResponse;
import com.aqar.api.payload.response.PropertySummaryResponse;
import com.aqar.api.security.CurrentUser;
import com.aqar.api.service.FavoriteService;
import com.aqar.api.service.PropertyService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Exposes the endpoints for saved listings and for the caller's own listings.
 *
 * @author Mohamed Sayed
 */
@RestController
public class FavoriteController {

    private final FavoriteService favoriteService;
    private final PropertyService propertyService;
    private final CurrentUser currentUser;

    /**
     * Creates the controller with its favorite and listing collaborators.
     *
     * @param favoriteService service managing saved listings
     * @param propertyService service reading listing summaries
     * @param currentUser resolver for the authenticated caller
     */
    public FavoriteController(final FavoriteService favoriteService, final PropertyService propertyService,
                              final CurrentUser currentUser) {
        this.favoriteService = favoriteService;
        this.propertyService = propertyService;
        this.currentUser = currentUser;
    }

    /**
     * Saves a listing to the caller's favorites, doing nothing when it is already saved.
     *
     * @param id listing identifier
     */
    @PutMapping("/api/v1/properties/{id}/favorite")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void add(@PathVariable final UUID id) {
        favoriteService.add(id, currentUser.requireId());
    }

    /**
     * Removes a listing from the caller's favorites.
     *
     * @param id listing identifier
     */
    @DeleteMapping("/api/v1/properties/{id}/favorite")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@PathVariable final UUID id) {
        favoriteService.remove(id, currentUser.requireId());
    }

    /**
     * Lists the listings the caller saved, newest favorite first.
     *
     * @param page zero-based page index
     * @param size page size
     * @return paginated saved listing summaries
     */
    @GetMapping("/api/v1/me/favorites")
    public PageResponse<PropertySummaryResponse> list(@RequestParam(defaultValue = "0") final int page,
                                              @RequestParam(defaultValue = "12") final int size) {
        return favoriteService.list(currentUser.requireId(), page, size);
    }

    /**
     * Lists the listings owned by the caller, newest first.
     *
     * @param page zero-based page index
     * @param size page size
     * @return paginated summaries of the caller's listings
     */
    @GetMapping("/api/v1/me/properties")
    public PageResponse<PropertySummaryResponse> myListings(@RequestParam(defaultValue = "0") final int page,
                                                    @RequestParam(defaultValue = "12") final int size) {
        return propertyService.myListings(currentUser.requireId(), page, size);
    }
}
