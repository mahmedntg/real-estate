package com.aqar.api.repository;

import java.util.List;
import com.aqar.api.domain.Country;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository for Country entities, exposing the active countries ordered by sort
 * order and code.
 *
 * @author Mohamed Sayed
 */
public interface CountryRepository extends JpaRepository<Country, String> {

    List<Country> findByActiveTrueOrderBySortOrderAscCodeAsc();
}
