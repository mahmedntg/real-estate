package com.aqar.api.repository;

import java.util.UUID;
import com.aqar.api.domain.Property;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

/**
 * Spring Data repository for Property entities with specification support, exposing owner
 * listings restricted to active countries plus an existence check on the English title.
 *
 * @author Mohamed Sayed
 */
public interface PropertyRepository extends JpaRepository<Property, UUID>, JpaSpecificationExecutor<Property> {

    Page<Property> findByOwnerIdAndGovernorateCountryActiveTrue(UUID ownerId, Pageable pageable);

    boolean existsByTitleEn(String titleEn);
}
