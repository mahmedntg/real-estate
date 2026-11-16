package com.aqar.api.repository;

import java.util.Collection;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import com.aqar.api.domain.Favorite;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Spring Data repository for Favorite entities, exposing lookups and deletions by user and
 * property plus queries restricted to properties in active countries.
 *
 * @author Mohamed Sayed
 */
public interface FavoriteRepository extends JpaRepository<Favorite, UUID> {

    boolean existsByUserIdAndPropertyId(UUID userId, UUID propertyId);

    Optional<Favorite> findByUserIdAndPropertyId(UUID userId, UUID propertyId);

    @EntityGraph(attributePaths = "property")
    @Query("select f from Favorite f where f.user.id = :userId and f.property.governorate.country.active = true")
    Page<Favorite> findActiveByUserId(@Param("userId") UUID userId, Pageable pageable);

    @Query("select f.property.id from Favorite f where f.user.id = :userId and f.property.id in :propertyIds")
    Set<UUID> findPropertyIds(@Param("userId") UUID userId, @Param("propertyIds") Collection<UUID> propertyIds);

    void deleteByUserIdAndPropertyId(UUID userId, UUID propertyId);
}
