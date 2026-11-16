package com.aqar.api.repository;

import java.util.Optional;
import java.util.UUID;
import com.aqar.api.domain.Conversation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository for Conversation entities, loading conversations together with their
 * property, renter and owner and querying them by id or by participant.
 *
 * @author Mohamed Sayed
 */
public interface ConversationRepository extends JpaRepository<Conversation, UUID> {

    @Override
    @EntityGraph(attributePaths = {"property", "renter", "owner"})
    Optional<Conversation> findById(UUID id);

    Optional<Conversation> findByPropertyIdAndRenterId(UUID propertyId, UUID renterId);

    @EntityGraph(attributePaths = {"property", "renter", "owner"})
    Page<Conversation> findByRenterIdOrOwnerId(UUID renterId, UUID ownerId, Pageable pageable);
}
