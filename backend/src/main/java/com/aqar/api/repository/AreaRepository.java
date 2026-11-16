package com.aqar.api.repository;

import java.util.List;
import java.util.Optional;
import com.aqar.api.domain.Area;
import com.aqar.api.domain.Governorate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

/**
 * Spring Data repository for Area entities, exposing active areas ordered by governorate
 * and area sort order plus a lookup by governorate and area code.
 *
 * @author Mohamed Sayed
 */
public interface AreaRepository extends JpaRepository<Area, Long> {

    @Query("select a from Area a join fetch a.governorate g join g.country c where c.active = true order by g.sortOrder, a.sortOrder, a.id")
    List<Area> findAllActiveOrdered();

    Optional<Area> findByGovernorateAndCode(Governorate governorate, String code);
}
