package com.aqar.api.web;

import java.time.Duration;
import java.util.List;
import com.aqar.api.payload.response.CountryResponse;
import com.aqar.api.service.LocationService;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Exposes the read-only location catalog of countries, governorates and areas.
 *
 * @author Mohamed Sayed
 */
@RestController
@RequestMapping("/api/v1/locations")
public class LocationController {

    private final LocationService locationService;

    /**
     * Creates the controller with its location collaborator.
     *
     * @param locationService service reading the location catalog
     */
    public LocationController(final LocationService locationService) {
        this.locationService = locationService;
    }

    /**
     * Returns the active countries with their governorates and areas, cacheable for one hour.
     *
     * @return country catalog with nested governorates and areas
     */
    @GetMapping
    public ResponseEntity<List<CountryResponse>> catalog() {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.maxAge(Duration.ofHours(1)).cachePublic())
                .body(locationService.catalog());
    }
}
