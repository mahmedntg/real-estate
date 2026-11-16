package com.aqar.api.repository;

import java.util.List;
import java.util.Optional;
import com.aqar.api.domain.Governorate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

/**
 * Spring Data repository for Governorate entities, exposing active governorates ordered by
 * country, governorate sort order and id plus a lookup by country code and governorate code.
 *
 * @author Mohamed Sayed
 */
public interface GovernorateRepository extends JpaRepository<Governorate, Long> {

    @Query("select g from Governorate g join fetch g.country c where c.active = true order by c.code, g.sortOrder, g.id")
    List<Governorate> findAllActiveOrdered();

    Optional<Governorate> findByCountry_CodeAndCode(String countryCode, String code);
}
