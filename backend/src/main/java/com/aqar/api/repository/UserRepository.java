package com.aqar.api.repository;

import java.util.Optional;
import java.util.UUID;
import com.aqar.api.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository for User entities, exposing case-insensitive lookups and existence
 * checks by email address plus phone lookups used to enforce a unique mobile number.
 *
 * @author Mohamed Sayed
 */
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);

    boolean existsByPhone(String phone);

    boolean existsByPhoneAndIdNot(String phone, UUID id);
}
